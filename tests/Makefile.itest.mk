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
MAKEFLAGS += -s --warn-undefined-variables
.SHELLFLAGS := -eu -c

export KUBECONFIG:=./fake.profile.yaml
export _:=$(shell umask 066;touch ${KUBECONFIG})


# testing the compose integration
include compose.mk

# Load 1 compose file, *not* into the root namespace.
$(eval $(call compose.import, ▰, FALSE, cm-tools.yml))

# Load all services from two files into 1 namespace.
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))

.DEFAULT_GOAL := all 
all: 
	printf '\n' && set -x \
	&& make demo \
	&& make demo-double-dispatch \
	&& make test.containerized.tty.output \
	&& make \
		test.flux.lib test.dispatch \
		test.compose.pipes \
		test.compose.services \
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

test.containerized.tty.output: ▰/gum/self.test.containerized.tty.output
self.test.containerized.tty.output:
	@# some TUI elements require that docker compose run with -it but NOT -T
	@# this exercises those
	make io.print.divider label="${BOLD_CYAN}${@}${NO_ANSI}"
	env|grep GITHUB_ACTIONS && true || (\
		gum spin --title 'testing gum' -- sleep 2; \
		printf seq 100|spark \
	)

test.import.root:
	make io.print.divider label="${BOLD_CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Test import-to-root argument for compose.import${NO_COLOR}\n"
	# test that the 4th argument for
	# import-to-root-namespace is honored
	! echo uname | make ansible/pipe 2>/dev/null
	echo uname | make cm-tools/ansible/pipe 2>/dev/null
	echo uname | make k3d/shell/pipe

test.main.bridge:
	make io.print.divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Test service enumeration\nTarget @ <compose_file>.services ${NO_COLOR}\n"
	make k8s-tools.services
	printf "\n${DIM_CYAN}Test detection\nTarget @ <compose_file>/get_shell ${NO_COLOR}\n"
	make k8s-tools/k8s/get_shell

test.multiple.compose.files:
	make io.print.divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Test services enumeration, 2nd file\nTarget @ <compose_file>/<svc>.services ${NO_COLOR}\n"
	make docker-compose.services
	printf "\n${DIM_CYAN}Test Streaming commands, 2nd file\nTarget @ <compose_file>/<svc>/pipe ${NO_COLOR}\n"
	echo uname -n -v | make docker-compose/debian/pipe \

test.compose.pipes:
	make io.print.divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Streaming commands to container\nTarget @ <svc>/shell/pipe ${NO_COLOR}\n"
	echo uname -n -v | make k8s/shell/pipe
	printf "\n${DIM_CYAN}Test streaming commands to container\nTarget @ <compose_file_stem><svc>/shell/pipe ${NO_COLOR}\n"
	echo uname -n -v | make k8s-tools/k8s/shell/pipe
	printf "\n${DIM_CYAN}Test streaming data to container\nTarget @ <svc>/shell/pipe ${NO_COLOR}\n"
	echo 'foo: bar' | make k8s-tools/yq/pipe
	set -x && echo '{"foo":"bar"}' | cmd='.foo' make k8s-tools/jq/pipe

test.compose.services:
	make io.print.divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Test main entrypoints\nTarget @ <compose_file>/<svc> ${NO_COLOR}\n"
	make k8s-tools/helm > /dev/null
	make k8s-tools/kubectl > /dev/null
	make k8s-tools/k3d cmd='--version'

test.dispatch:
	make io.print.divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Dispatch using private base target:${NO_COLOR}\n"
	echo uname | pipe=yes make ▰/k8s
	printf "\n${DIM_CYAN}Dispatch using k8s container:${NO_COLOR}\n"
	make ▰/k8s/self.container.dispatch
	printf "\n${DIM_CYAN}Dispatch using k3d container:${NO_COLOR}\n"
	make ▰/k3d/self.container.dispatch
self.container.dispatch:
	printf "in container `hostname`, platform info: `uname`\n"

test.flux.lib: 
	make io.print.divider label="${CYAN}${@}${NO_ANSI}"
	set -x && make test.flux.finally test.flux.mux test.flux.dmux test.flux.loop

test.flux.finally:
	# demo of using finally/always functionality in a pipeline.  touches a tmpfile 
	# somewhere in the middle of a failing pipeline without getting to the cleanup 
	# task, and it should be cleaned up anyway.
	bash -i -c "(make \
		flux.finally/.file.cleanup \
		.file.touch flux.sh.fail file-cleanup || true)"
	# NB: cannot assert this from here because cleanup only runs when the *test process* exits
	# ! ls .tmp.test.flux.finally	
.file.touch:
	touch .tmp.test.flux.finally

.file.cleanup:
	rm .tmp.test.flux.finally

test.flux.loop:
	make k8s-tools.dispatch/k8s/flux.loop/2/io.time.wait

test.flux.dmux:
	echo {} | make flux.dmux/yq,jq
	echo {} | make flux.split/yq,jq

test.flux.retry:
	! interval=1 make flux.retry/3/flux.sh.fail

test.flux.apply:
	make flux.apply.later/2/io.time.wait/1

test.flux.mux:
	make flux.mux targets="io.time.wait,io.time.wait,io.time.wait/2" | jq .
	make flux.join targets="io.time.wait,io.time.wait,io.time.wait/2" | jq .
	make flux.mux/io.time.wait
