#!/usr/bin/env -S make -s -f
##
# compose.mk
#
# This is designed to be used as an `include` from your project's main Makefile.
#
# DOCS: https://github.com/elo-enterprises/k8s-tools#compose.mk
#
# LATEST: https://github.com/elo-enterprises/k8s-tools/tree/master/compose.mk
#
# USAGE: (Add this to your project Makefile)
#      include compose.mk
#      $(eval $(call compose.import, ▰, ., docker-compose.yml))
#
#      # example for target dispatch:
#      # a target that runs inside the `debian` container
#      demo: ▰/debian/demo
#      .demo:
#      		uname -n -v
#
# USAGE: (Via CLI Interface)
#      # drop into debugging shell for the container
#      make <stem_of_compose_file>/<name_of_compose_service>/shell
#
#      # stream data into container
#      echo echo hello-world | make <stem_of_compose_file>/<name_of_compose_service>/shell/pipe
#
#      # show full interface (see also: https://github.com/elo-enterprises/k8s-tools#makecompose-bridge)
#      make help
#
# APOLOGIES: In advance if you're checking out the implementation.
#      Make-macros are not the most fun stuff to read or write.
#      Pull requests are welcome! =P
########################################################################
## BEGIN: data

# Color constants and other stuff for formatting user-messages
NO_ANSI=\033[0m
GREEN=\033[92m
YELLOW=\033[33m
DIM=\033[2m
UNDERLINE=\033[4m
BOLD=\033[1m
ITAL=\033[3m
NO_COLOR=\e[39m
RED=\033[91m
CYAN=\033[96m
DIM_RED:=${DIM}${RED}
DIM_CYAN:=${DIM}${CYAN}
BOLD_CYAN:=${BOLD}${CYAN}
BOLD_GREEN:=${BOLD}${GREEN}
DIM_GREEN:=${DIM}${GREEN}
DIM_ITAL:=${DIM}${ITAL}
NO_ANSI_DIM:=${NO_ANSI}${DIM}
CYAN_FLOW_LEFT:=${BOLD_CYAN}⋘${DIM}⋘${NO_ANSI_DIM}⋘${NO_ANSI}
GREEN_FLOW_LEFT:=${BOLD_GREEN}⋘${DIM}⋘${NO_ANSI_DIM}⋘${NO_ANSI}
SEP:=${NO_ANSI}//

# Glyphs used in log messages
GLYPH_DOCKER=${GREEN}${BOLD}≣${NO_ANSI}${DIM_GREEN}
GLYPH_IO=${GREEN}${BOLD}⇄${NO_ANSI}${DIM_GREEN}
GLYPH_FLUX=${GREEN}${BOLD}⋇${NO_ANSI}${DIM_GREEN}

# Hints for compose files to fix file permissions (see k8s-tools.yml for an example of how this is used)
OS_NAME:=$(shell uname -s)
ifeq (${OS_NAME},Darwin)
export DOCKER_UID:=0
export DOCKER_GID:=0
export DOCKER_UGNAME:=root
else 
export DOCKER_UID:=$(shell id -u)
export DOCKER_GID:=$(shell getent group docker 2> /dev/null | cut -d: -f3 || id -g)
export DOCKER_UGNAME:=user
endif

# Honored by `docker compose`, this helps to quiet output
export COMPOSE_IGNORE_ORPHANS?=True

# Used internally.  This is 1 if dispatched inside container, otherwise 0
export COMPOSE_MK_DIND?=0
export COMPOSE_MK?=0
export DOCKER_HOST_WORKSPACE?=$(shell pwd)

# Used internally.  If this is container-dispatch and DIND, 
# then DOCKER_HOST_WORKSPACE should be treated carefully
ifeq ($(shell echo $${COMPOSE_MK_DIND:-0}), 1)
export workspace?=$(shell echo ${DOCKER_HOST_WORKSPACE})
export COMPOSE_MK=0
endif

## END: data
## BEGIN: macros

# Macro to yank all the compose-services out of YAML.
# Important Note: this runs for each invocation of make, and unfortunately
# 'docker compose config' is actually pretty slow compared to parsing the
# yaml any other way! But we can't say for sure if 'yq' or python+pyyaml
# are available. Inside service-containers, even docker compose is likely
# unavailable.  To work around this, the COMPOSE_MK env-var is checked,
# so that inside containers `compose.get_services` always returns nothing.
# As a side-effect, this prevents targets-in-containers from calling other
# targets-in-containers (which won't work anyway unless those containers
# also have docker).  This is probably a good thing!
define compose.get_services
	$(shell if [ "${COMPOSE_MK}" = "0" ]; then \
		docker compose -f ${1} config --services; \
	else \
		echo -n ""; fi)
endef

# Macro to create all the targets for a given compose-service.
# See docs @ https://github.com/elo-enterprises/k8s-tools/#composemk-api-dynamic
define compose.create_make_targets
$(eval compose_service_name := $1)
$(eval target_namespace := $2)
$(eval import_to_root := $(strip $3))
$(eval compose_file := $(strip $4))
$(eval namespaced_service:=${target_namespace}/$(compose_service_name))
$(eval compose_file_stem:=$(shell basename -s .yml $(compose_file)))


${compose_file_stem}.dispatch/%:
	@# dispatch helper
	entrypoint=make cmd="`printf $${*}|cut -d/ -f2-`" \
	make ${compose_file_stem}/`printf $${*}|cut -d/ -f1`

${compose_file_stem}/$(compose_service_name)/get_shell:
	@# Detects the best shell to use with ${compose_file_stem}/$(compose_service_name)
	docker compose -f $(compose_file) \
		run --entrypoint sh $$(shell echo $$@|awk -F/ '{print $$$$2}') \
		-c "which bash || which sh" 2> /dev/null \
		|| printf "${YELLOW}Neither 'bash' nor 'sh' are available!\n(service=${compose_service_name} @ ${compose_file})\n${NO_ANSI}" > /dev/stderr

${compose_file_stem}/$(compose_service_name)/shell:
	@# Invokes the shell
	@export entrypoint=`make ${compose_file_stem}/$(compose_service_name)/get_shell` \
	&& printf "${GREEN}⇒${NO_ANSI}${DIM} ${compose_file_stem}/$(compose_service_name)/shell (${GREEN}`env|grep entrypoint\=`${NO_ANSI}${DIM})${NO_ANSI}\n" \
		&& make ${compose_file_stem}/$(compose_service_name)
	
${compose_file_stem}/$(compose_service_name)/shell/pipe:
	@# Pipes data into the shell, using stdin directly.
	@# NB: implementation must NOT use 'io.mktemp'!
	@#
	@$$(eval export shellpipe_tempfile:=$$(shell mktemp))
	trap "rm -f $${shellpipe_tempfile}" EXIT \
	&& cat /dev/stdin > $${shellpipe_tempfile} \
	&& eval "cat $${shellpipe_tempfile} | pipe=yes \
	  entrypoint=`make ${compose_file_stem}/$(compose_service_name)/get_shell` \
	  make ${compose_file_stem}/$(compose_service_name)"

${compose_file_stem}/$(compose_service_name)/pipe:
	cat /dev/stdin | make ⟂/${compose_file_stem}/$(compose_service_name)

$(eval ifeq ($$(import_to_root), TRUE)
$(compose_service_name): $(target_namespace)/$(compose_service_name)
$(compose_service_name)/pipe: ⟂/${compose_file_stem}/$(compose_service_name)
$(compose_service_name)/shell: ${compose_file_stem}/$(compose_service_name)/shell
$(compose_service_name)/get_shell:  ${compose_file_stem}/$(compose_service_name)/get_shell
$(compose_service_name)/shell/pipe: ${compose_file_stem}/$(compose_service_name)/shell/pipe
endif)

${target_namespace}/$(compose_service_name):
	@# A namespaced target for each docker-compose service
	make ${compose_file_stem}/$$(shell echo $$@|awk -F/ '{print $$$$2}')

${target_namespace}/$(compose_service_name)/%:
	@# A subtarget for each docker-compose service.
	@# This allows invocation of *another* make-target
	@# that runs inside the container
	@entrypoint=make cmd="$${*}" make ${compose_file_stem}/$(compose_service_name)
endef

# Main macro to import services from an entire compose file
define compose.import
$(eval target_namespace:=$1)
$(eval import_to_root := $(if $(2), $(strip $(2)), FALSE))
$(eval compose_file:=$(strip $3))
$(eval compose_file_stem:=$(shell basename -s.yaml `basename -s.yml $(strip ${3}`)))
$(eval __services__:=$(call compose.get_services, ${compose_file}))

⟂/${compose_file_stem}/%:
	@pipe=yes make ${compose_file_stem}/$${*}

	
## operations on the compose file itself
${compose_file_stem}.services:
	@# Outputs newline-delimited list of services for this compose file.
	@# NB: (This must remain suitable for use with xargs, etc)
	@#
	@echo $(__services__) | sed -e 's/ /\n/g'
${compose_file_stem}.build:
	@#
	set -x && docker compose -f $${compose_file} build
${compose_file_stem}.stop:
	@#
	docker compose -f $${compose_file} stop -t 1
${compose_file_stem}.up:
	@#
	docker compose -f $${compose_file} up
${compose_file_stem}.down: ${compose_file_stem}.clean
	@# Alias for 'compose_file_stem.down'
${compose_file_stem}.clean:
	@#
	set -x && docker compose -f $${compose_file} --progress quiet down -t 1 --remove-orphans

${compose_file_stem}/%:
	@# Generic dispatch for any service inside this compose-file
	@# NB: implementation must NOT use 'io.mktemp'!
	@#
	@$$(eval export svc_name:=$$(shell echo $$@|awk -F/ '{print $$$$2}'))
	@$$(eval export cmd:=$(shell echo $${cmd:-}))
	@$$(eval export pipe:=$(shell \
		if [ -z "$${pipe:-}" ]; then echo ""; else echo "-iT"; fi))
	@$$(eval export quiet:=$(shell \
		if [ -z "$${quiet:-}" ]; then echo ""; else echo "1"; fi))
	@$$(eval export nsdisp:=${BOLD}$${target_namespace}${NO_ANSI})
	@$$(eval export header:=${GREEN}$${nsdisp}${DIM} ${SEP} ${BOLD}${DIM_GREEN}$${compose_file_stem}${NO_ANSI_DIM} ${SEP} ${BOLD}${GREEN}${UNDERLINE}$${svc_name}${NO_ANSI_DIM} container${NO_ANSI}\n)
	@$$(eval export entrypoint:=$(shell \
		if [ -z "$${entrypoint:-}" ]; \
		then echo ""; else echo "--entrypoint $${entrypoint:-}"; fi))
	@$$(eval export base:=docker compose -f ${compose_file} \
		run --rm --quiet-pull --env COMPOSE_MK=1 \
		$${pipe} $${entrypoint} $${svc_name} $${cmd} )
	@$$(eval export stdin_tempf:=$$(shell mktemp))
	@$$(eval export entrypoint_display:=${CYAN}[${NO_ANSI}${BOLD}$(shell \
			if [ -z "$${entrypoint:-}" ]; \
			then echo "default${NO_ANSI} entrypoint"; else echo "$${entrypoint:-}"; fi)${NO_ANSI_DIM}${CYAN}]${NO_ANSI})
	@$$(eval export cmd_disp:=${NO_ANSI_DIM}${ITAL}`[ -z "$${cmd}" ] && echo " " || echo " $${cmd}\n"`${NO_ANSI})
	
	@trap "rm -f $${stdin_tempf}" EXIT \
	&& if [ -z "$${pipe}" ]; then \
		([ -z "$${quiet}" ] && printf "$${header}${DIM}$${nsdisp} ${NO_ANSI_DIM}$${entrypoint_display}$${cmd_disp}${GREEN_FLOW_LEFT}  ${CYAN}<${NO_ANSI}${BOLD}interactive${NO_ANSI}${CYAN}>${NO_ANSI}${DIM_ITAL}`cat $${stdin_tempf} | sed 's/^[\\t[:space:]]*//'| sed -e 's/COMPOSE_MK=[01] //'`${NO_ANSI}\n" > /dev/stderr || true) \
		&& eval $${base} ; \
	else \
		cat /dev/stdin > $${stdin_tempf} \
		&& ([ -z "$${quiet}" ] && printf "$${header}${DIM}$${nsdisp} ${NO_ANSI_DIM}$${entrypoint_display}$${cmd_disp}${CYAN_FLOW_LEFT}  ${DIM_ITAL}`cat $${stdin_tempf} | sed 's/^[\\t[:space:]]*//'| sed -e 's/COMPOSE_MK=[01] //'`${NO_ANSI}\n" > /dev/stderr || true) \
		&& cat "$${stdin_tempf}" | eval $${base} \
	; fi && printf '\n'
$(foreach \
 	compose_service_name, \
 	$(__services__), \
	$(eval \
		$(call compose.create_make_targets, \
			$${compose_service_name}, \
			${target_namespace}, ${import_to_root}, ${compose_file}, )))
endef

# Helper for working with temp files.  Returns filename, 
# and uses 'trap' to handle at-exit file-deletion automatically.
# Note that this has to be macro for reasons related to ONESHELL.
# You should chain commands with ' && ' to avoid early deletes
define io.mktemp
	export tmpf=$$(mktemp -p .) && trap "rm -f $${tmpf}" EXIT 
endef


# Define 'help' target iff it's not already defined.  This should be inlined 
# for all files that want to be simultaneously usable in stand-alone 
# mode + library mode (with 'include')
_help_id:=$(shell (uuidgen||cat /proc/sys/kernel/random/uuid || date +%s) | head -c 8 | tail -c 8)
define _help_gen
(LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$' || true)
endef
_help_${_help_id}:
	@# Attempts to autodetect the targets defined in this Makefile context.  
	@# Older versions of make dont have '--print-targets', so this uses the 'print database' feature.
	@# See also: https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
	@#
	@$(call _help_gen)
_help_namespaces_${_help_id}:
	@# Returns only the top-level target namespaces
	@$(call _help_gen) | cut -d. -f1 |cut -d/ -f1 | uniq|grep -v ^all$$
$(eval help: _help_${_help_id})
$(eval help.namespaces: _help_namespaces_${_help_id})

## END macros/data
## BEGIN 'flux.*' targets
## DOCS: https://github.com/elo-enterprises/k8s-tools/#api-flux

docker.init.compose:
	@# Ensures compose is available.  Note that 
	@# build/run/etc cannot happen without a file, 
	@# for that, see instead targets like '<compose_file_stem>.build'
	@#
	docker compose version | make io.print.dim > /dev/stderr

docker.init:
	@# Checks if docker is available, then displays version/context (no real setup)
	@#
	( printf "Docker Context: `docker context show`\n" \
	  && docker --version ) \
	| make io.print.dim > /dev/stderr
	make docker.init.compose

docker.panic:
	@# Debugging only!  This is good for ensuring a clean environment, 
	@# but running this from automation will nix your cache of downloaded
	@# images, and so you will probably quickly hit rate-limiting at dockerhub.  
	@# It tears down volumes and networks also, so you don't want to run this in prod.
	@#
	docker rm -f $$(docker ps -qa | tr '\n' ' ')
	docker network prune -f
	docker volume prune -f
	docker system prune -a -f

docker.context:
	@# Returns all of the available docker context. Pipe-friendly.
	@#
	docker context inspect

docker.context/%:
	@# Returns docker-context details for the given context-name.  
	@# Pipe-friendly; outputs JSON from 'docker context inspect'
	@#
	@# USAGE: (shortcut for the current context name)
	@#  make docker.context/current 
	@#
	@# USAGE: (with given named context)
	@#  docker.context/<context_name>
	@#
	@case "$(*)" in \
		current) \
			make docker.context |  jq ".[]|select(.Name=\"`docker context show`\")" -r; ;; \
		*) \
			make docker.context | jq ".[]|select(.Name=\"${*}\")" -r; ;; \
	esac
	
docker.socket:
	@# Returns the docker socket in use for the current docker context.
	@# No arguments; Pipe-friendly.
	@#
	make docker.context/current | jq -r .Endpoints.docker.Host

docker.stop:
	@# Stops one container, using the given timeout and the given id or name.
	@#
	@# USAGE:
	@#   make docker.stop id=8f350cdf2867 
	@#   make docker.stop name=my-container 
	@#   make docker.stop name=my-container timeout=99
	@#
	printf "${GLYPH_DOCKER} docker.stop${NO_ANSI_DIM} ${SEP} ${GREEN}$${id:-$${name}}${NO_ANSI}\n"
	export cid=`[ -z "$${id:-}" ] && docker ps --filter name=$${name} --format json | jq -r .ID || echo $${id}` \
	&& case "$${cid:-}" in \
		"") \
			printf "$${DIM}${GLYPH_DOCKER} docker.stop${NO_ANSI} // ${YELLOW}No containers found${NO_ANSI}\n"; ;; \
		*) \
			docker stop -t $${timeout:-1} $${cid}; ;; \
	esac

docker.stat: 
	@# Show information about docker-status.  No arguments.
	@#
	@# This is pipe-friendly, although it also displays additional 
	@# information on stderr for humans, specifically an abbreviated
	@# table for 'docker ps'.  Machine-friendly JSON is also output 
	@# with the following schema:
	@#
	@#   { "version": .., "container_count": ..,
	@#     "socket": .., "context_name": .. }
	@#
	$(call io.mktemp) && \
	make docker.context/current > $${tmpf} \
	&& printf "${GLYPH_DOCKER} docker.stat${NO_ANSI_DIM}:\n" > /dev/stderr \
	&& make docker.init  \
	&& docker ps --format "table {{.ID}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Names}}" \
	| make io.print.dim > /dev/stderr \
	&& echo {} \
		| make stream.json.builder key=version \
			val="`docker --version|sed 's/Docker " //'`" \
		| make stream.json.builder key=container_count \
			val="`docker ps --format json| jq '.Names'|wc -l`" \
		| make stream.json.builder key=socket \
			val="`cat $${tmpf} | jq -r .Endpoints.docker.Host`" \
		| make stream.json.builder key=context_name \
			val="`cat $${tmpf} | jq -r .Name`"

## END 'docker.*' targets
## BEGIN 'io.*' targets
## DOCS: https://github.com/elo-enterprises/k8s-tools/#api-io

io.bash:
	@# Starts an interactive shell with all the environment variables set 
	@# by the parent environment, plus those set by this Makefile context.
	@#
	env bash -l
io.tmux:
	@#
	@#
	@#

io.fmt.strip:
	@# Pipe-friendly helper for stripping whitespace.
	@#
	cat /dev/stdin | awk '{gsub(/[\t\n]/, ""); gsub(/ +/, " "); print}' ORS=''

io.fmt.strip_ansi:
	@# Pipe-friendly helper for stripping ansi.
	@# (Probably won't work everywhere, but has no deps)
	@#
	cat /dev/stdin | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g"'

io.print.dim: 
	@# Pipe-friendly helper for dimming the input text
	@#
	printf "${DIM}`cat /dev/stdin`${NO_ANSI}\n"

io.print.dim.indent:
	@# Like 'io.print.indent' except it also dims the text.
	@#
	cat /dev/stdin | make io.print.dim | make io.print.indent

io.print.divider:
	@# Prints a divider on stdout, defaulting to the full terminal width, 
	@# with optional label.  This automatically detects console width, but
	@# it requires 'tput' (usually part of a 'ncurses' package).
	@#
	@# USAGE: 
	@#  make io.print.divider label=".." filler=".." width="..."
	@#
	@export width=$${width:-`tput cols`} \
	&& label=$${label:-} \
	&& label=$${label/./-} \
	&& if [ -z "$${label}" ]; then \
	    filler=$${filler:-¯} && printf "%*s${NO_ANSI}\n" "$${width}" '' | sed "s/ /$${filler}/g"; \
	else \
		label=" $${label//-/ } " \
	    && default="#" \
		&& filler=$${filler:-$${default}} && label_length=$${#label} \
	    && side_length=$$(( ($${width} - $${label_length} - 2) / 2 )) \
	    && printf "%*s" "$${side_length}" | sed "s/ /$${filler}/g" \
		&& printf "$${label}" \
	    && printf "%*s\n\n" "$${side_length}" | sed "s/ /$${filler}/g" \
	; fi

io.print.divider/%:
	@# Print a divider with a width of `term_width / <arg>`
	@#
	@# USAGE: 
	@#  make io.print.divider/<int>
	@#
	@width=`echo \`tput cols\` / ${*} | bc` \
	make io.print.divider

io.print.indent:
	@# Pipe-friendly helper for indention; reads from stdin and returns indented result on stdout
	@#
	cat /dev/stdin | sed 's/^/  /'
io.print.indent.stderr:
	cat /dev/stdin | make io.print.indent > /dev/stderr
io.print.dim.indent.stderr:
	cat /dev/stdin | make io.print.dim | make io.print.indent > /dev/stderr

io.time.wait: io.time.wait/1
	@# Pauses for 1 second.

io.time.wait/%:
	@# Pauses for the given amount of seconds.
	@#
	@# USAGE: 
	@#   io.time.wait/<int>
	@#
	printf "${GLYPH_IO} io.wait${NO_ANSI} ${SEP} ${DIM}Waiting for ${*} seconds..${NO_ANSI}\n" > /dev/stderr \
	&& sleep ${*}

io.time.target/%:
	@# Emits run time for the given make-target in seconds.
	@# Pipe safe; target's stdout is sent to stderr.
	@#
	@# USAGE:
	@#   io.time.target/<target_to_run>
	@#
	start_time=$$(date +%s%N) \
	&& make ${*} >&2 \
	&& end_time=$$(date +%s%N) \
	&& time_diff_ns=$$((end_time - start_time)) \
	&& echo $$(echo "scale=9; $$time_diff_ns / 1000000000" | bc)

## END '.*' targets
## BEGIN 'flux.*' targets
## DOCS: https://github.com/elo-enterprises/k8s-tools/#api-flux

# NB: Used in 'flux.always' and 'flux.finally'.  For reasons related to ONESHELL,
# this code can't be target-chained and to make it reusable, it needs to be embedded.
define _flux.always
	printf "${GLYPH_FLUX} flux.always${NO_ANSI_DIM} ${SEP} registering target: ${GREEN}${*}${NO_ANSI}\n" >/dev/stderr 
	target="${*}" pid="$${PPID}" $(MAKE) .flux.always.bg &
endef
flux.always/%:
	@# Always run the given target, even if the rest of the pipeline fails.
	@#
	@#
	@# NB: For this to work, the `always` target needs to be declared at the 
	@# beginning.  See the example below where "<target>" always runs, even 
	@# though the pipeline fails in the middle.
	@#
	@# USAGE: 
	@#   make flux.always/<target_name> flux.sh.ok flux.sh.fail flux.sh.ok
	@#
	$(call _flux.always)
.flux.always.bg:
	@# Internal helper for `flux.always`
	@#
	header="${GLYPH_FLUX} flux.always${NO_ANSI_DIM} ${SEP} main process finished, " \
	&& ( \
		while kill -0 $${pid} 2> /dev/null; do sleep 1; done \
		&& 	printf "$${header} dispatching ${GREEN}$${target} ${NO_ANSI}\n" >/dev/stderr  \
		&& $(MAKE) $$target \
	) &

flux.dmux:
	@# Demultiplex / fan-out operator that sends stdin to each of the named targets in parallel.
	@# (This is like `flux.sh.tee` but works with make-target names instead of shell commands)
	@#
	@# USAGE: (pipes the same input to target1 and target2)
	@#   echo {} | make flux.dmux targets=",target2" 
	@#
	printf "${GLYPH_FLUX} flux.dmux${NO_ANSI_DIM} ${SEP} ${DIM}$${targets//,/ ; }${NO_ANSI}\n" > /dev/stderr
	cat /dev/stdin \
	| make flux.sh.tee \
		cmds="`\
			printf $${targets} \
			| tr ',' '\n' \
			| xargs -n1 -I% echo make % \
			| tr '\n' ','`"

flux.dmux/%:
	@# Same as.dmux flow, but accepts arguments directly (no variable)
	@#
	@# USAGE: ( pipes the same input to yq and jq )
	@#   echo {} | make flux.dmux/yq,jq
	@#
	cat /dev/stdin | targets="${*}" make flux.dmux

flux.loopf/%:
	@# Loop the given target forever
	@#
	@# To reduce logging noise, this sends stderr to null, 
	@# but preserves stdout. This makes debugging hard, so
	@# only use this with well tested/understood sub-targets!
	@#
	header="${GLYPH_FLUX} flux.loopf${NO_ANSI_DIM} ${SEP} ${GREEN}${*}${NO_ANSI}" \
	&& printf "$${header} (forever)\n" > /dev/stderr \
	&& while true; do ( \
		make ${*} 2>/dev/null \
		|| printf "$${header} ($${failure_msg:-failed})\n" > /dev/stderr \
	) ; sleep $${delta:-.5}; done	

flux.loop/%:
	@# Helper for repeatedly running the named target a given number of times.
	@# This requires the 'pv' tool for progress visualization, which is available
	@# by default in k8s-tools containers.   By default, stdout for targets is 
	@# supressed because it messes up the progress bar, but stderr is left alone. 
	@#
	@# USAGE:
	@#   make flux.loop/<times>/<target_name>
	@#
	@# NB: This requires "flat" targets with no '/' !
	$(eval export target:=$(strip $(shell echo ${*} | cut -d/ -f2-)))
	$(eval export times:=$(strip $(shell echo ${*} | cut -d/ -f1)))
	printf "${GLYPH_FLUX} flux.loop${NO_ANSI_DIM} ${SEP} ${GREEN}$${target}${NO_ANSI} ($${times}x)\n" > /dev/stderr
	export pv_cmd=`[ -z "$${quiet:-}" ] && echo "pv -s $${times} -l -i 1 --name \"$${target}\" -t -e -C -p" || echo cat` \
	&& (for i in `seq $${times}`; \
	do \
		make $${target} > /dev/null; echo $${i}; \
	done) | eval $${pv_cmd} > /dev/null

flux.mux:
	@# Runs the comma-separated named targets in parallel, then waits for all of them to finish.
	@# For stdout and stderr, this is a many-to-one mashup of whatever writes first, and nothing   
	@# about output ordering is guaranteed.  This works by creating a small script, displaying it, 
	@# and then running it.  It's not very sophisticated!  The script just tracks pids of 
	@# launched processes, then waits on all pids.
	@# 
	@# If the named targets are all well-behaved, this *might* be pipe-safe, but in 
	@# general it's possible for the subprocess output to be out of order.  If you do
	@# want legible structured output that *prints* in ways that are concurrency-safe,
	@# here's a hint: emit nothing, or emit minified JSON output with printf and 'jq -c',
	@# and there is a good chance you can consume it.  Printf should be atomic on most 
	@# platforms with JSON of practical size? And crucially, 'jq .' handles object input, 
	@# empty input, and streamed objects with no wrapper (like '{}<newline>{}').
	@#
	@# USAGE: (runs 3 commands in parallel)
	@#   make flux.mux targets="io.time.wait/3,io.time.wait/1,io.time.wait/2" | jq .
	@#
	printf "${GLYPH_FLUX} flux.mux${NO_ANSI_DIM} ${SEP} ${NO_ANSI_DIM}$${targets//,/ ; }${NO_ANSI}\n" > /dev/stderr
	$(call io.mktemp) && \
	mcmds=`printf $${targets} \
	| tr ',' '\n' \
	| xargs -d'\n' -I% printf "make % & pids+=\"$$\n" \
	| xargs -d'\n' -I% printf "%! \"\n" \
	` \
	&& (printf 'pids=""\n' \
		&& printf "$${mcmds}\n" \
		&& printf 'wait $${pids}\n') > $${tmpf} \
	&& printf "${CYAN_FLOW_LEFT} script \n${DIM}`cat $${tmpf}|make io.print.dim.indent`${NO_ANSI}\n" > /dev/stderr \
	&& bash $${tmpf}

flux.mux/%:
	@# Alias for flux.mux, but accepts arguments directly
	targets="${*}" make flux.mux 

flux.split: flux.dmux
	@# Alias for flux.dmux

flux.split/%: 
	@# Alias for flux.split, but accepts arguments directly
	export targets="${*}" && make flux.split

flux.join: 
	@# Alias for flux.mux
	make flux.mux

flux.finally/%:
	@# Alias for 'flux.always'
	@#
	$(call _flux.always)

flux.sh.tee:
	@# Helper for constructing a parallel process pipeline with `tee` and command substitution.
	@# Pipe-friendly, this works directly with stdin.  This exists mostly to enable `flux.dmux`
	@# but it can be used directly.
	@#
	@# Using this is easier than the alternative pure-shell version for simple commands, but it's 
	@# also pretty naive, and splits commands on commas; probably better to avoid loading other
	@# pipelines as individual commands with this approach.  
	@#
	@# USAGE: ( pipes the same input to jq and yq commands )
	@#   echo {} | make flux.sh.tee cmds="jq,yq" 
	@#
	src="`\
		echo $${cmds} \
		| tr ',' '\n' \
		| xargs -n1 -I% \
			printf  ">($${tee_pre:-}%$${tee_post:-}) "`" \
	&& header="${GLYPH_FLUX} flux.sh.tee${NO_ANSI} ${SEP}${DIM} starting pipe" \
	&& cmd="cat /dev/stdin | tee $${src} " \
	&& printf "$${header} (${NO_ANSI}${BOLD}`echo $${cmds} | grep -o ',' | wc -l`${NO_ANSI_DIM} components)\n" > /dev/stderr \
	&& printf "${NO_ANSI_DIM}${GLYPH_FLUX} ${NO_ANSI_DIM}flux.sh.tee${NO_ANSI} ${SEP} ${NO_ANSI_DIM}$${cmd}${NO_ANSI}\n" > /dev/stderr \
	&& eval $${cmd} | cat

flux.sh.timeout:
	@# Runs the given command for the given amount of seconds, then stops it with SIGINT.
	@#
	@# USAGE: (tails docker logs for up to 10s, then stops)
	@#   make flux.sh.timeout cmd='docker logs -f xxxx' timeout=10
	@#
	printf "${GLYPH_IO} flux.sh.timeout${NO_ANSI_DIM} (${YELLOW}$${timeout}s${NO_ANSI_DIM}) ${SEP} ${NO_ANSI_DIM}$${cmd}${NO_ANSI} ${NO_ANSI}\n" >/dev/stderr 
	trap "pkill -SIGINT -f \"$${cmd}\"" INT \
	&& eval "$${cmd} &" \
	&& export command_pid=$$! \
	&& sleep $${timeout} \
	&& printf "${DIM}${GLYPH_IO} flux.sh.timeout${NO_ANSI_DIM} (${YELLOW}$${timeout}s${NO_ANSI_DIM}) ${SEP} ${NO_ANSI}${YELLOW}finished${NO_ANSI}\n" >/dev/stderr \
	&& kill -INT $${command_pid}

flux.sh.fail:
	@# Alias for 'exit 1', which is failure.
	@# This is mostly for used for testing other pipelines.
	@#
	printf "${GLYPH_FLUX} flux.sh.fail${NO_ANSI_DIM} ${SEP} ${NO_ANSI} ${RED}failing${NO_ANSI} as requested!\n" >/dev/stderr  \
	&& exit 1 
flux.sh.ok:
	@# Alias for 'exit 0', which is success.
	@# This is mostly for used for testing other pipelines.
	@#
	printf "${GLYPH_FLUX} flux.sh.suceed${NO_ANSI_DIM} ${SEP} ${NO_ANSI} succceeding as requested!\n" >/dev/stderr  \
	&& exit 0

## END '.*' targets
## BEGIN 'stream.*' targets
## DOCS: https://github.com/elo-enterprises/k8s-tools/#api-stream
stream.echo:
	@# Just echoes the input stream.  Mostly used for testing 'flow.*' targets, etc
	cat /dev/stdin

stream.indent:
	@# Indents input stream
	@#
	cat /dev/stdin | make io.print.indent
stream.peek:
	@# Prints the entire input stream as indented/dimmed text on stderr,
	@# Then passes-through the entire stream to stdout.
	@#
	@# USAGE:
	@#   echo hello-world | make stream.peek | cat
	@#
	$(call io.mktemp) && \
	cat /dev/stdin > $${tmpf} \
	&& cat $${tmpf} | make io.print.dim.indent.stderr \
	&& cat $${tmpf}

stream.json.builder:
	@# Appends the given key/val to the input object.
	@# This is usually used to build JSON objects from scratch.
	@#
	@# USAGE: 
	@#	 echo {} | key=foo val=bar make stream.json.builder 
	@#   {"foo":"bar"}
	@#
	cat /dev/stdin | jq ". + {\"$${key}\": \"$${val}\"}"
stream.space.enum:
	@# Enumerates the space-delimited input list, zipping indexes with values.
	@#
	@# USAGE:
	@#   printf one two | make io.enum
	@# 		0	one
	@# 		1	two
	@#
	cat /dev/stdin | xargs -n1 echo | make stream.nl.enum
stream.nl.enum:
	@# Enumerates the newline-delimited input stream, zipping index with values
	@#
	@# USAGE:
	@#   printf "one\ntwo" | make stream.nl.enum
	@# 		0	one
	@# 		1	two
	@#
	cat /dev/stdin | nl -v0 -w1 -nln
stream.nl.first:
	@# Gets the first element, or the "car" of newline-delimited input
	cat /dev/stdin | awk 'NR==1'
stream.nl.rest:
	@# Gets the "rest", aka the tail or the cdr, of newline-delimited input
	cat /dev/stdin | awk 'NR>1'
stream.space.first:
	@# Gets the first element, or the "car" of space-delimited input
	cat /dev/stdin | awk '{print $$1}'
stream.space.rest:
	@# Gets the "rest", aka the tail or the cdr, of space-delimited input
	cat /dev/stdin |  awk '{$$1=""; print $$0}'
stream.space.nl:
	@# Converts space-delim stream to a newline-delimited one
	cat /dev/stdin | xargs -n1 echo

stream.to.stderr:
	@# Sends input stream to stderr
	@#
	cat /dev/stdin > /dev/stderr

compose.stat/%:
	# printf "${GLYPH_FLUX} compose.stat${NO_ANSI_DIM} ${SEP} ${DIM_GREEN} ${*} ${NO_ANSI}\n" >/dev/stderr
	# ( \
	# 	env | grep COMP || true \
	# 	; env | grep DOCKER || true \
	# 	; env|grep workspace || true ) | make io.print.dim.indent
