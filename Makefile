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

# Creates dynamic targets
include Makefile.compose.mk
$(eval $(call compose.import, ▰, ↪, TRUE, ${PROJECT_ROOT}/docker-compose.yml))

bash: compose.bash
k9: k9s


init: docker.init
build: compose.build
clean: compose.clean
docs:
	pynchon jinja render README.md.j2

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
	bash -x -c "cd tests && bash ./bootstrap.sh && make -s test"
