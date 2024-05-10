SHELL := bash
MAKEFLAGS += --warn-undefined-variables -s
.SHELLFLAGS := -euo pipefail -c

export KUBECONFIG:=./fake.profile.yaml

# testing the compose integration
include Makefile.compose.mk

# load all services from two files into 1 namespace.
$(eval $(call compose.import, ▰, ↪, TRUE, k8s-tools.yml))
$(eval $(call compose.import, ▰, ↪, FALSE, docker-compose.yml))

demo: ▰/debian/demo
↪demo:
	uname -n -v
demo-double-dispatch: ▰/debian/demo ▰/alpine/demo

test: demo demo-double-dispatch
test: test-import-root test-main-compose-file
test: test-2nd-compose-file test-piped-commands test-services

test-import-root:
	printf "\n${@}\n" > /dev/stderr
	# test that the 4th argument for
	# import-to-root-namespace is honored
	! echo uname | make debian/pipe 2>/dev/null
	echo uname | make k3d/shell/pipe

test-main-compose-file:
	printf "\n${@}\n--------------------\n" > /dev/stderr
	make k8s-tools/__services__

test-2nd-compose-file:
	printf "\n${@}\n" > /dev/stderr
	make docker-compose/__services__
	echo uname -n -v | make docker-compose/debian/pipe
	echo uname -n -v | make docker-compose/debian/pipe

test-piped-commands:
	printf "\n${@}\n" > /dev/stderr
	echo uname -n -v | pipe=yes make k8s-tools/base/shell
	echo 'foo: bar' | make k8s-tools/yq/pipe
	echo '{"foo":"bar"}' | cmd='.foo' make k8s-tools/jq/pipe

test-services:
	printf "\n${@}\n" > /dev/stderr
	make k8s-tools/helm
	make k8s-tools/kubectl
	make k8s-tools/k3d

test-dispatch:
	printf "\n${@}\n" > /dev/stderr
	echo uname | pipe=yes make ▰/base
	make ▰/base/test/container-dispatch
	make ▰/k3d/test/container-dispatch
↪test/container-dispatch:
	echo ${KUBECONFIG} `uname`

test-demo:
	make demo
	make demo-double-dispatch
