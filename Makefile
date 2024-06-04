#!/usr/bin/env -S make -s -f 
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

export KUBECONFIG?=./fake.profile.yaml
export _:=$(shell umask 066;touch ${KUBECONFIG})

export KN_CLI_VERSION?=v1.14.0
export HELMIFY_CLI_VERSION?=v0.4.12
export K3D_VERSION?=v5.6.3

# Creates dynamic targets
include k8s.mk
include compose.mk
$(eval $(call compose.import, ▰, TRUE, ${PROJECT_ROOT}/k8s-tools.yml))

.PHONY: docs
.DEFAULT_GOAL :=  all 
# default entrypoint
all: init clean build test docs
	@# Default entrypoint


# cache-busting / debugging entrypoints
# (only used during development; normal usage involves build-on-demand )
clean: k8s-tools.clean
	rm -f tests/compose.mk tests/k8s.mk
build: k8s-tools.build
shell: io.bash
init: docker.stat

# testing entrypoints
test: integration-test smoke-test e2e-test
	@# Runs all test-suites.
etest: e2e-test 
itest: integration-test
stest: smoke-test 
smoke-test:
	@# Smoke-test suite, exercising the containers we built.
	@# This just covers the compose file at k8s-tools.yml, ignoring Makefile integration
	$(call gum.style.target)
	cd tests && bash ./bootstrap.sh \
	 && cp Makefile.stest.mk Makefile && make
integration-test:
	@# Integration-test suite.  This tests compose.mk and ignores k8s-tools.yml.
	@# Exercises container dispatch and the make/compose bridge.  No kubernetes.
	$(call gum.style.target)
	cd tests && bash ./bootstrap.sh\
	 && cp Makefile.itest.mk Makefile && make
e2e-test:
	@# End-to-end tests.  This tests k8s.mk + compose.mk + k8s-tools.yml
	@# by walking through cluster-lifecycle stuff inside a 
	@# project-local kubernetes cluster.
	$(call gum.style.target)
	cd tests && bash -x ./bootstrap.sh \
	&& cp Makefile.e2e.mk Makefile && make

docs: docs.jinja docs.mermaid
	@# Builds all the docs
docs.jinja:
	@# Render docs twice to use includes, then get the ToC 
	set -x && pynchon jinja render README.md.j2 \
	&& pynchon jinja render README.md -o .tmp.R.md && mv .tmp.R.md README.md \
	&& pynchon markdown preview README.md
docs.mermaid:
	pynchon mermaid apply
docs.mmd: docs.mermaid

vhs: vhs.e2e vhs.demo
	@# Uses charmbracelete/vhs to record console videos of the test suites 
vhs.demo:
	@# Videos of the integration test suite.
	@# (Order matters here)
	rm -f img/demo-*.gif
	pushd tests \
		&& bash ./bootstrap.sh && cp Makefile.itest.mk Makefile \
		&& ls ../docs/tape/demo*.tape \
		| xargs -I% -n1 sh -x -c "vhs %" \
		&& mv img/* ../img
vhs.e2e:
	@# Videos of the e2e test suite.
	@# (Order matters here)
	rm -f img/e2e-*.gif
	pushd tests \
		&& bash ./bootstrap.sh && cp Makefile.e2e.mk Makefile \
		&& ls ../docs/tape/e2e*.tape \
		| xargs -I% -n1 sh -x -c "vhs %" \
		&& mv img/* ../img

# Define 'help' target iff it's not already defined.  This should be inlined for all files 
# that want to be simultaneously usable in stand-alone mode + library mode (with 'include')
ifeq ($(MAKELEVEL), 0)
_help_id:=$(shell uuidgen | head -c 8 || date +%s | tail -c 8)
_help_${_help_id}:
	@# Attempts to autodetect the targets defined in this Makefile context.  
	@# Older versions of make dont have '--print-targets', so this uses the 'print database' feature.
	@# See also: https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
	@#
	@LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$' || true
$(eval help: _help_${_help_id})
endif

