SHELL := bash
MAKEFLAGS += -s --warn-undefined-variables
.SHELLFLAGS := -euo pipefail -c

include Makefile.k8s.mk
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))

export DOCKER_UID:=$(shell id -u)
export DOCKER_GID:=$(shell getent group docker | cut -d: -f3 || id -g)
export DOCKER_UGNAME:=user
export KUBECONFIG:=./fake.profile.yaml
export CLUSTER_NAME:=e2e-test

e2e: \
	k8s-tools/__build__ \
	clean \
	init \
	provision \
	test

init: ▰/k3d/self.cluster.init
clean: ▰/k3d/self.cluster.clean
test: ▰/k3d/self.cluster.test cluster.test2
provision: ▰/kubectl/self.cluster.provision
self.cluster.init:
	@# Setup for the K3d cluster
	set -x \
	&& k3d --version \
	&& k3d cluster list > /dev/null \
	&& k3d cluster list | grep $${CLUSTER_NAME} \
	|| k3d cluster create $${CLUSTER_NAME} \
		--servers 3 --agents 5 \
		--api-port 6551 --port '8080:80@loadbalancer' \
		--volume $$(pwd)/:/$${CLUSTER_NAME}@all --wait

# Create a test-harness pod in the default namespace
# Create/activate default namespace
self.cluster.provision: \
	k8s.kubens.create/default \
	k8s.test_pod_in_namespace/default/test-harness

# Wait for anything in the default namespace to finish
# Send commands to the test-harness pod
self.cluster.test: k8s.namespace.wait/default
	kubectl cluster-info
cluster.test2:
	uname -a 
	echo uname -a | make k8s.shell/default/test-harness/pipe
	
self.cluster.clean:
	set -x && k3d cluster delete $${CLUSTER_NAME}