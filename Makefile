##
# Project Automation
# Typical usage: `make clean build test`
##
SHELL := bash
MAKEFLAGS += --warn-undefined-variables
.SHELLFLAGS := -euxo pipefail -c
THIS_MAKEFILE := $(abspath $(firstword $(MAKEFILE_LIST)))
THIS_MAKEFILE := `python -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' ${THIS_MAKEFILE}`

SRC_ROOT := $(shell git rev-parse --show-toplevel)
PROJECT_ROOT := $(shell dirname ${THIS_MAKEFILE})
export SRC_ROOT PROJECT_ROOT
export FAKE_KUBECONF:=/tmp/fake-kubeconf.conf
init:
	# check if docker is available 
	docker --version
	# we need this even to build if nothing else is set
	touch $${FAKE_KUBECONF}

build: 
	KUBECONFIG=$${KUBECONFIG:-$${FAKE_KUBECONF}} \
		docker compose build 

test: 
	KUBECONFIG=$${FAKE_KUBECONF} bash -x -c "\
		docker compose run helm version \
		&& docker compose run k9s version \
		&& docker compose run kubectl --help \
		&& docker compose run kompose version \
		&& docker compose run k3d version"
	
clean:
	KUBECONFIG=$${KUBECONFIG:-$${FAKE_KUBECONF}} \
		docker compose down --remove-orphans

shell:
	KUBECONFIG=$${KUBECONFIG:-$${FAKE_KUBECONF}} \
		docker compose run shell

# send the make var to a bash var, 
# we need this for the substring magic later
export MAKECMDGOALS

k8s/%:
	docker compose -f docker-compose.yml run ${*}  $${MAKECMDGOALS#*k8s/${*}}

%:
	@# NOOP catch all