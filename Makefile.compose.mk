##
# Makefile.compose.mk
#
# This is designed to be used as an `include` from your project's main Makefile.
#
# DOCS: https://github.com/elo-enterprises/k8s-tools#Makefile.compose.mk
#
# LATEST: https://github.com/elo-enterprises/k8s-tools/tree/master/Makefile.compose.mk
#
# USAGE: (Add this to your project Makefile)
#      include Makefile.compose.mk
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
export ANSI_GREEN?=\033[92m
export NO_ANSI?=\033[0m
export ANSI_DIM?=\033[2m
export ANSI_UNDERLINE?=\033[4m
export ANSI_BOLD?=\033[1m
export ANSI_RED?=\033[91m
export COMPOSE_IGNORE_ORPHANS?=True
export COMPOSE_MK?=0
export COMPOSE_MK_POLL_DELTA?=15

## END: data
########################################################################
## BEGIN: macros

# Macro to yank all the compose-services out of YAML.  
# This drops into python unfortunately and that's a significant dependency.  
# But bash or awk would be a nightmare, and even perl requires packages to be
# installed before it can parse YAML.  To work around this, the COMPOSE_MK 
# env-var is checked, so that inside containers `compose.get_services` always 
# returns nothing.
define compose.get_services
	$(shell if [ "${COMPOSE_MK}" = "0" ]; then cat ${1} | python3 -c 'import yaml, sys; data=yaml.safe_load(sys.stdin.read()); svc=data["services"].keys(); print(" ".join(svc))'; else echo -n ""; fi)
endef

# Macro to create all the targets for a given compose-service
define compose.create_make_targets
$(eval compose_service_name := $1)
$(eval target_namespace := $2)
$(eval import_to_root := $(strip $3))
$(eval compose_file := $(strip $4))
$(eval namespaced_service:=${target_namespace}/$(compose_service_name))
$(eval relf:=$(shell basename -s .yml $(compose_file)))

${relf}/$(compose_service_name)/shell:
	@export entrypoint=`docker compose -f $(compose_file) \
		run --entrypoint sh $$(shell echo $$@|awk -F/ '{print $$$$2}') \
		-c "which bash || which sh" \
		2>/dev/null \
		|| printf "$${ANSI_RED}Neither 'bash' nor 'sh' are available!\n(service=${compose_service_name} @ ${compose_file})\n$${NO_ANSI}" > /dev/stderr` \
	&& ( \
		( env|grep entrypoint\= &>/dev/null \
			|| exit 1 ) \
		&& make ${relf}/$(compose_service_name) \
	)

${relf}/$(compose_service_name)/shell/pipe:
	pipe=yes \
		make ${relf}/$(compose_service_name)/shell

${relf}/$(compose_service_name)/pipe:
	cat /dev/stdin | make ⟂/${relf}/$(compose_service_name)

$(eval ifeq ($$(import_to_root), TRUE)
$(compose_service_name): $(target_namespace)/$(compose_service_name)
$(compose_service_name)/pipe: ⟂/${relf}/$(compose_service_name)
$(compose_service_name)/shell: ${relf}/$(compose_service_name)/shell
$(compose_service_name)/shell/pipe: 
	cat /dev/stdin \
	| pipe=yes make ${relf}/$(compose_service_name)/shell
endif)

${target_namespace}/$(compose_service_name):
	@# A namespaced target for each docker-compose service
	make ${relf}/$$(shell echo $$@|awk -F/ '{print $$$$2}')

${target_namespace}/$(compose_service_name)/%:
	@# A subtarget for each docker-compose service.
	@# This allows invocation of *another* make-target
	@# that runs inside the container
	@echo COMPOSE_MK=1 make $${*} \
		| make ⟫/${relf}/$(compose_service_name)
endef

# Main macro to import services from an entire compose file
define compose.import
$(eval target_namespace:=$1)
$(eval import_to_root := $(if $(2), $(strip $(2)), FALSE))
$(eval compose_file:=$(strip $3))
$(eval relf:=$(shell basename -s .yml $(strip ${3})))
$(eval __services__:=$(call compose.get_services, ${compose_file}))

⟫/${relf}/%:
	@entrypoint=bash make ⟂/${relf}/$${*}

⟂/${relf}/%:
	@pipe=yes make ${relf}/$${*}

${relf}/__services__:
	@echo $(__services__)
${relf}/__build__:
	set -x && docker compose -f $${compose_file} build
${relf}/__stop__:
	docker compose -f $${compose_file} stop -t 1
${relf}/__up__:
	docker compose -f $${compose_file} up
${relf}/__clean__:
	set -x && docker compose -f $${compose_file} --progress quiet down -t 1 --remove-orphans

${relf}/%:
	@$$(eval export svc_name:=$$(shell echo $$@|awk -F/ '{print $$$$2}'))
	@$$(eval export cmd:=$(shell echo $${cmd:-}))
	@$$(eval export pipe:=$(shell if [ -z "$${pipe:-}" ]; then echo ""; else echo "-T"; fi))
	@$$(eval export entrypoint:=$(shell if [ -z "$${entrypoint:-}" ]; then echo ""; else echo "--entrypoint $${entrypoint}"; fi))
	@$$(eval export base:=docker compose -f ${compose_file} run --rm --quiet-pull --env HOME=/tmp --env COMPOSE_MK=1 $${pipe} $${entrypoint} $${svc_name} $${cmd} )
	@$$(eval export dispbase:=$$(shell echo $${base}|sed 's/\(.\{5\}\).*/\1.../'))
	@$$(eval export tmpf2:=$$(shell mktemp))
	@if [ -z "$${pipe}" ]; then \
		eval $${base} ; \
	else \
		cat /dev/stdin > $${tmpf2} \
		&& (printf "\
			$${ANSI_GREEN}⇒ ${NO_ANSI}${ANSI_DIM}container-dispatch ${ANSI_GREEN}$${svc_name}${NO_ANSI} \
			${ANSI_DIM}${ANSI_BOLD}@${NO_ANSI} ${ANSI_DIM}${ANSI_GREEN}$$(shell basename $${compose_file})${NO_ANSI} \
			\n${ANSI_BOLD}${ANSI_UNDERLINE}`cat $${tmpf2} | sed -e 's/COMPOSE_MK=[01]//'`\n$${NO_ANSI}" )  \
		&& trap "rm -f $${tmpf2}" EXIT \
		&& cat "$${tmpf2}" | eval $${base} \
	; fi
$(foreach \
 	compose_service_name, \
 	$(__services__), \
	$(eval \
		$(call compose.create_make_targets, \
			$${compose_service_name}, \
			${target_namespace}, ${import_to_root}, ${compose_file}, )))
endef

## END: macros
########################################################################
## BEGIN: meta targets (api-stable)

help:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$' || true


## END: meta targets
########################################################################
## BEGIN: convenience targets (api-stable)
compose.strip_ansi:
	@# Pipe-friendly helper for stripping ansi
	cat /dev/stdin | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g"'
compose.mktemp:
	export tmpf3=`mktemp` \
	&& trap "rm -f $${tmpf3}" EXIT \
	&& echo $${tmpf3}

compose.wait/%:
	printf "${ANSI_DIM}Waiting for ${*} seconds..${NO_ANSI}\n" > /dev/stderr \
	&& sleep ${*}
compose.indent:
	@#
	cat /dev/stdin | sed 's/^/  /'

compose.init:
	@# Ensure compose is available and build it
	docker compose version >/dev/null \
	&& make compose.build

compose.bash:
	@#
	env bash -l

docker.init:
	@# Check if docker is available, no real setup
	docker --version

docker.panic:
	@# Debugging only!  Running this from automation will 
	@# probably quickly hit rate-limiting at dockerhub,
	@# and obviously this is dangerous for production..
	docker rm -f $$(docker ps -qa | tr '\n' ' ')
	docker network prune -f
	docker volume prune -f
	docker system prune -a -f

# NB: looks empty, but don't edit this, it helps make to understand newline literals
define newline


endef