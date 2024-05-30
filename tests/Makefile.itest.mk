##
# k8s-tools.git integration tests, 
# exercising Makefile.compose.mk plus the compose file
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
include Makefile.compose.mk

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
	&& make \
		test-compose-pipes \
		test-compose-services \
		test-import-root \
		test-main-compose-file \
		test-multiple-compose-files \

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

print_divider: io.print_divider
test-import-root:
	make print_divider label="${BOLD_CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Test import-to-root argument for compose.import${NO_COLOR}\n"
	# test that the 4th argument for
	# import-to-root-namespace is honored
	! echo uname | make ansible/pipe 2>/dev/null
	echo uname | make cm-tools/ansible/pipe 2>/dev/null
	echo uname | make k3d/shell/pipe

test-main-compose-file:
	make print_divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Test service enumeration\nTarget @ <compose_file>/__services__ ${NO_COLOR}\n"
	make k8s-tools/__services__
	printf "\n${DIM_CYAN}Test detection\nTarget @ <compose_file>/__shell__ ${NO_COLOR}\n"
	make k8s-tools/k8s/__shell__

test-multiple-compose-files:
	make print_divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Test services enumeration, 2nd file\nTarget @ <compose_file>/<svc>/__services__ ${NO_COLOR}\n"
	make docker-compose/__services__
	printf "\n${DIM_CYAN}Test Streaming commands, 2nd file\nTarget @ <compose_file>/<svc>/pipe ${NO_COLOR}\n"
	echo uname -n -v | make docker-compose/debian/pipe \

test-compose-pipes:
	make print_divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Streaming commands to container\nTarget @ <svc>/shell/pipe ${NO_COLOR}\n"
	echo uname -n -v | make k8s/shell/pipe
	printf "\n${DIM_CYAN}Test streaming commands to container\nTarget @ <compose_file_stem><svc>/shell/pipe ${NO_COLOR}\n"
	echo uname -n -v | make k8s-tools/k8s/shell/pipe
	printf "\n${DIM_CYAN}Test streaming data to container\nTarget @ <svc>/shell/pipe ${NO_COLOR}\n"
	echo 'foo: bar' | make k8s-tools/yq/pipe
	set -x && echo '{"foo":"bar"}' | cmd='.foo' make k8s-tools/jq/pipe

test-compose-services:
	make print_divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Test main entrypoints\nTarget @ <compose_file>/<svc> ${NO_COLOR}\n"
	make k8s-tools/helm > /dev/null
	make k8s-tools/kubectl > /dev/null
	make k8s-tools/k3d cmd='--version'

test-dispatch:
	make print_divider label="${CYAN}${@}${NO_ANSI}"
	printf "\n${DIM_CYAN}Dispatch using private base target:${NO_COLOR}\n"
	echo uname | pipe=yes make ▰/k8s
	printf "\n${DIM_CYAN}Dispatch using k8s container:${NO_COLOR}\n"
	make ▰/k8s/self.container.dispatch
	printf "\n${DIM_CYAN}Dispatch using k3d container:${NO_COLOR}\n"
	make ▰/k3d/self.container.dispatch
self.container.dispatch:
	printf "in container `hostname`, platform info: `uname`\n"
