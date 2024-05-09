##
# Makefile.compose.mk
#
# This is designed to be used as an `include` inside your projects main Makefile.
#
#	Add this to project Makefile:
#
#     include Makefile.compose.mk
#     $(eval $(call compose.import, ▰, ↪, docker-compose.yml))
#
#   Usage (from CLI):
#     # drop into debugging shell for the container
#     make <path_to_compose_file>/<name_of_compose_service>/shell
#     # stream data into container
#     make <path_to_compose_file>/<name_of_compose_service>/shell
# 
##
export COLOR_GREEN:=\033[92m
export NO_COLOR:=\033[0m
export COLOR_DIM:=\033[2m
export COMPOSE_IGNORE_ORPHANS:=True
#####################################################################
define compose.get_services
    $(shell cat ${1} | python -c 'import yaml, sys; data=yaml.safe_load(sys.stdin.read()); svc=data["services"].keys(); print(" ".join(svc))')
endef

define compose.log 
	$(shell printf "${1}\n" > /dev/stderr)
endef
define compose.root_target 

endef
define compose.create_make_targets
$(eval compose_service_name := $1)
$(eval target_namespace := $2)
$(eval dispatch_prefix := $3)
$(eval import_to_root := $(strip $4))
$(eval compose_file := $(strip $5))
$(eval namespaced_service:=${target_namespace}/$(compose_service_name))
$(eval relf:=$(shell basename -s .yml $(compose_file)))

${relf}/$(compose_service_name)/shell:
	entrypoint=bash \
		make ${relf}/$$(shell python -c"print('$$@'.split('/')[1:][0])" )
${relf}/$(compose_service_name)/shell/pipe:
	pipe=yes 
		make ${relf}/$$(shell python -c"print('$$@'.split('/')[1:][0])" )/shell

${relf}/$(compose_service_name)/pipe: 
	cat /dev/stdin | make ⟂/${relf}/$(compose_service_name)

$(eval ifeq ($$(import_to_root), TRUE)
$(compose_service_name): $(target_namespace)/$(compose_service_name)
$(compose_service_name)/pipe: ⟂/${relf}/$(compose_service_name)
$(compose_service_name)/shell: ${relf}/$(compose_service_name)/shell
$(compose_service_name)/shell/pipe: 
	cat /dev/stdin | pipe=yes make ${relf}/$(compose_service_name)/shell
endif)


${target_namespace}/$(compose_service_name):
	@# A namespaced target for each docker-compose service
	make ${relf}/$$(shell python -c"print('$$@'.split('/')[1:][0])")

${target_namespace}/$(compose_service_name)/%:
	@# A subtarget for each docker-compose service.
	@# This allows invocation of *another* make-target
	@# that runs inside the container
	@echo make ${dispatch_prefix}$$(shell python -c"print('/'.join('$$@'.split('/')[2:]))") | make ⟫/${relf}/$$(shell python -c"print('$$@'.split('/')[1:][0])")
endef

###################################################################

define compose.import
$(eval target_namespace:=$1)
$(eval dispatch_prefix:=$2)
$(eval import_to_root := $(if $(3), $(strip $(3)), FALSE))
$(eval compose_file:=$(strip $4))

$(eval relf:=$(shell basename -s .yml $(strip $4)))


$(eval __services__:=$(call compose.get_services, ${compose_file}))

⟫/${relf}/%:
	@entrypoint=bash make ⟂/${relf}/$${*}

⟂/${relf}/%:
	@pipe=yes make ${relf}/$${*}

${relf}/__services__:
	@echo $(__services__)

${relf}/%:
	@$$(eval export svc_name:=$$(shell python -c"print('$$@'.split('/')[1:][0])"))
	@$$(eval export cmd:=$(shell echo $${cmd:-}))
	@$$(eval export pipe:=$(shell if [ -z "$${pipe:-}" ]; then echo ""; else echo "-T"; fi))
	@$$(eval export entrypoint:=$(shell if [ -z "$${entrypoint:-}" ]; then echo ""; else echo "--entrypoint $${entrypoint}"; fi))
	@$$(eval export base:=docker compose -f ${compose_file} run $${pipe} $${entrypoint} $${svc_name} $${cmd})
	@if [ -z "$${pipe}" ]; then \
		eval $${base} ; \
	else \
		cat /dev/stdin > .tmp.stdin \
		&& (printf "$${COLOR_GREEN}→ ($${svc_name}) $${COLOR_DIM}\n`cat .tmp.stdin`\n$${NO_COLOR}" >&2)  \
		&& cat .tmp.stdin | eval $${base} \
	; fi
$(foreach \
 	compose_service_name, \
 	$(__services__), \
	$(eval \
		$(call compose.create_make_targets, \
			$${compose_service_name}, \
			${target_namespace}, ${dispatch_prefix}, \
			${import_to_root}, ${compose_file}, )))
endef

#####################################################################

compose/build:
	docker compose build

compose/clean:
	docker compose down --remove-orphans

docker/init:
	@# Check if docker is available, no real setup
	@docker --version

docker/panic:
	@# Careful, this is potentially devastating in production..
	docker rm -f $$(docker ps -qa | tr '\n' ' ')
	docker network prune -f
	docker volume prune -f
	docker system prune -a -f

#####################################################################

help:
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$' || true

delay/%:
	sleep ${*}

create/namespace: assert-namespace
	kubectl create namespace $${namespace} \
		--dry-run=client -o yaml \
	| kubectl apply -f -
