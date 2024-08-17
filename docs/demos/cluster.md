# Demo: Cluster Automation




This section is a walk-through of the [end-to-end test](https://github.com/elo-enterprises/k8s-tools/tree/master/tests/Makefile.e2e.mk) included in the test-suite, demonstrating how you might use `k8s.mk` to put together a simple script for managing lifecycle aspects of a kubernetes cluster.

## Boilerplate, Overview & Overrides

Let's jump right into the obligatory boilerplate, some examples of version-overrides, and a high level overview of the automation that we expect to cover.

```Makefile 
# tests/Makefile.e2e.mk

# k8s-tools.git: End-to-end tests
#
# Exercising compose.mk, k8s.mk, plus the k8s-tools.yml services 
# to create & interact with a small k3d cluster.

# Standard boilerplate for make itself, nothing to see here.
SHELL := bash
MAKEFLAGS=-sS --warn-undefined-variables
.DEFAULT_GOAL=help
.SHELLFLAGS := -euo pipefail -c
.SUFFIXES:

# Override k8s-tools.yml service-defaults, 
# explicitly setting the k3d version used
export K3D_VERSION:=v5.6.3

# Cluster details that will be used by k3d.
export CLUSTER_NAME:=k8s-tools-e2e

# Ensure local KUBECONFIG exists & ignore anything from environment
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
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))

# Default target should do everything, end to end.
all: clean create deploy test

```

The `K3D_VERSION` part above is an example of overriding defaults from `k8s-tools.yml`, and effectively allows you to **pin tool versions inside scripts that use them, without editing with the compose file.**  Several of the compose-services [support explicit overrides along these lines](/k8s-tools/config#k8s-toolsyml), and it's a convenient way to test upgrades.

The `KREW_PLUGINS` variable holds a space-delimited list of [krew plugin names](https://krew.sigs.k8s.io/plugins/) that should be installed in the base k8s container.  These plugins are always installed: [kubens](https://github.com/ahmetb/kubectx), [kubectx](https://github.com/ahmetb/kubectx), [whoami](https://github.com/rajatjindal/kubectl-whoami), and [sick-pods plugin](https://github.com/alecjacobs5401/kubectl-sick-pods), but here you can specify any extras.

Note that when overrides like these are changed, [k8s-tools.yml](k8s-tools.yml) needs to be rebuilt.  (You can do that with `make k8s-tools.build` or `docker compose -f k8s-tools.yml build k8s`)

Next we organize some targets for cluster-operations.  Below you can see there are two public targets declared for direct access, and two private targets that run inside the `k3d` tool container.

```Makefile 
# tests/Makefile.e2e.mk

# Top level public targets for cluster operations, 
# plus (optional) convenience-aliases and stage-labels.

# These run private subtargets inside the named  tool containers (i.e. `k3d`).
clean cluster.clean: flux.stage/ClusterClean ▰/k3d/self.cluster.clean
create cluster.create: flux.stage/ClusterCreate ▰/k3d/self.cluster.create
teardown: flux.stage/ClusterTeardown cluster.teardown

# Plus a convenience alias to wait for all pods in all namespaces.
wait cluster.wait: k8s.cluster.wait

# Private targets for low-level cluster-ops.
# Host has no `k3d` command, so these targets
# run inside the `k3d` service from k8s-tools.yml
self.cluster.create:
	( k3d cluster list | grep $${CLUSTER_NAME} \
	  || k3d cluster create $${CLUSTER_NAME} \
			--servers 3 --agents 3 \
			--api-port 6551 --port '8080:80@loadbalancer' \
			--volume $$(pwd)/:/$${CLUSTER_NAME}@all --wait )
	
self.cluster.clean:
	set -x && k3d cluster delete $${CLUSTER_NAME}

```

Running `make clean` looks like this when it's tearing down the cluster:

<p align="center"><a href="/k8s-tools/img/e2e-clean.gif"><img width="90%" src="/k8s-tools/img/e2e-clean.gif"></a></p>

The `list` part makes the create target idempotent in the way you'd expect.  Here we're using CLI arguments for most of the cluster spec, but depending on your version, k3d supports most of this in external config yaml.

Running `make init` looks like this when it's setting up the cluster:

<p align="center"><a href="/k8s-tools/img/e2e-init.gif"><img width="90%" src="/k8s-tools/img/e2e-init.gif"></a></p>

## Deployment

The next section of the Makefile covers cluster provisioning.  Here we just want to install a helm chart, and to add a special "test-harness" pod to the default namespace.  

But we also want operations to be idempotent, and blocking operations where that makes sense, and we want to provide several entrypoints for the convenience of the user.

```Makefile 
# tests/Makefile.e2e.mk

# Top level public targets for deployments & (optional) convenience-aliases and stage-labels.
# These run private subtargets inside the named  tool containers (i.e. `helm`, and `k8s`).
deploy cluster.deploy: flux.stage/DeployApps flux.loop.until/k8s.cluster.ready deploy.helm deploy.test_harness deploy.prometheus
	# add a label to the default namespace
	key=manager val=k8s.mk make k8s.namespace.label/${POD_NAMESPACE}
deploy.prometheus:
	printf "\
		wait=yes \
		create_namespace=yes \
		chart_ref=prometheus \
		chart_version=25.24.1 \
		name=prometheus-community \
		release_namespace=prometheus \
		chart_repo_url=https://prometheus-community.github.io/helm-charts" \
	| make jb \
	| make ansible.helm
fwd.grafana:
	mapping="80:8081" make kubefwd.start/prometheus/grafana
	$(call log, ${GLYPH_DOCKER} looking up grafana password) 
	grafana_password=`kubectl get secret --namespace prometheus grafana -o jsonpath="{.data.admin-password}"|base64 --decode` \
	&& printf "http://admin:$${grafana_password}@grafana:8081\n"
	
deploy.grafana:
	printf "\
		wait=yes \
		name=grafana \
		chart_ref=grafana \
		create_namespace=yes \
		values:raw='{\"adminPassword\":\"test\"}' \
		release_namespace=prometheus \
		chart_repo_url=https://grafana.github.io/helm-charts" \
	| make jb \
	| make ansible.helm
	
deploy.helm: ▰/helm/self.cluster.deploy_helm_example io.time.wait/5
deploy.test_harness: ▰/k8s/self.test_harness.deploy

# Private targets with the low-level details for what to do in tool containers. 
# You can expand this to include usage of `kustomize`, etc. Volumes are already setup,
# so you can `kubectl apply` from the filesystem.  You can also call anything documented 
# in the API[1] https://github.com/elo-enterprises/k8s-tools/tree/master/docs/api/#k8smk.
self.cluster.deploy_helm_example: 
	@# Idempotent version of a helm install.
	@# Commands are inlined directly below for clarity, 
	@# but see also 'helm.repo.add', 'helm.chart.install', 
	@# and 'ansible.helm' for more advanced built-in helpers.
	set -x \
	&& (helm repo list 2>/dev/null | grep examples || helm repo add examples ${HELM_REPO} ) \
	&& (helm list | grep hello-world || helm install ahoy ${HELM_CHART})

# We stood up the test-harness with the 'k8s.test_harness' target,
# and stood up nginx with plain kubectl.  Let's tear down with 
# ansible to mix it up.
cluster.teardown:
	printf "\
		wait=yes kind=Pod state=absent \
		name=test-harness namespace=default" \
	| make ansible.k8s
	printf "\
		wait=true \
		name=ahoy \
		state=absent \
		release_namespace=default" \
	| make jb \
	| make ansible.helm 

# Prerequisites up top create & activate the `default` namespace 
# and then deploy a pod named `test-harness` into it, using a default image.
# In the body, we'll use kubectl directly to deploy a simple service into the default namespace.
self.test_harness.deploy: k8s.kubens.create/${POD_NAMESPACE} k8s.test_harness/${POD_NAMESPACE}/${POD_NAME} 
	kubectl apply -f nginx.svc.yml

```

Note that the `test_harness.provision` target above doesn't actually have a body!  The `k8s.*` targets coming from k8s.mk (documented [here](/k8s-tools/api/#api-k8smk)) do all of the heavy lifting.  

Meanwhile the helm provisioning target does have a body, which uses helm, and which runs inside the helm container.

<p align="center"><a href="/k8s-tools/img/e2e-provision-helm.gif"><img width="90%" src="/k8s-tools/img/e2e-provision-helm.gif"></a></p>


Helm is just an example.  Volumes for file-sharing with the container are also already setup, so you can `kustomize` or `kubectl apply` referencing the file system directly.

The other part of our provisioning is bootstrapping the test-harness pod.  This pod is nothing very special, but we can use it later to inspect the cluster.  Setting it up looks like this:

<p align="center"><a href="/k8s-tools/img/e2e-provision-test-harness.gif"><img width="90%" src="/k8s-tools/img/e2e-provision-test-harness.gif"></a></p>

## Testing

With the test-harness in place, there's a block of target definitions for a miniature test-suite that checks properties of the cluster.

```Makefile 
# tests/Makefile.e2e.mk

test: test.cluster test.contexts 
test.cluster cluster.test: flux.stage/test ▰/k8s/k8s.cluster.wait
	label="Showing kubernetes status" make charm.gum.style 
	make k8s/dispatch/k8s.stat 
	label="Previewing topology for default namespace" make charm.gum.style 
	size=40x make k8s.graph.tui/default/pod
	label="Previewing topology for kube-system namespace" make charm.gum.style 
	make k8s.graph.tui/kube-system/pod
	label="Previewing topology for prometheus namespace" make charm.gum.style 
	make k8s.graph.tui/prometheus/pod

test.contexts: 
	@# Helpers for displaying platform info 
	label="Demo pod connectivity" make charm.gum.style 
	make get.compose.ctx get.pod.ctx 

get.compose.ctx:
	@# Runs on the container defined by compose service
	echo uname -n | make k8s-tools/k8s/shell/pipe

get.pod.ctx:
	@# Runs inside the kubernetes cluster
	echo uname -n | make k8s.shell/default/test-harness/pipe

```

Amongst other things, the section above is using a streaming version of the `k8s.shell/<namespace>/<pod>/pipe` (we'll get to an interative version in later sections).

You can use this to assert things about the application pods you've deployed (basically a smoke test).  It's also useful for quick and easy checks that cover aspects of cluster internal networking, dns, etc.

Running `make test` looks like this:

<p align="center"><a href="/k8s-tools/img/e2e-test.gif"><img width="90%" src="/k8s-tools/img/e2e-test.gif"></a></p>

## Debugging

The tests are not a bad start for exercising the cluster, and instead of displaying platform info you can imagine tests that check service availability.  Since we blocked on pods or whole-namespaces being ready, we also know that nothing is stuck in crash loop or container-pull.  And we know that there were not errors with the helm charts, and that we can communicate with the test-harness pod.  

What if you want to inspect or interact with things though?  The next block of target definitions provides a few aliases to help with this.

```Makefile 
# tests/Makefile.e2e.mk

# Interactive shell for the test-harness pod 
# (See the 'deploy' steps for the setup of same)
cluster.shell: k8s.shell/${POD_NAMESPACE}/${POD_NAME}

# TUI for browsing the cluster 
cluster.show: k3d.commander

```

Again, no target bodies because `k8s.*` targets for stuff like this already exist, and we just need to pass in the parameters for our setup.  

Shelling into a pod is easy.  Actually `make k8s.shell/<namespace>/<pod_name>` was *always* easy if k8s.mk is used as an include, but now there's an even-easier alias that makes our project more self-documenting.  

<p align="center"><a href="/k8s-tools/img/e2e-interactive-shell.gif"><img width="90%" src="/k8s-tools/img/e2e-interactive-shell.gif"></a></p>

The `*k8s.shell/<namespace>/<pod_name>*` target used above is interactive, but there's also a streaming version that we used earlier in the cluster testing (`*k8s.shell/<namespace>/<pod_name>/pipe*`).

Since k3d is using docker for nodes, debugging problems sometimes involves inspecting host stats at the same time as a view of the cluster context.  Here's a side-by-side view of the kubernetes namespace (visualized with `ktop`), and the local docker containers (via `lazydocker`):

<p align="center"><a href="/k8s-tools/img/e2e-interactive-tui.gif"><img width="90%" src="/k8s-tools/img/e2e-interactive-tui.gif"></a></p>

## Development

For doing real application development, you'll probably want to get into some port-forwarding.  Using the `k8s.shell/<namespace>/<pod>/pipe` target, we could use `curl` to test things, but that's only meaningful *inside* the cluster, which is awkward.  

The [**`kubefwd.start/<namespace>`** target](/k8s-tools/api#kubefwdnamespacearg) makes it easy to forward ports/DNS for an entire namespace to the host:

<p align="center"><a href="/k8s-tools/img/e2e-kubefwd.gif"><img width="90%" src="/k8s-tools/img/e2e-kubefwd.gif"></a></p>

Note the weird DNS in the test above, where `nginx-service` resolves as expected, even from the host.  The `kubefwd` tool makes this work smoothly because `k8s-tools.yml` mounts `/etc/hosts` as a volume.

## Alternate Deployment

Really, a static or "project-local" kubernetes backend isn't required.  Since the automation separates platforming and application deployment from cluster-bootstrap, we can easily ignore k3d and use any existing cluster pretty easily.  To do this just export another value for `KUBECONFIG`.

For example, if you're using rancher desktop, you might do something like this:

```bash 
$ rdctl shell sudo k3s kubectl config view --raw > rancher-desktop.yml

$ KUBECONFIG=rancher-desktop.yml make deploy test
```

## Next Steps

From here you'll probably want to get something real done.  Most likely you are either trying to prototype something that you want to eventually productionize, or you already have a different production environment, and you are trying to get something from there to run more smoothly locally.  Either way, here's a few ideas for getting started.

1. **Experimenting with a different k8s distro than k3d should be easy,** since both `kind` and `eksctl` are already part of k8s-tools.yml.  Once you add a new setup/teardown/auth process for another backend, the rest of your automation stays the same.  
1. **Experimenting with extra cluster platforming probably begins with mirroring manifests or helm-charts.**  Container volumes are already setup to accomodate local files transparently.
1. **Experimenting with an application layer might mean more helm, and/or adding build/push/pull processes for application containers.**  Application work can be organized externally, or since **everything so far is still small enough to live in an application repository,** there's no pressing need to split code / infracode / automation into lots of repositories yet.  This is a good way to begin if you want to be local-dev friendly and have basic E2E testing for your application from the start.  For local application developement, you'll probably also want use `kubefwd` to start sharing cluster service ports, making them available on the host.
1. **For the architecture & microservices enthusiast,** a slight variation of this project boilerplate might involve adding another application-specific compose file that turns several of your first-party libraries into proper images using the using the [`dockerfile_inline:` trick](https://docs.docker.com/compose/compose-file/build/#dockerfile_inline) to run a little bit of `pip` or `npm`, then turning those versioned libraries into versioned APIs.  (If you already have external repositories with Dockerfiles wrapping your services, then compose `build:` also support URLs.)  If your needs are simple, then using [kompose](https://kompose.io/) can help multi-purpose that compose build-manifest, treating it as a deployment-manifest at the same time.  This is probably not where you want to stay, but an excellent place to start for things like PoCs and rapid-prototyping.
1. **Experimenting with private registries** might start with [compose-managed tags](https://docs.docker.com/reference/cli/docker/compose/push/) and a [local caching docker registry](https://docs.docker.com/docker-hub/mirror/)**, or you can push to a [k3d registry](https://k3d.io/v5.2.0/usage/registries/).  To use private, locally built images without a registry, see [`k3d image import`](https://k3d.io/v5.3.0/usage/commands/k3d_image_import/), or the equivalent [kind load](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster).
1. **Extending the make/compose technique to completely different automation tasks is straightforward,** as long as you stick to the layout.  For example substituing `k8s-tools.yml` for a new `iac-tools.yml` compose file that bundles together containers that package different versions of terraform, cloudformation, google/azure/databricks CLIs, etc.  Then `compose.mk` and `compose.import` generate targets as usual.  If necessary a new file `Makefile.iac.mk` can add a minimal interface for working with those containers.  These things together are basically an automation library, and it's up to individual projects to decide how to combine and drive the pieces.  

## Conclusion

So that's how less than 100 lines of mostly-aliases-and-documentation Makefile is enough to describe a simple cluster lifecycle, and can give access to ~20 versioned platforming tools, all with no host dependencies except docker + make.  It's simple, structured, portable, and lightweight.  If you don't care about partial excutions and exposing step-wise entrypoints to the CLI, then you can cut this line-count roughly in half.  Good automation will be self-documenting, but even if you're code-golfing with this approach, the result will probably *still* be organized/maintainable/durable than the equivalent shell-script or ansible.

No container orchestration logic was harmed during the creation of this demo, nor confined inside a Jenkinsfile or github action, and yet [it all works from github actions](https://github.com/elo-enterprises/k8s-tools/actions).  

Happy platforming =D



