# k8s-tools.git End-to-end tests
# Exercising compose.mk, k8s.mk, plus the k8s-tools.yml services to create & interact  with a small k3d cluster.
SHELL := bash
MAKEFLAGS += -s --warn-undefined-variables
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
export POD_NAME:=test-harness
export POD_NAMESPACE:=default

# Include and invoke the `compose.import` macro 
# so we have targets for k8s-tools.yml services
include k8s.mk
include compose.mk
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))
# Default target should do everything, end to end.
all: build clean cluster deploy test
pane1: 
	sleep 2;
	make gum.style text='Cluster Create / Deploy / Test'
	make docker.stat 
	make cluster deploy test
	make gum.style text='k8s.stat'
	make flux.loopu/k8s.stat
	make gum.style text='k8s.wait'
	make flux.loopf/k8s.wait
	# sleep 10; make k9s/kube-system

export PROMETHEUS_CLI_VERSION?=v2.52.0
export PROMETHEUS_HELM_REPO?=prometheus-community
export PROMETHEUS_HELM_REPO_URL?=https://prometheus-community.github.io/helm-charts
prometheus: k8s-tools.dispatch/k8s/.prometheus
.prometheus:
	make helm.repo.add/$${PROMETHEUS_HELM_REPO} url=$${PROMETHEUS_HELM_REPO_URL}
	make helm.chart.install/prometheus chart=$${PROMETHEUS_HELM_REPO}/prometheus 

# Forces an orderly rebuild on tools containers
build: k8s-tools.qbuild/k8s,dind k8s-tools.qbuild

###############################################################################

# Top level public targets for cluster operations.
# These run private subtargets inside the named 
# tool containers (like `k3d` or `helm`).
clean: ▰/k3d/self.cluster.clean
cluster: ▰/k3d/self.cluster.init

# Private targets for low-level cluster-ops.
# Host has no `k3d` command, so these targets
# run inside the `k3d` service from k8s-tools.yml
self.cluster.init:
	make gum.style text="Cluster Setup"
	( \
		k3d cluster list | grep $${CLUSTER_NAME} \
		|| k3d cluster create $${CLUSTER_NAME} \
			--servers 3 --agents 3 \
			--api-port 6551 --port '8080:80@loadbalancer' \
			--volume $$(pwd)/:/$${CLUSTER_NAME}@all --wait \
	) | make io.print.indent
self.cluster.clean:
	make gum.style text="Cluster Clean"
	set -x && k3d cluster delete $${CLUSTER_NAME}

###############################################################################

# You can expand this to include usage of `kustomize`, etc.
# Volumes are already setup, so you can `kubectl appply` from the filesystem.
deploy: 
	make gum.style text="Cluster Deploy"
	make deploy.helm deploy.test_harness 
deploy.helm: ▰/helm/self.cluster.deploy_helm_example io.time.wait/5
deploy.test_harness: ▰/k8s/self.test_harness.deploy
self.cluster.deploy_helm_example: 
	@# Idempotent version of a helm install
	@# Commands are inlined below, but see 'helm.repo.add' 
	@# and 'helm.chart.install' for built-in helpers.
	set -x \
	&& (helm repo list 2>/dev/null | grep examples || helm repo add examples ${HELM_REPO} ) \
	&& (helm list | grep hello-world || helm install ahoy ${HELM_CHART})

self.test_harness.deploy: k8s.kubens.create/${POD_NAMESPACE} k8s.test_harness/${POD_NAMESPACE}/${POD_NAME}
	@# Prerequisites above create & activate the `default` namespace 
	@# and then a pod named `test-harness` into it, using a default image.
	@#
	@# Below, we'll deploy a simple nginx service into the default namespace.
	kubectl apply -f nginx.svc.yml
	make k8s.namespace.wait/default 

###############################################################################

test: test.cluster test.contexts 
test.cluster: 
	@# Waits for anything in the default namespace to finish and show cluster info
	text="Waiting for all namespaces to be ready" make gum.style 
	make k8s/dispatch/k8s.namespace.wait/all
	text="Showing kubernetes status" make gum.style 
	make k8s/dispatch/k8s.stat 
	text="Previewing topology for kube-system namespace" make gum.style 
	make krux/qdispatch/k8s.graph.tui/kube-system/pod
	text="Previewing topology for default namespace" make gum.style 
	make krux/qdispatch/k8s.graph.tui/default/pod

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
	@# (See also'deploy' steps for the setup of same)

cluster.show: k3d.tui
	@# TUI for browsing the cluster 

test.flux.tmux:
	make flux.tmux/io.time.wait/10,io.time.wait/7,io.time.wait/6,io.time.wait/5,io.time.wait/4
