#!/usr/bin/env -S make -s -S --warn-undefined-variables -f
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
#   4) A small-but-powerful built-in TUI framework with no host dependencies. (See the tux.* API) 
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
#   3) If you need to work on this file, you want Makefile syntax-highlighting & tab/spaces visualization.
#

## BEGIN: data
SHELL := bash

# Color constants and other stuff for formatting user-messages
export no_ansi=\033[0m
export green=\033[92m
export yellow=\033[33m
export dim=\033[2m
export underline=\033[4m
export bold=\033[1m
export ital=\033[3m
export no_color=\e[39m
export red=\033[91m
export cyan=\033[96m
export dim_red:=${dim}${red}
export dim_cyan:=${dim}${cyan}
export bold_cyan:=${bold}${cyan}
export bold_green:=${bold}${green}
export dim_green:=${dim}${green}
export dim_ital:=${dim}${ital}
export no_ansi_dim:=${no_ansi}${dim}
export cyan_flow_left:=${bold_cyan}⋘${dim}⋘${no_ansi_dim}⋘${no_ansi}
export green_flow_left:=${bold_green}⋘${dim}⋘${no_ansi_dim}⋘${no_ansi}
export sep:=${no_ansi}//
export TERM?=xterm-256color

stderr:=/dev/stderr
devnull:=/dev/null

define _make.interrupt
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
_GLYPH_DOCKER=${bold}≣${no_ansi}
GLYPH_DOCKER=${green}${_GLYPH_DOCKER}${dim_green}
_GLYPH_IO=${bold}⇄${no_ansi}
GLYPH_IO=${green}${_GLYPH_IO}${dim_green}
_GLYPH_TUI=${bold}⏣${no_ansi}
GLYPH_TUI=${green}${_GLYPH_TUI}${dim_green}
_GLYPH_FLUX=${bold}Φ${no_ansi}
GLYPH_FLUX=${green}${_GLYPH_FLUX}${dim_green}
export GLYPH_DEBUG=${dim}(debug=${no_ansi}${COMPOSE_MK_DEBUG}${dim})${no_ansi} 

# Make related variables 
# MAKEFILE_LIST: ...
# MAKEFILE: ...
# MAKE: ...
export MAKEFILE_LIST
export MAKE_FLAGS=$(shell [ `echo ${MAKEFLAGS} | cut -c1` = - ] && echo "${MAKEFLAGS}" || echo "-${MAKEFLAGS}")
export MAKEFILE:=$(firstword $(MAKEFILE_LIST))
export MAKE:=make ${MAKE_FLAGS} -f ${MAKEFILE}
export make:=${MAKE}
# Used internally.  If this is container-dispatch and DIND, 
# then DOCKER_HOST_WORKSPACE should be treated carefully
ifeq ($(shell echo $${COMPOSE_MK_DIND:-0}), 1)
export workspace?=$(shell echo ${DOCKER_HOST_WORKSPACE})
export COMPOSE_MK=0
endif
.DEFAULT_GOAL?=help

## END data
## BEGIN 'compose.*' and 'docker.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-docker
##   [2] https://github.com/elo-enterprises/k8s-tools/#api-compose

COMPOSE_QUIET:=2> >(\
	grep -vE '.*Container.*(Running|Recreate|Created|Starting|Started)' \
	>&2 \
	| grep -vE '.*Network.*(Creating|Created)' >&2 )

compose.build/%:
	@#
	@#
	@#
	printf "${GLYPH_DOCKER} compose.build${no_ansi_dim} ${sep} ${green}${*}${no_ansi}\n" > ${stderr}
	docker compose -f ${*} build

compose.clean:
	@# Cleans all images from 'compose.mk' repository, i.e. all the embedded containers.
	@# No arguments.
	@#
	docker images --format json \
	| docker run ghcr.io/jqlang/jq:1.7.1 \
		-r '.|select(.Repository=="compose.mk").Tag'  \
	| xargs -I% docker rmi compose.mk:%

compose.dispatch.sh/%:
	@#
	@#
	@#
	([ $${COMPOSE_MK_TRACE} == 1 ] \
		&&  (printf "${GLYPH_DOCKER} compose.dispatch${no_ansi_dim} ${sep} ${green}${*}${no_ansi}\n" > ${stderr} )\
		|| true; ) \
	&& docker compose -f ${*} run \
		--entrypoint bash $${svc} \
		`[ $${COMPOSE_MK_TRACE} == 1 ] && echo '-x' || echo` \
		-c "$${cmd:-true}" ${COMPOSE_QUIET}

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

compose.get.stem/%:
	@# Returns a normalized version of the given compose-file stem
	@#
	@# USAGE:
	@#  make compose.get.stem/<fname>
	@#
	basename -s .yml `basename -s .yaml ${*}`

compose.kernel:
	@#
	@# USAGE:
	@#  echo flux.ok | ./compose.mk kernel
	@#
	set -x \
	&& ${make} $${make_extra:-} "`cat /dev/stdin | ${make} stream.peek`"

compose.qbuild/%:
	@#
	@#
	@#
	printf "${GLYPH_DOCKER} compose.qbuild${no_ansi_dim} ${sep} ${green}${*}${no_ansi}\n" > ${stderr}
	cmd="docker compose -f ${*} build" make io.quiet.stderr.sh

compose.services/%:
	docker compose -f ${*} config --services

compose.stat/%:
	# printf "${GLYPH_FLUX} compose.stat${no_ansi_dim} ${sep} ${dim_green} ${*} ${no_ansi}\n" >${stderr}
	# ( \
	# 	env | grep COMP || true \
	# 	; env | grep DOCKER || true \
	# 	; env|grep workspace || true ) | make stream.dim.indent

compose.validate/%:
	@# Validates the given compose file (i.e. asks docker compose to parse it)
	@# 
	@# USAGE:
	@#   make compose.validate/<compose_file>
	@#
	header="${GLYPH_IO} compose.validate ${sep} ${*} ${sep} " \
	&& printf "$${header} ${dim}$${label:-validating compose file}..${no_ansi}\n" > ${stderr} \
	&& make compose.services/${*} > ${devnull}


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
	printf "${GLYPH_DOCKER} docker.stop${no_ansi_dim} ${sep} ${green}$${id:-$${name}}${no_ansi}\n"
	export cid=`[ -z "$${id:-}" ] && docker ps --filter name=$${name} --format json | jq -r .ID || echo $${id}` \
	&& case "$${cid:-}" in \
		"") \
			printf "$${dim}${GLYPH_DOCKER} docker.stop${no_ansi} // ${yellow}No containers found${no_ansi}\n"; ;; \
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
	&& printf "${GLYPH_DOCKER} docker.stat${no_ansi_dim}:\n" > ${stderr} \
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

io.file.pygmentize/%:
	@# Syntax highlighting for the given file.
	@# Lexer will autodetected unless override is provided.  
	@# Style defaults to 'trac', which works best with dark backgrounds.
	@#
	@# USAGE:
	@#   make io.file.pygmentize/<fname>
	@#   lexer=.. make io.file.pygmentize/<fname>
	@#   lexer=.. style=.. make io.file.pygmentize/<fname>
	@#
	@# REFS:
	@# [1]: https://hub.docker.com/r/backplane/pygmentize
	@# [2]:https://pygments.org/styles/
	@#
	lexer=`[ -z $${lexer:-} ] && echo '-g' || echo -l $${lexer}` \
	&& style="-Ostyle=$${style:-trac}" \
	&& ${PYGMENTIZE} $${style} $${lexer} -f terminal256 ${*}

io.file.preview/%:
	@# Outputs syntax-highlighting + line-numbers for the given filename to stderr.
	@#
	@# USAGE:
	@#  make io.file.preview/<fname>
	@#
	header="${GLYPH_IO} io.file.preview${no_ansi}" \
	&& printf "$${header} ${sep} ${dim}${bold}${*}${no_ansi}\n" > ${stderr} \
	&& style=trac make io.file.pygmentize/${*} \
	| make stream.nl.enum | make stream.indent.to.stderr

io.env:; 
	@# Dumps a relevant subset of environment variables for the current context.
	@# Pipe-safe, this is just filtered output from 'env'.
	@#
	env   | grep '^PWD=' || true \
	; env | grep '^COMPOSE_MK.*=' || true \
	; env | grep '^MAKE.*=' || true \
	; env | grep '^TUI.*=' | grep -v TUI_TMUXP_PROFILE_DATA || true

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
	    filler=$${filler:-¯} && printf "%*s${no_ansi}\n" "$${width}" '' | sed "s/ /$${filler}/g"; \
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
	cmd="${make} ${*}" make io.quiet.stderr.sh 
	# ${make} ${*}

io.quiet.stderr.sh:
	@# Runs the given target, surpressing stderr output, except in case of error.
	@#
	@# USAGE: 
	@#  make io.quiet/<target_name>
	@#
	$(call io.mktemp) \
	&& header="io.quiet.stderr ${sep}" \
	&& printf "${GLYPH_IO} $${header} ${green}$${cmd}${no_ansi} \n" > ${stderr} \
	&& header="${_GLYPH_IO} io.quiet.stderr ${sep}" \
	&& printf "$${header} ${dim}(Quiet output, except in case of error.) ${no_ansi}\n" > ${stderr} \
	&& start=$$(date +%s) \
	&& $${cmd} 2>&1 > $${tmpf} ; exit_status=$$? ; end=$$(date +%s) ; elapsed=$$(($${end}-$${start})) \
	; case $${exit_status} in \
		0) \
			printf "$${header} ${green}ok ${no_ansi_dim}(in ${bold}$${elapsed}s${no_ansi_dim})${no_ansi}\n" > ${stderr}; ;; \
		*) \
			printf "$${header} ${red}failed ${no_ansi_dim} (error will be propagated)${no_ansi}\n" > ${stderr} \
			; cat $${tmpf} | awk '{print} END {fflush()}' > ${stderr} \
			; exit $${exit_status} ; \
		;; \
	esac

io.print.indent:
	@# Pipe-friendly helper for indention; reads from stdin and returns indented result on stdout
	@#
	cat /dev/stdin | sed 's/^/  /'

io.print.indent.stderr:
	@#
	@#
	@#
	cat /dev/stdin | make io.print.indent > ${stderr}

io.time.wait: io.time.wait/1
	@# Pauses for 1 second.

io.time.wait/%:
	@# Pauses for the given amount of seconds.
	@#
	@# USAGE: 
	@#   io.time.wait/<int>
	@#
	printf "${GLYPH_IO} io.wait${no_ansi} ${sep} ${dim}Waiting for ${*} seconds..${no_ansi}\n" > ${stderr} \
	&& sleep ${*}

## END 'io.*' targets
## BEGIN 'mk.*' targets
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-mk

make.stat:
	@#
	@#
	@#
	printf "${GLYPH_DOCKER} make.stat${no_ansi_dim}:\n" > ${stderr} \
	&& make --version | ${make} stream.dim.indent.stderr

make.help: help.namespace/mk
	@# Lists only the targets available under the 'make' namespace.
make.def.dispatch.python/%:; make make.def.dispatch/python3/${*}:
make.def.dispatch.python.pipe/%:; cat /dev/stdin | make make.def.dispatch.python/${*}
make.def.pdispatch/%:; cat /dev/stdin | make make.def.dispatch/${*}


make.def.dispatch/%:
	@# Reads the given <def_name>, writes to a tmp-file, 
	@# then runs the given interpretter on the tmp file.
	@#
	@# USAGE:
	@#   make make.def.dispatch/<interpretter>/<def_name>
	@#
	@# HINT: for testing, use 'make make.def.dispatch/cat/<def_name>' 
	$(call io.mktemp) \
	&& export intr=`printf "${*}"|cut -d/ -f1` \
	&& export def_name=`printf "${*}" | cut -d/ -f2-` \
	&& make make.def.write.to.file/$${def_name}/$${tmpf} \
	&& [ -z $${preview:-} ] && true || make io.file.preview/$${tmpf} \
	&& header="${GLYPH_IO} make.def.dispatch${no_ansi}" \
	&& ([ $${COMPOSE_MK_TRACE} == 1 ] &&  printf "$${header} ${sep} ${dim}`pwd`${no_ansi} ${sep} ${dim}$${tmpf}${no_ansi}\n" > ${stderr} || true ) \
	&& printf "$${header} ${sep} ${dim}${cyan}${bold}$${intr}${no_ansi} ${sep} ${dim}$${tmpf}${no_ansi}\n" > ${stderr} \
	&& which $${intr} > ${devnull} || exit 1 \
	&& set -x \
	&& $${intr} $${tmpf}
make.def.read/%:
	@# Reads the named define/endef block from this makefile, emitting it to stdout.
	@# This works around make's normal behaviour of completely wrecking indention/newlines
	@# present inside the block.
	@#
	@# USAGE: 
	@#   make mk.read_def/<name_of_define>
	@#
	$(eval def_name=${*})
	$(info $(value ${def_name}))
make.def.write.to.file/%:
	@# Reads the given define/endef block from this makefile, writing it to the given output file.
	@#
	@# USAGE: make make.def.write.to.file/<def_name>/<fname>
	@#
	def_name=`printf "${*}" | cut -d/ -f1` \
	&& out_file=`printf "${*}" | cut -d/ -f2-` \
	&& header="${GLYPH_IO} make.def.write.to.file${no_ansi}" \
	&& printf "$${header} ${sep} ${dim}${cyan}'$${def_name}'${no_ansi} ${sep} ${dim}${bold}$${out_file}${no_ansi}\n" > ${stderr} \
	&& ${make} make.def.read/$${def_name} > $${out_file}

## END 'make.*' targets
## BEGIN 'flux.*' targets
## DOCS:
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-io

define _flux.always
	@# NB: Used in 'flux.always' and 'flux.finally'.  For reasons related to ONESHELL,
	@# this code can't be target-chained and to make it reusable, it needs to be embedded.
	printf "${GLYPH_FLUX} flux.always${no_ansi_dim} ${sep} registering target: ${green}${*}${no_ansi}\n" >${stderr} 
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
	header="${GLYPH_FLUX} flux.always${no_ansi_dim} ${sep} main process finished, " \
	&& ( \
		while kill -0 $${pid} 2> ${devnull}; do sleep 1; done \
		&& 	printf "$${header} dispatching ${green}$${target} ${no_ansi}\n" >${stderr}  \
		&& $(MAKE) $$target \
	) &

flux.apply/%:
	@# Applies the given target(s). Mostly used to as a wrapper in case targets are unary.
	@# 
	@# USAGE:
	@#   make flux.timer/flux.apply/io.time.wait,io.time.wait
	@#
	printf ${*} \
	| tr ',' '\n' \
	| xargs -I% echo make % \
	| bash `([ $${COMPOSE_MK_TRACE} == 1 ] && echo '-x' || echo)`

flux.apply.later/%:
	@# 
	@#
	time=`printf ${*}| cut -d/ -f1` \
	&& target=`printf ${*}| cut -d/ -f2-` \
	&& printf "${GLYPH_FLUX} flux.apply.later${no_ansi_dim} ${sep} ${green}$${target}${no_ansi} (in $${time}s)\n" > ${stderr} \
	&& ( make io.time.wait/$${time} && make flux.apply/$${target}; )&

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
	header="${GLYPH_FLUX} flux.dmux${no_ansi_dim}" \
	&& header+=" ${sep} ${dim}$${targets//,/ ; }${no_ansi}\n" \
	&& printf "$${header}" | make stream.to.stderr
	cat /dev/stdin \
	| make flux.sh.tee \
		cmds="`\
			printf $${targets} \
			| tr ',' '\n' \
			| xargs -I% echo make % \
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
	@#
	@# See also the 'flux.ok' target.
	@#
	printf "${GLYPH_FLUX} flux.fail${no_ansi_dim} ${sep} ${no_ansi} ${red}failing${no_ansi} as requested!\n" > ${stderr}  \
	&& exit 1 

flux.finally/%:
	@# Alias for 'flux.always'
	@#
	$(call _flux.always)

flux.indent/%:
	@# Given a target, this indents both stdout/stderr from the output.
	@# See also the 'stream.indent' target.
	@#
	@# USAGE:
	@#   make flux.indent/<target>
	@#
	${make} flux.indent.sh cmd="${make} ${*}"

flux.indent.sh:
	@# Similar to flux.indent, but this works with any shell command.
	@# 
	@# USAGE:
	@#  cmd="echo foo; echo bar >/dev/stderr" make flux.indent.sh
	@#
	eval $${cmd}  1> >(sed 's/^/  /') 2> >(sed 's/^/  /')

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
	printf "${GLYPH_FLUX} flux.loop${no_ansi_dim} ${sep} ${green}$${target}${no_ansi} ($${times}x)\n" > ${stderr}
	export pv_cmd=`[ $${COMPOSE_MK_DEBUG}==1 ] && echo "pv -s $${times} -l -i 1 --name \"$${target}\" -t -e -C -p" || echo cat` \
	&& (for i in `seq $${times}`; \
	do \
		make $${target} > ${devnull}; echo $${i}; \
	done) | eval $${pv_cmd} > ${devnull}

flux.loopf/%:
	@# Loop the given target forever
	@#
	@# To reduce logging noise, this sends stderr to null, 
	@# but preserves stdout. This makes debugging hard, so
	@# only use this with well tested/understood sub-targets!
	@#
	header="${GLYPH_FLUX} flux.loopf${no_ansi_dim}" \
	&& header+=" ${sep} ${green}${*}${no_ansi}" \
	&& printf "$${header} (forever)\n" > ${stderr} \
	&& while true; do ( \
		make ${*} 2>${devnull} \
		|| printf "$${header} ($${failure_msg:-failed})\n" > ${stderr} \
	) ; sleep $${interval:-1}; done	

flux.loopu/%:
	@# Loop the given target until it succeeds.
	@#
	@# To reduce logging noise, this sends stderr to null, 
	@# but preserves stdout. This makes debugging hard, so
	@# only use this with well tested/understood sub-targets!
	@#
	header="${GLYPH_FLUX} flux.loopu${no_ansi_dim} ${sep} ${green}${*}${no_ansi}" \
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
	header="${GLYPH_FLUX} flux.mux${no_ansi_dim}" \
	&& header+=" ${sep} ${no_ansi_dim}$${targets//,/ ; }${no_ansi}\n" \
	&& printf "$${header}" > ${stderr}
	$(call io.mktemp) && \
	mcmds=`printf $${targets} \
	| tr ',' '\n' \
	| xargs -I% printf 'make % & pids+=\"$$! \"\n' \
	` \
	&& (printf 'pids=""\n' \
		&& printf "$${mcmds}\n" \
		&& printf 'wait $${pids}\n') > $${tmpf} \
	&& printf "${cyan_flow_left} script \n${dim}`cat $${tmpf}|make stream.dim.indent`${no_ansi}\n" > ${stderr} \
	&& bash $${tmpf}

flux.mux/%:
	@# Alias for flux.mux, but accepts arguments directly
	targets="${*}" make flux.mux 

flux.ok:
	@# Alias for 'exit 0', which is success.
	@# This is mostly for used for testing other pipelines.
	@# See also 'flux.fail'
	@#
	printf "${GLYPH_FLUX} flux.ok${no_ansi_dim} ${sep} ${no_ansi} succceeding as requested!\n" > ${stderr}  \
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
		| xargs -I% \
			printf  ">($${tee_pre:-}%$${tee_post:-}) "`" \
	&& header="${GLYPH_FLUX} flux.sh.tee${no_ansi} ${sep}${dim} starting pipe" \
	&& cmd="cat /dev/stdin | tee $${src} " \
	&& printf "$${header} (${no_ansi}${bold}`echo $${cmds} \
		| grep -o ',' \
		| wc -l`${no_ansi_dim} components)\n" > ${stderr} \
	&& printf "${no_ansi_dim}${GLYPH_FLUX} ${no_ansi_dim}flux.sh.tee${no_ansi} ${sep} ${no_ansi_dim}$${cmd}${no_ansi}\n" > ${stderr} \
	&& eval $${cmd} | cat

flux.sh.timeout:
	@# Runs the given command for the given amount of seconds, then stops it with SIGINT.
	@#
	@# USAGE: (tails docker logs for up to 10s, then stops)
	@#   make flux.sh.timeout cmd='docker logs -f xxxx' timeout=10
	@#
	printf "${GLYPH_IO} flux.sh.timeout${no_ansi_dim} (${yellow}$${timeout}s${no_ansi_dim}) ${sep} ${no_ansi_dim}$${cmd}${no_ansi} ${no_ansi}\n" >${stderr} 
	trap "pkill -SIGINT -f \"$${cmd}\"" INT \
	&& eval "$${cmd} &" \
	&& export command_pid=$$! \
	&& sleep $${timeout} \
	&& printf "${dim}${GLYPH_IO} flux.sh.timeout${no_ansi_dim} (${yellow}$${timeout}s${no_ansi_dim}) ${sep} ${no_ansi}${yellow}finished${no_ansi}\n" > ${stderr} \
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
	&& header="${GLYPH_IO} flux.retry${no_ansi_dim}" \
	&& printf "$${header} (${no_ansi}${yellow}$${times}x${no_ansi_dim}) ${sep} ${no_ansi_dim}$${target}${no_ansi}\n" >${stderr}  \
	&& ( r=$${times};\
		 while ! (\
			make $${target} \
			|| ( printf "${dim}$${header} (${no_ansi}${yellow}failed.${no_ansi_dim} waiting ${dim_green}${K8S_POLL_DELTA}s${no_ansi_dim}) ${sep} ${no_ansi_dim}$${target}${no_ansi}\n" > ${stderr}\
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
all_devnull:=2>&1 > /dev/null

export PYGMENTIZE:=docker run --rm --interactive \
		-e TERM=$${TERM}  -v `pwd`:/workspace -w /workspace \
		--entrypoint pygmentize lambdalab/pygments:0.7.34

## END 'flux.*' targets
## BEGIN 'gum.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-gum
##   [2] https://github.com/charmbracelet/gum
define gum.style
text="${1}" make gum.style 
endef 
define gum.style.target
$(call gum.style,${@})
endef 

gum.dispatch:
	@#
	@#
	@#
	which gum > ${devnull} \
	&& $${gum_cmd} 2>${devnull} \
	|| COMPOSE_MK_DEBUG=0 cmd="$${gum_cmd}" make tux.dispatch.sh

gum.spin:
	@#
	@#
	@#
	gum_cmd="gum spin --title \"$${title:-?}\" -- $${cmd:-sleep 2};" \
	make gum.dispatch
	
gum.style: 
	@# Helper for formatting text and banners using 'gum style'.
	@# See https://github.com/charmbracelet/gum for more details.
	@#
	@# There's an optimization here where we attempt to use 
	@# gum on the host if it's available, falling back to using 
	@# it from the 'gum'container
	@#
	@# USAGE:
	@#   make gum.style text="..."
	@#
	gum_cmd="gum style ${GUM_STYLE_DEFAULT} ${GUM_STYLE_DIV} \"$${text}\"" \
	make gum.dispatch


## END 'gum.*' targets
## BEGIN 'stream.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-stream

stream.csv.pygmentize:; cat /dev/stdin | lexer=ini make stream.pygmentize


stream.dim.indent.stderr:
	cat /dev/stdin | make stream.dim| make io.print.indent > ${stderr}

stream.help: help.namespace/stream
	@# Lists only the targets available under the 'stream' namespace.


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
	printf "${dim}`cat /dev/stdin`${no_ansi}\n"

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

stream.pygmentize:
	@# Syntax highlighting for the input stream.
	@#
	@# https://hub.docker.com/r/backplane/pygmentize
	@# https://pygments.org/styles/
	lexer=`[ -z $${lexer:-} ] && echo '-g' || echo -l $${lexer}` \
	&& style="-Ostyle=$${style:-trac}" \
	&& cat /dev/stdin | ${PYGMENTIZE} $${style} $${lexer} -f terminal256 

stream.indent.to.stderr:; cat /dev/stdin | make stream.indent | make stream.to.stderr
	@# Shortcut for ' | stream.indent | stream.to.stderr'

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
## BEGIN 'tux.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-tux
# TUI_CONTAINER_NAME::
# TUI_THEME_NAME::
# TUI_TMUX_SOCKET::
# TUI_LAYOUT_CALLBACK::
# TUI_THEME_PRE_HOOK::
# TUI_THEME_POST_HOOK::
export TUI_CONTAINER_NAME?=tux
export TUI_TMUX_SOCKET?=/workspace/tmux.sock
export TUI_TMUX_SESSION_NAME?=tui
export TUI_LAYOUT_CALLBACK?=.tux.layout.horizontal
export TUI_INIT_CALLBACK?=.tux.init
export TUI_THEME_PRE_HOOK?=.tux.theme.custom
export TUI_THEME_POST_HOOK?=.tux.theme.buttons
export TUI_THEME_POST_HOOK?=
export TUI_THEME_NAME?=powerline/double/blue
export TUI_COMPOSE_FILE?= .tmp.compose.mk.yml
export TUI_BOOTSTRAP?=tux.bootstrap
export TUI_COMPOSE_EXTRA_ARGS?=
export TUI_TMUXP_PROFILE_DATA = $(value _TUI_TMUXP_PROFILE)
export BOOTSTRAPPED:=
export TMUXP:=.tmp.tmuxp.yml


tux.bootstrap:
	@# 
	@# USAGE:
	@#
	header="${GLYPH_TUI} tux.bootstrap ${sep}" \
	&& [ -z $${BOOTSTRAPPED} ] && ${make} .tux.bootstrap \
	|| case `pwd` in \
		*$${BOOTSTRAPPED}*) \
			printf "$${header} ${dim}Skipping bootstrap, already done. ${underline}`pwd`${no_ansi}\n" > ${stderr}; exit 0; ;; \
		*) ${make} .tux.bootstrap; ;; \
	esac
tux.commander/%:
	@# A tmux layout with N panes, using the "commander" layout callback.
	@# See .tux.commander.layout for more details.
	@#
	TUI_LAYOUT_CALLBACK=.tux.commander.layout make tux.mux/${*}

tux.commander: tux.commander/4
	@# A 4-pane session using the commander layout
	@# See .tux.commander.layout for more details.
	@#

tux.dispatch.sh:
	@# Dispatches the given <cmd> into the (embedded) 'tux' container.
	@#
	@# USAGE:
	@#   cmd=... make tux.dispatch.sh
	@#
	${make} tux.bootstrap ${all_devnull} \
	&& svc=tux cmd="$${cmd}" \
	make compose.dispatch.sh/${TUI_COMPOSE_FILE}

tux.dispatch/%:
	@# Dispatch the given target inside the TUI container
	@#
	([ $${COMPOSE_MK_TRACE} == 1 ] && set -x || true) \
	&& cmd="TMUX=${TUI_TMUX_SOCKET} ${make} ${*}" ${make} tux.dispatch.sh

tux.pane/%:
	@# Remote control for the TUI, from the host, running the given target.
	@#
	@# USAGE:
	@#   make tux.pane/1/<target_name>
	@#
	make tux.dispatch/.tux.pane/${*}

tux.help: help.namespace/tux
	@# Lists only the targets available under the 'tux' namespace.

tux.mux/%:
	@# Maps execution for each of the comma-delimited targets 
	@# into separate panes of a tmux (actually 'tmuxp') session.
	@#
	@# USAGE:
	@#   make tux.mux/<target1>,<target2>
	@#
	targets=`printf ${*}| sed 's/,$$//'` \
	&& reattach="TMUX=${TUI_TMUX_SOCKET}" \
	&& export reattach="$${reattach} tmux attach -t ${TUI_TMUX_SESSION_NAME}" \
	&& ([ $${COMPOSE_MK_TRACE} == 1 ] && set -x || true) && ${make} tux.mux.detach/$${targets}

tux.mux.detach/%:
	@#
	@# Like 'tux.mux' except without default attachment
	@#
	@# USAGE:
	@#
	true \
	&& header="${GLYPH_TUI} tux.mux.detach ${sep} ${*} ${sep} " \
	&& printf "$${header}\n" > ${stderr} \
	&& printf "$${header} ${TUI_CONTAINER_NAME} ${TUI_INIT_CALLBACK} ${TUI_LAYOUT_CALLBACK}\n" > ${stderr} \
	&& export panes=$(strip $(shell ${make} .tux.panes/${*})) \
	&& eval "$${TUI_TMUXP_PROFILE_DATA}" > $${TMUXP}  \
	&& cmd="true" \
	&& cmd="$${cmd} && tmuxp load -d -S ${TUI_TMUX_SOCKET} $${TMUXP}" \
	&& cmd="$${cmd} && TMUX=${TUI_TMUX_SOCKET} tmux list-sessions" \
	&& cmd="$${cmd} && TMUX=${TUI_TMUX_SOCKET} ${make} ${TUI_INIT_CALLBACK}" \
	&& cmd="$${cmd} && TMUX=${TUI_TMUX_SOCKET} ${make} ${TUI_LAYOUT_CALLBACK}" \
	&& cmd="$${cmd} && $${reattach}" \
	&& ([ $${COMPOSE_MK_TRACE} == 1 ] && set -x || true) \
	&& docker compose -f ${TUI_COMPOSE_FILE} \
		$${TUI_COMPOSE_EXTRA_ARGS} run \
		-e TUI_TMUX_SOCKET="${TUI_TMUX_SOCKET}" \
		-e TUI_TMUX_SESSION_NAME="${TUI_TMUX_SESSION_NAME}" \
		-e TUI_INIT_CALLBACK="${TUI_INIT_CALLBACK}" \
		-e TUI_LAYOUT_CALLBACK="${TUI_LAYOUT_CALLBACK}" \
		-e MAKE="${MAKE}" \
		-e reattach="$${reattach:-true}" \
		--entrypoint bash ${TUI_CONTAINER_NAME} \
		`[ $${COMPOSE_MK_TRACE} == 1 ] && echo '-x' || echo` \
		-c "$${cmd}" ${COMPOSE_QUIET}
	
tux.ui: tux.ui/2
	@#
	@#
	@# USAGE:
	@#

tux.ui/%: #${TUI_BOOTSTRAP}
	@# Starts a split-screen display of several panes inside a tmux (actually 'tmuxp') session.
	@# (Works without a tmux requirement on the host, using the embedded 'compose.mk:tux' container.)
	@#
	@# If argument is an integer, opens the given number of shells in tmux.
	@# Otherwise, executes one shell per pane for each of the comma-delimited container-names.
	@# 
	@# USAGE:
	@#   make tux.ui/<svc1>,<svc2>
	@#
	@# USAGE:
	@#   make tux.ui/<int>
	@#
	header="${GLYPH_TUI} tux.ui ${sep} ${*}" \
	&& printf "$${header}\n" > ${stderr} \
	&& case ${*} in \
		''|*[!0-9]*) \
			targets=`echo $(strip $(shell printf ${*}|sed 's/,/\n/g' | xargs -I% printf '%/shell,'))| sed 's/,$$//'` \
			; ;; \
		*) \
			targets=`seq ${*}|xargs -I% printf "io.bash,"` \
			; ;; \
	esac \
	&& ${make} tux.mux/$(strip $${targets})

.tux.bootstrap:
	@# Private helper for tux.bootstrap
	@#
	header="${GLYPH_TUI} tux.bootstrap ${sep}" \
	&& ls ${TUI_COMPOSE_FILE} ${all_devnull} \
	|| printf "$${header} ${dim}Ensuring TUI containers are ready..${no_ansi}\n" > ${stderr}\
	&& export BOOTSTRAPPED="$${BOOTSTRAPPED} `pwd`" \
		$(eval BOOTSTRAPPED=$(BOOTSTRAPPED) $(shell pwd)) \
	&& ( \
		${make} make.def.write.to.file/_TUX_CONF/${TUI_COMPOSE_FILE} \
		&& ([ -z $${preview:-} ] && true || ${make} io.file.preview/${TUI_COMPOSE_FILE}) \
		&& label="Validating TUI services.." \
			${make} compose.validate/${TUI_COMPOSE_FILE} \
		&& label="Building TUI if not cached.." \
			${make} compose.qbuild/${TUI_COMPOSE_FILE} \
	) > >(sed 's/^/  /') 2> >(sed 's/^/  /'); \

.tux.commander.layout: 
	@# Configures a custom geometry on up to 4 panes.
	@# This has a large central window and a sidebar.
	@#
	tmux display-message ${@}
	geometry="7384,118x68,0,0{74x68,0,0,1,43x68,75,0[43x21,75,0,2,43x28,75,22,3,43x17,75,51,4]}" \
	make .tux.geo.set

.tux.init.titles:
	@# Private helper for .tui.init.  (This fixes a bug in tmuxp with pane titles)
	tmux set -g base-index 1
	tmux setw -g pane-base-index 1
	tmux set -g pane-border-style fg=magenta
	tmux set -g pane-active-border-style "bg=default fg=magenta"
	# Ensure window index numbers get reordered on delete.
	tmux set-option -g renumber-windows on
	$(eval export tmp=$(strip $(shell cat .tmp.tmuxp.yml | yq .windows[].panes[].name -c| xargs)))
	$(eval export tmpseq=$(shell seq 1 $(words ${tmp})))
	$(foreach i, $(tmpseq), $(shell bash -x -c "tmux select-pane -t `echo ${i}-1|bc` -T $(strip $(shell echo ${tmp}| cut -d' ' -f ${i}));"))

.tux.bind.keys:
	@# Private helper for .tui.init.  
	@# (This bind default keys for pane resizing, etc)
	tmux bind -n M-Up resize-pane -U 5 \
	; tmux bind -n M-Down resize-pane -D 5 \
	; tmux bind -n M-Left resize-pane -L 5 \
	; tmux bind -n M-Right resize-pane -R 5
	#`make .tux.bind.keys.helper2`

.tux.bind.keys.helper1:
	@#
	./k8s-tools.yml config --services \
	| python3 -c "import sys; tmp=sys.stdin.read().split()[:1]; tmp=[f'#[range=user|{x}][{x}]#[norange]' for x in tmp]; tmp=' '.join(tmp); print(tmp)"
.tux.bind.keys.helper2:
	@#
	make k8s-tools.services | make make.def.dispatch/python3/_.tux.bind.helper2 | make stream.peek

.tux.init: 
	@# Initialization for the TUI (a tmuxinator-managed tmux instance).
	@# This needs to be called from inside the TUI container, with tmux already running.
	@#
	@# Typically this is used internally during TUI bootstrap, but you can call this to 
	@# rexecute the main setup for things like default key-bindings and look & feel.
	@#
	printf "${GLYPH_TUI} .tux.init ${sep} ${dim}Initializing TUI... ${no_ansi}\n" > ${stderr}
	${make} .tux.config 

.tux.config: \
	.tux.pane.focus/0 \
	.tux.init.titles \
	.tux.bind.keys .tux.theme

.tux.layout.spiral: .tux.dwindle/s
	@# Alias for the dwindle spiral layout.  
	@# See '.tux.dwindle' docs for more info

.tux.layout.shuffle: .tux.dwindle/h
	${make} flux.delay/1/.tux.dwindle/h \
		flux.delay/1/.tux.dwindle/v \
		flux.delay/1/.tux.dwindle/s 

.tux.layout.horizontal: .tux.dwindle/h
	@# Alias for the horizontal layout.  
	@# See '.tux.dwindle' docs for more info

.tux.dwindle/%:
	@# Sets geometry to the given layout, using tmux-layout-dwindle.
	@# This is installed by default in k8s-tools.yml / k8s:krux container.
	@# See [1] for general docs and discussion of options.
	@#
	@# [1] https://raw.githubusercontent.com/sunaku/home/master/bin/tmux-layout-dwindle
	@#
	set -x && tmux-layout-dwindle ${*}

.tux.geo.get:
	@# Gets current geometry
	tmux list-windows | sed -n 's/.*layout \(.*\)] @.*/\1/p'

.tux.geo.set:
	@# Sets the given current geometry
	tmux select-layout "$${geometry}"

.tux.pane.focus/%:
	@# Focuses the given pane
	tmux select-pane -t 0.${*} || true
.tux.pane/%:
	@# Dispatches the given make-target to the tmux pane with the given id.
	@#
	@# USAGE:
	@#   make .tux.pane/<pane_id>/<target_name>
	@#
	pane_id=`printf "${*}"|cut -d/ -f1` \
	&& target=`printf "${*}"|cut -d/ -f2-` \
	cmd="make $${target}" make .tux.pane.sh/${*}

.tux.pane.sh/%:
	@# Dispatch a shell command to the tmux pane with the given ID.
	@#
	@# USAGE:
	@#   cmd="echo hello tmux pane" make .tux.pane.sh/<pane_id>
	@#
	pane_id=`printf "${*}"|cut -d/ -f1` \
	&& export TMUX=${TUI_TMUX_SOCKET} \
	&& session_id="${TUI_TMUX_SESSION_NAME}:0" \
	&& tmux send-keys \
		-t $${session_id}.$${pane_id} \
		"$${cmd:-echo hello .tui.pane.sh}" C-m

.tux.pane.title/%:
	pane_id=`printf "${*}"|cut -d/ -f1` \
	tmux select-pane -t ${*} -T "$${title}"

.tux.panes/%:
	@# This generates the tmuxp panes data structure (a JSON array) from comma-separated target list.
	echo $${*} \
	&& export targets="${*}" \
	&& ( printf "$${targets}" \
		 | ${make} stream.comma.to.nl \
		 | xargs -I% echo "{\"name\":\"%\",\"shell\":\"${make} %\"}" \
	) | jq -s -c | echo \'$$(cat /dev/stdin)\' 

.tux.msg/%:
	@#
	@#
	tmux display-message ${*}

.tux.pane.title/%:
	@#
	pane_id=`printf "${*}"|cut -d/ -f1` \
	tmux select-pane -t ${*} -T "$${title}"

.tux.theme:
	@#
	([ $${COMPOSE_MK_TRACE} == 1 ] && set -x || true) \
	&& ${make} ${TUI_THEME_PRE_HOOK} \
	&& ${make} .tux.theme.set/${TUI_THEME_NAME}  \
	&& [ -z ${TUI_THEME_POST_HOOK} ] \
		&& true \
		|| ${make} ${TUI_THEME_POST_HOOK}
.tux.panic:
	@#
	tmux kill-session

define _tux.theme.buttons 
#{?window_end_flag,#[range=user|new_pane_button][ NewPane ]#[norange]#[range=user|exit_button][ Exit ]#[norange],}
endef
.tux.theme.buttons:
	@#
	wscf=`make make.def.read/_tux.theme.buttons | xargs -I% printf "$(strip %)"` \
	&& tmux set -g window-status-current-format "$${wscf}" \
	&& ___1="" \
	&& __1="{if -F '#{==:#{mouse_status_range},exit_button}' {kill-session} $${___1}}" \
	&& _1="{if -F '#{==:#{mouse_status_range},new_pane_button}' {split-window} $${__1}}" \
	&& tmux bind -Troot MouseDown1Status "if -F '#{==:#{mouse_status_range},window}' {select-window} $${_1}"

.tux.theme.custom:
	@# Stuff that has to be set before importing the theme 
	setter="tmux set -goq" \
	&& $${setter} @theme-status-interval 1 \
	&& $${setter} @themepack-status-left-area-right-format \
		"wd=#{pane_current_path}" \
	&& $${setter} @themepack-status-right-area-middle-format \
		"cmd=#{pane_current_command} pid=#{pane_pid}"

.tux.theme.set/%: 
	@# Sets the named theme for current tmux session.  
	@#
	@# Requires themepack [1] (installed by default with compose.mk:tux container)
	@#
	@# USAGE:
	@#   make .tux.theme.set/powerline/double/cyan
	@#
	@# [1]: https://github.com/jimeh/tmux-themepack.git
	@# [2]: https://github.com/tmux/tmux/wiki/Advanced-Use
	@#
	tmux display-message "io.tmux.theme: ${*}" \
	&& tmux source-file $${HOME}/.tmux-themepack/${*}.tmuxtheme	

## END 'tux.*' targets
## BEGIN Embedded files

define _TUX_CONF 
# ${TUI_COMPOSE_FILE}: 
# This is an embedded/JIT compose-file, generated by compose.mk.
#
# Do not edit by hand and do not commit to version control.
# It's left just for reference & transparency, and is regenerated
# on demand, so you can also feel free to delete it.
#
# This describes a stand-alone config for a DIND / TUI base container.  
# If you have a docker-compose file that you're using with 'compose.import', 
# you can build on this container by using 'FROM compose.mk:tux' 
# and then adding your own stuff.
#
services:
  # https://github.com/efrecon/docker-images/tree/master/chafa
  dind_base: &dind_base 
    tty: true
    build:
      tags: ["compose.mk:dind_base"]
      context: . 
      dockerfile_inline: |
        FROM ${DEBIAN_CONTAINER_VERSION:-debian:bookworm}
        RUN groupadd --gid ${DOCKER_GID:-1000} ${DOCKER_UGNAME:-root}
        RUN useradd --uid ${DOCKER_UID:-1000} --gid ${DOCKER_GID:-1000} --shell /bin/bash --create-home ${DOCKER_UGNAME:-root}
        RUN echo "${DOCKER_UGNAME:-root} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        RUN apt-get update && apt-get install -y curl uuid-runtime git
        RUN curl -fsSL https://get.docker.com -o get-docker.sh && bash get-docker.sh
        USER ${DOCKER_UGNAME:-root}
  # tux: for dockerized tmux!
  # This is used for TUI scripting by the 'tui.*' targets
  # Docs: .....
  # Manifest: 
  #   [1] tmux 3.4 by default (slightly newer than bookworm default)
  #   [2] tmuxp, for working with profiled sessions
  #   [3] https://github.com/hpjansson/chafa
  #   [4] https://github.com/efrecon/docker-images/tree/master/chafa
  #   [5] https://raw.githubusercontent.com/sunaku/home/master/bin/tmux-layout-dwindle
  #   [6] https://github.com/tmux-plugins/tmux-sidebar/blob/master/docs/options.md
  tux: &tux
    <<: *dind_base
    depends_on:  ['dind_base']
    hostname: tux
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
    environment: &tux_environment
      DOCKER_UID: ${DOCKER_UID:-1000}
      DOCKER_GID: ${DOCKER_GID:-1000}
      DOCKER_UGNAME: ${DOCKER_UGNAME:-root}
      DOCKER_HOST_WORKSPACE: ${DOCKER_HOST_WORKSPACE:-${PWD}}
      TERM: ${TERM:-xterm-256color}
      COMPOSE_MK_DIND: "1"
    build:
      tags: ['compose.mk:tux']
      context: . 
      dockerfile_inline: |
        FROM ghcr.io/charmbracelet/gum as gum
        FROM compose.mk:dind_base
        COPY --from=gum /usr/local/bin/gum /usr/bin
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
# This tmuxp profile is generated by compose.mk.
# Do not edit by hand and do not commit to version control.
# It's left just for reference & transparency, and is regenerated
# on demand, so you can feel free to delete it.
session_name: tui
start_directory: /workspace
environment: {}
global_options: {}
options: {}
windows:
  - window_name: TUI
    options:
      automatic-rename: on
    panes: ${panes:-[]}
EOF
endef
define _.tux.bind.helper2
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
		-c "which bash || which sh" 2> ${devnull} \
		|| ( printf "${yellow}Neither 'bash' nor 'sh' are available!\n (service=$${compose_service_name} @ $${compose_file})\n${no_ansi}" > ${stderr} ; exit 1)

${compose_file_stem}/$(compose_service_name)/shell:
	@# Invokes the shell
	@#
	@ export entrypoint=`${make} ${compose_file_stem}/$(compose_service_name)/get_shell` \
	&& printf "${green}⇒${no_ansi}${dim} ${compose_file_stem}/$(compose_service_name)/shell (${green}`env|grep entrypoint\=`${no_ansi}${dim})${no_ansi}\n" \
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
	@printf "${GLYPH_IO} ${compose_file_stem}.stat${no_ansi} ${sep}\n  $(__services__)\n" > ${stderr}

${compose_file_stem}.build:
	@#
	set -x && docker compose -f ${compose_file} build

${compose_file_stem}.qbuild:; make compose.qbuild/${compose_file}
	@#

${compose_file_stem}.qbuild/%:; make io.quiet.stderr/${compose_file_stem}.build/$${*}
	@#

${compose_file_stem}.build/%:
	@#
	echo $${*} \
	| make stream.comma.to.nl \
	| xargs -I% sh -x -c "docker compose -f ${compose_file} build %"

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
	@$$(eval export nsdisp:=${bold}$${target_namespace}${no_ansi})
	@$$(eval export header:=${green}$${nsdisp}${dim} ${sep} ${bold}${dim_green}$${compose_file_stem}${no_ansi_dim} ${sep} ${bold}${green}${underline}$${svc_name}${no_ansi_dim} container $${GLYPH_DEBUG}${no_ansi}\n)
	@$$(eval export entrypoint:=$(shell \
		if [ -z "$${entrypoint:-}" ]; \
		then echo ""; else echo "--entrypoint $${entrypoint:-}"; fi))
	@$$(eval export base:=docker compose -f ${compose_file} \
		run --rm --quiet-pull \
		--env COMPOSE_MK=1 \
		--env COMPOSE_MK_DEBUG=$${COMPOSE_MK_DEBUG} \
		$${pipe} $${entrypoint} $${svc_name} $${cmd})
	@$$(eval export stdin_tempf:=$$(shell mktemp))
	@$$(eval export entrypoint_display:=${cyan}[${no_ansi}${bold}$(shell \
			if [ -z "$${entrypoint:-}" ]; \
			then echo "default${no_ansi} entrypoint"; else echo "$${entrypoint:-}"; fi)${no_ansi_dim}${cyan}]${no_ansi})
	@$$(eval export cmd_disp:=${no_ansi_dim}${ital}`[ -z "$${cmd}" ] && echo " " || echo " $${cmd}\n"`${no_ansi})
	@trap "rm -f $${stdin_tempf}" EXIT \
	&& if [ -z "$${pipe}" ]; then \
		([ $${COMPOSE_MK_DEBUG} == 1 ] && printf "$${header}${dim}$${nsdisp} ${no_ansi_dim}$${entrypoint_display}$${cmd_disp}${green_flow_left}  ${cyan}<${no_ansi}${bold}interactive${no_ansi}${cyan}>${no_ansi}${dim_ital}`cat $${stdin_tempf} | sed 's/^[\\t[:space:]]*//'| sed -e 's/COMPOSE_MK=[01] //'`${no_ansi}\n" > ${stderr} || true) \
		&& ([ $${COMPOSE_MK_TRACE} == 1 ] && printf "${dim}$${base}${no_ansi}\n">${stderr} || true ) \
		&& eval $${base}  2\> \>\(\
                 grep -vE \'.\*Container.\*\(Running\|Recreate\|Created\|Starting\|Started\)\' \>\&2\ \
                 \| grep -vE \'.\*Network.\*\(Creating\|Created\)\' \>\&2\ \
                 \) ; \
	else \
		cat /dev/stdin > $${stdin_tempf} \
		&& ([ $${COMPOSE_MK_DEBUG} == 1 ] && printf "$${header}${dim}$${nsdisp} ${no_ansi_dim}$${entrypoint_display}$${cmd_disp}${cyan_flow_left}  ${dim_ital}`cat $${stdin_tempf} | sed 's/^[\\t[:space:]]*//'| sed -e 's/COMPOSE_MK=[01] //'`${no_ansi}\n" > ${stderr} || true) \
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
	export tmpf=$$(TMPDIR=`pwd` mktemp) && trap "rm -f $${tmpf}" EXIT
endef


## END macros
## BEGIN macros
stderr_devnull:=2>${devnull}
# Define 'help' target iff it's not already defined.  This should be inlined 
# for all files that want to be simultaneously usable in stand-alone 
# mode + library mode (with 'include')
_help_id:=$(shell (uuidgen ${stderr_devnull} || cat /proc/sys/kernel/random/uuid 2>${devnull} || date +%s) | head -c 8 | tail -c 8)
define _help_gen
(LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : ${stderr_devnull} | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$' || true)
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
# Generated by compose.mk, for ${fname}.
#
# Do not edit by hand and do not commit to version control.
# It's left just for reference & transparency, and is regenerated
# on demand, so you can feel free to delete it.
#
SHELL := bash
.SHELLFLAGS?=-euo pipefail -c
include ${COMPOSE_MK_SRC}
\$(eval \$(call compose.import, ▰, TRUE, ${TUI_COMPOSE_FILE}))
\$(eval \$(call compose.import, ▰, TRUE, ${fname}))
EOF
endef
export TUI_TMUXP_PROFILE_DATA = $(value _TUI_TMUXP_PROFILE)

## END macros
## BEGIN special targets (only available in stand-alone mode)
ifeq ($(COMPOSE_MK_STANDALONE),1)
export LOADF = $(value _loadf)
loadf: 
	@# Loads the given file, 
	@# then curries the rest of the CLI arguments to the resulting environment
	@# FIXME: this is linux-only due to usage of COMPOSE_MK_CLI
	@#
	@# USAGE:
	@#  make compose.loadf <compose_file> ...
	@#
	true \
	&& words=`echo "$${COMPOSE_MK_CLI#*loadf}"` \
	&& fname=`printf "$${words}" | sed 's/ /\n/g' | tail -n +2|head -1` \
	&& words=`printf "$${words}" | sed 's/ /\n/g' | tail -n +3` \
	&& make gum.style text="Loading $${fname}.." \
	&& header="${GLYPH_IO} loadf${no_ansi_dim} ${sep} ${green}${underline}$${fname}${no_ansi} ${sep} ${dim}$${words:-(No commands given.  Defaulting to opening UI..)}${no_ansi}" \
	&& printf "$${header} ${dim_green} ${*} ${no_ansi}\n" >${stderr} \
	&& ls $${fname} > ${devnull} || (printf "No such file"; exit 1) \
	&& tmpf=.tmp.mk \
	&& stem=`${make} compose.get.stem/$${fname}` \
	&& ${make} io.file.preview/$${fname} 2>&1 | make stream.indent \
	&& eval "$${LOADF}" > $${tmpf} \
	&& ${make} io.file.preview/$${tmpf} 2>&1 | make stream.indent \
	&& ( \
		printf "$${header} $${tmpf} ${sep} ${dim} Validating services..${no_ansi}\n" \
		&& make -f $${tmpf} $${stem}.services ) | make stream.indent.to.stderr \
	&& first=`make -f $${tmpf} $${stem}.services \
		| head -5 | xargs -I% printf "% " \
		| sed 's/ /,/g' | sed 's/,$$//'` \
	&& printf "$${header} $${tmpf} ${sep} ${dim} Derived pane targets: $${first}${no_ansi}\n" | make stream.indent.to.stderr \
	&& make gum.style text="Starting TUI" \
	&& set -x \
	&& make -f $${tmpf} $${words:-tux.ui/$${first}}
	$(call _make.interrupt)
endif 