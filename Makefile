##
# Project Automation
# Typical usage: `make clean build test`
##
SHELL := bash
MAKEFLAGS += -s --warn-undefined-variables
.SHELLFLAGS?=-euo pipefail -c
THIS_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))
THIS_MAKEFILE := `python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${THIS_MAKEFILE}`

export SRC_ROOT := $(shell git rev-parse --show-toplevel)
export PROJECT_ROOT := $(shell dirname ${THIS_MAKEFILE})

export FAKE_KUBECONF:=/tmp/fake-kubeconf.conf
export KUBECONFIG?=${FAKE_KUBECONF}
_:=$(shell touch ${KUBECONFIG})


export KN_CLI_VERSION?=v1.14.0
export HELMIFY_CLI_VERSION?=v0.4.12
export K3D_VERSION?=v5.6.3

# Creates dynamic targets
include Makefile.k8s.mk
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, ${PROJECT_ROOT}/k8s-tools.yml))

.DEFAULT_GOAL :=  all 
all: clean build test docs

bash: compose.bash

init: docker.init

# NB: only used during development; normal usage involves build-on-demand 
clean: k8s-tools/__clean__
build: k8s-tools/__build__
test: integration-test smoke-test e2e-test
.PHONY: docs
docs:
	@# Render docs twice to use includes, then get the ToC 
	set -x && pynchon jinja render README.md.j2 \
	&& pynchon jinja render README.md -o .tmp.R.md && mv .tmp.R.md README.md \
	&& pynchon markdown preview README.md

# NB: `vhs.*` targets are for docs/img generation, using terminal-recording
vhs: vhs.e2e vhs.demo
vhs.demo:
	rm -f img/demo-*.gif
	pushd tests \
		&& bash ./bootstrap.sh && cp Makefile.itest.mk Makefile \
		&& ls ../docs/tape/demo*.tape \
		| xargs -I% -n1 sh -x -c "vhs %" \
		&& mv img/* ../img
vhs.e2e:
	@# NB: order matters here
	rm -f img/e2e-*.gif
	pushd tests \
		&& bash ./bootstrap.sh && cp Makefile.e2e.mk Makefile \
		&& ls ../docs/tape/e2e*.tape \
		| xargs -I% -n1 sh -x -c "vhs %" \
		&& mv img/* ../img

smoke-test:
	make compose.divider label="${@}"
	@# Smoke test the containers we built
	bash -x -c "docker compose -f k8s-tools.yml run fission --help \
	&& docker compose -f k8s-tools.yml run helmify --version \
	&& docker compose -f k8s-tools.yml run kn --help \
	&& docker compose -f k8s-tools.yml run k9s version \
	&& docker compose -f k8s-tools.yml run kubectl --help \
	&& docker compose -f k8s-tools.yml run kompose version \
	&& docker compose -f k8s-tools.yml run k3d --help \
	&& docker compose -f k8s-tools.yml run helm --help \
	&& docker compose -f k8s-tools.yml run argo --help \
	&& docker compose -f k8s-tools.yml run kubefwd --help" 2>&1 >/dev/null
stest: smoke-test 

integration-test:
	cd tests && bash ./bootstrap.sh\
	 && cp Makefile.itest.mk Makefile && make
itest: integration-test

e2e-test:
	cd tests && bash -x ./bootstrap.sh \
	&& cp Makefile.e2e.mk Makefile && make
etest: e2e-test 

