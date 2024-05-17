##
# Project Automation
# Typical usage: `make clean build test`
##
SHELL := bash
MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -euo pipefail -c
THIS_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))
THIS_MAKEFILE := `python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${THIS_MAKEFILE}`

export SRC_ROOT := $(shell git rev-parse --show-toplevel)
export PROJECT_ROOT := $(shell dirname ${THIS_MAKEFILE})

export FAKE_KUBECONF:=/tmp/fake-kubeconf.conf
export KUBECONFIG?=${FAKE_KUBECONF}
_:=$(shell touch ${KUBECONFIG})
export DOCKER_UID:=$(shell id -u)
export DOCKER_GID:=$(shell getent group docker | cut -d: -f3 || id -g)
export DOCKER_UGNAME:=user

export KN_CLI_VERSION?=v1.14.0
export HELMIFY_CLI_VERSION?=v0.4.12
#export K3D_VERSION?=v5.6.3
export K3D_VERSION?=v5.5.0

# Creates dynamic targets
include Makefile.k8s.mk
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, ${PROJECT_ROOT}/docker-compose.yml))

bash: compose.bash

init: docker.init

build: docker-compose/__build__

clean: docker-compose/__clean__

docs:
	pynchon jinja render README.md.j2 \
	&& pynchon markdown preview README.md

vhs:
	rm -f img/*.gif 
	ls img/*.tape | xargs -n1 -I% bash -x -c "vhs %"
	firefox img/*gif

test: itest stest
stest:
	@# Smoke test the containers we built
	docker compose run fission --help \
	&& docker compose run helmify --version \
	&& docker compose run kn --help \
	&& docker compose run k9s version \
	&& docker compose run kubectl --help \
	&& docker compose run kompose version \
	&& docker compose run k3d --help \
	&& docker compose run helm --help \
	&& docker compose run argo --help \
	&& docker compose run kubefwd --help

itest:
	bash -x -c "cd tests && bash ./bootstrap.sh && cp -fv Makefile.itest.mk Makefile && make -s test"
etest:
	bash -x -c "cd tests && bash ./bootstrap.sh && cp -fv Makefile.etest.mk Makefile && make -s e2e"