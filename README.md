








<table align=center style="width:100%">
  <tr>
    <td colspan=2><strong>k8s-tools </strong>&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
  </tr>
  <tr>
    <td align=center width=10%>
      <center>
        <img src=img//docker.png style="width:75px"><br/>
        <img src=img//kubernetes.png style="width:75px"><br/>
        <img src=img//make.png style="width:75px"><br/>
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
      <hr style="border-bottom:1px solid black;"><center><span align=center>&nbsp;<a href="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docs.yml"><img src="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docs.yml/badge.svg"></a><a href="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml"><img src="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml/badge.svg"></a>&nbsp;<a href="/docs/env-vars.md"><img alt=":alpine/k8s:1.30.0" src="https://img.shields.io/badge/alpine%2Fk8s%3A1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="alpine_k8s:alpine/k8s:1.30.0" src="https://img.shields.io/badge/alpine_k8s%3Aalpine%2Fk8s%3A1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="cdk:2.149.0" src="https://img.shields.io/badge/cdk%3A2.149.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kn:v1.14.0" src="https://img.shields.io/badge/kn%3Av1.14.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="debian_container:debian:bookworm" src="https://img.shields.io/badge/debian_container%3Adebian%3Abookworm-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helmify:v0.4.12" src="https://img.shields.io/badge/helmify%3Av0.4.12-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="fission:v1.20.1" src="https://img.shields.io/badge/fission%3Av1.20.1-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kompose:v1.33.0" src="https://img.shields.io/badge/kompose%3Av1.33.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="argo:v3.4.17" src="https://img.shields.io/badge/argo%3Av3.4.17-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kubefwd:1.22.5" src="https://img.shields.io/badge/kubefwd%3A1.22.5-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="k3d:v5.6.3" src="https://img.shields.io/badge/k3d%3Av5.6.3-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kind:v0.23.0" src="https://img.shields.io/badge/kind%3Av0.23.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="k9s:v0.32.4" src="https://img.shields.io/badge/k9s%3Av0.32.4-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="rancher:v2.8.4" src="https://img.shields.io/badge/rancher%3Av2.8.4-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="prometheus:v2.52.0" src="https://img.shields.io/badge/prometheus%3Av2.52.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="yq:4.43.1" src="https://img.shields.io/badge/yq%3A4.43.1-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="jq:1.7.1" src="https://img.shields.io/badge/jq%3A1.7.1-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="ansible:10.1.0" src="https://img.shields.io/badge/ansible%3A10.1.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kubectl:v1.30.0" src="https://img.shields.io/badge/kubectl%3Av1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helm:v3.14.4" src="https://img.shields.io/badge/helm%3Av3.14.4-blue"></a>&nbsp;&nbsp;<a href="/docs/env-vars.md"><img alt="kubectl:v1.30.0" src="https://img.shields.io/badge/kubectl%3Av1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helm:v3.14.4" src="https://img.shields.io/badge/helm%3Av3.14.4-blue"></a>&nbsp;</span></center><hr style="border-bottom:1px solid black;">
    </td>
  </tr>
</table><center><span align=center>
  Completely dockerized version of a kubernetes toolchain, plus a zero-dependency automation framework for extending and interacting it. Project-local clusters, cluster lifecycle automation, customizable TUIs, and more.
</span></center>



--------------------------------

<p align="center"><a href="img/e2e-k3d.commander.gif"><img width="100%" src="img/e2e-k3d.commander.gif"></a></p>

--------------------------------



## Overview

**This repository aggregates 20+ individual utilities for working with kubernetes into one dockerized toolchain, hosted inside a single compose file as [k8s-tools.yml](#versioned-toolkit).**  It's useful for CI/CD pipelines or general development, and can be [embedded alongside your existing project](/integration), which helps to fix the problem of different project developers using different local versions of things like `helm`, `kubectl`, etc.

Containers defined here aren't built from scratch, and official sources are used where possible.  Low-level tools (*like `kubectl`, `helm`, etc*) mostly come from [alpine/k8s](https://hub.docker.com/r/alpine/k8s) but [many other tools](#features) (*like `argo`, `knative`, `cdk`, `k9s`, `k3d`, etc) are also included.  However, *this isn't an attempt to build an omnibus "do-everything" container..* it's more a response to the fact that there are a lot of diverse tools that really can't be unified, so it's better to just learn how to work with that.  Tools containers are versioned independently, and pulled only when they are used.

------------------------

**Besides bundling some tooling, this repository is a reference implementation** for a pattern that [bridges compose services and Makefile targets](#makecompose-bridge), creating a "minimum viable automation framework" for things like [orchestrating tasks across tool containers](#container-dispatch).  It's expressive and flexible, yet also focused on minimizing both conceptual overhead and software dependencies.  It's incredibly useful for lots of things, and whether it is a tool, a library, or a framework  depends on how you decide to use it.  There's 3 pieces to this, and the full triple of *k8s.mk*, *compose.mk*, and *k8s-tools.yml* is sometimes called **the k8s-tools suite.** 



This reference focuses on a few use-cases in particular:

1. Cluster lifecycle / development / debugging workflows in general.
1. Decoupling project automation from the choice of CI/CD backend.
1. Project-local kubernetes clusters & corresponding lifecycle automation using `kind` or `k3d`.
1. Proper separation of automation tasks from specifications for runtime / container context.
1. Less shell code in general, but where we need it: it <u>shouldn't</u> be embedded in YAML, Jenkinsfiles, etc.
1. Per-project tool-versioning, providing defaults but allowing overrides, and ensuring versions match everywhere.
1. Generally modernizing & extending `make` for containers, colors, & concurrency, making it ready for the 21st Century.

There's a lot of hate for `make` (especially for "creative" usage of it!), but you'll find that these are not the Makefile's of your ancestors.  Support for [container dispatch](#container-dispatch) feels like a tiny, unobtrusive DSL on top of tech you already know, and you can run it anywhere you are.  Less time spent negotiating with bolted-on plugin-frameworks, hook systems, and build-bots, more time for the problems you care about.  And yes, *the build-bots themselves will be happy to run your automation,* and the output is easy to parse.  See the [this repo's github actions](https://github.com/elo-enterprises/k8s-tools/actions?query=branch%3Amaster), which bootstrap and exercise a cluster as part of the [end to end tests](/demos#demo-cluster-automation).

**Working with [compose.mk](/composemk) and [k8s.mk](/k8s.mk) makes `make` hit different.**  

Beyond addressing the issues above, these tools add new capabilities to `make` itself, including some support for [quickly building custom TUIs](#embedded-tui) from dockerized components.

<p align="center"><a href="/img/tui-6.gif"><img width="90%" src="/img/tui-6.gif"></a></p>

With or without the TUI, all output is carefully curated and logged to appropriate output streams, aiming to be readable and human-friendly on stderr, while still remaining machine-friendly for downstream processing on stdout.  Help not only *works,* it also goes beyond mere target-listing to actually include namespace and per-target documentation, rendered via a dockerized version of [charmbracelete/glow](https://github.com/charmbracelet/glow).

<p align="center"><a href="/img/tui-7.gif"><img width="90%" src="/img/tui-7.gif"></a></p>


--------------------------------

## Features

### Versioned Toolkit

**[k8s-tools.yml](k8s-tools.yml)** is a compose file with 20+ container specifications covering popular platforming tools and other utilities for working with Kubernetes.  This file makes use of the [dockerfile_inline directive](https://docs.docker.com/compose/compose-file/build/#dockerfile_inline), plus the fact that tool-containers  *tend to involve layering really small customizations*.  Now you can version these tools explicitly, customize them if you need to, and still avoid having N Dockerfiles cluttering up your whole repository.  **All tool containers are just-in-time & on-demand,** so that having these declared in case of eventual use won't saddle you with an enormous bootstrap process.  As usual with docker-compose, containers aren't pulled until they are used, and build-when-changed mostly works as you'd expect.  Here's a quick overview of the manifest and some details about versioning:

* **Local parts of the tool bundle** ([See the latest here](k8s-tools.yml))
  * <ins>Cluster management:</ins> [kind](https://github.com/kubernetes-sigs/kind), [k3d](https://k3d.io/)
  * <ins>Workflows, FaaS, and Misc Platforming Tools:</ins> [argocli](https://argo-workflows.readthedocs.io/en/latest/walk-through/argo-cli/), [kn](https://knative.dev/docs/client/install-kn/), [fission](https://fission.io/docs/installation/), [rancher](https://github.com/rancher/cli)
  * <ins>Lower-level helpers:</ins> [helmify](https://github.com/arttor/helmify), [kompose](https://kompose.io/), [kubefwd](https://github.com/txn2/kubefwd)
  * <ins>Monitoring and metrics tools:</ins> [promtool](https://prometheus.io/docs/prometheus/latest/command-line/promtool/), [k9s](https://k9scli.io/), [lazydocker](https://github.com/jesseduffield/lazydocker)
  * <ins>Krew plugins:</ins> [sick-pods](https://github.com/alecjacobs5401/kubectl-sick-pods), [ktop](https://github.com/vladimirvivien/ktop), [kubectx, and kubens](https://github.com/ahmetb/kubectx) available by default, and more on demand.
  * <ins>TUI and user-messaging utilities</ins>: [gum](https://github.com/charmbracelet/gum), [pv](https://www.ivarch.com/programs/pv.shtml), [spark](https://raw.githubusercontent.com/holman/spark/), [tte](https://github.com/ChrisBuilds/terminaltexteffects)
  * <ins>General Utilities:</ins> Fixed (i.e. non-busybox) versions of things like date, ps, uuidgen, etc
  * **Tooling in the local bundle is all versioned independently:**
    * Defaults are provided, but [overrides allowed from environment variables](docs/env-vars.md#k8stoolsyml).
* **Upstream parts of the tool bundle** ([See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.)
  * <ins>Cluster management:</ins> [eksctl](https://github.com/weaveworks/eksctl)
  * <ins>Core Utilities:</ins> [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [kustomize](https://github.com/kubernetes-sigs/kustomize), [helm](https://github.com/helm/helm), [krew](https://github.com/kubernetes-sigs/krew)
  * <ins>Misc Utilities:</ins> [helm-diff](https://github.com/databus23/helm-diff), [helm-unittest](https://github.com/helm-unittest/helm-unittest), [helm-push](https://github.com/chartmuseum/helm-push), [kubeseal](https://github.com/bitnami-labs/sealed-secrets), [vals](https://github.com/helmfile/vals), [kubeconform](https://github.com/yannh/kubeconform)
  * <ins>Cloud Utilities:</ins> [awscli v1](https://github.com/aws/aws-cli), [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
  * <ins>General Utilities:</ins> Such as bash, curl, jq, yq, etc
  * **Upstream tool versioning is determined by the alpine-k8s base,**
    * But *k8s-tools.yml* has service-stubs for quick overrides if you need something specific.

### Bonus Features

**Sane defaults for volumes & environments are included for each tool-container,** meaning that sharing the working directory, docker socket, and kubeconfigs is done automatically.  For host vs. container file permissions, `k8s-tools.yml` also attempts to provide *smoother operations with root-user containers* (*[more details here](/limitations#docker-and-file-permissions)*.  

For advanced usage of the tool containers defined in `k8s-tools.yml` it's best to pair it with the rest of the automation here, but the compose file also works in stand-alone mode.  The file is even executable, and  *./k8s-tools.yml ...*  is equivalent to *docker compose -f k8s-tools.yml ...*.

**The focus for k8s-tools.yml is to stand alone with no host dependencies, not even Dockerfiles, yet provide boilerplate that's parametric enough to work pretty well across different projects  without changing the compose file.**  If the default tool versions don't work for your use-cases, [k8s-tools.yml probably has an environment variable you can override](environment-variables).

-------

### Toolchain Automation

After you've made your whole kit portable in one swipe, you might want to focus on *driving* those tools with something that offers more structure than a shell script, and something that also *won't add to your host dependencies*.  If that sounds interesting, you might like to meet `compose.mk` and `k8s.mk`. 

<ins>**[compose.mk](/compose.mk)** is simultaneously a stand-alone CLI tool and an automation library for working with `make` + containers.</ins>  It defines targets and macros that can extend Make's core functionality in a variety of ways actually, but the main feature is ensuring that it's simple to work with docker-compose files and services, and docker in general.

#### Importing Compose Services

* **Tool containers can be "imported" as a group of related make-targets.**
  * This creates wrapper-targets that use the containers.
  * You can interact with them using the [Make/compose bridge](#makecompose-bridge).
  * You can [use container-dispatch syntax](#container-dispatch) to run existing make-targets **inside** tool containers.
  * You can use the containers effectively from "outside", or drop into debugging shell "inside".
* **Tool containers can be anything, defined anywhere:**
    * No explicit dependency for *k8s-tools.yml*.
    * [Multiple compose-files are supported](#multiple-compose-files)
    * Bring your own compose file and build automation APIs on those instead *(cm-tools.yml? docs-tools.yml? whatever)*

<ins>The best way to think of compose.mk is to consider it an extension of `make` that's written in `make`.</ins>  As a single file with no external dependencies, it can in principle work as a global-install, but the emphasis is on embedding it into existing projects.  Since it doesn't depend explicitly on either `k8s-tools.yml` or `k8s.mk`, it slots comfortably into many kinds of projects that have nothing to do with kubernetes.  Beyond the docker support, there are [many other features](/compose.mk).

-------

<ins>**[k8s.mk](/k8s.mk)** inherits all the *compose.mk* features, then integrates with *k8s-tools.yml*.</ins>  Both *compose.mk* and *k8s-tools.yml* files are a soft-dependency for *k8s.mk*, because the emphasis is on seamless usage of those containers.  

In terms of wrappers, all of the autogenerated targets for low-level container access described by [the Make/Compose Bridge](#makecompose-bridge) are available for the *k8s-tools.yml* services, plus more composite functionality.  

For example, `k8s.mk` provides some primitives for common tasks (*like waiting for all pods to be ready*), context management (*like setting the active namespace*), and the usual patterns (*like idempotent usage of `helm`*).  Besides helping to version tools, it can make it simpler to interact with them or make it simpler to script actions that involve multiple tools. Additionally, `k8s.mk` also inherits and extends the [TUI support from compose.mk](#embedded-tui), including the ability to automate the TUI itself. 

### k8s.mk Features

* **Main features:**
  * Useful as a library, especially if you're building cluster lifecycle automation
  * Useful as an interactive debugging/inspection/development tool.
  * Helps to do the common tasks quickly, either interactively or from other automation
    * Launch a pod in a namespace, or a shell in a pod, without lots of kubectl'ing
    * Stream and pipe commands to/from pods, or between pods
  * Assemble custom interactive dashboards with new or existing TUI elements
  * **[Curated collection of automation interfaces](#k8smk-api)**, arranged into a few namespaces:
      * [**`k8s.*` targets:**](/api#api-k8s) Default namespace with debugging tools, cluster life-cycle primitives, etc.
      * [**`ansible.*` targets:**](/api#api-ansible) A direct interface to containerized versions of things like [kubernetes.core.k8s](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html) or [kubernetes.core.helm](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/helm_module.html), no playbooks and no inventories required.
      * **Many more specific interfaces** to things like [k3d](/api#api-k3d), [kubefwd](/api#api-kubefwd), etc. [See the full API here.](#k8smk-api)
  

Whereas `compose.mk` is useful in general, `k8s.mk` is of course more focused on projects working with kubernetes, and is the best example of how to go about extending `compose.mk`.

--------------------------------

## Quick Start

### Clone/Build/Test This Repo

```bash
# for ssh
$ git clone git@github.com:elo-enterprises/k8s-tools.git

# or for http
$ git clone https://github.com/elo-enterprises/k8s-tools

# build the tool containers & check them
$ make clean build test
```


### Tools via Compose CLI

```bash
$ docker compose run -f k8s-tools.yml ansible ...
$ docker compose run -f k8s-tools.yml argo ...
$ docker compose run -f k8s-tools.yml awscli ...
$ docker compose run -f k8s-tools.yml aws-iam-authenticator ...
$ docker compose run -f k8s-tools.yml cdk ...
$ docker compose run -f k8s-tools.yml dind ...
$ docker compose run -f k8s-tools.yml eksctl ...
$ docker compose run -f k8s-tools.yml fission ...
$ docker compose run -f k8s-tools.yml graph-easy ...
$ docker compose run -f k8s-tools.yml gum ...
$ docker compose run -f k8s-tools.yml helm ...
$ docker compose run -f k8s-tools.yml helm-diff ...
$ docker compose run -f k8s-tools.yml helmify ...
$ docker compose run -f k8s-tools.yml helm-push ...
$ docker compose run -f k8s-tools.yml helm-unittest ...
$ docker compose run -f k8s-tools.yml jq ...
$ docker compose run -f k8s-tools.yml k3d ...
$ docker compose run -f k8s-tools.yml k8s ...
$ docker compose run -f k8s-tools.yml k9s ...
$ docker compose run -f k8s-tools.yml kind ...
$ docker compose run -f k8s-tools.yml kn ...
$ docker compose run -f k8s-tools.yml kompose ...
$ docker compose run -f k8s-tools.yml krew ...
$ docker compose run -f k8s-tools.yml kubeconform ...
$ docker compose run -f k8s-tools.yml kubectl ...
$ docker compose run -f k8s-tools.yml kubefwd ...
$ docker compose run -f k8s-tools.yml kubeseal ...
$ docker compose run -f k8s-tools.yml kustomize ...
$ docker compose run -f k8s-tools.yml lazydocker ...
$ docker compose run -f k8s-tools.yml promtool ...
$ docker compose run -f k8s-tools.yml rancher ...
$ docker compose run -f k8s-tools.yml tui ...
$ docker compose run -f k8s-tools.yml vals ...
$ docker compose run -f k8s-tools.yml yq ...
```


### Tools via Make

Using the special form './k8s.mk <container_name> -- ... ` you can pass commands directly to tool containers in *k8s-tools.yml*.  This works with the container's default entrypoint, and has the usual features available (like making the working directory accessible as a volume). For example, commands like this will work at the repository root:

```bash
./k8s.mk kubectl -- version --client
```

You can see many more examples included as part of [the smoke tests](https://github.com/elo-enterprises/k8s-tools/tree/master/tests/Makefile.smoke-test-k8s.mk).  

This way of interacting with containers is sometimes convenient for interactive one-offs, but it's also missing the full flexibility of overriding the default container entrypoint, streaming more than one command into the container, etc.  When developing automation, it's often more convenient to use lower-level access that's more explicit and more flexible:

```bash
# runs kubectl, which can be used directly or with pipes 
$ cmd='apply -f my-manifest.yml' ./k8s.mk kubectl
$ cat my-manifest.yml | ./k8s.mk kubectl/pipe cmd='apply -f -'

# run helmify (which expects stdin)
$ cat my-manifest.yml | ./k8s.mk helmify/pipe

# drop to a shell to work with helm container (interactive; plus '.' is already volume-shared)
$ ./k8s.mk helm/shell

# get cluster info from k3d
$ ./k8s.mk k3d cmd='cluster list -o json'

# equivalently 
$ echo k3d cluster list -o json | ./k8s.mk k3d/shell/pipe
```

For more details about targets that are **autogenerated for tool containers in the compose-spec**, how this works in general, and what else you can do with it.. check out the docs for [the Make/Compose bridge](#makecompose-bridge).  There are various static-targets available too, [see the full API docs](//api).

Building on the capabilities of those tool-containers, here's some random examples of more advabced features of *k8s.mk*.  

```bash
# KUBECONFIG should already be set!
# wait for all pods in all namespaces
$ ./k8s.mk k8s.wait

# start a debugging shell in the 'default' namespace and attach to it (interactive)
$ ./k8s.mk k8s.test_harness/default/my-test-harness 
$ ./k8s.mk k8s.shell/default/my-test-harness

# run k9s TUI for the given namespace (interactive)
$ ./k8s.mk k9s/my-namespace
```

For the full documentation of those targets, see [k8s.mk API](/api/#api-k8smk).

This repository includes lots of examples for make/compose integration in general, and in particular how you can accomplish lifecycle scripting with k8s.mk.

* For advanced usage that builds automation APIs by running targets *inside* tool containers, see [the dispatch-demo](#container-dispatch).
* For a more involved tutorial [see the cluster-lifecycle demo](/demos#demo-cluster-automation).
* For examples, you can also the [integration tests](https://github.com/elo-enterprises/k8s-tools/tree/master/tests/Makefile.itest.mk) and [end-to-end tests](https://github.com/elo-enterprises/k8s-tools/tree/master/tests/Makefile.e2e.mk).  
* For a complete, external project that uses this approach for cluster automation, see [k3d-faas.git](https://github.com/elo-enterprises/k3d-faas)



--------------------------------

## Integration With Your Project

The k8s-tools suite can be integrated with your project in a few ways, either with some kind of global compose file and global aliases (*not recommended*), or with a more project-based approach.  But first, you might like to check out the compatibility notes.

### Compatibility Notes

Platforms used in development include modern docker (say `25+`), make (`3.8+`), and bash `(~5`) on both Linux and MacOS, but testing in github-actions only uses Linux and won't try every possible combination of versions.  

In general, *the goal is to support most things you'll encounter in the wild*, including OSX, out of the box.  But you may see some of the usual problems with certain arguments to non-posix OSX default `sed` / `ps` / `xargs`, etc.  Please report issues!

### Tools Via Simple Aliases

The simplest and most global way to use k8s-tools.yml is to just download it and setup shell aliases, ignoring `compose.mk` and `k8s.mk`.  Not generally recommended, since this is the least project-based, least portable thing you can do. 

```bash
$ cd myproject

# or use your fork/clone..
$ curl -sL https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/k8s-tools.yml > k8s-tools.yml

$ alias helm=docker compose -f myproject/k8s-tools.yml run helm

$ helm ....
```

 Not bad for experiments, but *don't write scripts based on this an expect to ship them to coworkers or build bots!*  Aliases are convenient but rather fragile.  (For example, obviously this will break if you move your `myproject` folder around).  **See the next sections for something that is a more durable and flexible.**

### Embedding Tools With Makefiles

You'll probably want to read over the [compose.mk](/compose.mk) section to understand what's going on here.  In case you've already seen it though, here's the quick start with the copy/paste stuff.



First, copy the files from this repo into your project:

```bash
$ cd myproject 

# Download the compose file with the tool containers
$ curl -sL \
  https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/k8s-tools.yml \
    > k8s-tools.yml

# Download the compose.mk automation lib
$ curl -sL \
  https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/compose.mk \
    > compose.mk

# Download the k8s.mk automation lib.
$ curl -sL \
  https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/k8s.mk \
    > k8s.mk

```

These 3 files are usually working together, but in some cases they are useful in a stand-alone mode.  Make them all executable like this:

```bash
$ chmod ugo+x k8s-tools.yml compose.mk k8s.mk

# equivalent to `make -f k8s.mk ..`
./k8s.mk ... 

# equivalent to `make -f compose.mk ..`
$ ./compose.mk ... 

# equivalent to `docker compose -f k8s-tools.yml run ...`
$ ./k8s-tools.yml run ...
```

That's all the setup you'll need just for using tools directly.  See the next section for more information/examples re: stand-alone mode.

If you're interested in tighter integration like setting up the [Make/Compose bridge](#makecompose-bridge) or preparing for [Container Dispatch](#container-dispatch), here's an example of what your project Makefile should look like:

```Makefile
# myproject/Makefile (Make sure you have real tabs, not spaces!)
 
# Include/invoke the target-building macros 
# somewhere near the top of your existing boilerplate
include compose.mk
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))

# At this point, targets are defined for whatever services
# are mentioned in the external compose config, and they are
# ready to use. Now you can dispatch any task to any container!
test: ▰/k8s/self.test
self.test:
  kubectl --version
  echo hello world from `uname -n -v`
```


### Stand Alone Tools

If you're not interested in custom automation that requires project-Makefile integration, some features of `compose.mk` and `k8s.mk` can be used without that.  See the [Loading Compose Files](#loading-compose-files) docs, plus the [full CLI docs](/api) for more details.

--------------------------------

# compose.mk

A tool / library / automation framework for working with containers.  Also the biggest, baddest, and most highly-powered mutant Makefile you're ever likely to see, although this aspect is generally safe to ignore unless you're interested ;)

  * **Library-mode** extends `make` in a variety of ways, including support for working with containers (Docs: [[1]](#), [[2]](#), [[3]](#))
  * **Stand-alone mode also available,** i.e. a tool that requires no external Makefile / compose file. (Docs: [[1]](#))
  * **Zero host-dependencies,** as long as you have docker + make.  Even the [TUI backend](#embedded-tui) is dockerized.
  * **Container-dependencies are minimal too,** so that almost any base can work with [container-dispatch](#container-dispatch).
  * **Built-in TUI framework** that's small but powerful.  (See the [Embedded TUI docs](#embedded-tui) and the [tux.* API](/api#api-tux))
  * **A minimal, elegant, and dependency-free approach to describing workflow pipelines** (See the [flux.* API](/api#api-flux))
  
In many ways, `compose.mk` breaks all the rules that you can imagine for how you are *supposed* to use Makefiles, starting with the fact that it weighs in at ~3.5k lines.  But there's method to this madness, and hopefully you'll agree that the juice is worth the squeeze!  

Code-to-comment ratios throughout are roughly 1:1, and although it's not practical to measure code-coverage, [the test-suite](https://github.com/elo-enterprises/k8s-tools/tree/master/tests/) is pretty extensive.  The single-file approach used with `compose.mk` makes it easy to embed, and the API is quickly approaching a "frozen" status.  [Hacking is generally encouraged](#contributing), and users can feel free to rip out any parts of `compose.mk` they don't want or need.  With minor modifications, it's also easy to concatenate `compose.mk` and `k8s.mk` and use that, keeping one more piece of boilerplate out of your project repository.

### Library Mode

In library-mode, `compose.mk` is used as an `include` from your project Makefile.  With that as a starting place, you can **[build a bridge between docker-compose services and make-targets](#makecompose-bridge)** and use [**minimum viable patterns for container-dispatch.**](#container-dispatch).  The main macro is called *`compose.import`*, which can be used/included from any Makefile, used with any compose file, and [used with *multiple* compose files](#multiple-compose-files).  

Besides support for compose-files, `compose.mk` has many other features that extend the core capabilities of make, plus a *[curated collection of reusable utility targets](#composemk-api).  Here's an overview:


* 🚀 **Executable file:** `./compose.mk ...  <==> make -f compose.mk ...`
* Built-in supervisor process, [improving support for signal handling](#signals-and-supervisors).
* [**`flux.*` targets:**](/api#api-flux) A tiny but powerful workflow/pipelining API, roughly comparable to something like [declarative pipelines in Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/).  This provides composable concurrency & staging operators, where the primitives are usually make-target names.  
* [**`tux.*` targets:**](#embedded-tui) Control-surface for a tmux-backed console geometry manager.
  * **No host dependencies.** This uses the `compose.mk:tux` tool container to dockerize tmux itself.
  * **Supports docker-in-docker style host-socket sharing with zero configuration,** so your TUI can generally do all the same container orchestration tasks as the docker host.
  * Open split-screen displays, shelling into 1 or more of the tool containers in k8s-tools.yml (or any other compose file).
  * Combines well with `flux.*` targets to quickly create dashboards / custom development environments.
* [**`stream.*`:**](/api#api-stream) Support for working with streams, including newline/comma/space delimited streams, common use cases with JSON, etc.  Everything here is used with pipes, and reads from stdin.  It's not what you'd call "typed", but it reduces error-prone parsing and moves a little bit closer to structured data.
* [**`io.*`:**](/api#api-io) Misc. utilities for printing, formatting, timers, etc.
* [**`docker.*`:**](/api#api-docker) An interface for working with docker.
* [**`mk.*`:**](/api#api-docker) Meta-tooling for 'make' itself. This enables help functions, signals and supervisors, some utilities for reflection, etc.
* [**`compose.*`:**](/api#api-docker) An interface for working with compose.  


## Stand Alone Mode

**In Stand-alone Mode,** you can still use most of the features above but skip [the usual project integration](#embedding-tools-with-makefiles). 

Highlighting just a few random use-cases, you can:

* [Load compose files into TUIs](#loading-compose-files) with 1 shell per service,
* [Syntax-highlight files](/api/#iofilepreviewarg)
* [Build JSON with jb](/api#jb)
* [Parse JSON with jq](/api#jq)
* [Clean, refactor, or port existing bash script](#) towards something that's easier to read and write.

And lots more, all using local tools if available and falling back to dockerized tool-versions if necessary.

If you prefer to learn from examples, you might want to just [get started](#makecompose-bridge) or skip to the main [cluster automation demo](/demos#demo-cluster-automation) or to a [tui demo](#embedded-tui).  If you're the type that needs to hear the motivation first, read on in the next section.

## But Why?

There's many reasons why you might want these capabilities if you're working with tool-containers, builds, deploys, and complex task orchestration.  But why `make`?  People tend to have strong opions about this topic, and it's kind of a long story.

The short version is this:

1. Makefiles run practically everywhere and most people can read/write them.  
1. They're also really good at describing DAGs, and lots of automation, but *especially life-cycle automation*, is a natural fit for this paradigm.  

The only trouble is that **a)** *make has nothing like native support for tasks in containers*, and **b)** *describing the containers themselves is even further outside of its domain*.  Meanwhile, docker-compose is exactly the opposite.  

Make & Compose are already a strong combination for this reason, and by adding some syntactic sugar using *compose.mk*, you can orchestrate make-targets across several containers without cluttering your host.  More than that.. you can also bootstrap surprisingly sophisticated and flexible automation-APIs with surprisingly little effort.  

One reason this works so well is because with `make`, *the programmatic API basically <ins>is</ins> the CLI interface,* or to put it another way, once you have finished one of these you automatically have the other.

If you're interested in the gory details of a longer-format answer, see [the Design Philosophy docs](docs/but-why.md).

## Make/Compose Bridge

*`compose.mk`* provides lots of interfaces (i.e. automatically generated make targets) which are suitable for interactive use.  

Let's set aside the tool containers described inside k8s-tools.yml for now and walk through a much more minimal example, starting with a hypothetical compose file:

```yaml 
# example docker-compose.yml
services:
  debian:
    image: debian
  alpine:
    image: alpine 
```

Next, the Makefile.  To generate make-targets for every service in the given compose file, we just need to import the `compose.import` macro and call it.

```Makefile
# Inside your project Makefile
include compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))
```

The arguments *`(▰, TRUE)`* above allow for control of namespacing and syntax.  *(More on that later in the [Macro Arguments section](#macro-arguments).)*  The final argument is just the (unquoted) name of the file you want to import services from.  

That's it for the Make/Compose boilerplate, but we already have lots of interoperability.  

### Dynamic API

In general, the autogenerated targets created by [the bridge described above](#make-compose-bridge) fall into these categories:

Assuming `compose.import` was allowed to import to the root namespace:

* [**`<svc_name>`**](#target-svc_name)
* [**`<svc_name>`/shell**](#target-svc_nameshell)
* [**`<svc_name>`/shell/pipe**](#target-svc_nameshellpipe)
* [**`<svc_name>`/get_shell**](#target-svc_namespecial)

Assuming `compose.import` was used at all:

* [**`<compose_stem>`.services**](#target-compose_stemspecial)
* [**`<compose_stem>`.build**](#target-compose_stemspecial)
* [**`<compose_stem>`.clean**](#target-compose_stemspecial)
* [**`<compose_stem>`/`<svc>`**](#target-svc_nameshell)

See the sections below for more concrete examples.

#### **`<svc_name>`/shell** 

The **`<svc_name>`/shell** target drops to a containter shell for the named service, and is usually interactive.

```bash 

# Interactive shell on debian container
$ make debian/shell

# Interactive shell on "alpine" container
$ make alpine/shell
```

<img src="img/demo-bridge-shell.gif">


----------------------------------------------------

#### **`<svc_name>`/shell/pipe** 

The **`<svc_name>`/shell/pipe** target allows streaming data:

```bash
# Stream commands into debian container
$ echo uname -n -v | make debian/shell/pipe

# Equivalent to above, since the debian image's default entrypoint is bash
$ echo uname -n -v | make debian/pipe

# Streams command input / output between containers
echo echo echo hello-world | make alpine/pipe | make debian/pipe
```

<img src="img/demo-bridge-stream.gif">

----------------------------------------------------

#### **`<svc_name>`** 

The top-level **`<svc_name>`** target is more generic and can be used without arguments, or with optional explicit overrides for the compose-service defaults.  Usually this isn't used directly, but it's sometimes useful to call from automation.  Indirectly, most other targets are implemented using this target.

```bash 
# Runs an arbitrary command on debian container (overriding compose defaults)
$ entrypoint=ls cmd='-l' make debian

# Streams data into an arbitrary command on alpine container
$ echo hello world | pipe=yes entrypoint=cat cmd='/dev/stdin' make alpine
```

----------------------------------------------------

#### **`<svc_name>`/`<special>`**

Besides targets for working *with* services there are targets for answering questions *about* services.

The *`<svc_name>/get_shell`* targets answers what shell can be used as an entrypoint for the container. Usually this is `bash`, `sh`, or an error, but when there's an answer you'll get it in the form of an absolute path.

```bash

$ make debian/get_shell
/bin/bash
```

----------------------------------------------------

#### **`<compose_stem>/<svc>`**

Namespaced aliases are also available. Due to the file-stem of the compose file we imported, all of the stuff above will work on targets like you see below.

```bash
$ make docker-compose/debian
$ make docker-compose/debian/shell
```

Note that if `compose.import` uses a file name like `k8s-tools.yml` instead, the namespace is *`k8s-tools/<svc_name>`*.

----------------------------------------------------

#### **`<compose_stem>`.`<cmd>`**

Besides targets for working with compose-services, some targets work on the compose file itself.  Assuming your compose file is named `docker-compose.yml`, the special targets work like this:

```bash 

# Build (equivalent to `docker compose -f docker-compose.yml build`)
make docker-compose.build

# Build (equivalent to `docker compose -f docker-compose.yml stop`)
make docker-compose.stop

# Clean (equivalent to `docker compose -f docker-compose.yml down --remove-orphans`)
make docker-compose.clean

# List all services defined for file (Array of strings, xargs-friendly)
make docker-compose.services
```

Using the `<compose_stem>.services` target, it's easy to map a command onto every container.  Try something like this:

```bash 
$ make docker-compose.services | xargs -n1 -I% sh -x -c "echo uname -n |make docker-compose/%/shell/pipe"
```

### Make/Compose Bridge with k8s-tools.yml

This repo's [Makefile](Makefile) uses compose.mk macros to load services from [k8s-tools.yml](k8s-tools.yml), so that [the targets available at the project root](#tools-via-make) are similar to the ones above, but will use names like *`k8s, kubectl, k3d`* instead of *`debian, alpine`*, and will use *`k8s-tools/`* prefixes instead of *`docker-compose/`* prefixes.

```bash 

$ make k8s-tools.services
ansible
argo
awscli
aws-iam-authenticator
cdk
dind
eksctl
fission
graph-easy
gum
helm
helm-diff
helmify
helm-push
helm-unittest
jq
k3d
k8s
k9s
kind
kn
kompose
krew
kubeconform
kubectl
kubefwd
kubeseal
kustomize
lazydocker
promtool
rancher
tui
vals
yq
```

```bash 
$ echo k3d --version | make k8s-tools/k3d/shell/pipe 
k3d version v5.6.3
k3s version v1.28.8-k3s1 (default)
```

```bash 
$ make k8s/shell
⇒ k8s-tools/k8s/shell (entrypoint=/bin/bash)
▰ // k8s-tools // k8s container
▰ [/bin/bash] ⋘ <interactive>
k8s-base:/workspace$ 
```

See also the [TUI docs](#embedded-tui) for examples of opening up multiple container-shells inside a split-screen display.

## Container Dispatch

Let's look at a more complicated example where we want to use make to dispatch commands *into* the compose-service containers.  For this we'll have to change the boilerplate somewhat as we add more functionality.

```Makefile
# Makefile (make sure you have real tabs, not spaces)

include compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))

# New target declaration that we can use to run stuff
# inside the `debian` container.  The syntax conventions
# are configured by the `compose.import` call we used above.
demo: ▰/debian/self.demo

# Displays platform info to show where target is running.
# Since this target is intended to be private, we will 
# prefix "self" to indicate it should not run on host.
self.demo:
	source /etc/os-release && printf "$${PRETTY_NAME}\n"
	uname -n -v
```

The example above demonstrates another automatically generated target that uses some special syntax: `▰/<svc_name>/<target_to_dispatch>`.  This is just syntactic sugar that says that running `make demo` on the host runs `make self.demo` on the debian container.  Calling the top-level target looks like this:

<img src="/img/demo-dispatch.gif">

What just happend?  If we unpack the syntactic sugar even more, you could say that the following are roughly equivalent:

```bash
# pithy invocation with compose.mk
$ make demo

# the verbose alternative invocation
$ docker compose -f docker-compose.yml \
    run --entrypoint bash debian -c "make self.demo"
```

Let's add another target to demonstrate dispatch for multiple containers:

```Makefile
# Makefile (make sure you have real tabs, not spaces)

include compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))

# User-facing top-level target, with two dependencies
demo-double-dispatch: ▰/debian/self.demo ▰/alpine/self.demo

# Displays platform info to show where target is running.
# Since this target is intended to be private, we will 
# prefix "self" to indicate it should not run on host.
self.demo:
	source /etc/os-release && printf "$${PRETTY_NAME}\n"
	uname -n -v
```

The *`self`* prefix is just a convention, more on that in the following sections.  The above looks pretty tidy though, and hopefully helps to illustrate how the target/container/callback association works.  Running that looks like this:

<img src="/img/demo-double-dispatch.gif">

Meanwhile, the equivalent-but-expanded version below is getting cluttered, plus it breaks when files move or get refactored.

```bash
# pithy invocation with compose.mk
$ make demo-double-dispatch 

# verbose, fragile alternative
$ docker compose -f docker-compose.yml \
    run --entrypoint bash debian -c "make self.demo" \
  && docker compose -f docker-compose.yml \
    run --entrypoint bash alpine -c "make self.demo"
```

**This simple pattern for dispatching targets in containers is the main feature of `compose.mk` as a library, and it's surprisingly powerful.**  The next sections will cover macro arguments, and dispatch syntax/semantics in more detail.  If you're interested in a demo of how you can use this with k8s-tools.yml, you can skip to [this section](/demos/#cluster-automation-demo).

Container-dispatch with `compose.mk` can also autodetect what shell to use with the container (via the [`<svc_name>/get_shell` target](#target-svc_namespecial)).  Even better, the Makefile-based approach scales to lots of utility-containers in separate compose files, and can detect and prevent whole categories of errors (like typos in the name of the compose-file, service name, entrypoint, etc) at the start of a hour-long process instead of somewhere in the middle.  (See [docs for `make --reconn`](https://www.gnu.org/software/make/manual/html_node/Instead-of-Execution.html) to learn more about dry-runs).  If you are thoughtful about the ways that you're using volumes and file state, you can also consider using [`make --jobs` for parallel execution](https://www.gnu.org/software/make/manual/make.html#Parallel-Execution).

**To make this work as expected though, we do have to add more stuff to the compose file.**  In practice the containers you use might be ready, but if they are slim, perhaps not.  Basically, **if the subtarget is going to run on the container, the container needs to at least have:**  `make`, `bash` (or whatever shell the Makefile uses), and a volume mount to read the `Makefile`.  

```yaml
##
# tests/docker-compose.yml: 
#  A minimal compose file that works with target dispatch
##
services:
  debian: &base
    hostname: debian
    build:
      context: .
      dockerfile_inline: |
        FROM debian
        RUN apt-get update && apt-get install -y make procps
    entrypoint: bash
    working_dir: /workspace
    volumes:
      - ${PWD}:/workspace
  ubuntu: 
    <<: *base
    hostname: ubuntu
    build:
      context: .
      dockerfile_inline: |
        FROM ubuntu
        RUN apt-get update && apt-get install -y make procps
  alpine:
    <<: *base
    hostname: alpine
    build:
      context: .
      dockerfile_inline: |
        FROM alpine
        RUN apk add --update --no-cache coreutils alpine-sdk bash procps-ng

```

The debian/alpine compose file above and most of the interfaces described so far are all exercised inside [this repo's test suite](tests/).

## Macro Arguments

Make isn't big on named-arguments, so let's unpack the typical `compose.import` macro invocation.

```Makefile
include compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))
```

 **The 1st argument for `compose.import` is called `target_namespace`**.  You can swap the unicode for `▰` out, opting instead for different symbols, path-like prefixes, whatever.  If you're bringing in services from several compose files, one way to control syntax and namespacing is to use different symbols for different calls to `compose.import`.  (For a 2-file example, see the [Multiple Compose Files](#multiple-compose-files) section.)

**The 2nd argument for `compose.import` controls whether service names are available as top-level Makefile targets.**  The only value that means True is *`TRUE`*, because Make isn't big on bool types.  Regardless of the value here, service targets are always under `<compose_file_stem>/<compose_service_name>`. 

**The last argument for `compose.import` is the compose-file to load services from.**  It will be tempting to quote this and the other arguments, but that won't work, so resist the urge!

## Container Dispatch Syntax/Semantics

Let's look at the container-dispatch example in more detail.  This isn't a programming language you've never seen before, it's just a (legal) Makefile that uses unicode symbols in some of the targets.  

```Makefile
# A target that runs stuff inside the `debian` container, runs from host using `make demo`
demo: ▰/debian/self.demo

# Dispatching 1 target to 2 containers looks like this
demo-dispatch: ▰/debian/self.demo ▰/alpine/self.demo

# Displays platform info to show where target is running.
self.demo:
	source /etc/os-release && printf "$${PRETTY_NAME}\n"
	uname -n -v
```

The suggested defaults here will annoy some people, but the syntax is configurable, and this hopefully won't collide with existing file paths or targets.  Using the *`self`* prefix is just a convention that you can change, but having some way to guard the target from accidental execution on the host is a good idea.  This decorator-inspired syntax is also creating a convention similar to the idea of private methods: *`self`* hopefully implies internal/private, and it's not easy to type the weird characters at the command line.  So users likely won't think to call anything except `make demo`.  For people reading the code, the visual hints make it easy to understand what's at the top-level.

But what about the semantics?  In this example, the user-facing `demo` target depends on `▰/debian/demo`, which isn't really a target as much as a declaration.  The declaration means the *private* target `self.demo`, will be executed inside the `debian` container that the compose file defines.  *Crucially, the `self.demo` target can use tools the host doesn't have, stuff that's only available in the tool container.*  

Look, no `docker run ..` clutter littered everywhere!  Ok, yeah, it's still kind of a weird CI/CD DSL, but the conventions are simple and it's not locked inside Jenkins or github =)

Under the hood, dispatch is implemented by building on the [default targets that are provided by the bridge](#makecompose-bridge).

## Multiple Compose Files


This can be easily adapted for working with *multiple* compose files, but you'll have to think about service-name collisions between those files.  If you have two compose files with the same service name, you can use multiple target-namespaces like this:

```Makefile
# Makefile (Make sure you have real tabs, not spaces!)

# Load 1st compose file under paralleogram namespace,
# Load 2nd compose file under triangle namespace
include compose.mk
$(eval $(call compose.import, ▰, FALSE, my-compose-files/build-tools.yml))
$(eval $(call compose.import, ▲, FALSE, my-compose-files/cluster-tools.yml))

# Top-level "build" target that dispatches subtargets
# "build-code" and "build-cluster" on different containers
build: ▰/maven/build.code ▲/kubectl/build.cluster
build.cluster:
  kubectl .. 
build.code:
  maven ...
```

There's lots of ways to use this.  And if your service names across 2 files do not collide, you are free to put everything under exactly the same namespace.  It's only syntax, but if you choose the conventions wisely then it will probably help you to think and to read whatever you're writing.

Confused about what targets are available after using `compose.import`?  See the [`<compose_stem>.services`](#target-compose_stemcmd) for list services, and check out the `make help` output.

## Loading Compose Files

For the simplest use-cases where you have a compose-file, and want some of the compose.mk features, but don't have a project makefile, it's possible to skip some of the steps in the [usual integration](#embedding-tools-with-makefiles) by letting `loadf` generate integration for you just in time.

```bash 
$ ./compose.mk loadf <path_to_compose_file> <other_instructions>
```

Since `make` can't modify available targets from inside recipes, this basically works by creating temporary files that use the [compose.import macro](#macro-arguments) on the given compose file, then proxying subsequent CLI arguments over to *that* automation.  When no other instructions are provided, the default is to [open container shells in the TUI](#embedded-tui).

<a href=img/tui-3.gif><img src=img/tui-3.gif></a>

Actually any type of instructions you pass will get the compose-file context, so you can use any of the other targets documented as [part of the bridge](#make-compose-bridge) or the [static targets](/api#api-compose.mk).  For example:

<a href=img/tui-4.gif><img src=img/tui-4.gif></a>

Despite all the output this is pipe-safe, in case the commands involved might return JSON for downstream parsing, etc.  See the [Embedded TUI](#embedded-tui) docs for other examples that are using `loadf`.

## Embedded TUI 

<table align=center width=95%>
    <tr>
        <td><p align="center"><a href="img/tui-1.gif"><img width="200px" src="img/tui-1.gif"></a></p></td>
        <td><p align="center"><a href="img/tui-4.gif"><img width="200px" src="img/tui-4.gif"></a></p></td>
        <td><p align="center"><a href="img/tui-6.gif"><img width="200px" src="img/tui-6.gif"></a></p></td>
    </tr>
    <tr>
        <td><p align="center"><a href="img/tui-2.gif"><img width="200px" src="img/tui-2.gif"></a></p></td>
        <td><p align="center"><a href="img/tui-3.gif"><img width="200px" src="img/tui-3.gif"></a></p></td>
        <td><p align="center"><a href="img/tui-5.gif"><img width="200px" src="img/tui-5.gif"></a></p></td>
    </tr>
</table>

The basic components of the TUI are things like [tmux](https://github.com/tmux/tmux) for core drawing and geometry, [tmuxp](https://github.com/tmux-python/tmuxp) for session management, and overridable defaults for [tmux themes](https://github.com/jimeh/tmux-themepack/), [plugins](https://github.com/tmux-plugins/tpm), [keybindings](#tui-keybindings), etc.  These elements (plus other niceties like [gum](https://github.com/charmbracelet/gum) and [chafa](https://hpjansson.org/chafa/)) are all setup in the embedded `compose.mk:tux` container so that there are no host requirements for any of this except docker.

<img src=img/tui-5.gif>

How does this work?  The behaviour above relies on a few things.  First, the `compose.mk:tux` container supports docker-in-docker style host-socket sharing with zero configuration.  This means that the TUI can generally do all the same container orchestration tasks as the docker host.  

Without actually writing any custom code, there are many ways to customize the way that the TUI starts and the stuff that's running inside it.  By combining the TUI with the [`loadf` target,](#loading-compose-files) you can leverage existing compose files but skip [the usual integration with a project Makefile](/integration).

<img src=img/tui-1.gif>

One way to look at the TUI is that it's just a way of mapping make-targets into tmux panes.  So you don't actually have to use targets that are related to containers.

<img src=img/tui-2.gif>

#### TUI Keybindings

| ---------------- | ------------------------------------------------------ |
| Escape           | *Exit TUI*                                             |
| Ctrl b |         | *Split pane vertically*                                |
| Ctrl b -         | *Split pane horizontally*                              |
| Alt t            | *Shuffle pane layout*                                  |
| Alt ^            | *Grow pane up*                                         |
| Alt v            | *Grow pane down*                                       |
| Alt <            | *Grow pane left*                                       |
| Alt >            | *Grow pane right*                                      |
| Alt <left>       | *Grow pane left*                                       |
| Alt <right>      | *Grow pane right*                                      |
| Alt <up>         | *Grow pane up*                                         |
| Alt <down>       | *Grow pane down*                                       |
| Alt-1            | *Select pane 1*                                        |
| Alt-2            | *Select pane 2*                                        |
| ...              | *...*                                                  |


## Signals and Supervisors


 
 ### Motivation 
 
 Without [forking make](https://remake.readthedocs.io/en/latest/), there's no simple method to get hooks into the default way that it handles interrupts and signals.  But why would you want to anyway?  Most of the time this occurs to people [it's about cleanup](https://www.gnu.org/software/make/manual/html_node/Interrupts.html), but `compose.mk` doesn't exactly look like traditional use-cases.
 
The main reason to care is that short-circuiting make's default CLI option parsing is *really useful*.  Especially since `compose.mk` allows us to "wrap" lots of containerized tools, we want to be able to proxy arguments over to those tools without `make` being greedy about parsing everything.

The [`loadf` command](#loading-compose-file) is a typical example: the 2nd argument, a filename, must not be parsed as a Makefile target:

```bash
# Opens all shells for each service in the given file inside the TUI
./compose.mk loadf tests/docker-compose.yml
```
 
Sometimes we want individual targets to essentially be able to consume the rest of the command line.  In this case, the filename is best understood as an argument to the first target, and not a target itself.
 
The [wrapper for jb](docs/api/#jb) is another example of an invocation that requires reading the whole command-line.  And for targets created with [`compose.import`](#makecompose-bridge), the [special form with '--'] (#special-form) also requires this kind of short-circuiting.

### Implementation






 
* [mk.supervisor.enter/<arg>](docs/api#mk.supervisor.enterarg) 
* [mk.supervisor.exit/<arg>](docs/api#mk.supervisor.exitarg) 
* [mk.supervisor.interrupt](docs/api#mk.supervisor.interrupt) 
* [mk.supervisor.interrupt/<arg>](docs/api#mk.supervisor.interruptarg) 
* [mk.supervisor.pid](docs/api#mk.supervisor.pid) 
* [mk.supervisor.trap/<arg>](docs/api#mk.supervisor.traparg) 
* [mk.interrupt](docs/api#mk.interrupt) 
* [mk.interrupt/<arg>](docs/api#mk.interruptarg) 
* [mk.interrupt/SIGINT](docs/api#mk.interruptSIGINT) 



--------------------------------

## k8s.mk

`k8s.mk` exists to create automation APIs over the tool-containers that are described in k8s-tools.yml, and includes lots of helper targets for working with Kubernetes.  It works best in combination with [compose.mk](/compose.mk) and [k8s-tools.yml](#features), but in many cases that isn't strictly required if things like `kubectl` are already available on your host.  

The focus is on simplifying a few categories of frequent challenges:

1. **Reusable implementations for common cluster automation tasks,** like [waiting for pods to get ready](/api#k8s.wait)
1. **Context-management tasks,** (like [setting the currently active namespace](/api#k8snamespacearg))
1. **Interactive debugging tasks,** (like [shelling into a new or existing pod inside some namespace](/api#k8sshellarg))

The full API is [here](/api/#api-k8smk), and the [Cluster Lifecycle Demo](/demos#demo-cluster-automation) includes a walk-through of using it from your own project automation.  

By combining these tools with compose.mk's [`flux.*` API](/api#api-flux) you can describe workflows, and using the [`tux.*` API](/api#api-tux) you can send tasks, or groups of tasks, into panes on a TUI.


### Automation APIs over Tool Containers

What *is* an automation API over a tool container anyway?  As an example, let's consider the [`k8s.get` target](/api/#k8sget), which you might use like this:

```bash
# Usage: k8s.get/<namespace>/<kind>/<name>/<filter>
$ KUBECONFIG=.. ./k8s.mk k8s.get/argo-events/svc/webhook-eventsource-svc/.spec.clusterIP

# roughly equivalent to:
$ kubectl get $${kind} $${name} -n $${namespace} -o json | jq -r $${filter}"
```

The first command has no host requirements for `kubectl` or `jq`, but uses both via docker.  Similarly, the [`helm.install` target](/api#helm.install) works as you'd expect but does not require `helm` ( and plus it's a little more idempotent than using `helm` directly).  Meanwhile `k8s.mk k9s/<namespace>` works like `k9s --namespace` does, but doesn't require k9s.

Many of these targets are fairly simple wrappers, but just declaring them accomplishes several things at once.

The typical `k8s.mk` entrypoint is:

1. CLI friendly, for interactive contexts, as above
1. API friendly, for more programmatic use, as part of the prereqs or the body for other project automation
1. Workflow friendly, either as part of `make`'s native DAG processing, or via [flux](/api#api-flux).
1. Potentially a TUI element, via the [embedded TUI](/#embedded-tui) and [tux](/api#tux).
1. Context-agnostic, generally using tools directly if available or falling back to docker when necessary.

Some targets like [`k8s.shell`](/api/#k8sshell) or [`kubefwd.[start|stop|restart]`](/api/#kubefwd) are more composite than simple wrappers, and achieve more complex behaviour by orchestrating 1 or more commands across 1 or more containers.  See also the [ansible wrapper](/api#api-ansible), which exposes a subset of `ansible` without all the overhead of inventories & config.

If you want you can always to stream arbitrary commands or scripts into these containers more directly, via [the Make/Compose bridge](#makecompose-bridge), or write your own targets that run inside those containers.  But the point of `k8s.mk` is to ignore more of the low-level details more of the time, and start to compose things.  For example, here's a one-liner that creates a namespace, adds a label to it, launches a pod there, and shells into it:

```bash 
$ pod=`uuidgen` \
&& namespace=testing \
&& ./k8s.mk \
    k8s.kubens.create/${namespace} \ \
    k8s.namespace.label/$${namespace}/mylabel/value
    k8s.test_harness/${namespace}/${pod} \
    k8s.namespace.wait/${namespace} \
    k8s.shell/${namespace}/${pod}
```


### But Why?

There's many reasons why you might want these capabilities if you're working with cluster-lifecycle automation.  People tend to have strong opions about this topic, and it's kind of a long story.  The short version is this: 

* Tool versioning, idempotent operations, & deterministic cluster bootstrapping are all hard problems, but not really the problems we *want* to be working on.
* IDE-plugins and desktop-distros that offer to manage Kubernetes are hard for developers to standardize on, and tend to resist automation.  
* Project-local clusters are much-neglected, but also increasingly important aspects of project testing and overall developer-experience.  
* Ansible/Terraform are great, but they have a lot of baggage, aren't necessarily a great fit for this type of problem, and they also have to be versioned.  

`k8s.mk`, especially combined with `k8s-tools.yml` and `compose.mk`, is aimed at fixing this stuff.  

If you're interested in the gory details of a longer-format answer, see [the Design Philosophy docs](docs/but-why.md).



--------------------------------


## Contributing

Since this project generally aims at providing extensible boilerplate for use with other projects, we use [the unlicense](https://choosealicense.com/licenses/unlicense/) and hope that accomodates any kind of spin-offs and variations that might be of interest to people.

You're free to copy this code into your repository and start ripping out pieces and adding new ones.  Forking aggressively and not looking back doesn't make sense for many kinds of upstreams, but in this case there is no package manager for `make`, and no one wants a submodule for a few files.  Besides, in some cases removing parts of the API you know you don't need may improve performance (for example with target tab completion).

If you can keep the maiming to a minimum though and make something cool that also feels sufficiently generic, please do consider contributing back to upstream!

As mentioned elsewhere, `k8s.mk` is growing slowly but the goal is to freeze the [compose.mk API](/api#api-composemk) in place fairly soon.  That said.. any interesting feature requests will definitely be considered.  If you're up for it, the best way to spec out a feature-request is always to add a new failing testing with interface you're proposing.

--------------------------------

# Known Limitations and Issues

#### KUBECONFIG should already be set 

We fake it for builds/tests, but note that **`KUBECONFIG` generally must be set for things to work!**  Sadly, lots of tools will fail even simple invocations like `helm version` or even `--help` if this is undefined or set incorrectly, and it will often crash with errors that aren't very clear.

Dealing with per-project KUBECONFIGs is best, where you can set that inside your project Makefile and be assured of no interference with your main environment.  Alternatively, use bashrc if you really want globals, or provide it directly as environment variable per invocation using something like `KUBECONFIG=.. make <target_name>`.

#### Working Directories

By default, the compose file shares the working directory with containers it's using as volumes.  **This means files you're using should be inside or somewhere below the working directory!**  The compose file itself can be anywhere though, so instead of keeping it in your projects source-tree you can decide to deploy it separately to `/opt` or `~/.config`

#### General Argument Passing

Unfortunately, there's not a good way to convince `make` to just proxy arguments without parsing them.  **For example `./k8s.mk kubectl apply -f` looks convenient, but it won't work.**  (It will instead parse `apply -f` as arguments to make.)  

The simplest workaround is to just use `cmd="apply ..." ./k8s.mk kubectl`.  However if [supervisors and signals](#supervisors-and-signals) are supported, then you can use the special form ' -- ', as in "./k8s.mk kubectl -- version --client".  See also [the smoke-tests](https://github.com/elo-enterprises/k8s-tools/tree/master/tests/Makefile.smoke-test-k8s.mk).

#### Docker and File Permissions 

The usual problem with root-user-in-containers vs normal-user on host and file permissions.  The alpine base is a container using root, as are many other things.  And there is a long-standing [known bug in the compose spec](https://github.com/compose-spec/compose-go/pull/299) that makes fixing this from the compose file hard.  

Invoking compose exclusively from a Makefile actually helps with this though.  By default with [compose.mk](/compose.mk), `DOCKER_UID | DOCKER_GID| DOCKER_UGNAME` variables are set and available for use in [k8s-tools.yml](k8s-tools.yml).  This works slightly differently for Linux and MacOS, based on what messes things up the least, but YMMV.  With Linux, it looks something like this:

```Makefile
export DOCKER_UID?=$(shell id -u)
export DOCKER_GID?=$(shell getent group docker | cut -d: -f3 || id -g)
export DOCKER_UGNAME?=user
```

If you're not working with Makefiles at all, you can export appropriate values in .bashrc or .env files you use.  If none of this is appealing, and you mix host-local and dockerized usage of things like helm, then you may end up with weird file ownership.  You can fix this if it comes up using `sudo chown -R $USER:$USER .`.  

#### MacOS, Docker Sockets, and DinD

As long as docker is working, any kind of setup (Docker Desktop, Rancher Desktop, Colima) can work with `compose.mk` for container-dispatch.  But for working with `k8s-tools.yml` containers specifically, the docker-socket sharing *must also be working*.  If you're having problems that might be related to this, first make sure that your setup can correctly run this command:

```bash 
$ docker run -v /var/run/docker.sock:/var/run/docker.sock -ti docker ps
```

If the volume mount is working correctly, the result here should look the same as `docker ps` from your host.  If your docker socket is in a different place (like `~/.rd/docker.sock` for Rancher Desktop), you may need to symlink the file.

MacOS Docker desktop can be especially annoying here, and it seems likely the same is true for windows.  YMMV, but as of 2024 sharing the socket may mean required changes from the UI preferences, and/or enabling/disabling virtualization backends.  Another way the problem can manifest is an error like this:

```ini 
You can configure shared paths from Docker -> Preferences... -> Resources -> File Sharing.
See https://docs.docker.com/desktop/mac for more info.
```

If you want better parity with docker in Linux, you might like to checkout Colima/Rancher.

#### Pipes & Temp Files 

Working with streaming pipes generates temporary files with `mktemp`, removing them when the process exits with `trap`.  Pure streams would be better.  Also in many cases tmp files need to be in the working directory, otherwise they can't be shared by docker volumes.  Moving to a temp-dir based approach would be better.

--------------------------------

