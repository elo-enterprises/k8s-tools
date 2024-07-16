





<table align=center style="width:100%">
  <tr>
    <td colspan=2><strong>k8s-tools &nbsp; // &nbsp; <strong>Demos</strong></strong>&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
  </tr>
  <tr>
    <td align=center width=10%>
      <center>
        <img src=../../img//docker.png style="width:75px"><br/>
        <img src=../../img//kubernetes.png style="width:75px"><br/>
        <img src=../../img//make.png style="width:75px"><br/>
      </center>
    </td>
    <td width=90%>
      <table align=center border=1>
        <tr align=center><td align=center width="13%"><a href=/README.md#overview>Overview</a></td>
<td align=center width="13%"><a href=/README.md#features>Features</a></td>
<td align=center width="13%"><a href=/README.md#integration>Integration</a></td>
<td align=center width="13%"><a href=/README.md#composemk>compose.mk</a></td>
<td align=center width="13%"><a href=/README.md#k8smk>k8s.mk</a></td>
<td align=center width="13%"><a href=/docs/api/>API</a></td>
<td align=center width="13%"><a href=/docs/demos>Demos</a></td></tr>
      </table>
      <hr style="border-bottom:1px solid black;"><center><span align=center>&nbsp;<a href="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml"><img src="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml/badge.svg"></a>&nbsp;<a href="/docs/env-vars.md"><img alt=":alpine/k8s:1.30.0" src="https://img.shields.io/badge/alpine%2Fk8s%3A1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="alpine_k8s:alpine/k8s:1.30.0" src="https://img.shields.io/badge/alpine_k8s%3Aalpine%2Fk8s%3A1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="cdk:2.149.0" src="https://img.shields.io/badge/cdk%3A2.149.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kn:v1.14.0" src="https://img.shields.io/badge/kn%3Av1.14.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="debian_container:debian:bookworm" src="https://img.shields.io/badge/debian_container%3Adebian%3Abookworm-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helmify:v0.4.12" src="https://img.shields.io/badge/helmify%3Av0.4.12-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="fission:v1.20.1" src="https://img.shields.io/badge/fission%3Av1.20.1-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kompose:v1.33.0" src="https://img.shields.io/badge/kompose%3Av1.33.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="argo:v3.4.17" src="https://img.shields.io/badge/argo%3Av3.4.17-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kubefwd:1.22.5" src="https://img.shields.io/badge/kubefwd%3A1.22.5-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="k3d:v5.6.3" src="https://img.shields.io/badge/k3d%3Av5.6.3-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kind:v0.23.0" src="https://img.shields.io/badge/kind%3Av0.23.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="k9s:v0.32.4" src="https://img.shields.io/badge/k9s%3Av0.32.4-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="rancher:v2.8.4" src="https://img.shields.io/badge/rancher%3Av2.8.4-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="prometheus:v2.52.0" src="https://img.shields.io/badge/prometheus%3Av2.52.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="yq:4.43.1" src="https://img.shields.io/badge/yq%3A4.43.1-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="jq:1.7.1" src="https://img.shields.io/badge/jq%3A1.7.1-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="ansible:10.1.0" src="https://img.shields.io/badge/ansible%3A10.1.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kubectl:v1.30.0" src="https://img.shields.io/badge/kubectl%3Av1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helm:v3.14.4" src="https://img.shields.io/badge/helm%3Av3.14.4-blue"></a>&nbsp;&nbsp;<a href="/docs/env-vars.md"><img alt="kubectl:v1.30.0" src="https://img.shields.io/badge/kubectl%3Av1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helm:v3.14.4" src="https://img.shields.io/badge/helm%3Av3.14.4-blue"></a>&nbsp;</span></center><hr style="border-bottom:1px solid black;">
    </td>
  </tr>
</table><center><span align=center>
  Completely dockerized version of a kubernetes toolchain, plus a zero-dependency automation framework for extending and interacting it. Project-local clusters, cluster lifecycle automation, customizable TUIs, and more.
</span></center>

<div class="toc">
<ul></ul>
</div>


---------------------------------------------------------




<details><summary>:arrow_up_down:<h2>
Demo: Cluster Automation
</h3></summary>




This section is a walk-through of the [end-to-end test](tests/Makefile.e2e.mk) included in the test-suite.  

<details>:arrow_up_down:<summary><h3> Boilerplate, Overrides, Clean & Init</h3></summary>

```Makefile 
# tests/Makefile.e2e.mk

# k8s-tools.git End-to-end tests
# Exercising compose.mk, k8s.mk, plus the k8s-tools.yml services to create & interact  with a small k3d cluster.
SHELL := bash
MAKEFLAGS=-sS --warn-undefined-variables
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL=help
.SUFFIXES:
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

```

Note that the `K3D_VERSION` part above is overriding defaults [in k8s-tools.yml](k8s-tools.yml), and effectively allows you to **pin tool versions inside scripts that use them, without editing with the compose file.**  Several of the compose-services [support explicit overrides along these lines](/docs/env-vars.md##k8s-toolsyml), and it's a convenient way to test upgrades.

The `KREW_PLUGINS` variable holds a space-delimited list of [krew plugin names](https://krew.sigs.k8s.io/plugins/) that should be installed in the base k8s container.  These plugins are always installed: [kubens](https://github.com/ahmetb/kubectx), [kubectx](https://github.com/ahmetb/kubectx), [whoami](https://github.com/rajatjindal/kubectl-whoami), and [sick-pods plugin](https://github.com/alecjacobs5401/kubectl-sick-pods), but here you can specify any extras.

Note that when overrides like these are changed, [k8s-tools.yml](k8s-tools.yml) needs to be rebuilt.  (You can do that with `make k8s-tools.build` or `docker compose -f k8s-tools.yml build k8s`)

Next we organize some targets for cluster-operations.  Below you can see there are two public targets declared for direct access, and two private targets that run inside the `k3d` tool container.

```Makefile 
# tests/Makefile.e2e.mk

# Top level public targets for cluster operations & (optional) convenience-aliases and stage-labels.
# These run private subtargets inside the named  tool containers (i.e. `k3d`).
clean cluster.clean: flux.stage/ClusterClean ▰/k3d/self.cluster.clean
cluster cluster.create: flux.stage/ClusterCreate ▰/k3d/self.cluster.create
# Plus a convenience alias to wait for all pods in all namespaces.
cluster.wait: k8s.cluster.wait
# We stood up the test-harness with the 'k8s.test_harness' target,
# and stood up nginx with plain kubectl.  Let's tear down with 
# ansible to mix it up.
cluster.teardown:
	make jb wait=yes state=absent kind=Pod namespace=default name=test-harness | make ansible.k8s
	make jb release_namespace=default name=ahoy state=absent wait=true | make ansible.helm 
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

<img src="img/e2e-clean.gif">

The `list` part makes the create target idempotent in the way you'd expect.  Here we're using CLI arguments for most of the cluster spec, but depending on your version, k3d supports most of this in external config yaml.

Running `make init` looks like this when it's setting up the cluster:

<p align="center"><a href="img/e2e-init.gif"><img width="90%" src="img/e2e-init.gif"></a></p>

</details>

<details><summary>&nbsp;&nbsp; <h4>Deployment</h4> <i>(click to expand)</i>&nbsp;&nbsp; :arrow_up_down: </summary>

The next section of the Makefile covers cluster provisioning.  Here we just want to install a helm chart, and to add a special "test-harness" pod to the default namespace.  

But we also want operations to be idempotent, and blocking operations where that makes sense, and we want to provide several entrypoints for the convenience of the user.

```Makefile 
# tests/Makefile.e2e.mk

# Top level public targets for deployments & (optional) convenience-aliases and stage-labels.
# These run private subtargets inside the named  tool containers (i.e. `helm`, and `k8s`).
deploy cluster.deploy: flux.stage/DeployApps deploy.helm deploy.test_harness
	# add a label to the default namespace
	key=manager val=k8s.mk make k8s.namespace.label/${POD_NAMESPACE}
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
# Prerequisites up top create & activate the `default` namespace 
# and then deploy a pod named `test-harness` into it, using a default image.
# In the body, we'll use kubectl directly to deploy a simple service into the default namespace.
self.test_harness.deploy: k8s.kubens.create/${POD_NAMESPACE} k8s.test_harness/${POD_NAMESPACE}/${POD_NAME} 
	kubectl apply -f nginx.svc.yml

```

Note that the `test_harness.provision` target above doesn't actually have a body!  The `k8s.*` targets coming from k8s.mk (documented [here](/docs/api/#api-k8smk)) do all of the heavy lifting.  

Meanwhile the helm provisioning target does have a body, which uses helm, and which runs inside the helm container.

<p align="center"><a href="img/e2e-provision-helm.gif"><img width="90%" src="img/e2e-provision-helm.gif"></a></p>


Helm is just an example.  Volumes for file-sharing with the container are also already setup, so you can `kustomize` or `kubectl apply` referencing the file system directly.

The other part of our provisioning is bootstrapping the test-harness pod.  This pod is nothing very special, but we can use it later to inspect the cluster.  Setting it up looks like this:

<p align="center"><a href="img/e2e-provision-test-harness.gif"><img width="90%" src="img/e2e-provision-test-harness.gif"></a></p>

</details>

<details><summary>&nbsp;&nbsp; <h3>Testing</h3> <i>(click to expand)</i>&nbsp;&nbsp; :arrow_up_down: </summary>

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

<p align="center"><a href="img/e2e-test.gif"><img width="90%" src="img/e2e-test.gif"></a></p>

</details>

<details><summary>&nbsp;&nbsp; <h3>Debugging</h3> <i>(click to expand)</i>&nbsp;&nbsp; :arrow_up_down: </summary>

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

Shelling into a pod is easy.  Actually `make k8s.shell/<namespace>/<pod_name>` was *always* easy if k8s.mk is included, but now there's an even-easier alias that makes our project more self-documenting.  

<p align="center"><a href="img/e2e-interactive-shell.gif"><img width="90%" src="img/e2e-interactive-shell.gif"></a></p>

The `*k8s.shell/<namespace>/<pod_name>*` target used above is interactive, but there's also a streaming version that we used earlier in the cluster testing (`*k8s.shell/<namespace>/<pod_name>/pipe*`).

Since k3d is using docker for nodes, debugging problems sometimes involves inspecting host stats at the same time as a view of the cluster context.  Here's a side-by-side view of the kubernetes namespace (visualized with `ktop`), and the local docker containers (via `lazydocker`):

<p align="center"><a href="img/e2e-interactive-tui.gif"><img width="90%" src="img/e2e-interactive-tui.gif"></a></p>

</details>

<details><summary><h3>Development </h3></summary>

For doing real application development, you'll probably want to get into some port-forwarding.  Using the `k8s.shell/<namespace>/<pod>/pipe` target, we could use `curl` to test things, but that's only meaningful *inside* the cluster, which is awkward.  

The [**`kubefwd.start/<namespace>`** target](#target-kubefwdnamespacearg) makes it easy to forward ports/DNS for an entire namespace to the host:

<p align="center"><a href="img/e2e-kubefwd.gif"><img width="90%" src="img/e2e-kubefwd.gif"></a></p>

Note the weird DNS in the test above, where `nginx-service` resolves as expected, even from the host.  The `kubefwd` tool makes this work smoothly because [k8s-tools.yml](k8s-tools.yml) mounts `/etc/hosts` as a volume.

</details>

<details><summary>&nbsp;&nbsp; <h3>Alternate Deployment</h3> <i>(click to expand)</i>&nbsp;&nbsp; :arrow_up_down: </summary>

Really, a static or "project-local" kubernetes backend isn't required.  Since the automation separates platforming and application deployment from cluster-bootstrap, we can easily ignore k3d and use any existing cluster pretty easily.  To do this just export another value for `KUBECONFIG`.

For example, if you're using rancher desktop, you might do something like this:

```bash 
$ rdctl shell sudo k3s kubectl config view --raw > rancher-desktop.yml

$ KUBECONFIG=rancher-desktop.yml make deploy test
```
</details>

<details><summary>&nbsp;&nbsp; <h3>Next Steps</h3> <i>(click to expand)</i>&nbsp;&nbsp; :arrow_up_down: </summary>

From here you'll probably want to get something real done.  Most likely you are either trying to prototype something that you want to eventually productionize, or you already have a different production environment, and you are trying to get something from there to run more smoothly locally.  Either way, here's a few ideas for getting started.

1. **Experimenting with a different k8s distro than k3d should be easy,** since both `kind` and `eksctl` are already part of k8s-tools.yml.  Once you add a new setup/teardown/auth process for another backend, the rest of your automation stays the same.  
1. **Experimenting with extra cluster platforming probably begins with mirroring manifests or helm-charts.**  Container volumes are already setup to accomodate local files transparently.
1. **Experimenting with an application layer might mean more helm, and/or adding build/push/pull processes for application containers.**  Application work can be organized externally, or since **everything so far is still small enough to live in an application repository,** there's no pressing need to split code / infracode / automation into lots of repositories yet.  This is a good way to begin if you want to be local-dev friendly and have basic E2E testing for your application from the start.  For local application developement, you'll probably also want use `kubefwd` to start sharing cluster service ports, making them available on the host.
1. **For the architecture & microservices enthusiast,** a slight variation of this project boilerplate might involve adding another application-specific compose file that turns several of your first-party libraries into proper images using the using the [`dockerfile_inline:` trick](https://docs.docker.com/compose/compose-file/build/#dockerfile_inline) to run a little bit of `pip` or `npm`, then turning those versioned libraries into versioned APIs.  (If you already have external repositories with Dockerfiles wrapping your services, then compose `build:` also support URLs.)  If your needs are simple, then using [kompose](https://kompose.io/) can help multi-purpose that compose build-manifest, treating it as a deployment-manifest at the same time.  This is probably not where you want to stay, but an excellent place to start for things like PoCs and rapid-prototyping.
1. **Experimenting with private registries** might start with [compose-managed tags](https://docs.docker.com/reference/cli/docker/compose/push/) and a [local caching docker registry](https://docs.docker.com/docker-hub/mirror/)**, or you can push to a [k3d registry](https://k3d.io/v5.2.0/usage/registries/).  To use private, locally built images without a registry, see [`k3d image import`](https://k3d.io/v5.3.0/usage/commands/k3d_image_import/), or the equivalent [kind load](https://kind.sigs.k8s.io/docs/user/quick-start/#loading-an-image-into-your-cluster).
1. **Extending the make/compose technique to completely different automation tasks is straightforward,** as long as you stick to the layout.  For example substituing `k8s-tools.yml` for a new `iac-tools.yml` compose file that bundles together containers that package different versions of terraform, cloudformation, google/azure/databricks CLIs, etc.  Then `compose.mk` and `compose.import` generate targets as usual.  If necessary a new file `Makefile.iac.mk` can add a minimal interface for working with those containers.  These things together are basically an automation library, and it's up to individual projects to decide how to combine and drive the pieces.  
</details>

<details><summary>&nbsp;&nbsp; <h3>Conclusion</h3> <i>(click to expand)</i>&nbsp;&nbsp; :arrow_up_down: </summary>

So that's how less than 100 lines of mostly-aliases-and-documentation Makefile is enough to describe a simple cluster lifecycle, and can give access to ~20 versioned platforming tools, all with no host dependencies except docker + make.  It's simple, structured, portable, and lightweight.  If you don't care about partial excutions and exposing step-wise entrypoints to the CLI, then you can cut this line-count roughly in half.  Good automation will be self-documenting, but even if you're code-golfing with this approach, the result will probably *still* be organized/maintainable/durable than the equivalent shell-script or ansible.

No container orchestration logic was harmed during the creation of this demo, nor confined inside a Jenkinsfile or github action, and yet [it all works from github actions](https://github.com/elo-enterprises/k8s-tools/actions).  

Happy platforming =D
</details>

</details>

---------------------------------------------------------




<details><summary>&nbsp;&nbsp; <h2>Demo: Platform Setup</h2> <i>(click to expand)</i>&nbsp;&nbsp; :arrow_up_down: </summary>

### Basic Platforming 

Consider this hypothetical snippet:

``` Makefile
# Project Makefile
#
# Implementing a fake setup for platform bootstrap:
#   1. infrastructure is configured by the terraform container, 
#   2. application is configured by the ansible container,
#   3. we assume both emit json events (simulating terraform state output, etc)

platform1.setup: ▰/terraform/self.infra.setup ▰/ansible/self.app.setup
self.infra.setup:
    echo '{"event":"doing things in terraform container", "log":"infra setup done", "metric":123}'
self.app.setup:
    echo '{"event":"doing things in ansible container", "log":"app setup done", "metric":123}'
```

It's powerful, concise, expressive, and already orchestrating tasks across two containers defined in some external compose-file.  The syntax is configurable, and it's even starting to look object-oriented.  

Typically app-setup and infra-setup might further split into stages, but you get the idea.  And the infrastructure/app split always comes up, but it might look different.. for example your setup might replace `terraform` with `eksctl`, and `ansible` with `helm`.

### Extension with LME

Let's consider an extension of this.  Suppose output from `platform.setup` needs to be used separately by the next bootstrap processes.  For example, sending the platform output to different backends for `logging`, `metrics`, and `events`, respectively.  

For this kind of thing it's most natural to think in terms of process algebra, and you can express it like this:

```Makefile

# Fake some handlers for logging, metrics, events.
#   1. logging uses the `elk` container,
#   2. metrics uses the `prometheus` container,
#   3. events uses the `datadog` container.

logging: ▰/elk/self.logging
self.logging:
    # pretending to push data somewhere with curl
    cat /dev/stdin | jq .log

metrics: ▰/prometheus/self.metrics
self.metrics:
    # pretending to do stuff with the promtool CLI
    cat /dev/stdin | jq .metric

events: ▰/datadog/self.events
self.events:
    echo 'pretending to do stuff with the datadog CLI'
    cat /dev/stdin | jq .event

bootstrap:
    # pipes all the platform.setup output into a handler-target for each LME backend
    make platform1.setup | make flux.dmux/logging,metrics,events
```

Above, the builtin [flux.dmux target](/docs/api#fluxdmux) is used to send platform-setup's output into the three backend handlers.  This is just syntactic sugar for a 1-to-many pipe (aka a demultiplexer, or "dmux").  Each handler pulls out the piece of the input that it cares about, simulating further setup using that info.  The `bootstrap` entrypoint kicks everything off.  

This is actually a lot of control and data-flow that's been expressed.  Ignoring ordering, graphing it would look something like this:

<p align="center"><a href="/docs/example-platform-1.png"><img width="90%" src="/docs/example-platform-1.png"></a></p>

Whew.  We know what happens next is probably *more* platforms, more tools/containers, and more data flows.  Not to belabor the point but let's watch how it blows up with just one more platform:

<p align="center"><a href="/docs/example-platform-2.png"><img width="90%" src="/docs/example-platform-2.png"></a></p>

The stripped-down and combined automation is included below. It feels pretty organized and maintainable, and weighs in at only ~20 lines.  That's almost exactly the same number of lines in the [mermaid source-code for the diagram](docs/example-platform-1.mmd), which is kind of remarkable, because usually implementations are usually *orders of magnitude larger* than the diagrams that describe them!  Zeroing in on a minimum viable description length?

```Makefile 
include compose.mk
$(eval $(call compose.import, ▰, TRUE, my-containers.yml))

all: bootstrap 
bootstrap:
    make platform1.setup | make flux.dmux/logging,metrics,events
platform1.setup: ▰/terraform/self.infra.setup ▰/ansible/self.app.setup
logging: ▰/elk/self.logging
metrics: ▰/prometheus/self.metrics
events: ▰/datadog/self.events
self.infra.setup:
    echo '{"event":"doing things in terraform container", "log":"infra setup done", "metric":123}'
self.app.setup:
    echo '{"event":"doing things in ansible container", "log":"app setup done", "metric":123}'
self.logging:
    cat /dev/stdin | jq .log
self.metrics:
    cat /dev/stdin | jq .metric
self.events:
    cat /dev/stdin | jq .event
```

There are many other `flux.*` targets ([see the API docs](/docs/api#api-flux)), and while it's not recommended to go crazy with this stuff, when you need it you need it.

This tight expression of complex flow will already be familiar to lots of people: whether they are bash wizards, functional programming nerds, or the Airflow/MLFlow/ArgoWF users.  *But this example pipes data between 5 containers, with no dependencies, and in remarkably direct way that feels pretty seamless!*  It neatly separates the automation itself from the context that it runs in, all with no platform lock-in.  Plus.. compared to the alternatives, doesn't it feel more like working with a programming language and less like jamming bash into yaml? 🤔

It's a neat party trick that `compose.mk` has some features that look like Luigi or Airflow if you squint, but of course it's not *really* made for ETLs.  Flux is similar in spirit to things like [declarative pipelines in Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/#declarative-pipeline).

This example mostly runs as written, but properly escaping the JSON properly is awkward, etc. (Actually [`jb`](/docs/api#jb) or [`stream.json.object.append`](/docs/api#api-stream) can help with this, but it tends to obfuscate the example.)  If you want to see something that actually runs, check out the [simple dispatch demo](#container-dispatch) (which runs as part of [integration tests](tests/Makefile.itest.mk)), or check out the [cluster lifecycle demo](/docs/demos#demo-cluster-automation) (which is just a walk-through of the [end-to-end tests](tests/Makefile.e2e.mk)).

For a full blown project, check out [k3d-faas.git](https://github.com/elo-enterprises/k3d-faas), which also breaks down automation into platforms, infrastructure, and app phases.

</details>

---------------------------------------------------------




<details><summary>&nbsp;&nbsp; <h2>Demo: Mad Science</h2> <i>(click to expand)</i>&nbsp;&nbsp; :arrow_up_down: </summary>




This section is a small walk-through of some of the bad ideas in the [mad science test-suite](tests/Makefile.mad-science.mk).  You can run this test-suite from the project root with `make mad`.

Most of the demonstrations here are frankly nuts, and most likely no one will thank you for introducing these techniques into real projects!  Now, with that stern warning out of the way.. Here are some powerful techniques for "polyglotting" your Makefiles, or in other words **implementing different targets in different languages** and things like that.  This is useful for prototyping, and with some judicious restraint then you can potentially improve on many things that are otherwise very awkward from `make` or `bash`.  But if you use it with wild abandon you'll probably regret it.  Choose wisely ;)

### Working with Foreign Languages

```Makefile 
# tests/Makefile.mad-science.mk

# Minimal boilerplate for working with elixir-lang.  
# This picks an image for the language kernel 
# allowing overrides from the environment, 
# then runs a script with it.

export IMG_ELIXIR?=elixir:otp-27-alpine

demo.elixir:
	img=$${IMG_ELIXIR} \
	entrypoint=elixir \
	def=Elixir.hello_world \
	make docker.run.def

define Elixir.hello_world 
import IO, only: [puts: 1]
puts("elixir World!")
System.halt(0)
endef

```

### Inlined Docker Files

```Makefile 
# tests/Makefile.mad-science.mk

## Inlined Docker Files

# Minimal inlined dockerfile.  
# You can install anything or nothing here, 
# but let's have the minimal stuff required for target dispatch.
define Dockerfile.demo_dockerfile
FROM alpine
RUN echo building container spec from inlined dockerfile
RUN apk add --update --no-cache coreutils alpine-sdk bash procps-ng
endef


# Wrapper target that's using the container.
# This basically sets the container-build as a pre-req,
# so that within the body we can assume the base image exists.
demo.dockerfile: docker.from.def/demo_dockerfile
	# Working with the image directly, note the 'compose.mk' prefix.
	docker image inspect compose.mk:demo_dockerfile > /dev/null
	docker run -it --entrypoint sh compose.mk:demo_dockerfile -x -c "true" > /dev/null
	
	# Working with compose.mk builtins omits prefix, 
	# and can do dispatch targets to run inside the new image
	img=demo_dockerfile make mk.docker.run/self.demo.dockerfile
	
	# Add the prefix explicitly, and you can use `docker.run` instead of private `.docker.run`
	img=compose.mk:demo_dockerfile make docker.run/self.demo.dockerfile
	entrypoint=sh cmd='-c "ls"' img=compose.mk:demo_dockerfile make docker.run.sh 
	# Subsequent runs will use the cached image.  
	# Pass 'force' to work around this.
	force=1 make docker.from.def/demo_dockerfile

self.demo.dockerfile:
	echo "Testing target from inside the inlined-container"
	uname -a

```

### Extending Inlined Docker Files

Inlined containers can actually be extended with other inlines, but notice again the 'compose.mk' prefix which is used as a "repository".

```Makefile 
# tests/Makefile.mad-science.mk

## Inlined Docker Files

# Minimal inlined dockerfile.  
# You can install anything or nothing here, 
# but let's have the minimal stuff required for target dispatch.
define Dockerfile.demo_dockerfile
FROM alpine
RUN echo building container spec from inlined dockerfile
RUN apk add --update --no-cache coreutils alpine-sdk bash procps-ng
endef


# Wrapper target that's using the container.
# This basically sets the container-build as a pre-req,
# so that within the body we can assume the base image exists.
demo.dockerfile: docker.from.def/demo_dockerfile
	# Working with the image directly, note the 'compose.mk' prefix.
	docker image inspect compose.mk:demo_dockerfile > /dev/null
	docker run -it --entrypoint sh compose.mk:demo_dockerfile -x -c "true" > /dev/null
	
	# Working with compose.mk builtins omits prefix, 
	# and can do dispatch targets to run inside the new image
	img=demo_dockerfile make mk.docker.run/self.demo.dockerfile
	
	# Add the prefix explicitly, and you can use `docker.run` instead of private `.docker.run`
	img=compose.mk:demo_dockerfile make docker.run/self.demo.dockerfile
	entrypoint=sh cmd='-c "ls"' img=compose.mk:demo_dockerfile make docker.run.sh 
	# Subsequent runs will use the cached image.  
	# Pass 'force' to work around this.
	force=1 make docker.from.def/demo_dockerfile

self.demo.dockerfile:
	echo "Testing target from inside the inlined-container"
	uname -a

```

### Local Interpretters, Without a Container

```Makefile 
# tests/Makefile.mad-science.mk

## Extending Inlined Docker Files
# Minimal inlined dockerfile.  
# You can install anything or nothing here, 
# but let's have the minimal stuff required for target dispatch.
define Dockerfile.demo_dockerfile2
FROM compose.mk:demo_dockerfile
RUN echo hello-docker
endef


# Wrapper target that's using the container.
# This basically sets the container-build as a pre-req,
# so that within the body we can assume the base image exists.
demo.dockerfile2: docker.from.def/demo_dockerfile2
	# # Working with the image directly, note the 'compose.mk' prefix.
	docker image inspect compose.mk:demo_dockerfile2 > /dev/null
	docker run -it --entrypoint sh compose.mk:demo_dockerfile2 -x -c "true" > /dev/null
	
	# Working with compose.mk builtins omits prefix, 
	# and can dispatch targets to run inside the new image
	img=demo_dockerfile2 make mk.docker.run/self.demo.dockerfile2
	
	# Add the prefix explicitly, and you can use `docker.run` instead of private `.docker.run`
	img=compose.mk:demo_dockerfile2 make docker.run/self.demo.dockerfile2
	
	# Subsequent runs will use the cached image.  
	# Pass 'force' to work around this.
	force=1 make docker.from.def/demo_dockerfile2

self.demo.dockerfile2:
	echo "Testing target from inside the inlined-container"
	uname -a

```

### Exotic Targets & Pipes

```Makefile 
# tests/Makefile.mad-science.mk

## Local Interpretters, Without a Container

# Look, here's a simple python script 
define Python.demo
import sys
print('python world')
print('dollarsigns are safe: $')
endef

# Minimal boilerplate to run the script,
# using a specific interpretter (python3).
# No container here, so this requires that 
# the interpretter is actually available.
demo.python:
	make mk.def.dispatch/python3/Python.demo

```

### Passing Data Structures to Externally Managed Containers

So far we've seen examples of passing code, but of course the process is much the same for data.

Let's embed a playbook, then run it with the `ansible` container defined in `k8s-tools.yml`.

```Makefile 
# tests/Makefile.mad-science.mk

## Local Interpretters, Without a Container

# Look, here's a simple python script 
define Python.demo
import sys
print('python world')
print('dollarsigns are safe: $')
endef

# Minimal boilerplate to run the script,
# using a specific interpretter (python3).
# No container here, so this requires that 
# the interpretter is actually available.
demo.python:
	make mk.def.dispatch/python3/Python.demo

```

This is just an example, and anyway you may prefer to work with the [ansible.adhoc](/docs/api#ansibleadhocarg) tooling which is better for simple use-cases.  

But of course the playbook above could just as easily be an `eksctl` config or `kubectl` manifest.

### How it Works 

Most of this stuff hinges on multi-line defines, plus the ability of `compose.mk` to handle reflection, which is possible because it has some ability to parse its own contents.  See the API for [*`mk.*`*](/docs/api#api-mk) and [*`docker.*`*](/docs/api#api-docker) for more details.  Note also that the [*`mk.def.*`* targets](/docs/api#api-mk) leave the data inside the defs completely unmolested, which means that there's no nightmare of escaping the contents and things like '$' are always left alone.  This also means the **content is fairly static**, and not typically amenable to pre-execution templating.  It *is* possible to work around this, but that's an even worse idea than the rest of this is, and so left as an exercise to the reader. =P

</details>
