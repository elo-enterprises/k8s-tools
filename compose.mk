#!/usr/bin/env -S make -s --warn-undefined-variables -f
##
# compose.mk: A minimal automation framework for working with containers.
#
# DOCS: https://github.com/elo-enterprises/k8s-tools#compose.mk
#
# LATEST: https://github.com/elo-enterprises/k8s-tools/tree/master/compose.mk
#
# FEATURES:
#   1) Library-mode extends `make`, adding native support for working with (external) container definitions
#   2) Stand-alone mode also available, i.e. a tool that requires no Makefile and no compose file.
#   3) A minimal, elegant, and dependency-free approach to describing workflow pipelines. (See the flux.* API)
#   4) A small-but-powerful built-in TUI framework with no host dependencies. (See the crux.* API) 
#
# USAGE: ( For Integration )
#   # Add this to your project Makefile
#   include compose.mk
#   $(eval $(call compose.import, ▰, ., docker-compose.yml))
#   # Example for target dispatch:
#   # A target that runs inside the `debian` container
#   demo: ▰/debian/demo
#   .demo:
#       uname -n -v
#
# USAGE: ( Stand-alone tool mode )
#   ./compose.mk help
#
# USAGE: ( Via CLI Interface, after Integration )
#   # drop into debugging shell for the container
#   make <stem_of_compose_file>/<name_of_compose_service>/shell
#
#   # stream data into container
#   echo echo hello-world | make <stem_of_compose_file>/<name_of_compose_service>/shell/pipe
#
#   # show full interface (see also: https://github.com/elo-enterprises/k8s-tools#makecompose-bridge)
#   make help
#
# APOLOGIES: 
#   In advance if you're checking out the implementation.  This is unavoidably gnarly in a lot of places.
#   No one likes a file this long, and especially make-macros are not the most fun stuff to read or write.
#   Breaking this apart would make development easier but complicate boilerplate required for integration 
#   with external projects.  Pull requests are welcome! =P
#
# HINTS:
#   1) The goal is that the implementation is well tested, nearly frozen, and generally safe to ignore!
#   2) If you just want API or other docs, see https://github.com/elo-enterprises/k8s-tools#compose.mk
#   3) If you *need* to work on this file, insist on make syntax highlighting + tab/spaces visualization.
#

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
export TERM?=xterm-256color

define _mk.interrupt
kill -INT $${PPID}
endef

# Hints for compose files to fix file permissions (see k8s-tools.yml for an example of how this is used)
OS_NAME:=$(shell uname -s)
ifeq (${OS_NAME},Darwin)
export DOCKER_UID:=0
export DOCKER_GID:=0
export DOCKER_UGNAME:=root
export COMPOSE_MK_CLI:=
else 
export DOCKER_UID:=$(shell id -u)
export DOCKER_GID:=$(shell getent group docker 2> /dev/null | cut -d: -f3 || id -g)
export DOCKER_UGNAME:=user
export COMPOSE_MK_CLI:=$(shell \
	( cat /proc/$(strip $(shell ps -o ppid= -p $$$$))/cmdline 2>/dev/null \
		| tr '\0' ' ' ) ||echo '?')
endif


# Honored by `docker compose`, this helps to quiet output
export COMPOSE_IGNORE_ORPHANS?=True

# Variables used internally.  
# COMPOSE_MK:       1 if dispatched inside container, otherwise 0
# COMPOSE_MK_CLI:   Full CLI invocation for this process (Linux only)
# COMPOSE_MK_DIND:  Determines whether docker-in-docker is allowed
# COMPOSE_MK_TRACE: Increase verbosity (more detailed than COMPOSE_MK_DEBUG)
# DOCKER_HOST_WORKSPACE: Needs override for correctly working with DIND volumes
# COMPOSE_MK_EXTRA_COMPOSE_FILES: .....
export COMPOSE_MK?=0
export COMPOSE_MK_CLI
export COMPOSE_MK_DIND?=0
export COMPOSE_MK_DEBUG?=1
export DOCKER_HOST_WORKSPACE?=$(shell pwd)
export COMPOSE_MK_TRACE?=0
export COMPOSE_MK_EXTRA_COMPOSE_FILES?=
export COMPOSE_MK_SRC=$(shell echo ${MAKEFILE_LIST}|sed 's/ /\n/g'|grep compose.mk)
ifneq ($(findstring compose.mk, ${COMPOSE_MK_CLI}),)
export COMPOSE_MK_LIB=0
export COMPOSE_MK_STANDALONE=1
export COMPOSE_MK_SRC=$(findstring compose.mk, ${COMPOSE_MK_CLI})
endif
ifeq ($(findstring compose.mk, ${COMPOSE_MK_CLI}),)
export COMPOSE_MK_LIB=1
export COMPOSE_MK_STANDALONE=0
endif

# Glyphs used in log messages 📢 🤐
GLYPH_DOCKER=${GREEN}${BOLD}≣${NO_ANSI}${DIM_GREEN}
GLYPH_IO=${GREEN}${BOLD}⇄${NO_ANSI}${DIM_GREEN}
GLYPH_FLUX=${GREEN}${BOLD}⋇${NO_ANSI}${DIM_GREEN}
export GLYPH_DEBUG=${DIM}(debug=${NO_ANSI}${COMPOSE_MK_DEBUG}${DIM})${NO_ANSI} 

# Make related variables 
# MAKEFILE_LIST: ...
# MAKE_C_FLAGS: -C arguments in this invocation CLI.  (not implemented yet)
# MAKEFILE: ...
# MAKE: ...
# export MAKE_C_FLAGS:=
export MAKEFILE_LIST
export MAKE_FLAGS=$(shell [ `echo ${MAKEFLAGS}|cut -c1` = - ] && echo "${MAKEFLAGS}" || echo "-${MAKEFLAGS}")
export MAKEFILE:=$(firstword $(MAKEFILE_LIST))
export MAKE:=make ${MAKE_FLAGS} -f ${MAKEFILE}
export make:=${MAKE}
# Used internally.  If this is container-dispatch and DIND, 
# then DOCKER_HOST_WORKSPACE should be treated carefully
ifeq ($(shell echo $${COMPOSE_MK_DIND:-0}), 1)
export workspace?=$(shell echo ${DOCKER_HOST_WORKSPACE})
export COMPOSE_MK=0
endif
.DEFAULT_GOAL?=all 
all: help

## END data
## BEGIN 'compose.*' and 'docker.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-docker
##   [2] https://github.com/elo-enterprises/k8s-tools/#api-compose
stderr:=/dev/stderr

compose.get.stem/%:; basename -s .yml `basename -s .yaml ${*}`

compose.kernel:
	@#
	@# USAGE:
	@#  echo flux.ok | ./compose.mk kernel
	@#
	set -x \
	&& ${make} $${make_extra:-} "`cat /dev/stdin | ${make} stream.peek`"

compose.qbuild/%:
	cmd="make compose.build/${*}" make io.quiet.stderr.sh
compose.build/%:; docker compose -f ${*} build

compose.dind.stream:
	@# Sets context that docker-in-docker is allowed, then streams commands into the given target/container.
	@# This is not really recommended for external use, but it enables some features of 'k8s.tui.*' targets
	@# By default, the presence of the COMPOSE_MK var prevents this.  We also need to override  
	@# the 'workspace' var, which (unintuitively) needs to be a _host_ path, not a container path.
	@#
	@# USAGE:
	@#	target=<target_to_stream_into> script=<script_to_stream> make compose.dind.stream
	@#
	export workspace="$${DOCKER_HOST_WORKSPACE}" \
	&& export stream="`printf "$${script}"`" \
	&& export stream="\nexport COMPOSE_MK_DIND=1;\n$${stream}" \
	&& printf "export COMPOSE_MK_DEBUG=$${COMPOSE_MK_DEBUG}; $${stream}" \
	| COMPOSE_MK_DEBUG=$${COMPOSE_MK_DEBUG} make $${target}
compose.services/%:
	docker compose -f ${*} config --services
compose.stat/%:
	# printf "${GLYPH_FLUX} compose.stat${NO_ANSI_DIM} ${SEP} ${DIM_GREEN} ${*} ${NO_ANSI}\n" >${stderr}
	# ( \
	# 	env | grep COMP || true \
	# 	; env | grep DOCKER || true \
	# 	; env|grep workspace || true ) | make stream.dim.indent

docker.help: help.namespace/docker
	@# Lists only the targets available under the 'docker' namespace.

docker.init.compose:
	@# Ensures compose is available.  Note that 
	@# build/run/etc cannot happen without a file, 
	@# for that, see instead targets like '<compose_file_stem>.build'
	@#
	docker compose version | make stream.dim> ${stderr}

docker.init:
	@# Checks if docker is available, then displays version/context (no real setup)
	@#
	( printf "Docker Context: `docker context show`\n" \
	  && docker --version ) \
	| make stream.dim> ${stderr}
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
	&& printf "${GLYPH_DOCKER} docker.stat${NO_ANSI_DIM}:\n" > ${stderr} \
	&& make docker.init  \
	&& docker ps --format "table {{.ID}}\t{{.CreatedAt}}\t{{.Status}}\t{{.Names}}" \
	| make stream.dim> ${stderr} \
	&& echo {} \
		| make stream.json.object.append key=version \
			val="`docker --version|sed 's/Docker " //'`" \
		| make stream.json.object.append key=container_count \
			val="`docker ps --format json| jq '.Names'|wc -l`" \
		| make stream.json.object.append key=socket \
			val="`cat $${tmpf} | jq -r .Endpoints.docker.Host`" \
		| make stream.json.object.append key=context_name \
			val="`cat $${tmpf} | jq -r .Name`"

## END 'docker.*' targets
## BEGIN 'io.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-io

io.help: help.namespace/io
	@# Lists only the targets available under the 'io' namespace.

io.bash:
	@# Starts an interactive shell with all the environment variables set 
	@# by the parent environment, plus those set by this Makefile context.
	@#
	env bash -l

stream.csv.pygmentize:; cat /dev/stdin | lexer=ini make stream.pygmentize

export PYGMENTIZE:=docker run --rm --interactive \
		-e TERM=$${TERM}  -v `pwd`:/workspace -w /workspace \
		--entrypoint pygmentize lambdalab/pygments:0.7.34
stream.pygmentize:
	@# 
	@#
	@# https://hub.docker.com/r/backplane/pygmentize
	@# https://pygments.org/styles/
	lexer=`[ -z $${lexer:-} ] && echo '-g' || echo -l $${lexer}` \
	&& style="-Ostyle=$${style:-trac}" \
	&& cat /dev/stdin | ${PYGMENTIZE} $${style} $${lexer} -f terminal256 

io.file.pygmentize/%:
	lexer=`[ -z $${lexer:-} ] && echo '-g' || echo -l $${lexer}` \
	&& style="-Ostyle=$${style:-trac}" \
	&& ${PYGMENTIZE} $${style} $${lexer} -f terminal256 ${*}

io.file.preview/%:
	@#
	@# https://hub.docker.com/r/backplane/pygmentize
	@# https://pygments.org/styles/
	header="${GLYPH_IO} io.file.preview${NO_ANSI}" \
	&& printf "$${header} ${SEP} ${DIM}${BOLD}${*}${NO_ANSI}\n" > ${stderr} \
	&& style=trac make io.file.pygmentize/${*} \
	| make stream.nl.enum | make stream.indent.stderr
# && ( cat ${*} | make stream.nl.enum && echo )

io.env:; 
	@# Dump main information about this environment
	env|grep ^PWD=||true \
	; env|grep 'COMPOSE_MK.*=' || true \
	; env|grep MAKE || true \
	; env|grep TUI | grep -v TUI_TMUXP_PROFILE_DATA || true

io.fmt.strip:
	@# Pipe-friendly helper for stripping whitespace.
	@#
	cat /dev/stdin | awk '{gsub(/[\t\n]/, ""); gsub(/ +/, " "); print}' ORS=''

io.print.div:
	@# Prints a divider on stdout, defaulting to the full terminal width, 
	@# with optional label.  This automatically detects console width, but
	@# it requires 'tput' (usually part of a 'ncurses' package).
	@#
	@# USAGE: 
	@#  make io.print.div label=".." filler=".." width="..."
	@#
	@export width=$${width:-`tput cols||echo 45`} \
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


io.print.div/%:
	@# Print a divider with a width of `term_width / <arg>`
	@#
	@# USAGE: 
	@#  make io.print.div/<int>
	@#
	@width=`echo \`tput cols\` / ${*} | bc` \
	make io.print.div

io.quiet.stderr/%:
	@# Runs the given target, surpressing stderr output, except in case of error.
	@#
	@# USAGE: 
	@#  make io.quiet/<target_name>
	@#
	cmd="make ${*}" make io.quiet.stderr.sh 

io.quiet.stderr.sh:
	$(call io.mktemp) \
	&& header="${GLYPH_IO} io.quiet ${SEP} ${DIM_GREEN}stderr ${SEP}" \
	&& printf "$${header} ${GREEN}$${cmd}${NO_ANSI} \n" > ${stderr} \
	&& printf "$${header} ${DIM_GREEN}stderr${NO_ANSI} ${SEP} ${DIM}Quiet output, except in case of error. ${NO_ANSI}\n" > ${stderr} \
	&& start=$$(date +%s) \
	&& $${cmd} > /dev/null 2>&1 > $${tmpf} ; set +x; exit_status=$$? ; end=$$(date +%s) ; elapsed=$$(($${end}-$${start})) \
	&& header="${DIM}${GLYPH_IO} io.quiet${NO_ANSI} ${SEP}" \
	; case $${exit_status} in \
		0) \
			printf "$${header} ${GREEN}ok ${NO_ANSI_DIM}(in ${BOLD}$${elapsed}s${NO_ANSI_DIM})${NO_ANSI}\n" > ${stderr}; ;; \
		*) \
			printf "$${header} ${RED}failed ${NO_ANSI}\n" > ${stderr} \
			; cat $${tmpf} >> ${stderr} \
			; exit $${exit_status}; \
		;; \
	esac

io.print.indent:
	@# Pipe-friendly helper for indention; reads from stdin and returns indented result on stdout
	@#
	cat /dev/stdin | sed 's/^/  /'
io.print.indent.stderr:
	cat /dev/stdin | make io.print.indent > ${stderr}
stream.dim.indent.stderr:
	cat /dev/stdin | make stream.dim| make io.print.indent > ${stderr}
stream.help: help.namespace/stream
	@# Lists only the targets available under the 'stream' namespace.

io.time.wait: io.time.wait/1
	@# Pauses for 1 second.

io.time.wait/%:
	@# Pauses for the given amount of seconds.
	@#
	@# USAGE: 
	@#   io.time.wait/<int>
	@#
	printf "${GLYPH_IO} io.wait${NO_ANSI} ${SEP} ${DIM}Waiting for ${*} seconds..${NO_ANSI}\n" > ${stderr} \
	&& sleep ${*}



## END 'io.*' targets
## BEGIN 'mk.*' targets
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-mk

mk.help: help.namespace/mk
	@# Lists only the targets available under the 'io' namespace.
mk.def.dispatch.python/%:; make mk.def.dispatch/python3/${*}:
mk.def.dispatch.python.pipe/%:; cat /dev/stdin | make mk.def.dispatch.python/${*}
mk.def.pdispatch/%:; cat /dev/stdin | make mk.def.dispatch/${*}


mk.def.dispatch/%:
	@# Reads the given <def_name>, writes to a tmp-file, 
	@# then runs the given interpretter on the tmp file.
	@#
	@# USAGE:
	@#   make mk.def.dispatch/<interpretter>/<def_name>
	@#
	@# HINT: for testing, use 'make mk.def.dispatch/cat/<def_name>' 
	$(call io.mktemp) \
	&& export intr=`printf "${*}"|cut -d/ -f1` \
	&& export def_name=`printf "${*}" | cut -d/ -f2-` \
	&& make mk.def.write.to.file/$${def_name}/$${tmpf} \
	&& [ -z $${preview:-} ] && true || make io.file.preview/$${tmpf} \
	&& header="${GLYPH_IO} mk.def.dispatch${NO_ANSI}" \
	&& ([ $${COMPOSE_MK_TRACE} == 1 ] &&  printf "$${header} ${SEP} ${DIM}`pwd`${NO_ANSI} ${SEP} ${DIM}$${tmpf}${NO_ANSI}\n" > ${stderr} || true ) \
	&& printf "$${header} ${SEP} ${DIM}${CYAN}${BOLD}$${intr}${NO_ANSI} ${SEP} ${DIM}$${tmpf}${NO_ANSI}\n" > ${stderr} \
	&& which $${intr} > /dev/null || exit 1 \
	&& set -x \
	&& $${intr} $${tmpf}
mk.def.read/%:
	@# Reads the named define/endef block from this makefile, emitting it to stdout.
	@# This works around make's normal behaviour of completely wrecking indention/newlines
	@# present inside the block.
	@#
	@# USAGE: 
	@#   make mk.read_def/<name_of_define>
	@#
	$(eval def_name=${*})
	$(info $(value ${def_name}))
mk.def.write.to.file/%:
	@# Reads the given define/endef block from this makefile, writing it to the given output file.
	@#
	@# USAGE: make mk.def.write.to.file/<def_name>/<fname>
	@#
	def_name=`printf "${*}" | cut -d/ -f1` \
	&& out_file=`printf "${*}" | cut -d/ -f2-` \
	&& header="${GLYPH_IO} mk.def.write.to.file${NO_ANSI}" \
	&& printf "$${header} ${SEP} ${DIM}${CYAN}'$${def_name}'${NO_ANSI} ${SEP} ${DIM}${BOLD}$${out_file}${NO_ANSI}\n" > ${stderr} \
	&& ${make} mk.def.read/$${def_name} > $${out_file}

## END 'mk.*' targets
## BEGIN 'flux.*' targets
## DOCS:
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-io

define _flux.always
	@# NB: Used in 'flux.always' and 'flux.finally'.  For reasons related to ONESHELL,
	@# this code can't be target-chained and to make it reusable, it needs to be embedded.
	printf "${GLYPH_FLUX} flux.always${NO_ANSI_DIM} ${SEP} registering target: ${GREEN}${*}${NO_ANSI}\n" >${stderr} 
	target="${*}" pid="$${PPID}" $(MAKE) .flux.always.bg &
endef

flux.help: help.namespace/flux
	@# Lists only the targets available under the 'flux' namespace.

flux.always/%:
	@# Always run the given target, even if the rest of the pipeline fails.
	@#
	@#
	@# NB: For this to work, the `always` target needs to be declared at the 
	@# beginning.  See the example below where "<target>" always runs, even 
	@# though the pipeline fails in the middle.
	@#
	@# USAGE: 
	@#   make flux.always/<target_name> flux.ok flux.fail flux.ok
	@#
	$(call _flux.always)
.flux.always.bg:
	@# Internal helper for `flux.always`
	@#
	header="${GLYPH_FLUX} flux.always${NO_ANSI_DIM} ${SEP} main process finished, " \
	&& ( \
		while kill -0 $${pid} 2> /dev/null; do sleep 1; done \
		&& 	printf "$${header} dispatching ${GREEN}$${target} ${NO_ANSI}\n" >${stderr}  \
		&& $(MAKE) $$target \
	) &

flux.apply/%:
	@# Applies the given target(s).
	@# This is mostly used to as a wrapper in case targets are unary.
	@# 
	@# USAGE:
	@#   make flux.timer/flux.apply/io.time.wait,io.time.wait
	@#
	printf ${*} \
	| tr ',' '\n' \
	| xargs -I% echo make % \
	| bash -x
flux.apply.later/%:
	@# 
	@#
	time=`printf ${*}| cut -d/ -f1` \
	&& target=`printf ${*}| cut -d/ -f2-` \
	&& printf "${GLYPH_FLUX} flux.apply.later${NO_ANSI_DIM} ${SEP} ${GREEN}$${target}${NO_ANSI} (in $${time}s)\n" > ${stderr} \
	&& sleep $${time} \
	&& make flux.apply/$${target}

flux.delay/%:; make flux.apply.later/${*}
	@#
	@#

flux.dmux:
	@# Demultiplex / fan-out operator that sends stdin to each of the named targets in parallel.
	@# (This is like `flux.sh.tee` but works with make-target names instead of shell commands)
	@#
	@# USAGE: (pipes the same input to target1 and target2)
	@#   echo {} | make flux.dmux targets=",target2" 
	@#
	header="${GLYPH_FLUX} flux.dmux${NO_ANSI_DIM}" \
	&& header+=" ${SEP} ${DIM}$${targets//,/ ; }${NO_ANSI}\n" \
	&& printf "$${header}" | make stream.to.stderr
	cat /dev/stdin \
	| make flux.sh.tee \
		cmds="`\
			printf $${targets} \
			| tr ',' '\n' \
			| xargs -n1 -I% echo make % \
			| tr '\n' ','`"

flux.dmux/%:
	@# Same as flux.dmux, but accepts arguments directly (no variable)
	@# Stream-usage is required (this blocks waiting on stdin).
	@#
	@# USAGE: ( pipes the same input to yq and jq )
	@#   echo {} | make flux.dmux/yq,jq
	@#
	cat /dev/stdin | targets="${*}" make flux.dmux


flux.fail:
	@# Alias for 'exit 1', which is failure.
	@# This is mostly for used for testing other pipelines.
	@# See also 'flux.ok'
	@#
	printf "${GLYPH_FLUX} flux.fail${NO_ANSI_DIM} ${SEP} ${NO_ANSI} ${RED}failing${NO_ANSI} as requested!\n" > ${stderr}  \
	&& exit 1 

flux.finally/%:
	@# Alias for 'flux.always'
	@#
	$(call _flux.always)

flux.join: 
	@# Alias for flux.mux
	make flux.mux

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
	printf "${GLYPH_FLUX} flux.loop${NO_ANSI_DIM} ${SEP} ${GREEN}$${target}${NO_ANSI} ($${times}x)\n" > ${stderr}
	export pv_cmd=`[ $${COMPOSE_MK_DEBUG}==1 ] && echo "pv -s $${times} -l -i 1 --name \"$${target}\" -t -e -C -p" || echo cat` \
	&& (for i in `seq $${times}`; \
	do \
		make $${target} > /dev/null; echo $${i}; \
	done) | eval $${pv_cmd} > /dev/null

flux.loopf/%:
	@# Loop the given target forever
	@#
	@# To reduce logging noise, this sends stderr to null, 
	@# but preserves stdout. This makes debugging hard, so
	@# only use this with well tested/understood sub-targets!
	@#
	header="${GLYPH_FLUX} flux.loopf${NO_ANSI_DIM}" \
	&& header+=" ${SEP} ${GREEN}${*}${NO_ANSI}" \
	&& printf "$${header} (forever)\n" > ${stderr} \
	&& while true; do ( \
		make ${*} 2>/dev/null \
		|| printf "$${header} ($${failure_msg:-failed})\n" > ${stderr} \
	) ; sleep $${interval:-1}; done	

flux.loopu/%:
	@# Loop the given target until it succeeds.
	@#
	@# To reduce logging noise, this sends stderr to null, 
	@# but preserves stdout. This makes debugging hard, so
	@# only use this with well tested/understood sub-targets!
	@#
	header="${GLYPH_FLUX} flux.loopu${NO_ANSI_DIM} ${SEP} ${GREEN}${*}${NO_ANSI}" \
	&& printf "$${header} (until success)\n" > ${stderr} 
	make ${*} || (sleep $${interval:-1}; make flux.loopu/${*})

flux.loopw/%:
	@# Loops the given target forever, using 'watch' instead of the while-loop default
	@#
	watch \
		--interval $${interval:-2} \
		--color --no-wrap make ${*}

flux.map/%:
	@# Similar to 'flux.apply', but maps input stream 
	@# sequentially onto the comma-delimited target list.
	@#
	@# USAGE:
	@#   echo hello-world | make flux.map/stream.echo,stream.echo
	@#
	$(call io.mktemp) && \
	cat /dev/stdin > $${tmpf} \
	&& printf ${*}|sed 's/,/\n/g' | xargs -I% printf 'cat $${tmpf} | make %\n' \
	| bash -x

flux.wrap/%:; make flux.apply/${*}
	@# Wraps all of the given targets as if it were a single target.
	@# This allows using multiple targets anywhere that unary targets are supported.
	@#
	@# USAGE:
	@#   make flux.timer/flux.wrap/io.time.wait,io.time.wait
	@#

flux.mux:
	@# Runs the given comma-delimited targets in parallel, then waits for all of them to finish.
	@# For stdout and stderr, this is a many-to-one mashup of whatever writes first, and nothing   
	@# about output ordering is guaranteed.  This works by creating a small script, displaying it, 
	@# and then running it.  It's not very sophisticated!  The script just tracks pids of 
	@# launched processes, then waits on all pids.
	@# 
	@# If the named targets are all well-behaved, this *might* be pipe-safe, but in 
	@# general it's possible for the subprocess output to be out of order.  If you do
	@# want *legible, structured output* that *prints* in ways that are concurrency-safe,
	@# here's a hint: emit nothing, or emit minified JSON output with printf and 'jq -c',
	@# and there is a good chance you can consume it.  Printf should be atomic on most 
	@# platforms with JSON of practical size? And crucially, 'jq .' handles object input, 
	@# empty input, and streamed objects with no wrapper (like '{}<newline>{}').
	@#
	@# USAGE: (runs 3 commands in parallel)
	@#   make flux.mux targets="io.time.wait/3,io.time.wait/1,io.time.wait/2" | jq .
	@#
	@# NB: Not to be confused 
	header="${GLYPH_FLUX} flux.mux${NO_ANSI_DIM}" \
	&& header+=" ${SEP} ${NO_ANSI_DIM}$${targets//,/ ; }${NO_ANSI}\n" \
	&& printf "$${header}" > ${stderr}
	$(call io.mktemp) && \
	mcmds=`printf $${targets} \
	| tr ',' '\n' \
	| xargs -d'\n' -I% printf "make % & pids+=\"$$\n" \
	| xargs -d'\n' -I% printf "%! \"\n" \
	` \
	&& (printf 'pids=""\n' \
		&& printf "$${mcmds}\n" \
		&& printf 'wait $${pids}\n') > $${tmpf} \
	&& printf "${CYAN_FLOW_LEFT} script \n${DIM}`cat $${tmpf}|make stream.dim.indent`${NO_ANSI}\n" > ${stderr} \
	&& bash $${tmpf}

flux.mux/%:
	@# Alias for flux.mux, but accepts arguments directly
	targets="${*}" make flux.mux 

flux.ok:
	@# Alias for 'exit 0', which is success.
	@# This is mostly for used for testing other pipelines.
	@# See also 'flux.fail'
	@#
	printf "${GLYPH_FLUX} flux.ok${NO_ANSI_DIM} ${SEP} ${NO_ANSI} succceeding as requested!\n" > ${stderr}  \
	&& exit 0

flux.split: flux.dmux
	@# Alias for flux.dmux

flux.split/%: 
	@# Alias for flux.split, but accepts arguments directly
	export targets="${*}" && make flux.split

flux.sh.tee:
	@# Helper for constructing a parallel process pipeline with `tee` and command substitution.
	@# Pipe-friendly, this works directly with stdin.  This exists mostly to enable `flux.dmux`
	@# but it can be used directly.
	@#
	@# Using this is easier than the alternative pure-shell version for simple commands, but it's 
	@# also pretty naive, and splits commands on commas; probably better to avoid loading other
	@# pipelines as individual commands with this approach.  
	@#
	@# USAGE: ( pipes the same input to 'jq' and 'yq' commands )
	@#   echo {} | make flux.sh.tee cmds="jq,yq" 
	@#
	src="`\
		echo $${cmds} \
		| tr ',' '\n' \
		| xargs -n1 -I% \
			printf  ">($${tee_pre:-}%$${tee_post:-}) "`" \
	&& header="${GLYPH_FLUX} flux.sh.tee${NO_ANSI} ${SEP}${DIM} starting pipe" \
	&& cmd="cat /dev/stdin | tee $${src} " \
	&& printf "$${header} (${NO_ANSI}${BOLD}`echo $${cmds} \
		| grep -o ',' \
		| wc -l`${NO_ANSI_DIM} components)\n" > ${stderr} \
	&& printf "${NO_ANSI_DIM}${GLYPH_FLUX} ${NO_ANSI_DIM}flux.sh.tee${NO_ANSI} ${SEP} ${NO_ANSI_DIM}$${cmd}${NO_ANSI}\n" > ${stderr} \
	&& eval $${cmd} | cat

flux.sh.timeout:
	@# Runs the given command for the given amount of seconds, then stops it with SIGINT.
	@#
	@# USAGE: (tails docker logs for up to 10s, then stops)
	@#   make flux.sh.timeout cmd='docker logs -f xxxx' timeout=10
	@#
	printf "${GLYPH_IO} flux.sh.timeout${NO_ANSI_DIM} (${YELLOW}$${timeout}s${NO_ANSI_DIM}) ${SEP} ${NO_ANSI_DIM}$${cmd}${NO_ANSI} ${NO_ANSI}\n" >${stderr} 
	trap "pkill -SIGINT -f \"$${cmd}\"" INT \
	&& eval "$${cmd} &" \
	&& export command_pid=$$! \
	&& sleep $${timeout} \
	&& printf "${DIM}${GLYPH_IO} flux.sh.timeout${NO_ANSI_DIM} (${YELLOW}$${timeout}s${NO_ANSI_DIM}) ${SEP} ${NO_ANSI}${YELLOW}finished${NO_ANSI}\n" > ${stderr} \
	&& kill -INT $${command_pid}

flux.retry/%:
	@# Retries the given target a certain number of times.
	@#
	@# USAGE: (using default interval of 'K8S_POLL_DELTA')
	@#   make flux.retry/<times>/<target> 
	@#
	@# USAGE: (explicit interval in seconds)
	@#   interval=3 make flux.retry/<times>/<target> 
	@#
	times=`printf ${*}|cut -d/ -f1` \
	&& target=`printf ${*}|cut -d/ -f2-` \
	&& header="${GLYPH_IO} flux.retry${NO_ANSI_DIM}" \
	&& printf "$${header} (${NO_ANSI}${YELLOW}$${times}x${NO_ANSI_DIM}) ${SEP} ${NO_ANSI_DIM}$${target}${NO_ANSI}\n" >${stderr}  \
	&& ( r=$${times};\
		 while ! (\
			make $${target} \
			|| ( printf "${DIM}$${header} (${NO_ANSI}${YELLOW}failed.${NO_ANSI_DIM} waiting ${DIM_GREEN}${K8S_POLL_DELTA}s${NO_ANSI_DIM}) ${SEP} ${NO_ANSI_DIM}$${target}${NO_ANSI}\n" > ${stderr}\
				; exit 1) \
		); do ((--r)) || exit; sleep $${interval:-${K8S_POLL_DELTA}}; done)

flux.timer/%:
	@# Emits run time for the given make-target in seconds.
	@# Pipe safe; target stdout is sent to stderr.
	@#
	@# USAGE:
	@#   flux.timer/<target_to_run>
	@#
	start_time=$$(date +%s%N) \
	&& make ${*} >&2 \
	&& end_time=$$(date +%s%N) \
	&& time_diff_ns=$$((end_time - start_time)) \
	&& echo $$(echo "scale=9; $$time_diff_ns / 1000000000" | bc)

flux.timeout/%:
	@# Runs the given target for the given number of seconds, then stops it with SIGINT.
	@#
	@# USAGE: 
	@#   make flux.timeout/<seconds>/<target>
	@#
	timeout=`printf ${*} | cut -d/ -f1` \
	&& target=`printf ${*} | cut -d/ -f2-` \
	timeout=$${timeout} cmd="make $${target}" make flux.sh.timeout

## END 'flux.*' targets
## BEGIN 'stream.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-stream

stream.comma.to.nl:
	@# Converts comma-delimited input stream newline-delimited
	tmp=`cat /dev/stdin` && printf "$${tmp//,/\\n}"

stream.comma.to.json:
	@# Converts comma-delimited input into minimized JSON array
	@#
	@# USAGE:
	@#   echo 1,2,3 | make stream.comma.to.json
	@#   ["1","2","3"]
	@#
	cat /dev/stdin | make stream.comma.to.nl | make stream.nl.to.json.array

stream.dim: 
	@# Pipe-friendly helper for dimming the input text
	@#
	printf "${DIM}`cat /dev/stdin`${NO_ANSI}\n"

stream.dim.indent:
	@# Like 'io.print.indent' except it also dims the text.
	@#
	cat /dev/stdin | make stream.dim| make io.print.indent

stream.echo:; cat /dev/stdin
	@# Just echoes the input stream.  Mostly used for testing.
	@#
	@# USAGE:
	@#   echo hello-world | make stream.echo
	@#

stream.json.array.append:
	@# Appends <val> to input array
	@# 
	@# USAGE:
	@#   echo '[]'|val=1 make stream.json.array.append|val=2 make stream.json.array.append
	@#   [1,2]
	@# 
	cat /dev/stdin | jq "[.[],\"$${val}\"]"

stream.json.object.append:
	@# Appends the given key/val to the input object.
	@# This is usually used to build JSON objects from scratch.
	@#
	@# USAGE: 
	@#	 echo {} | key=foo val=bar make stream.json.object.append 
	@#   {"foo":"bar"}
	@#
	cat /dev/stdin | jq ". + {\"$${key}\": \"$${val}\"}"

stream.indent:
	@# Indents input stream
	@#
	cat /dev/stdin | make io.print.indent

stream.indent.stderr:; cat /dev/stdin|make stream.indent|make stream.to.stderr
	@# Shortcut for '|stream.indent|stream.to.stderr'

stream.peek:
	@# Prints the entire input stream as indented/dimmed text on stderr,
	@# Then passes-through the entire stream to stdout.
	@#
	@# USAGE:
	@#   echo hello-world | make stream.peek | cat
	@#
	$(call io.mktemp) && \
	cat /dev/stdin > $${tmpf} \
	&& cat $${tmpf} | make stream.dim.indent.stderr \
	&& cat $${tmpf}

stream.stderr.indent:
	@# Indents the input stream, writing output to stderr
	@#
	cat /dev/stdin | make stream.dim | make io.print.indent > ${stderr}

stream.nl.to.json.array: 
	@#  Converts newline-delimited input stream into a JSON array
	@# 
	src=`\
		cat /dev/stdin \
		| xargs -I% printf "| val=\"%\" make stream.json.array.append "\
	` \
	&& src="echo '[]' $${src} | jq -c ." \
	&& tmp=`eval $${src}` \
	&& echo $${tmp}

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
	cat /dev/stdin | nl --starting-line-number=0 --number-width=1 --number-format=ln

stream.to.stderr:
	@# Sends input stream to stderr.
	@# Unlike 'stream.peek', this does not pass on the input stream.
	@#
	cat /dev/stdin > ${stderr}

stream.preview: stream.to.stderr
	@# Previews the input stream, sending output to stderr.  
	@# Alias for stream.to.stderr.

## END 'stream.*' targets
## BEGIN 'crux.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-crux
# TUI_CONTAINER_NAME TUI_THEME_NAME
# TUI_TMUX_SOCKET
# TUI_LAYOUT_CALLBACK
# TUI_THEME_PRE_HOOK TUI_THEME_POST_HOOK
export TUI_CONTAINER_NAME?=crux
export TUI_TMUX_SOCKET?=/workspace/tmux.sock
export TUI_TMUX_SESSION_NAME?=crux_tui
export TUI_LAYOUT_CALLBACK?=.crux.layout.horizontal
export TUI_INIT_CALLBACK?=.crux.init
export TUI_THEME_PRE_HOOK?=.crux.theme.custom
export TUI_THEME_POST_HOOK?=.crux.theme.buttons
export TUI_THEME_NAME?=powerline/double/cyan
export TUI_COMPOSE_FILE?= .tmp.compose.mk.yml
export TUI_BOOTSTRAP?=tux.bootstrap
export TUI_COMPOSE_EXTRA_ARGS?=
export TUI_TMUXP_PROFILE_DATA = $(value _TUI_TMUXP_PROFILE)

crux.help: help.namespace/crux
	@# Lists only the targets available under the 'crux' namespace.

tux.bootstrap:
	@#
	@#
	@#
	header="${GLYPH_IO} tux.bootstrap ${SEP} ${TUI_COMPOSE_FILE} ${SEP} " \
	&& printf "$${header} ${DIM}writing.. ${NO_ANSI}\n" | make stream.indent.stderr \
	&& ${make} mk.def.write.to.file/_CRUX_CONF/${TUI_COMPOSE_FILE} \
	&& ( \
		([ -z $${preview:-} ] && true || ${make} io.file.preview/${TUI_COMPOSE_FILE}) \
		&& printf "$${header} ${DIM}validating..${NO_ANSI}\n" \
		&& make compose.services/${TUI_COMPOSE_FILE} | ${make} stream.dim.indent.stderr \
		&& printf "$${header} ${DIM}building..${NO_ANSI}\n") | make stream.indent.stderr \
	&& ${make} compose.qbuild/${TUI_COMPOSE_FILE}

crux.mux/%:
	@# Maps execution for each of the comma-delimited targets 
	@# into separate panes of a tmux (actually 'tmuxp') session.
	@#
	@# USAGE:
	@#   make crux.mux/<target1>,<target2>
	@#
	# 
	reattach="TMUX=${TUI_TMUX_SOCKET} tmux attach -t ${TUI_TMUX_SESSION_NAME}" \
	${make} crux.mux.detach/${*}

crux.mux.detach/%:
	@#
	@# Like 'crux.mux' except without default attachment
	@#
	header="${GLYPH_IO} crux.mux.detach ${SEP} ${*} ${SEP} " \
	&& printf "$${header}\n" > ${stderr} \
	&& export panes=$(strip $(shell ${make} .crux.panes/${*})) \
	&& eval "$${TUI_TMUXP_PROFILE_DATA}" > $${TMUXP}  \
	&& set -x \
	&& docker compose -f ${TUI_COMPOSE_FILE} run \
		-e TUI_TMUX_SOCKET="${TUI_TMUX_SOCKET}" \
		-e TUI_TMUX_SESSION_NAME="${TUI_TMUX_SESSION_NAME}" \
		-e TUI_INIT_CALLBACK="${TUI_INIT_CALLBACK}" \
		-e TUI_LAYOUT_CALLBACK="${TUI_LAYOUT_CALLBACK}" \
		-e TMUX=${TUI_TMUX_SOCKET} \
		-e MAKE="${MAKE}" \
		--entrypoint bash crux -x -c "\
			tmuxp load -d -S ${TUI_TMUX_SOCKET} $${TMUXP} \
			&& ${make} ${TUI_BOOTSTRAP} \
			&& tmux list-sessions \
			&& $${reattach:-true}"
export TMUXP:=.tmp.tmuxp.yml

crux.ui: crux.ui/2
	@#
	@#
	@#

crux.ui/%: ${TUI_BOOTSTRAP}
	@# Starts a split-screen display of several panes inside a tmux (actually 'tmuxp') session.
	@# (Works without a tmux requirement on the host, using the embedded 'compose.mk:crux' container.)
	@#
	@# If argument is an integer, opens the given number of shells in tmux.
	@# Otherwise, executes one shell per pane for each of the comma-delimited container-names.
	@# 
	@# USAGE:
	@#   make crux.ui/<svc1>,<svc2>
	@#
	@# USAGE:
	@#   make crux.ui/<int>
	@#
	header="${GLYPH_IO} crux.ui ${SEP} ${*}" \
	&& printf "$${header}\n" > ${stderr} \
	&& case ${*} in \
		''|*[!0-9]*) \
			targets=`echo $(strip $(shell printf ${*}|sed 's/,/\n/g' | xargs -I% printf '%/shell,'))| sed 's/,$$//'` \
			; ;; \
		*) \
			targets=`seq ${*}|xargs -n1 -I% printf "io.bash,"` \
			; ;; \
	esac \
	&& ${make} crux.mux/$(strip $${targets})

.crux.bind.keys:
	@# Private helper for .tui.init.  
	@# (This bind default keys for pane resizing, etc)
	tmux bind -n M-Up resize-pane -U 5 \
	; tmux bind -n M-Down resize-pane -D 5 \
	; tmux bind -n M-Left resize-pane -L 5 \
	; tmux bind -n M-Right resize-pane -R 5
	#`make .crux.bind.keys.helper2`
.crux.bind.keys.helper1:
	@#
	./k8s-tools.yml config --services \
	| python3 -c "import sys; tmp=sys.stdin.read().split()[:1]; tmp=[f'#[range=user|{x}][{x}]#[norange]' for x in tmp]; tmp=' '.join(tmp); print(tmp)"
.crux.bind.keys.helper2:
	@#
	make k8s-tools.services | make mk.def.dispatch/python3/_.crux.bind.helper2 | make stream.peek

.crux.init: 
	@# Initialization for the TUI (a tmuxinator-managed tmux instance).
	@# This needs to be called from inside the TUI container, with tmux already running.
	@#
	@# Typically this is used internally during TUI bootstrap, but you can call this to 
	@# rexecute the main setup for things like default key-bindings and look & feel.
	@#
	printf "${GLYPH_IO} .crux.init ${SEP} ... ${NO_ANSI}\n" > ${stderr}
	make .tui.config 

.crux.layout.spiral: .crux.dwindle/s
	@# Alias for the dwindle spiral layout.  
	@# See '.crux.dwindle' docs for more info

.crux.layout.horizontal: .crux.dwindle/h
	@# Alias for the horizontal layout.  
	@# See '.crux.dwindle' docs for more info

.crux.dwindle/%:
	@# Sets geometry to the given layout, using tmux-layout-dwindle.
	@# This is installed by default in k8s-tools.yml / k8s:krux container.
	@# See [1] for general docs and discussion of options.
	@#
	@# [1] https://raw.githubusercontent.com/sunaku/home/master/bin/tmux-layout-dwindle
	@#
	set -x && tmux-layout-dwindle ${*}

.crux.geo.get:
	@# Gets current geometry
	tmux list-windows | sed -n 's/.*layout \(.*\)] @.*/\1/p'

.crux.geo.set:
	@# Sets the given current geometry
	tmux select-layout "$${geometry}"
.crux.pane.focus/%:
	@# Focuses the given pane
	tmux select-pane -t 0.${*} || true
.crux.pane/%:
	@# Dispatches the given make-target to the tmux pane with the given id.
	@#
	@# USAGE:
	@#   make .crux.pane/<pane_id>/<target_name>
	@#
	pane_id=`printf "${*}"|cut -d/ -f1` \
	&& target=`printf "${*}"|cut -d/ -f2-` \
	cmd="make $${target}" make .crux.pane.sh/${*}
.crux.pane.sh/%:
	@# Dispatch a shell command to the tmux pane with the given ID.
	@#
	@# USAGE:
	@#   cmd="echo hello tmux pane" make .crux.pane.sh/<pane_id>
	@#
	pane_id=`printf "${*}"|cut -d/ -f1` \
	&& export TMUX=${TUI_TMUX_SOCKET} \
	&& session_id="${TUI_TMUX_SESSION_NAME}:0" \
	&& set -x \
	&& tmux send-keys \
		-t $${session_id}.$${pane_id} \
		"$${cmd:-echo hello .tui.pane.sh}" C-m
.crux.pane.title/%:
	pane_id=`printf "${*}"|cut -d/ -f1` \
	tmux select-pane -t ${*} -T "$${title}"

.crux.panes/%:
	@# This generates the tmuxp panes data structure (a JSON array) from comma-separated target list.
	echo $${*} \
	&& export targets="${*}" \
	&& ( printf "$${targets}" \
		 | ${make} stream.comma.to.nl \
		 | xargs -n1 -I% echo "{\"name\":\"%\",\"shell\":\"${make} %\"}" \
	) | jq -s -c | echo \'$$(cat /dev/stdin)\' 

.crux.msg/%:
	@#
	@#
	tmux display-message ${*}

.crux.pane.title/%:
	pane_id=`printf "${*}"|cut -d/ -f1` \
	tmux select-pane -t ${*} -T "$${title}"

.crux.theme:
	@#
	set -x \
	&& make \
		${TUI_THEME_PRE_HOOK} \
		.crux.theme.set/${TUI_THEME_NAME} \
		${TUI_THEME_POST_HOOK} 
	
define _crux.theme.buttons 
#{?window_end_flag,#[range=user|new_pane_button][NewPane]#[norange]#[range=user|exit_button][Exit]#[norange],}
endef
.crux.theme.buttons:
	wscf=`make mk.def.read/_crux.theme.buttons | xargs -I% printf "$(strip %)"` \
	&& tmux set -g window-status-current-format "$${wscf}" \
	&& _1="{if -F '#{==:#{mouse_status_range},new_pane_button}' {split-window} $${__1}}" \
	&& __1="{if -F '#{==:#{mouse_status_range},exit_button}' {split-window}}" \
	&& tmux bind -Troot MouseDown1Status "if -F '#{==:#{mouse_status_range},window}' {select-window} $${_1}"
.crux.theme.custom:
	@# Stuff that has to be set before importing the theme 
	setter="tmux set -goq" \
	&& $${setter} @theme-status-interval 1 \
	&& $${setter} @themepack-status-left-area-right-format \
		"wd=#{pane_current_path}" \
	&& $${setter} @themepack-status-right-area-middle-format \
		"cmd=#{pane_current_command} pid=#{pane_pid}"
.crux.theme.set/%: 
	@# Sets the named theme for current tmux session.  
	@#
	@# Requires themepack [1] (installed by default with compose.mk:crux container)
	@#
	@# USAGE:
	@#   make io.tmux.theme/powerline/double/cyan
	@#
	@# [1]: https://github.com/jimeh/tmux-themepack.git
	@# [2]: https://github.com/tmux/tmux/wiki/Advanced-Use
	@#
	tmux display-message "io.tmux.theme: ${*}" \
	&& tmux source-file $${HOME}/.tmux-themepack/${*}.tmuxtheme	

## END 'crux.*' targets
## BEGIN Embedded files

define _CRUX_CONF 
# .tmp.compose.mk.yml: 
#   This is an embedded/JIT compose file generated by compose.mk.
#
# This describes a stand-alone docker-compose config for a 
# DIND / TUI base container.  This is included for some TUI 
# functionality in case your project  doesn't actually *have* 
# any docker-compose file.  If you do have a docker-compose file 
# that you're using with 'compose.import', you can build on this 
# container by using 'FROM compose.mk:crux' and then adding
# your own stuff.
#
services:
  # https://github.com/efrecon/docker-images/tree/master/chafa
  dind_base: &dind_base 
    image: compose.mk:dind_base 
    tty: true
    build:
      context: . 
      dockerfile_inline: |
        FROM ${DEBIAN_CONTAINER_VERSION:-debian:bookworm}
        RUN groupadd --gid ${DOCKER_GID:-1000} ${DOCKER_UGNAME:-root}
        RUN useradd --uid ${DOCKER_UID:-1000} --gid ${DOCKER_GID:-1000} --shell /bin/bash --create-home ${DOCKER_UGNAME:-root}
        RUN echo "${DOCKER_UGNAME:-root} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        RUN apt-get update && apt-get install -y curl uuid-runtime git
        RUN curl -fsSL https://get.docker.com -o get-docker.sh && bash get-docker.sh
        USER ${DOCKER_UGNAME:-root}
  # crux: for dockerized tmux!
  # This is used for TUI scripting by the 'tui.*' targets
  # Docs: .....
  # Manifest: 
  #   [1] tmux 3.4 by default (slightly newer than bookworm default)
  #   [2] tmuxp, for working with profiled sessions
  #   [3] https://github.com/hpjansson/chafa
  #   [4] https://github.com/efrecon/docker-images/tree/master/chafa
  #   [5] https://raw.githubusercontent.com/sunaku/home/master/bin/tmux-layout-dwindle
  #   [6] https://github.com/tmux-plugins/tmux-sidebar/blob/master/docs/options.md
  crux: &crux
    <<: *dind_base
    image: compose.mk:crux
    hostname: crux
    tty: true
    working_dir: /workspace
    volumes:
      # Share the docker sock.  Almost everything will need this
      - ${DOCKER_SOCKET:-/var/run/docker.sock}:/var/run/docker.sock
      # Share /etc/hosts, so tool containers have access to any custom or kubefwd'd DNS
      - /etc/hosts:/etc/hosts:ro
      # Share the working directory with containers.  
      # Overrides are allowed for the workspace, which is occasionally useful with DIND
      - ${workspace:-${PWD}}:/workspace
    environment: &crux_environment
      DOCKER_UID: ${DOCKER_UID:-1000}
      DOCKER_GID: ${DOCKER_GID:-1000}
      DOCKER_UGNAME: ${DOCKER_UGNAME:-root}
      DOCKER_HOST_WORKSPACE: ${DOCKER_HOST_WORKSPACE:-${PWD}}
      TERM: ${TERM:-xterm-256color}
      COMPOSE_MK_DIND: "1"
    build:
      context: . 
      dockerfile_inline: |
        FROM compose.mk:dind_base
        USER root 
        RUN apt-get update && apt-get install -y python3-pip wget tmux libevent-dev build-essential yacc ncurses-dev
        RUN wget https://github.com/tmux/tmux/releases/download/${TMUX_CLI_VERSION:-3.4}/tmux-${TMUX_CLI_VERSION:-3.4}.tar.gz
        RUN apt-get install -y chafa jq yq bc ack-grep tree pv
        RUN pip3 install tmuxp --break-system-packages
        RUN tar -zxvf tmux-${TMUX_CLI_VERSION:-3.4}.tar.gz 
        RUN cd tmux-${TMUX_CLI_VERSION:-3.4} && ./configure && make && mv ./tmux `which tmux`
        RUN mkdir -p /home/${DOCKER_UGNAME:-root}
        RUN curl -sL https://raw.githubusercontent.com/sunaku/home/master/bin/tmux-layout-dwindle > /usr/bin/tmux-layout-dwindle
        RUN chmod ugo+x /usr/bin/tmux-layout-dwindle
        USER ${DOCKER_UGNAME:-root}
        WORKDIR /home/${DOCKER_UGNAME:-root}
        RUN git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        RUN git clone https://github.com/jimeh/tmux-themepack.git ~/.tmux-themepack
        RUN git clone https://github.com/tmux-plugins/tmux-sidebar ~/.tmux/plugins/tmux-sidebar
        
        # Write default tmux conf 
        RUN tmux show -g | sed 's/^/set-option -g /' > ~/.tmux.conf
        
        # Really basic stuff like mouse-support, standard key-bindings
        RUN cat <<EOF >> ~/.tmux.conf
          set -g mouse on
          set -g @plugin 'tmux-plugins/tmux-sensible'
          bind-key  -n  M-1   select-window    -t  :=1
          bind-key  -n  M-2   select-window    -t  :=2
          bind-key  -n  M-3   select-window    -t  :=3
          bind-key  -n  M-4   select-window    -t  :=4
          bind-key  -n  M-5   select-window    -t  :=5
          bind-key  -n  M-6   select-window    -t  :=6
          bind-key  -n  M-7   select-window    -t  :=7
          bind-key  -n  M-8   select-window    -t  :=8
          bind-key  -n  M-9   select-window    -t  :=9
          bind | split-window -h
          bind - split-window -v
          run -b '~/.tmux/plugins/tpm/tpm'
        EOF
        
        # Cause 'tpm' to installs any plugins mentioned above
        RUN cd ~/.tmux/plugins/tpm/scripts \
          && TMUX_PLUGIN_MANAGER_PATH=~/.tmux/plugins/tpm \
            ./install_plugins.sh
endef


define _TUI_TMUXP_PROFILE
cat <<EOF
session_name: crux_tui
start_directory: /workspace
environment:
  TUI_LAYOUT_CALLBACK: ${TUI_LAYOUT_CALLBACK}
global_options:
  status-right-length: 100
options: {}
windows:
  - window_name: crux_tui
    options:
      automatic-rename: on
    panes: ${panes:-[]}
EOF
endef
define _.crux.bind.helper2
import sys; import json
tmp=sys.stdin.read().split()[:3]; 
acc=''
for x in tmp:
  z = "{if -F '#{==:#{mouse_status_range}," + x +"}' { split-window; send-keys 'make "+x+"/shell' C-m}}"
  if not acc: acc=z 
  else: acc=acc[:-1]+z+'}'
assert len([x for x in acc if x=='{'])==len([x for x in acc if x=='}'])
sys.stdout.write(acc)
endef

## BEGIN: compose.macros

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
	@# Dispatch helper
	@#
	printf "${make} `printf $${*}|cut -d/ -f2-`" \
	| ${make} $${compose_file_stem}/`printf $${*}|cut -d/ -f1`/shell/pipe

${compose_file_stem}.qdispatch/%: 
	@# Quiet version of dispatch
	@#
	COMPOSE_MK_DEBUG=0 make $${compose_file_stem}.dispatch/$${*}

${compose_file_stem}/$(compose_service_name)/get_shell:
	@# Detects the best shell to use with ${compose_file_stem}/$(compose_service_name)
	@#
	docker compose -f $$(compose_file) \
		run --entrypoint sh $$(shell echo $$@|awk -F/ '{print $$$$2}') \
		-c "which bash || which sh" 2> /dev/null \
		|| ( \
			export err="${YELLOW}Neither 'bash' nor 'sh' are available!\n" \
			&& err+="(service=$${compose_service_name} @ $${compose_file})\n${NO_ANSI}" \
			&& printf "$${err}" > ${stderr} ; exit 1)

${compose_file_stem}/$(compose_service_name)/shell:
	@# Invokes the shell
	@#
	@ export entrypoint=`${make} ${compose_file_stem}/$(compose_service_name)/get_shell` \
	&& printf "${GREEN}⇒${NO_ANSI}${DIM} ${compose_file_stem}/$(compose_service_name)/shell (${GREEN}`env|grep entrypoint\=`${NO_ANSI}${DIM})${NO_ANSI}\n" \
		&& ${make} ${compose_file_stem}/$(compose_service_name)
	
${compose_file_stem}/$(compose_service_name)/shell/pipe:
	@# Pipes data into the shell, using stdin directly.
	@# NB: implementation must NOT use 'io.mktemp'!
	@#
	@$$(eval export shellpipe_tempfile:=$$(shell mktemp))
	trap "rm -f $${shellpipe_tempfile}" EXIT \
	&& cat /dev/stdin > $${shellpipe_tempfile} \
	&& eval "cat $${shellpipe_tempfile} \
	| pipe=yes \
	  entrypoint="bash" \
	  ${make} ${compose_file_stem}/$(compose_service_name)"

${compose_file_stem}/$(compose_service_name)/pipe:
	cat /dev/stdin | make ⟂/${compose_file_stem}/$(compose_service_name)

$(eval ifeq ($$(import_to_root), TRUE)
$(compose_service_name): $(target_namespace)/$(compose_service_name)
$(compose_service_name)/pipe: ⟂/${compose_file_stem}/$(compose_service_name)
$(compose_service_name)/shell: ${compose_file_stem}/$(compose_service_name)/shell
$(compose_service_name)/get_shell:  ${compose_file_stem}/$(compose_service_name)/get_shell
$(compose_service_name)/build: ${compose_file_stem}.build/$(compose_service_name)
$(compose_service_name)/shell/pipe: ${compose_file_stem}/$(compose_service_name)/shell/pipe
$(compose_service_name)/dispatch/%:; ${make} ${compose_file_stem}.dispatch/$(compose_service_name)/$${*}
$(compose_service_name)/qdispatch/%:;${make} ${compose_file_stem}.qdispatch/$(compose_service_name)/$${*}
endif)

${target_namespace}/$(compose_service_name):
	@# A namespaced target for each docker-compose service
	@#
	make ${compose_file_stem}/$$(shell echo $$@|awk -F/ '{print $$$$2}')

${target_namespace}/$(compose_service_name)/%:
	@# A subtarget for each docker-compose service.
	@# This allows invocation of *another* make-target
	@# that runs inside the container
	@#
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

${compose_file_stem}.stat: 
	@printf "${GLYPH_IO} ${compose_file_stem}.stat${NO_ANSI} ${SEP}\n  $(__services__)\n" > ${stderr}

${compose_file_stem}.build:; set -x && docker compose -f ${compose_file} build
${compose_file_stem}.qbuild:; make compose.qbuild/${compose_file}
${compose_file_stem}.qbuild/%:; make io.quiet.stderr/${compose_file_stem}.build/$${*}
${compose_file_stem}.build/%:; echo $${*} | make stream.comma.to.nl | xargs -n1 -I% sh -x -c "docker compose -f ${compose_file} build %"
${compose_file_stem}.stop:; docker compose -f $${compose_file} stop -t 1
	@#
${compose_file_stem}.up:; docker compose -f $${compose_file} up
	@#
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
	@$$(eval export nsdisp:=${BOLD}$${target_namespace}${NO_ANSI})
	@$$(eval export header:=${GREEN}$${nsdisp}${DIM} ${SEP} ${BOLD}${DIM_GREEN}$${compose_file_stem}${NO_ANSI_DIM} ${SEP} ${BOLD}${GREEN}${UNDERLINE}$${svc_name}${NO_ANSI_DIM} container $${GLYPH_DEBUG}${NO_ANSI}\n)
	@$$(eval export entrypoint:=$(shell \
		if [ -z "$${entrypoint:-}" ]; \
		then echo ""; else echo "--entrypoint $${entrypoint:-}"; fi))
	@$$(eval export base:=docker compose -f ${compose_file} \
		run --rm --quiet-pull \
		--env COMPOSE_MK=1 \
		--env COMPOSE_MK_DEBUG=$${COMPOSE_MK_DEBUG} \
		$${pipe} $${entrypoint} $${svc_name} $${cmd})
	@$$(eval export stdin_tempf:=$$(shell mktemp))
	@$$(eval export entrypoint_display:=${CYAN}[${NO_ANSI}${BOLD}$(shell \
			if [ -z "$${entrypoint:-}" ]; \
			then echo "default${NO_ANSI} entrypoint"; else echo "$${entrypoint:-}"; fi)${NO_ANSI_DIM}${CYAN}]${NO_ANSI})
	@$$(eval export cmd_disp:=${NO_ANSI_DIM}${ITAL}`[ -z "$${cmd}" ] && echo " " || echo " $${cmd}\n"`${NO_ANSI})
	@trap "rm -f $${stdin_tempf}" EXIT \
	&& if [ -z "$${pipe}" ]; then \
		([ $${COMPOSE_MK_DEBUG} == 1 ] && printf "$${header}${DIM}$${nsdisp} ${NO_ANSI_DIM}$${entrypoint_display}$${cmd_disp}${GREEN_FLOW_LEFT}  ${CYAN}<${NO_ANSI}${BOLD}interactive${NO_ANSI}${CYAN}>${NO_ANSI}${DIM_ITAL}`cat $${stdin_tempf} | sed 's/^[\\t[:space:]]*//'| sed -e 's/COMPOSE_MK=[01] //'`${NO_ANSI}\n" > ${stderr} || true) \
		&& ([ $${COMPOSE_MK_TRACE} == 1 ] && printf "${DIM}$${base}${NO_ANSI}\n">${stderr} || true ) \
		&& eval $${base} ; \
	else \
		cat /dev/stdin > $${stdin_tempf} \
		&& ([ $${COMPOSE_MK_DEBUG} == 1 ] && printf "$${header}${DIM}$${nsdisp} ${NO_ANSI_DIM}$${entrypoint_display}$${cmd_disp}${CYAN_FLOW_LEFT}  ${DIM_ITAL}`cat $${stdin_tempf} | sed 's/^[\\t[:space:]]*//'| sed -e 's/COMPOSE_MK=[01] //'`${NO_ANSI}\n" > ${stderr} || true) \
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

## END compose.macros
## BEGIN io.macros

# Helper for working with temp files.  Returns filename, 
# and uses 'trap' to handle at-exit file-deletion automatically.
# Note that this has to be macro for reasons related to ONESHELL.
# You should chain commands with ' && ' to avoid early deletes
define io.mktemp
	export tmpf=$${prefix:-}$$(mktemp --suffix $${suffix:-.tmp} -p .) && trap "rm -f $${tmpf}" EXIT
endef


## END macros
## BEGIN macros

# Define 'help' target iff it's not already defined.  This should be inlined 
# for all files that want to be simultaneously usable in stand-alone 
# mode + library mode (with 'include')
_help_id:=$(shell (uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s) | head -c 8 | tail -c 8)
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
help.namespace/%:; ${make} help | uniq | grep -v ^all$$ | grep ^${*}[.]

define _loadf 
cat <<EOF
# generated for ${fname}
SHELL := bash
.SHELLFLAGS?=-euo pipefail -c
include ${COMPOSE_MK_SRC}
\$(eval \$(call compose.import, ▰, TRUE, ${TUI_COMPOSE_FILE}))
\$(eval \$(call compose.import, ▰, TRUE, ${fname}))
EOF
endef
export TUI_TMUXP_PROFILE_DATA = $(value _TUI_TMUXP_PROFILE)

## END macros

ifeq ($(COMPOSE_MK_STANDALONE),1)
export LOADF = $(value _loadf)
loadf/%: 
	@#
	@# USAGE:
	@#  make compose.loadf/<compose_file>
	@# 2>&1 | make stream.indent > ${stderr}
	true \
	&& make gum.style text="Preparing TUI" \
	&& header="${GLYPH_IO} loadf${NO_ANSI_DIM} ${SEP}" \
	&& printf "$${header} ${DIM_GREEN} ${*} ${NO_ANSI}\n" >${stderr} \
	&& fname="${*}" \
	&& ls $${fname} > /dev/null || (printf "No such file"; exit 1) \
	&& tmpf=.tmp.mk \
	&& words=`echo "$${COMPOSE_MK_CLI#*loadf/}"` \
	&& words=`printf "$${words}" | sed 's/ /\n/g' | tail -n +2` \
	&& stem=`${make} compose.get.stem/$${fname}` \
	&& ${make} io.file.preview/$${fname} 2>&1 | make stream.indent \
	&& eval "$${LOADF}" > $${tmpf} \
	&& ${make} io.file.preview/$${tmpf} 2>&1 | make stream.indent \
	&& ( \
		printf "$${header} $${tmpf} ${SEP} ${DIM} validating services\n" \
		&& make -f $${tmpf} $${stem}.services ) | make stream.indent.stderr \
	&& first=`make -f $${tmpf} $${stem}.services \
		| head -5 | xargs -I% printf "% " \
		| sed 's/ /,/g' | sed 's/,$$//'` \
	&& printf "$${header} $${tmpf} ${SEP} ${DIM} pane targets: $${first}\n" | make stream.indent.stderr \
	&& make gum.style text="Starting TUI" \
	&& set -x \
	&& make -f $${tmpf} $${words:-crux.ui/$${first}}
	$(call _mk.interrupt)
endif 