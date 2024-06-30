##
# k8s-tools.git smoke-tests part 2:
#   exercise the special form for ./k8s.mk <svc> -- <cmd>
#
# USAGE: ( from project root )
#   $ make smoke-test
##


SHELL:=bash
.SHELLFLAGS:=-eu -c
MAKEFLAGS=-sS --warn-undefined-variables

export KUBECONFIG:=./fake.profile.yaml
export _:=$(shell umask 066;touch ${KUBECONFIG})

include k8s.mk
include compose.mk
$(eval $(call compose.import, ▰, FALSE, k8s-tools.yml))
.DEFAULT_GOAL=help

## Smoke-test suite covers basics stuff about k8s-tools.yml directly, ignoring Makefile libs
all: clean build smoke-test 
build: #tux.require
clean: #compose.clean/k8s-tools.yml 
test.help:
	./k8s.mk help|grep ansible.adhoc
	./k8s.mk mk.namespace.filter/io|grep io.bash
	./k8s.mk mk.namespace.list | grep ansible
	./k8s.mk help.namespaces|grep ansible 
	./k8s.mk help helm
	
test.ansible:
	# call the block-in-file module 
	./compose.mk jb path=.gitignore block=".flux.stage.*" | ./k8s.mk ansible.blockinfile
	# failure should fail 
	! make jb msg="failing as requested" | make ansible.adhoc/ansible.builtin.fail
	make jb msg="hello-world" | make ansible.adhoc/ansible.builtin.debug

test.pygmentize:
	./compose.mk stream.pygmentize/k8s-tools.yml
	cat k8s-tools.yml | ./compose.mk stream.pygmentize

smoke-test: test.pygmentize test.ansible
	set -x && ./k8s.mk tux.require \
		&& ./k8s.mk fission -- --help \
		&& ./k8s.mk helmify -- --version \
		&& ./k8s.mk kn -- --help \
		&& ./k8s.mk k9s -- version \
		&& ./k8s.mk kubectl -- version --client \
		&& ./k8s.mk kompose -- version \
		&& ./k8s.mk k3d --  --help \
		&& ./k8s.mk helm -- --help \
		&& ./k8s.mk promtool -- --version \
		&& ./k8s.mk argo -- --help \
		&& ./k8s.mk kind -- --version \
		&& ./k8s.mk rancher -- --version \
		&& ./k8s.mk kubefwd -- --help

#*/