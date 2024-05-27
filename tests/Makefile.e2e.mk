##
# k8s-tools.git End-to-end tests, 
# exercising Makefile.compose.mk, Makefile.k8s.mk, 
# plus the k8s-tools.yml services to create & interact 
# with a small k3d cluster.
##
SHELL := bash
MAKEFLAGS += -s --warn-undefined-variables
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL :=  all 

# Override k8s-tools.yml service-defaults, 
# explicitly setting the k3d version used
export K3D_VERSION:=v5.6.3
export KREW_PLUGINS:=sick-pods

# Cluster details that will be used by k3d.
export CLUSTER_NAME:=k8s-tools-e2e
export KUBECONFIG:=./fake.profile.yaml

# Chart & Pod details that we'll use later during provision
export HELM_REPO:=https://helm.github.io/examples
export HELM_CHART:=examples/hello-world
export POD_NAME:=test-harness
export POD_NAMESPACE:=default

# Include and invoke the `compose.import` macro 
# so we have targets for k8s-tools.yml services
include Makefile.k8s.mk
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))

# Default target should do everything, end to end.
all: k8s-tools/__build__ clean init provision test

###############################################################################

# Top level public targets for cluster operations.
# These run private subtargets inside the named 
# tool containers (like `k3d` or `helm`).
clean: ▰/k3d/self.cluster.clean
init: ▰/k3d/self.cluster.init

# Private targets for low-level cluster-ops.
# Host has no `k3d` command, so these targets
# run inside the `k3d` service from k8s-tools.yml
self.cluster.init:
	set -x \
	&& k3d --version \
	&& k3d cluster list | grep $${CLUSTER_NAME} \
	|| k3d cluster create $${CLUSTER_NAME} \
		--servers 3 --agents 3 \
		--api-port 6551 --port '8080:80@loadbalancer' \
		--volume $$(pwd)/:/$${CLUSTER_NAME}@all --wait
self.cluster.clean:
	set -x && k3d cluster delete $${CLUSTER_NAME}

###############################################################################

# You can expand this to include usage of `kustomize`, etc.
# Volumes are already setup, so you can `kubectl appply` from the filesystem.
provision: provision.helm provision.test_harness 
provision.helm:	▰/helm/self.cluster.provision_helm_example compose.wait/5
provision.test_harness: ▰/k8s/self.test_harness.provision
self.cluster.provision_helm_example: 
	@# Idempotent version of a helm install
	helm repo list 2>/dev/null | grep examples \
		|| helm repo add examples ${HELM_REPO}
	helm list | grep hello-world \
		|| helm install ahoy ${HELM_CHART}

self.test_harness.provision: \
	k8s.kubens.create/${POD_NAMESPACE} \
	k8s.test_pod_in_namespace/${POD_NAMESPACE}/${POD_NAME}/alpine/k8s
	@# Prerequisites above create & activate the `default` namespace 
	@# and then launch a pod named `test-harness` into it, using the 
	@# image 'alpine/k8s:1.30.0'.
	@#
	@# Below, we'll provision a simple nginx service into the default namespace.
	kubectl apply -f nginx.svc.yml
	make k8s.namespace.wait/default 

###############################################################################

test: test.cluster test.contexts 

test.cluster: ▰/k8s/k8s.namespace.wait/all ▰/k8s/k8s.stat
	@# Waits for anything in the default namespace to finish and show cluster info

test.contexts: get.host.ctx get.compose.ctx get.pod.ctx 
	@# Helpers for displaying platform info 

get.host.ctx:
	@# Runs on the docker host
	echo -n; set -x; uname -n
	printf "\n\n"

get.compose.ctx:
	@# Runs on the container defined by compose service
	echo uname -n | make k8s-tools/k8s/shell/pipe

get.pod.ctx:
	@# Runs inside the kubernetes cluster
	echo uname -n | make k8s.shell/default/test-harness/pipe

###############################################################################

cluster.shell: k8s.shell/${POD_NAMESPACE}/${POD_NAME}
	@# Interactive shell for the test-harness pod 
	@# (See also'provision' steps for the setup of same)

cluster.show: k8s.commander
	@# TUI for browsing the cluster 

