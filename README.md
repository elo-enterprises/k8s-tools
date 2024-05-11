
<table style="width:100%">
  <tr>
    <td colspan=2><strong>
    k8s-tools
      </strong>&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
  </tr>
  <tr>
    <td width=15%><img src=img/icon.png style="width:150px"></td>
    <td>
      Dockerized version of a kubernetes toolchain
      <br/><br/>
      <a href="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml"><img src="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml/badge.svg"></a>
    </td>
  </tr>
</table>

-------------------------------------------------------------

<div class="toc">
<ul>
<li><a href="#overview">Overview</a></li>
<li><a href="#features">Features</a></li>
<li><a href="#quick-start">Quick Start</a><ul>
<li><a href="#clonebuildtest-this-repo">Clone/Build/Test This Repo</a></li>
<li><a href="#tools-via-compose-cli">Tools via Compose CLI</a></li>
<li><a href="#tools-via-make">Tools via Make</a></li>
</ul>
</li>
<li><a href="#integration">Integration</a><ul>
<li><a href="#embedding-tools-with-aliases">Embedding Tools With Aliases</a></li>
<li><a href="#embedding-tools-with-makefiles">Embedding Tools With Makefiles</a></li>
</ul>
</li>
<li><a href="#makefilecomposemk">Makefile.compose.mk</a><ul>
<li><a href="#but-why">But Why?</a></li>
<li><a href="#makecompose-bridge">Make/Compose Bridge</a></li>
<li><a href="#container-dispatch">Container Dispatch</a></li>
<li><a href="#macro-arguments">Macro Arguments</a></li>
<li><a href="#dispatch-syntaxsemantics">Dispatch Syntax/Semantics</a></li>
<li><a href="#multiple-compose-files">Multiple Compose Files</a></li>
<li><a href="#bonus-context-management-for-host-shells">Bonus: Context Management for Host Shells</a></li>
</ul>
</li>
<li><a href="#known-limitations-and-issues">Known Limitations and Issues</a></li>
</ul>
</div>


-------------------------------------------------------------

## Overview

This repository aggregates a bunch of individual utilities for working with kubernetes into one dockerized toolchain.  It's useful for CI/CD pipelines but also fixes the problem of different project developers using different local versions of things like `helm`.

The containers defined here aren't built from scratch, leveraging official sources where possible.  Most tools (like `kubectl`, `helm`, etc) come from [alpine/k8s](https://hub.docker.com/r/alpine/k8s) but other tools are also included (like `k9s`, `k3d`).

This isn't an attempt to build an omnibus "do-everything" container, it's more a response to the fact that there are a lot of diverse tools that really can't be unified, so it's better to just learn how to work with that.

Besides bundling some tooling, this repository is the reference implementation of a pattern for [bridging compose services and Makefile targets](#Makefile.compose.mk), providing a minimum viable framework for orchestrating tasks across those tool containers. This pattern makes it easy to read/write/run those tasks, and makes it easier to avoid lock-in from things like Jenkinsfiles or Github Actions.



-------------------------------------------------------------

## Features

The local parts of the tool bundle. See the [docker-compose.yml](docker-compose.yml) for more details.

* [helmify](https://github.com/arttor/helmify)
* [kn](https://knative.dev/docs/client/install-kn/)
* [fission](https://fission.io/docs/installation/)
* [k3d](https://k3d.io/)
* [k9s](https://k9scli.io/)
* [kompose](https://kompose.io/)

Plus the stuff from the upstream tool bundle. [See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.

* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [kustomize](https://github.com/kubernetes-sigs/kustomize)
* [helm](https://github.com/helm/helm)
* [helm-diff](https://github.com/databus23/helm-diff)
* [helm-unittest](https://github.com/helm-unittest/helm-unittest)
* [helm-push](https://github.com/chartmuseum/helm-push)
* [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
* [eksctl](https://github.com/weaveworks/eksctl)
* [awscli v1](https://github.com/aws/aws-cli)
* [kubeseal](https://github.com/bitnami-labs/sealed-secrets)
* [krew](https://github.com/kubernetes-sigs/krew)
* [vals](https://github.com/helmfile/vals)
* [kubeconform](https://github.com/yannh/kubeconform)
* General tools, such as bash, curl, jq, yq, etc

Plus macros for working with compose from makefiles (see [Makefile.compose.mk](#makefile.compose.mk) section).

Note that if you're only interested in the upstream stuff from `alpine/k8s`, the compose file is nicer than the alternative huge `docker run ..` commands, because it sets up volumes for you to share the docker socket, and shares kubeconfigs for you automatically.

-------------------------------------------------------------

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

----------------------------------------------------

### Tools via Compose CLI

```bash
$ docker compose run base ...
$ docker compose run helm ...
$ docker compose run kubectl ...
$ docker compose run kustomize ...
$ docker compose run helm-diff ...
$ docker compose run helm-unittest ...
$ docker compose run helm-push ...
$ docker compose run aws-iam-authenticator ...
$ docker compose run eksctl ...
$ docker compose run awscli ...
$ docker compose run kubeseal ...
$ docker compose run krew ...
$ docker compose run vals ...
$ docker compose run kubeconform ...
$ docker compose run kn ...
$ docker compose run helmify ...
$ docker compose run fission ...
$ docker compose run kompose ...
$ docker compose run k3d ...
$ docker compose run k9s ...
$ docker compose run yq ...
$ docker compose run jq ...
```

----------------------------------------------------

### Tools via Make 

Commands like this will work at the repository root.  

```bash 
# run k9s container (intreractive)
$ make k9s

# run helmify (which expects stdin)
$ cat manifest.yml | make helmify/pipe

# run kubectl, which can be used directly or with pipes 
$ cmd='apply -f manifest.yml' make kubectl
$ cat manifest.yml | make kubectl/pipe cmd='apply -f -'

# drop to a shell to work with helm (interactive; . is already a volume)
$ make helm/shell

# get cluster info from k3d
$ make k3d cmd='cluster list -o json'
```

For more details on other targets available, how this works in general, and what else you can do with it.. read on in [this section](#makecompose-bridge).

----------------------------------------------------

## Integration 

You can embed the k8s-tools suite in your project in two ways, either with some kind of global compose file and global aliases, or with a more project-based approach using Makefiles.

----------------------------------------------------

### Embedding Tools With Aliases

For using this pattern with your existing projects, you might want to maintain separated compose files and setup aliases.

```bash
$ cd myproject

# or use your fork/clone..
$ curl -sL https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/docker-compose.yml > k8s-tools.yml

$ alias helm=docker compose -f myproject/k8s-tools.yml run helm

$ helm ....
```

Aliases are convenient but rather fragile (obviously this will break if you move your `myproject` folder around).  See the next section for something that is a little more durable.

----------------------------------------------------

### Embedding Tools With Makefiles

You'll probably want to read over the [Makefile.compose.mk](#Makefile.compose.mk) section to understand what's going on here.  In case you've already seen it though, here's the quick start with the copy/paste stuff for using the `compose.import` macro with your projects.



First, copy the files from this repo into your project:

```bash
$ cd myproject 

# or use your fork/clone..
$ curl -sL \
  https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/docker-compose.yml \
    > k8s-tools.yml

$ curl -sL \
  https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/Makefile.compose.mk \
    > Makefile.compose.mk
```

Now include `Makefile.compose.mk` inside your main project Makefile and call the `compose.import` macro.

```Makefile
# myproject/Makefile (Make sure you have real tabs, not spaces!)
 
# Include/invoke the target-building macros 
# somewhere near the top of your existing boilerplate
include Makefile.compose.mk
$(eval $(call compose.import, ▰, ↪, TRUE, k8s-tools.yml))

# At this point, targets are defined for whatever services
# are mentioned in the external compose config, and they are
# ready to use. Now you can dispatch any task to any container!
test: ▰/kubectl/test
↪test:
  kubectl --version
  echo hello world from `uname -n -v`
```


Skip to the sections describing the [Make/Compose bridge](#makecompose-bridge) and [Container Dispatch](#container-dispatch) for more details.

---------------------------------------------------------------

## Makefile.compose.mk

This repository includes Makefile macros which can **build a bridge between docker-compose services and make-targets**, and provide a minimum viable pattern for container-dispatch.  The main macro is called `compose.import`, which can be used/included from any Makefile, used with any compose file, and used with *multiple* compose files (more on that later).  

### But Why?

There's a few reasons why you might care about something like this in the context of tool-containers, builds, and complex task orchestration:

* **Tool containers are much more useful when you can easily dispatch commands to them,** especially without some extremely long CLI invocation.  A compose file specifying volumes and such helps a lot, but, *you don't want `docker compose run ...` littered all over your scripts for builds and orchestration*.  
* **Everyone knows that plain shell scripts won't take you far.** There's lots of reasons for this but to name a few... option/argument parsing, code-reuse, reentrant behaviours, and other things you're going to need aren't simple to get. Configuration management tools like Ansible can fix this, but bring their own problems, including: significant setup, significant dependencies, ongoing upstream changes, and the fact that many people cannot read or write it.
* **Orchestration *between* or *across* tool containers is usually awkward.** This is a task that needs some structure imposed, and while you can get that structure in lots of ways, it's always frustrating to see your work locked into esoteric JenkinsFile / GitHubAction blobs where things get complicated to describe, run, or read.  Project automation ideally needs to run smoothly both inside and outside of CI/CD.
* **If running commands against several containers is easy, then there is less need to try and get everything into *one* tool container**, which can be pretty hard if very different bases are involved.
* **Make is actually the happy medium here;** it is old but it is everywhere, it's expressive if not always *easy*, and it's fast.  It's the lingua franca for engineers, devops, and data-science.  Just as important.. `make` is probably the *least* likely thing in your toolkit to be affected by externalities like pip breakage, package updates, or changing operating systems completely.  If you need something *outside* of docker that you want stability & ubiquity from, it's hard to find a better choice.  

The only problem is.. **Makefiles have nothing like native support for running tasks in containers**.  So let's fix that!  Makefiles are already pretty good at describing task execution, but describing the containers themselves is outside of that domain.  Meanwhile, docker-compose is exactly the opposite, and so Make/Compose is a perfect combination.

Enough philosophy, let's dive into examples.

----------------------------------------------------

### Make/Compose Bridge

Makefile.compose.mk provides lots of interfaces (i.e. automatically generated make targets) which are suitable for interactive use.  Let's consider a a minimal example, starting with a hypothetical the compose file:

```yaml 
# docker-compose.yml
services:
  debian:
    image: debian
  alpine:
    image: alpine 
```

Next, the Makefile.  Here we just need to import macros and call them, and `compose.import` will generate make-targets for every service in the given compose file.  

```Makefile
# Makefile
include Makefile.compose.mk
$(eval $(call compose.import, ▰, ↪, TRUE, docker-compose.yml))
```

The arguments *`(▰, ↪, TRUE,)`* above allow for control of namespacing and syntax.  (More on that later in the [Macro Arguments section](#macro-arguments)).

That's it for the Make/Compose boilerplate, but we already have lots of functionality that ties these two contexts together.  Here's some examples of what the automatically generated targets are, and how you can use them.

```bash 

# Runs bash on debian (interactive)
$ make debian/shell

# Runs sh on alpine (automatically detects that bash is missing)
$ make alpine/shell

# Streams commands into debian
$ echo uname -n -v | make debian/shell/pipe

# Equivalent to above, since the debian image's default entrypoint is bash
$ echo uname -n -v | make debian/pipe

# Runs an arbitrary command on debian
$ entrypoint=ls cmd='-l' make debian

# Streams data into an arbitrary command on alpine
$ echo hello world | pipe=yes entrypoint=cat cmd='/dev/stdin' make alpine

# Streams command input / output between containers
echo echo echo hello-world | make alpine/pipe | make debian/pipe

# Equivalently, due to the stem of the compose-file we imported,
# all of the stuff above will work on namespaced targets under like this.
# (if we compose.import'ed from k8s-tools.yml, namespace is 'k8s-tools/' instead)
$ make docker-compose/debian
$ make docker-compose/debian/shell

# Lists all compose services under file
make docker-compose/__services__

# Lists user-facing make-targets (skipping the internal ones)
make help
```

This repo's [Makefile](Makefile) / [docker-compose.yml](docker-compose.yml) are also using Makefile.compose.mk macros, so the [targets available at the project root](#tools-via-make) are similar, but will use the tool names like kubectl / k3d / etc.

----------------------------------------------------

### Container Dispatch

Let's look at a more complicated example with container dispatch.  

For this we'll have to change the boilerplate somewhat as we add more functionality.

```Makefile
# Makefile (make sure you have real tabs, not spaces)

include Makefile.compose.mk
$(eval $(call compose.import, ▰, ↪, TRUE, docker-compose.yml))

# New target declaration that we can use to run stuff
# inside the `debian` container.  The syntax conventions
# are configured by the `compose.import` call we used above
demo: ▰/debian/demo
↪demo:
  uname -n -v

# Another target, dispatching ↪demo target to each of 2 containers
demo-double-dispatch: ▰/debian/demo ▰/alpine/demo
```

**This simple pattern for dispatching targets into containers is the main feature of `Makefile.compose.mk` as a library, and it's surprisingly powerful.**  The next sections will cover macro arguments, syntax, and semantics in more detail.  If you're interested in seeing a non-toy example of how you can use this, check out [the build for this FaaS-on-K3d cluster](https://github.com/elo-enterprises/k3d-faas/tree/main/Makefile).  

To make this work as expected though, we do have to add more stuff to the compose file.  In practice the containers you use might be ready, but if they are slim, perhaps not.  Basically, if the subtarget is going to run on the container, the container needs to at least have:  `make` itself, `python` with yaml capabilities to parse the compose-file, and a volume mount to read `Makefile`.  Here's a minimal compose file that works with target-dispatch:

```yaml
# docker-compose.yml
services:
  debian: &base
    build:
      context: .
      dockerfile_inline: |
        FROM python:slim
        RUN apt-get update && apt-get install -y make
    entrypoint: bash
    working_dir: /workspace
    volumes:
      - ${PWD}:/workspace
  alpine:
    <<: *base
    build:
      context: .
      dockerfile_inline: |
        FROM python:alpine
        RUN apk add --update --no-cache alpine-sdk bash

```

The debian/alpine compose file above and most of the interfaces described so far are all exercised inside [this repo's test suite](tests/).

----------------------------------------------------

### Macro Arguments 

Let's unpack the arguments you can use with the Macro. 

```Makefile
include Makefile.compose.mk
$(eval $(call compose.import, ▰, ↪, TRUE, docker-compose.yml))
```

Make isn't big on named-arguments, but the **1st argument for `compose.import` is called `target_namespace`**, and the **2nd argument for `compose.import` is called `dispatch_prefix`**.  You can swap the unicode for `▰` and `↪` out, opting instead for different symbols, path-like prefixes, whatever.  If you're bringing in services from several compose files, one way to control syntax and namespacing is to use different symbols for different calls to `compose.import`.  See the [Integration section](#integration) below for 2-file example.

**The 3rd argument for `compose.import` controls whether service names are available as top-level Makefile targets.**  The only value that means True is *`TRUE`*, because Make isn't big on bool types.  Regardless of the value here, service targets are always under `<compose_file_stem>/<compose_service_name>`. 

**The last argument for `compose.import` is the compose file to load services from.**  It will be tempting to quote this and the other arguments, but that won't work, so resist the urge.

----------------------------------------------------

### Dispatch Syntax/Semantics

Let's look at the container-dispatch example in more detail.  In the words of Whitehead.. *By relieving the brain of all unnecessary work, a good notation sets it free to concentrate on more advanced problems*.  

```Makefile
# A target that runs stuff inside the `debian` container, 
# which is runnable from host using `make demo`.
demo: ▰/debian/demo
↪demo:
  uname -n -v

# Dispatching one make target to two containers looks like this
demo-dispatch: ▰/debian/demo ▰/alpine/demo
```

This isn't a programming language you've never seen before, it's just a (legal) Makefile that uses unicode symbols in some of the targets.  

This decorator-inspired syntax is creating a convention similar to the idea of private methods: it's not easy to type the weird characters at the command line, and it's not supposed to be.  So here, users won't ever call anything except `make demo`.  For people reading the code, the visual hints make it easy to understand what's at the top-level.

But what about the semantics?  In this example, the user-facing `demo` target depends on `▰/debian/demo`, which isn't really a target as much as a declaration.  The declaration means the *private* target `↪demo`, will be executed inside the `debian` container that the compose file defines.  *Crucially, the `↪demo` target can use tools the host doesn't have, stuff that's only available in the tool container.*  Look, no `docker run ..` clutter littered everywhere!  Ok, ok, it's kind of a weird CI/CD DSL, but the conventions are simple and it's not locked inside Jenkins or github.

Under the hood, dispatch works by using the [default targets that are provided by the bridge](#makecompose-bridge).

---------------------------------------------------------------

### Multiple Compose Files

This can be easily adapted for working with *multiple* compose files, but you'll have to think about service-name collisions between those files.  If you have two compose files with the same service name, you can use multiple target-namespaces like this:

```Makefile
# Makefile (Make sure you have real tabs, not spaces!)

# Load 1st compose file under paralleogram namespace,
# Load 2nd compose file under triangle namespace
include Makefile.compose.mk
$(eval $(call compose.import, ▰, ↪, FALSE, mycomposefiles/build-tools.yml))
$(eval $(call compose.import, ▲, ↪, FALSE, mycomposefiles/cluster-tools.yml))

# Top-level "build" target that dispatches subtargets
# "build-code" and "build-cluster" on different containers
build: ▰/maven/build-code ▲/kubectl/build-cluster
↪build-cluster:
  kubectl .. 
↪build-code:
  maven ...
```

There's lots of ways to use this.  And if your service names across 2 files do not collide, you are free to put everything under exactly the same namespace.  It's only syntax, but if you choose the conventions wisely then it will probably help you to think and to read whatever you're writing.

Confused about what targets are available after using `compose.import`?  Don't forget about these special targets that can help:

```bash
# the 'help' target provided by Makefile.compose.mk lists
# most targets, but not the dispatch-related ones.
make help

# the special target __services__ can list services per compose file
 make cluster-tools/__services__
 make build-tools/__services__
```

---------------------------------------------------------------

### Bonus: Context Management for Host Shells

We've talked about container shells, but project-based manipulation of *host* shells can also be useful.

If your project requires several environment variables (say `KUBECONFIG` & `CLUSTER_NAME`), you can drop into a host shell *starting* from the Makefile using `make shell` and you'll have access to those variables, or a subset of those variables, without jamming stuff into your bashrc.  It's not just a convenience, but it's also *safer* than potentially mixing up your dev/prod KUBECONFIGs =)

```Makefile
# myproject/Makefile (Make sure you have real tabs, not spaces!)

bash:
	@# Full shell, inheriting the parent environment (including `export`s from this Makefile)
  env bash -l

ibash:
  @# An isolated shell, no environment passed through.
	env -i bash -l

pbash:
  @# Passing a partial environment, only the $USER var
	env -i `env|grep USER` bash -l
```

Now if you want to ensure that you've switched context as appropriate, you can run `make bash` from your project root.

-------------------------------------------------------------

# Known Limitations and Issues

1. We fake it for builds/tests, but note that **`KUBECONFIG` generally must be set for things to work!**  Sadly, lots of tools will fail even simple invocations like `helm version` or even `--help` if this is undefined or set incorrectly, and it will often crash with errors that aren't very clear.
1. By default, the compose file shares the working directory with containers it's using as volumes.  **This means files you're using should be inside or somewhere below the working directory!**  The compose file itself can be anywhere though, so instead of keeping it in your projects source-tree you can decide to deploy it separately to `/opt` or `~/.config`
1. Unfortunately, there's not a good way to convince `make` to just proxy arguments without parsing them.  **For example `make kubectl apply -f` looks convenient, but it won't work.**  It will parse `apply -f` as arguments to make.
1. Working with streaming pipes currently generates temporary files with `mktemp`, removing them when the process exits with `trap`.  This is a hack that needs to be fixed, pure streams would be better.
