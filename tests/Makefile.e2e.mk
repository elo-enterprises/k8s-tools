# k8s-tools.git End-to-end tests
# Exercising compose.mk, k8s.mk, plus the k8s-tools.yml services to create & interact  with a small k3d cluster.
SHELL := bash
MAKEFLAGS=-s -S --warn-undefined-variables
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL :=  all 

# Override k8s-tools.yml service-defaults, 
# explicitly setting the k3d version used
export K3D_VERSION:=v5.6.3
export KREW_PLUGINS:=graph

# Cluster details that will be used by k3d.
export CLUSTER_NAME:=k8s-tools-e2e

# Ensure KUBECONFIG exists
export KUBECONFIG:=./fake.profile.yaml
export _:=$(shell umask 066;touch ${KUBECONFIG})

# Chart & Pod details that we'll use later during deploy
export HELM_REPO:=https://helm.github.io/examples
export HELM_CHART:=examples/hello-world
export POD_NAME?=test-harness
export POD_NAMESPACE?=default

# Include and invoke the `compose.import` macro 
# so we have targets for k8s-tools.yml services
include k8s.mk
include compose.mk
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))
# Default target should do everything, end to end.
all: build cluster.clean cluster.create deploy test

###############################################################################

# Top level public targets for cluster operations & (optional) convenience aliases and stage-labels.

# These run private subtargets inside the named  tool containers (i.e. `k3d`).
clean cluster.clean: flux.stage/ClusterClean ▰/k3d/self.cluster.clean
cluster cluster.create: flux.stage/ClusterCreate ▰/k3d/self.cluster.create

# Plus a convenience alias to wait for all pods in all namespaces.
cluster.wait: k8s.cluster.wait

# Private targets for low-level cluster-ops.
# Host has no `k3d` command, so these targets
# run inside the `k3d` service from k8s-tools.yml
self.cluster.create:
	( k3d cluster list | grep $${CLUSTER_NAME} \
	  || k3d cluster create $${CLUSTER_NAME} \
			--servers 3 --agents 3 \
			--api-port 6551 --port '8080:80@loadbalancer' \
			--volume $$(pwd)/:/$${CLUSTER_NAME}@all --wait \
	)

self.cluster.clean:
	set -x && k3d cluster delete $${CLUSTER_NAME}

###############################################################################

# Top level public targets for deployments & (optional) convenience aliases and stage-labels.
# These run private subtargets inside the named  tool containers (i.e. `helm`, and `k8s`).

deploy: flux.stage/DeployApps deploy.helm deploy.test_harness 
deploy.helm: ▰/helm/self.cluster.deploy_helm_example io.time.wait/5
deploy.test_harness: ▰/k8s/self.test_harness.deploy

# Private targets with the low level details for what to do in tool containers. 
# You can expand this to include usage of `kustomize`, etc. Volumes are already setup,
# so you can `kubectl apply` from the filesystem.  You can also call anything documented 
# in the API[1] https://github.com/elo-enterprises/k8s-tools/tree/master/docs/api/#k8smk.
self.cluster.deploy_helm_example: 
	@# Idempotent version of a helm install
	@# Commands are inlined below, but see 'helm.repo.add' 
	@# and 'helm.chart.install' for built-in helpers.
	set -x \
	&& (helm repo list 2>/dev/null | grep examples || helm repo add examples ${HELM_REPO} ) \
	&& (helm list | grep hello-world || helm install ahoy ${HELM_CHART})

self.test_harness.deploy: k8s.kubens.create/${POD_NAMESPACE} k8s.test_harness/${POD_NAMESPACE}/${POD_NAME}
	@# Prerequisites above create & activate the `default` namespace 
	@# and then deploy a pod named `test-harness` into it, using a default image.
	@#
	@# Below, we'll deploy a simple nginx service into the default namespace.
	kubectl apply -f nginx.svc.yml

###############################################################################

test: test.cluster test.contexts 
test.cluster cluster.test: flux.stage/TestDeployment ▰/k8s/k8s.cluster.wait
	label="Showing kubernetes status" make gum.style 
	make k8s/dispatch/k8s.stat 
	label="Previewing topology for kube-system namespace" make gum.style 
	make k8s.graph.tui/kube-system/pod
	label="Previewing topology for default namespace" make gum.style 
	size=40x make k8s.graph.tui/default/pod

test.contexts: 
	@# Helpers for displaying platform info 
	label="Demo pod connectivity" make gum.style 
	make get.compose.ctx get.pod.ctx 

get.compose.ctx:
	@# Runs on the container defined by compose service
	echo uname -n | make k8s-tools/k8s/shell/pipe

get.pod.ctx:
	@# Runs inside the kubernetes cluster
	echo uname -n | make k8s.shell/default/test-harness/pipe

###############################################################################

cluster.shell: k8s.shell/${POD_NAMESPACE}/${POD_NAME}
	@# Interactive shell for the test-harness pod 
	@# (See the 'deploy' steps for the setup of same)

cluster.show: k3d.commander
	@# TUI for browsing the cluster 

test.tux.mux:
	make tux.mux/io.time.wait/10,io.time.wait/7,io.time.wait/6,io.time.wait/5,io.time.wait/4

###############################################################################

export PROMETHEUS_CLI_VERSION?=v2.52.0
export PROMETHEUS_HELM_REPO?=prometheus-community
export PROMETHEUS_HELM_REPO_URL?=https://prometheus-community.github.io/helm-charts
prometheus: k8s-tools.dispatch/k8s/.prometheus
.prometheus:
	make helm.repo.add/$${PROMETHEUS_HELM_REPO} url=$${PROMETHEUS_HELM_REPO_URL}
	make helm.chart.install/prometheus chart=$${PROMETHEUS_HELM_REPO}/prometheus 

# Forces an orderly rebuild on tools containers
build: k8s-tools.qbuild/k8s k8s-tools.qbuild/dind,tui