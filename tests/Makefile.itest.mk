##
# k8s-tools.git integration tests, 
# exercising compose.mk plus the compose file
#   
#
# Usage: 
#
#   # from project root
#   $ make etest
##
SHELL := bash
MAKEFLAGS=-s -S --warn-undefined-variables
.SHELLFLAGS := -eu -c

export KUBECONFIG:=./fake.profile.yaml
export _:=$(shell umask 066;touch ${KUBECONFIG})


# testing the compose integration
include compose.mk

# Load 1 compose file, *not* into the root namespace.
$(eval $(call compose.import, ▰, FALSE, cm-tools.yml))

# Load all services from two files into 1 namespace.
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))
$(eval $(call compose.import, ▰, FALSE, k8s-tools.yml))

.DEFAULT_GOAL := all 
all: docker-compose.qbuild #k8s-tools.qbuild/k8s k8s-tools.qbuild/k3d
	printf '\n' && set -x \
	&& make demo demo-double-dispatch \
	&& make test.docker.run \
		test.containerized.tty.output \
		test.flux.lib test.dispatch \
		test.compose.pipes \
	&& make test.compose.services \
		test.import.root \
		test.main.bridge \
		test.multiple.compose.files

# New target declaration that we can use to run stuff
# inside the `debian` container.  The syntax conventions
# are configured by the `compose.import` call we used above.
demo: ▰/debian/self.demo

# Displays platform info to show where target is running.
# Since this target is intended to be private, we will 
# prefix "self" to indicate it should not run on host.
self.demo:
	. /etc/os-release && printf "$${PRETTY_NAME}\n"
	uname -n -v
demo-double-dispatch: ▰/debian/self.demo ▰/alpine/self.demo

test.containerized.tty.output: 
	cmd='sleep 2' \
	label='testing gum spinner inside container' \
	make gum.spin

test.import.root:
	make io.print.div label="${bold_cyan}${@}${no_ansi}"
	printf "\n${dim_cyan}Test import-to-root argument for compose.import${no_color}\n"
	# test that the 4th argument for
	# import-to-root-namespace is honored
	! echo uname | make ansible/pipe 2>/dev/null
	echo uname | make cm-tools/ansible/pipe 2>/dev/null
	echo uname | make k8s-tools/k3d/shell/pipe

test.main.bridge:
	make io.print.div label="${cyan}${@}${no_ansi}"
	printf "\n${dim_cyan}Test service enumeration\nTarget @ <compose_file>.services ${no_color}\n"
	make k8s-tools.services
	printf "\n${dim_cyan}Test detection\nTarget @ <compose_file>/get_shell ${no_color}\n"
	make k8s-tools/k8s/get_shell

test.multiple.compose.files:
	make io.print.div label="${cyan}${@}${no_ansi}"
	printf "\n${dim_cyan}Test services enumeration, 2nd file\nTarget @ <compose_file>/<svc>.services ${no_color}\n"
	make docker-compose.services
	printf "\n${dim_cyan}Test Streaming commands, 2nd file\nTarget @ <compose_file>/<svc>/pipe ${no_color}\n"
	echo uname -n -v | make docker-compose/debian/pipe \

test.compose.pipes:
	make io.print.div label="${cyan}${@}${no_ansi}"
	printf "\n${dim_cyan}Streaming commands to container\nTarget @ <svc>/shell/pipe ${no_color}\n"
	echo uname -n -v | make k8s-tools/k8s/shell/pipe
	printf "\n${dim_cyan}Test streaming commands to container\nTarget @ <compose_file_stem><svc>/shell/pipe ${no_color}\n"
	echo uname -n -v | make k8s-tools/k8s/shell/pipe
	printf "\n${dim_cyan}Test streaming data to container\nTarget @ <svc>/shell/pipe ${no_color}\n"
	echo 'foo: bar' | make k8s-tools/yq/pipe
	set -x && echo '{"foo":"bar"}' | cmd='.foo' make k8s-tools/jq/pipe

test.compose.services:
	make io.print.div label="${cyan}${@}${no_ansi}"
	printf "\n${dim_cyan}Test main entrypoints\nTarget @ <compose_file>/<svc> ${no_color}\n"
	make k8s-tools/helm > /dev/null
	make k8s-tools/kubectl > /dev/null
	make k8s-tools/k3d cmd='--version'

test.dispatch:
	make io.print.div label="${cyan}${@}${no_ansi}"
	printf "\n${dim_cyan}Dispatch using private base target:${no_color}\n"
	echo uname | pipe=yes make ▰/debian
	printf "\n${dim_cyan}Dispatch using debian container:${no_color}\n"
	make ▰/debian/self.container.dispatch
	printf "\n${dim_cyan}Dispatch using alpine container:${no_color}\n"
	make ▰/alpine/self.container.dispatch
self.container.dispatch:
	printf "in container `hostname`, platform info: `uname`\n"

test.flux.lib: 
	make io.print.div label="${cyan}${@}${no_ansi}"
	set -x && make test.flux.finally test.flux.mux test.flux.dmux test.flux.loop

test.flux.finally:
	# demo of using finally/always functionality in a pipeline.  touches a tmpfile 
	# somewhere in the middle of a failing pipeline without getting to the cleanup 
	# task, and it should be cleaned up anyway.
	bash -i -c "(make \
		flux.finally/.file.cleanup \
		.file.touch flux.fail file-cleanup || true)"
	# NB: cannot assert this from here because cleanup only runs when the *test process* exits
	# ! ls .tmp.test.flux.finally	
.file.touch:
	touch .tmp.test.flux.finally

.file.cleanup:
	rm .tmp.test.flux.finally

test.flux.loop:
	make k8s-tools.dispatch/k8s/flux.loop/2/io.time.wait

test.flux.dmux:
	echo {} | make flux.dmux/k8s-tools/yq,k8s-tools/jq
	echo {} | make flux.split/k8s-tools/yq,k8s-tools/jq

test.flux.retry:
	! interval=1 make flux.retry/3/flux.fail

test.flux.apply:
	make flux.apply.later/2/io.time.wait/1

test.flux.mux:
	make flux.mux targets="io.time.wait,io.time.wait,io.time.wait/2" | jq .
	make flux.join targets="io.time.wait,io.time.wait,io.time.wait/2" | jq .
	make flux.mux/io.time.wait

test.docker.run:
	make docker.run/python:3.11-bookworm/flux.ok
	echo hello-python-docker1 | make test.docker.run.script
	echo hello-python-docker2 | entrypoint=cat cmd=/dev/stdin make docker.run.sh/python:3.11-slim-bookworm
	entrypoint=python cmd='--version' make docker.run.sh/python:3.11-slim-bookworm

test.docker.run.script:; entrypoint=python make docker.run.script/${@}/python:3.11-slim-bookworm
define script.demo.docker.run.script 
# python script 
import sys
print(['input',sys.stdin.read().strip()])
endef
