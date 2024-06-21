#!/usr/bin/env -S make -s -S -f 
##
# Project Automation
# Typical usage: `make clean build test`
##
SHELL := bash
.SHELLFLAGS?=-euo pipefail -c
MAKEFLAGS=-s -S --warn-undefined-variables
THIS_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))

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
all: init clean build test docs

build: k8s-tools.qbuild/k8s
	@# Development usage only.  This uses explicit ordering that is 
	@# required because compose 'depends_on' key affects the 
	@# ordering for 'docker compose up', but doesn't affect 
	@# ordering for 'docker compose build'.

# cache-busting / debugging entrypoints
# (only used during development; normal usage involves build-on-demand )
clean: k8s-tools.clean
	@# Removes temporary files used by build / tests 
	rm -f tests/compose.mk tests/k8s.mk tests/k8s-tools.yml

init: make.stat docker.stat

# shell:
# 	make gum.style text='Launching shell'
# 	make tux.ui/k8s,io.bash

# testing entrypoints
test: integration-test smoke-test tui-test e2e-test
	@# Runs all test-suites.

test-suite/%:
	@# Generic test-suite runner, just provide the test-suite name.
	@# (Names are taken from the files like "tests/Makefile.<name>.mk")
	$(call gum.style.target)
	cd tests && bash ./bootstrap.sh
	cp tests/Makefile.${*}.mk tests/Makefile
	env -i PATH=$${PATH} HOME=$${HOME} bash -x -c "cd tests && make ${MAKE_FLAGS}"

ttest: tui-test
etest: e2e-test 
mtest: test-suite/mad-science
itest: integration-test
stest: smoke-test 

tui-test: test-suite/tui 
	@# TUI test-suite, exercising the embedded 'compose.mk:tux'
	@# container and various ways to automate tmux.

smoke-test: test-suite/stest
	@# Smoke-test suite, exercising the containers we built.
	@# This just covers the compose file at k8s-tools.yml, ignoring Makefile integration

integration-test: test-suite/itest
	@# Integration-test suite.  This tests compose.mk and ignores k8s-tools.yml.
	@# Exercises container dispatch and the make/compose bridge.  No kubernetes.

e2e-test: test-suite/e2e
	@# End-to-end tests.  This tests k8s.mk + compose.mk + k8s-tools.yml
	@# by walking through cluster-lifecycle stuff inside a 
	@# project-local kubernetes cluster.

mad: test-suite/mad-science
	@# Polyglot tests.  These demonstrate some mad-science and other bad ideas 
	@# that allow make-targets to be written in real programming languages.

docs: docs.jinja docs.mermaid
	@# Builds all the docs

docs.jinja:
	@# Render docs twice to use includes, then get the ToC 
	set -x && pynchon jinja render docs/README.md.j2 \
	&& mv docs/README.md . \
	&& pynchon jinja render README.md -o .tmp.R.md && mv .tmp.R.md README.md \
	&& pynchon markdown preview README.md

docs.mermaid:; pynchon mermaid apply

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
vhs.tui:
	@# Videos for demos of the TUI
	rm -f img/tui-*.gif
	ls docs/tape/tui-*.tape \
	| xargs -I% -n1 sh -x -c "vhs %"

vhs.e2e:
	@# Videos of the e2e test suite.
	@# (Order matters here)
	rm -f img/e2e-*.gif
	pushd tests \
		&& bash ./bootstrap.sh && cp Makefile.e2e.mk Makefile \
		&& ls ../docs/tape/e2e*.tape \
		| xargs -I% -n1 sh -x -c "vhs %" \
		&& mv img/* ../img