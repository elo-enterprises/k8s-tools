
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
<li><a href="#integration-with-your-project">Integration With Your Project</a><ul>
<li><a href="#embedding-tools-with-aliases">Embedding Tools With Aliases</a></li>
<li><a href="#embedding-tools-with-makefiles">Embedding Tools With Makefiles</a></li>
</ul>
</li>
<li><a href="#makefilecomposemk">Makefile.compose.mk</a><ul>
<li><a href="#but-why">But Why?</a></li>
<li><a href="#makecompose-bridge">Make/Compose Bridge</a></li>
<li><a href="#with-k8s-toolsyml">With k8s-tools.yml</a></li>
<li><a href="#container-dispatch">Container Dispatch</a></li>
<li><a href="#macro-arguments">Macro Arguments</a></li>
<li><a href="#container-dispatch-syntaxsemantics">Container Dispatch Syntax/Semantics</a></li>
<li><a href="#multiple-compose-files">Multiple Compose Files</a></li>
<li><a href="#static-targets-for-makefilecomposemk">Static Targets for Makefile.compose.mk</a></li>
</ul>
</li>
<li><a href="#makefilek8smk">Makefile.k8s.mk</a><ul>
<li><a href="#static-targets-for-makefilek8smk">Static Targets for Makefile.k8s.mk</a></li>
</ul>
</li>
<li><a href="#demo-cluster-automation">Demo: Cluster Automation</a></li>
<li><a href="#known-limitations-and-issues">Known Limitations and Issues</a><ul>
<li><a href="#kubeconfig-should-already-be-set">KUBECONFIG should already be set</a></li>
<li><a href="#working-directories">Working Directories</a></li>
<li><a href="#general-argument-passing">General Argument Passing</a></li>
<li><a href="#docker-and-file-permissions">Docker and File Permissions</a></li>
<li><a href="#pipes-temp-files">Pipes &amp; Temp Files</a></li>
</ul>
</li>
</ul>
</div>


-------------------------------------------------------------

## Overview

This repository aggregates a bunch of individual utilities for working with kubernetes into one dockerized toolchain, hosted inside a single compose file as [k8s-tools.yml](k8s-tools.yml).  It's useful for CI/CD pipelines but can also be [embedded alongside your existing project](#integration-with-your-project), which helps to fix the problem of different project developers using different local versions of things like `helm`, `kubectl`, etc.

The containers defined here aren't built from scratch, and official sources are used where possible.  Most tools (like `kubectl`, `helm`, etc) come from [alpine/k8s](https://hub.docker.com/r/alpine/k8s) but many other tools are also included (like `k9s`, `k3d`).

This isn't an attempt to build an omnibus "do-everything" container, it's more a response to the fact that there are a lot of diverse tools that really can't be unified, so it's better to just learn how to work with that.

Besides bundling some tooling, this repository is the reference implementation of a pattern for [bridging compose services and Makefile targets](#makefilecomposemk), **providing a minimum viable framework for orchestrating tasks across those tool containers.** This pattern makes it easy to read/write/run/organize those tasks, and makes it easier to avoid lock-in from things like Jenkinsfiles or Github Actions.



-------------------------------------------------------------


## Features

**[k8s-tools.yml](k8s-tools.yml)**, a compose file.

* **Local parts of the tool bundle** ([See the latest here](k8s-tools.yml))
  * [argocli](https://argo-workflows.readthedocs.io/en/latest/walk-through/argo-cli/), [kn](https://knative.dev/docs/client/install-kn/), [k3d](https://k3d.io/), [k9s](https://k9scli.io/), [fission](https://fission.io/docs/installation/), [helmify](https://github.com/arttor/helmify), [kompose](https://kompose.io/), [kubefwd](https://github.com/txn2/kubefwd), [lazydocker](https://github.com/jesseduffield/lazydocker)
* **Upstream part of the tool bundle** ([See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.)
  * [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [kustomize](https://github.com/kubernetes-sigs/kustomize), [helm](https://github.com/helm/helm), [helm-diff](https://github.com/databus23/helm-diff), [helm-unittest](https://github.com/helm-unittest/helm-unittest), [helm-push](https://github.com/chartmuseum/helm-push), [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator), [eksctl](https://github.com/weaveworks/eksctl), [awscli v1](https://github.com/aws/aws-cli), [kubeseal](https://github.com/bitnami-labs/sealed-secrets), [krew](https://github.com/kubernetes-sigs/krew), [vals](https://github.com/helmfile/vals), [kubeconform](https://github.com/yannh/kubeconform).  Plus general tools, such as bash, curl, jq, yq, etc
* As usual with docker-compose, containers aren't pulled until they are used, and build-when-changed mostly works as you'd expect.  **Having these declared in case of eventual use won't saddle you with an enormous boostrap process.**
* If you're only interested in the upstream stuff from `alpine/k8s`, the compose file is nicer than the alternative huge `docker run ..` commands, because it sets up volumes for you to share the docker socket, and shares kubeconfigs for you automatically.  
* Also provides an approach for fixing root-user docker file-permissions (see [this section for more details](#docker-and-file-permissions)).

After you've made your whole tool chain portable in one swipe, you might also be interested in *driving* those tools with something that offers more structure than a shell script, and something that *also* won't add to your dependencies.  Check out the detailed docs for:

* **[Makefile.compose.mk](#makefilecomposemk)**, which defines various make-targets and macros for working with compose files & compose services.
* **[Makefile.k8s.mk](#makefilek8smk)**, which defines some make-targets for working with kubernetes from Makefiles.

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
$ docker compose run -f k8s-tools.yml k8s ...
$ docker compose run -f k8s-tools.yml helm ...
$ docker compose run -f k8s-tools.yml kubectl ...
$ docker compose run -f k8s-tools.yml kustomize ...
$ docker compose run -f k8s-tools.yml helm-diff ...
$ docker compose run -f k8s-tools.yml helm-unittest ...
$ docker compose run -f k8s-tools.yml helm-push ...
$ docker compose run -f k8s-tools.yml aws-iam-authenticator ...
$ docker compose run -f k8s-tools.yml eksctl ...
$ docker compose run -f k8s-tools.yml awscli ...
$ docker compose run -f k8s-tools.yml kubeseal ...
$ docker compose run -f k8s-tools.yml krew ...
$ docker compose run -f k8s-tools.yml vals ...
$ docker compose run -f k8s-tools.yml kubeconform ...
$ docker compose run -f k8s-tools.yml kn ...
$ docker compose run -f k8s-tools.yml helmify ...
$ docker compose run -f k8s-tools.yml fission ...
$ docker compose run -f k8s-tools.yml kompose ...
$ docker compose run -f k8s-tools.yml argo ...
$ docker compose run -f k8s-tools.yml kubefwd ...
$ docker compose run -f k8s-tools.yml k3d ...
$ docker compose run -f k8s-tools.yml lazydocker ...
$ docker compose run -f k8s-tools.yml k9s ...
$ docker compose run -f k8s-tools.yml yq ...
$ docker compose run -f k8s-tools.yml jq ...
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

## Integration With Your Project

You can embed the k8s-tools suite in your project in two ways, either with some kind of global compose file and global aliases, or with a more project-based approach using Makefiles.

----------------------------------------------------

### Embedding Tools With Aliases

For using this pattern with your existing projects, you might want to maintain separated compose files and setup aliases.

```bash
$ cd myproject

# or use your fork/clone..
$ curl -sL https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/k8s-tools.yml > k8s-tools.yml

$ alias helm=docker compose -f myproject/k8s-tools.yml run helm

$ helm ....
```

Aliases are convenient but rather fragile (obviously this will break if you move your `myproject` folder around).  See the next section for something that is a more durable and flexible.

----------------------------------------------------

### Embedding Tools With Makefiles

You'll probably want to read over the [Makefile.compose.mk](#makefilecomposemk) section to understand what's going on here.  In case you've already seen it though, here's the quick start with the copy/paste stuff for using the `compose.import` macro with your projects.



First, copy the files from this repo into your project:

```bash
$ cd myproject 

# or use your fork/clone..
$ curl -sL \
  https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/k8s-tools.yml \
    > k8s-tools.yml
$ curl -sL \
  https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/Makefile.compose.mk \
    > Makefile.compose.mk

# optional.  this can also just be appended to
# Makefile.compose.mk if you want less clutter
$ curl -sL \
  https://raw.githubusercontent.com/elo-enterprises/k8s-tools/master/Makefile.k8s.mk \
    > Makefile.k8s.mk
```

Now include `Makefile.compose.mk` inside your main project Makefile and call the `compose.import` macro.

```Makefile
# myproject/Makefile (Make sure you have real tabs, not spaces!)
 
# Include/invoke the target-building macros 
# somewhere near the top of your existing boilerplate
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))

# At this point, targets are defined for whatever services
# are mentioned in the external compose config, and they are
# ready to use. Now you can dispatch any task to any container!
test: ▰/kubectl/test
.test:
  kubectl --version
  echo hello world from `uname -n -v`
```


Skip to the sections describing the [Make/Compose bridge](#makecompose-bridge) and [Container Dispatch](#container-dispatch) for more details.


---------------------------------------------------------------

## Makefile.compose.mk

*`Makefile.compose.mk`* includes macros which can **[build a bridge between docker-compose services and make-targets](#makecompose-bridge)** at the same time as it provides a [**minimum viable pattern for container-dispatch.**](#container-dispatch)

The main macro is called *`compose.import`*, which can be used/included from any Makefile, used with any compose file, and used with *multiple* compose files (more on that later).  

If you prefer to learn from examples, you might want to just [get started](#makecompose-bridge) or skip to the main [cluster automation demo](#demo-cluster-automation).  If you're the type that needs to hear the motivation first, read on in the next section.

### But Why?

There's many reasons why you might want these capabilities if you're working with tool-containers, builds, deploys, and complex task orchestration.  People tend to have strong opions about this topic, but here are some observations that probably aren't too controversial:

* **Orchestration *between* or *across* tool containers is usually awkward.** This is a challenge that needs some structure imposed.  You can get that structure in lots of ways, but it's always frustrating to see your work locked into esoteric JenkinsFile / GitHubAction blobs where things get complicated to describe, run, or read.  *Project automation ideally needs to run smoothly both inside and outside of CI/CD.*
* **If running commands with different containers is easy, then there is less need to try and get everything into *one* tool container.**  The omnibus approach is usually time-consuming, and can be pretty hard if very different base images are involved.
* **Tool containers are much more useful when you can easily dispatch commands to them,** especially without a long, fragile CLI invocation.  A compose file specifying volumes and such helps a lot, but *you don't want `docker run ...` littered all over your scripts for builds and orchestration*.
* **Plain shell scripts won't take you far.** There's lots of reasons for this but to name a few... features involving option/argument parsing, multiple entrypoints, code-reuse, partial-execution for partial-updates, and other things you're going to need *just aren't simple to get.*  Maintainability also isn't great. Configuration management tools like Ansible can fix some of this, but bring their own problems, including: significant setup, significant dependencies, ongoing upstream changes, and the fact that many people cannot read or write it.

Much more controversially: **Make is the happy medium here**, despite the haters, the purists, and the skeptics who argue that *make is not a task-runner*.  That's because `make` is too good to ignore, and there are several major benefits.  It is old but it is everywhere, it's expressive but has relatively few core concepts, and it's fast.  It's the lingua franca for engineers, devops, and data-science, probably because easy things stay easy and advanced things are still possible.  It's the lingua franca for javascript, python, or golang enthusiasts who need to be able to somehow work together.  Most importantly: `make` is probably the *least* likely thing in your toolkit to be affected by externalities like pip breakage, package updates, or changing operating systems completely.  If you need something *outside* of docker that you want stability & ubiquity from, it's hard to find a better choice.  

The only problem is.. **Makefiles have nothing like native support for running tasks in containers**, but this is exactly what *`Makefile.compose.mk`* fixes.  Makefiles are already pretty good at describing task execution, but describing the containers themselves is outside of that domain.  Meanwhile, docker-compose is exactly the opposite, and so Make/Compose is a perfect combination.

Enough philosophy, more examples.

----------------------------------------------------

### Make/Compose Bridge

*`Makefile.compose.mk`* provides lots of interfaces (i.e. automatically generated make targets) which are suitable for interactive use.  

Let's forget about the k8s-tools.yml for now and walk through a more minimal example, starting with a hypothetical the compose file:

```yaml 
# docker-compose.yml
services:
  debian:
    image: debian
  alpine:
    image: alpine 
```

Next, the Makefile.  To generate make-targets for every service in the given compose file, we just need to import the `compose.import` macro and call it.

```Makefile
# Makefile
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))
```

The arguments *`(▰, TRUE)`* above allow for control of namespacing and syntax.  (More on that later in the [Macro Arguments section](#macro-arguments)).

That's it for the Make/Compose boilerplate, but we already have lots of interoperability.  

In general, the autogenerated targets fall into these categories: [**`<svc_name>`**](#target-svc_name), [**`<svc_name>/shell`**](#target-svc_nameshell), [**`<svc_name>/shell/pipe`**](#target-svc_nameshellpipe), [**`<svc_name>/__shell__`**](#target-svc_namespecial), [**`<compose_stem>/<svc>`**], (#target-svc_nameshell), [**`<compose_stem>/__services__`**](#target-compose_stemspecial), [**`<compose_stem>`/__build__**](#target-compose_stemspecial), [**`<compose_stem>`/__clean__**](#target-compose_stemspecial).

See the sections below for more concrete examples.

#### Target: **`<svc_name>/shell`** 

The **`<svc_name>/shell`** target drops to a containter shell for the named service, and is usually interactive.

```bash 

# Interactive shell on debian container
$ make debian/shell

# Interactive shell on "alpine" container
$ make alpine/shell
```

<img src="img/demo-bridge-shell.gif">


#### Target: **`<svc_name>/shell/pipe`** 

The **`<svc_name>/shell/pipe`** target allows streaming data:

```bash
# Stream commands into debian container
$ echo uname -n -v | make debian/shell/pipe

# Equivalent to above, since the debian image's default entrypoint is bash
$ echo uname -n -v | make debian/pipe

# Streams command input / output between containers
echo echo echo hello-world | make alpine/pipe | make debian/pipe
```

<img src="img/demo-bridge-stream.gif">

#### Target: **`<svc_name>`** 

The top-level **`<svc_name>`** target is more generic and can be used without arguments, or with optional, explicit overrides for the compose-service defaults.

```bash 
# Runs an arbitrary command on debian container (overriding compose defaults)
$ entrypoint=ls cmd='-l' make debian

# Streams data into an arbitrary command on alpine container
$ echo hello world | pipe=yes entrypoint=cat cmd='/dev/stdin' make alpine
```

#### Target: **`<svc_name>`/__special__**

Besides targets for working *with* services there are targets for answering questions *about* services.

The *`<svc_name>/__shell__`* targets answers what shell can be used as an entrypoint for the container. Usually this is `bash` or `sh`, but you'll get the answer in the form of an absolute path.

```bash 

$ make debian/__shell__
/bin/bash
```

#### Target: **`<compose_stem>/<svc>`**

Namespaced aliases are also available. So due to the stem of the compose-file we imported, all of the stuff above will work on targets like you see below.

```bash
$ make docker-compose/debian
$ make docker-compose/debian/shell
```

Note that if `compose.import` uses a file name like `k8s-tools.yml` instead, the namespace is *`k8s-tools/<svc_name>`*.


#### Target: **`<compose_stem>`/__special__**

Besides targets for working with compose-services, the **`<compose_stem>`/__special__** targets work on the compose files themselves. 

```bash 
# Clean (equivalent to `docker compose -f docker-compose.yml clean`)
make docker-compose/__clean__

# Build (equivalent to `docker compose -f docker-compose.yml build`)
make docker-compose/__build__

# List all services defined for file (Array of strings, xargs-friendly)
make docker-compose/__services__
```

Using the `<compose_stem>/__service__` target, it's easy to map a command onto every container, which can be useful for testing.  Try something like this:

```bash 
$ make docker-compose/__services__ | xargs -n1 -I% sh -x -c "echo uname -n |make docker-compose/%/shell/pipe"
```


#### Target: Misc

There are a few other utility-targets, including `make help` for displaying all the autogenerated targets.

```bash 
# Lists user-facing make-targets (skipping internal ones)
make help
```

See [the static targets list for a complete list](#static-targets-for-makefilecomposemk).

### With k8s-tools.yml 

This repo's [Makefile](Makefile) uses Makefile.compose.mk macros to load services from [k8s-tools.yml](k8s-tools.yml), so that [the targets available at the project root](#tools-via-make) are similar to the ones above, but will use names like *`k8s, kubectl, k3d`* instead of *`debian, alpine`*, and will use *`k8s-tools/`* prefixes instead of *`docker-compose/`* prefixes.

----------------------------------------------------

### Container Dispatch

Let's look at a more complicated example where we want to use make to dispatch commands *into* the compose-service containers.  For this we'll have to change the boilerplate somewhat as we add more functionality.

```Makefile
# Makefile (make sure you have real tabs, not spaces)

include Makefile.compose.mk
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

<img src="img/demo-dispatch.gif">

What just happend?  If we unpack the syntactic sugar even more, you could say that the following are roughly equivalent:

```bash
# pithy invocation with Makefile.compose.mk
$ make demo

# the verbose alternative invocation
$ docker compose -f docker-compose.yml \
    run --entrypoint bash debian -c "make self.demo"
```

Let's add another target to demonstrate dispatch for multiple containers:

```Makefile
# Makefile (make sure you have real tabs, not spaces)

include Makefile.compose.mk
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

<img src="img/demo-double-dispatch.gif">


Meanwhile, the equivalent-but-expanded version below is getting cluttered, plus it breaks when files move or get refactored.

```bash
# pithy invocation with Makefile.compose.mk
$ make demo-double-dispatch 

# verbose, fragile alternative
$ docker compose -f docker-compose.yml \
    run --entrypoint bash debian -c "make self.demo" \
  && docker compose -f docker-compose.yml \
    run --entrypoint bash alpine -c "make self.demo"
```

Container-dispatch with `Makefile.compose.mk` can also autodetect what shell to use with the container (via the [`<svc_name>/__shell__` target](#target-compose_stemspecial)).  Even better, the Makefile-based approach scales to lots of utility-containers in separate compose files, and can detect and prevent whole categories of errors (like typos in the name of the compose-file, service name, entrypoint, etc) at the start of a hour-long process instead of somewhere in the middle.  (See [docs for `make --reconn`](https://www.gnu.org/software/make/manual/html_node/Instead-of-Execution.html) to learn more about dry-runs).

<ins>**This simple pattern for dispatching targets in containers is the main feature of `Makefile.compose.mk` as a library, and it's surprisingly powerful.**</ins>  The next sections will cover macro arguments, and dispatch syntax/semantics in more detail.  If you're interested in a demo of how you can use this with k8s-tools.yml, you can skip to [this section](#cluster-automation-demo).

To make this work as expected though, we do have to add more stuff to the compose file.  In practice the containers you use might be ready, but if they are slim, perhaps not.  Basically, **if the subtarget is going to run on the container, the container needs to at least have:**  `make`, `bash` (or whatever shell the Makefile uses), and a volume mount to read the `Makefile`.  

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
        RUN apt-get update && apt-get install -y make
    entrypoint: bash
    working_dir: /workspace
    volumes:
      - ${PWD}:/workspace
  alpine:
    <<: *base
    hostname: alpine
    build:
      context: .
      dockerfile_inline: |
        FROM alpine
        RUN apk add --update --no-cache alpine-sdk bash

```

The debian/alpine compose file above and most of the interfaces described so far are all exercised inside [this repo's test suite](tests/).

----------------------------------------------------

### Macro Arguments

Make isn't big on named-arguments, so let's unpack the `compose.import` macro invocation. 

```Makefile
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))
```

 **The 1st argument for `compose.import` is called `target_namespace`**.  You can swap the unicode for `▰` out, opting instead for different symbols, path-like prefixes, whatever.  If you're bringing in services from several compose files, one way to control syntax and namespacing is to use different symbols for different calls to `compose.import`.  See the [Integration section](#integration) below for 2-file example.

**The 2nd argument for `compose.import` controls whether service names are available as top-level Makefile targets.**  The only value that means True is *`TRUE`*, because Make isn't big on bool types.  Regardless of the value here, service targets are always under `<compose_file_stem>/<compose_service_name>`. 

**The last argument for `compose.import` is the compose-file to load services from.**  It will be tempting to quote this and the other arguments, but that won't work, so resist the urge!

----------------------------------------------------

### Container Dispatch Syntax/Semantics

Let's look at the container-dispatch example in more detail.  This isn't a programming language you've never seen before, it's just a (legal) Makefile that uses unicode symbols in some of the targets.  

```Makefile
# A target that runs stuff inside the `debian` container, 
# which is runnable from host using `make demo`.
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

Look, no `docker run ..` clutter littered everywhere!  Ok, yeah.. it's still kind of a weird CI/CD DSL, but the conventions are simple and it's not locked inside Jenkins or github =)

Under the hood, dispatch is implemented by building on the [default targets that are provided by the bridge](#makecompose-bridge).

---------------------------------------------------------------

### Multiple Compose Files

This can be easily adapted for working with *multiple* compose files, but you'll have to think about service-name collisions between those files.  If you have two compose files with the same service name, you can use multiple target-namespaces like this:

```Makefile
# Makefile (Make sure you have real tabs, not spaces!)

# Load 1st compose file under paralleogram namespace,
# Load 2nd compose file under triangle namespace
include Makefile.compose.mk
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

### Static Targets for Makefile.compose.mk

Besides the `compose.import` macro and the auto-generated targets per service, there are several static targets you might find useful.  These are mostly just I/O helpers and other utilities. 



#### **`compose.bash`**

```bash 
Drops into an interactive shell with the en vars 
 that have been set by the parent environment, 
 plus those set by this Makefile context.
```

#### **`compose.divider`**

```bash 
Alias for print_divider
```

#### **`compose.indent`**

```bash 
Pipe-friendly helper for indenting, 
 reading from stdin and returning it to stdout.
```

#### **`compose.init`**

```bash 
Ensures compose is available.  Note that 
 build/run/etc cannot happen without a file, 
 for that, see instead targets like '<compose_file_stem>/__build__'
```

#### **`compose.mktemp`**

```bash 
Helper for working with temp files.  Returns filename, 
 and uses 'trap' to handle at-exit file-deletion automatically
```

#### **`compose.print_divider`**

```bash 
Prints a divider on stdout, defaulting to the full terminal width, 
 with optional label.  This automatically detects console width, but
 it requires 'tput', which is usually part of an ncurses package.

 USAGE: 
  make compose.print_divider label=".." filler=".." width="..."
```

#### **`compose.print_divider/<arg>`**

```bash 
Print a divider with a width of `term_width / <arg>`

 USAGE: 
  make compose.print_divider/<int>
```

#### **`compose.strip_ansi`**

```bash 
Pipe-friendly helper for stripping ansi.
 (Probably won't work everywhere, but has no deps)
```

#### **`compose.wait/<arg>`**

```bash 
Pauses for the given amount of seconds.

 USAGE: 
   compose.wait/<int>
```

#### **`docker.init`**

```bash 
Checks if docker is available, then displays version (no real setup)
```

#### **`docker.panic`**

```bash 
Debugging only!  Running this from automation will 
 probably quickly hit rate-limiting at dockerhub,
 plus you probably don't want to run this in prod.
```

#### **`help`**

```bash 
Attempts to autodetect the targets defined in this Makefile context.  
 Older versions of make dont have '--print-targets', so this uses the 'print database' feature.
 See also: https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
```


---------------------------------------------------------------

## Makefile.k8s.mk

`Makefiles.k8s.mk` includes lots of helper targets for working with kubernetes.  It works best in combination with Makefile.compose.mk and k8s-tools.yml, but that isn't required if things like `kubectl` are already available on your host.  These targets assume that KUBECONFIG is already set when they are running.

The focus is on simplifying few categories of frequent interactions:

1. Reusable implementations for common cluster automation tasks (like waiting for pods to get ready)
1. Context-management tasks (like setting the currently active namespace)
1. Interactive debugging tasks (like shelling into a new or existing pod inside some namespace)

Documentation per-target is included in the next section, but these tools aren't that interesting in isolation.  See the [Cluster Automation Demo](#demo-cluster-automation) for an example of how you can put all this stuff together.

### Static Targets for Makefile.k8s.mk

Here's an overview of available targets.  

Note that almost all of these targets will [require KUBECONFIG to already be set](#kubeconfig-should-already-be-set).  



#### **`k3d.panic`**

```bash 
Non-graceful stop for everything that is k3d related
 
 USAGE:  
   make k3d.panic
```

#### **`k3d.ps`**

```bash 
Container names for everything that is k3d related
 
 USAGE:  
   make k3d.ps
```

#### **`k8s.cluster_info`**

```bash 
Simple alias for `kubectl cluster-info`
```

#### **`k8s.commander`**

```bash 
Opens k8s.commander for the "default" namespace
```

#### **`k8s.commander/<arg>`**

```bash 
A split-screen TUI dashboard that opens lazydocker[1] and k9s[2].
 (Requires tmux)

 USAGE:  
   make k3d.commander/<namespace>
```

#### **`k8s.commander/default`**

```bash 

```

#### **`k8s.kubens.create/<arg>`**

```bash 
Context-manager.  Activates the given namespace, creating it first if necessary.
 This has side-effects and those will persist for subprocesses!

 USAGE: 
    k8s.kubens.create/<namespace>
```

#### **`k8s.kubens/<arg>`**

```bash 
Context-manager.  Activates the given namespace.
 Note that this modifies state in the kubeconfig,
 so it can effect contexts outside of the current
 process, therefore this is not thread-safe.

 USAGE:  
   make k8s.kubens/<namespace>
```

#### **`k8s.namespace.create/<arg>`**

```bash 
Idempotent version of namespace-create

 USAGE: 
    k8s.namespace.create/<namespace>
```

#### **`k8s.namespace.list`**

```bash 
Returns all namespaces in a simple array.
 NB: Must remain suitable for use with `xargs`!
```

#### **`k8s.namespace.purge/<arg>`**

```bash 
Wipes everything inside the given namespace

 USAGE: 
    k8s.namespace.purge/<namespace>
```

#### **`k8s.namespace.wait/<arg>`**

```bash 
Waits for every pod in the given namespace to be ready
 NB: If the parameter is "all" then this uses --all-namespaces

 USAGE: 
   k8s.namespace.wait/<namespace>
```

#### **`k8s.namespace/<arg>`**

```bash 
Context-manager.  Activates the given namespace.
 This has side-effects and those will persist for subprocesses!

 USAGE:  
	 k8s.namespace/<namespace>
```

#### **`k8s.pods.wait_until_ready`**

```bash 
Waits until all pods in every namespace are ready.
 (No parameters; kube context should already be configured)
```

#### **`k8s.purge_namespaces_by_prefix/<arg>`**

```bash 
Runs a separate purge for every matching namespace

 USAGE: 
    k8s.purge_namespaces_by_prefix/<prefix_>
```

#### **`k8s.shell/<arg>`**

```bash 
This drops into a debugging shell for the named pod,
 using `kubectl exec`.  This target is unusual because
 it MUST run from the host + also uses containers, and it 
 assumes `compose.import` created the 'k8s' service target

 WARNING: 
   This target assumes that k8s-tools.yml is imported
   to the root namespace, and using the default syntax.  

 USAGE: Interactive shell in pod:
   make k8s.shell/<namespace>/<pod_name>

 USAGE: Stream commands into a pod:
   echo uname -a | make k8s.shell/<namespace>/<pod_name>/pipe
```

#### **`k8s.test_pod_in_namespace/<arg>`**

```bash 
Starts a test-pod in the given namespace, then blocks until it's ready.

 USAGE: 
	`k8s.test_pod_in_namespace/<namespace>/<pod_name>` or 
	`k8s.test_pod_in_namespace/<namespace>/<pod_name>/<image>`
```

#### **`k9`**

```bash 
Starts the k9s pod-browser TUI, 
 opened by default to whatever 
 namespace is currently activated
 
 NB: This assumes the `compose.import` macro has 
 already been used to import the k8s-tools services

 USAGE:  
   make k9
```

#### **`k9s`**

```bash 

```

#### **`k9s/<arg>`**

```bash 
Starts the k9s pod-browser TUI, 
 opened by default to the given namespace
 
 NB: This assumes the `compose.import` macro has 
 already been used to import the k8s-tools services
 
 USAGE:  
   make k9s/<namespace>
```


---------------------------------------------------------------

## Demo: Cluster Automation




This section is a walk-through of the [end-to-end test](tests/Makefile.e2e.mk) included in the test-suite.  

First up, there's some pretty standard boilerplate and setting values for constants.  

```Makefile 
SHELL := bash
MAKEFLAGS += -s --warn-undefined-variables
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL :=  all 
export K3D_VERSION:=v5.6.3
export CLUSTER_NAME:=k8s-tools-e2e
export KUBECONFIG:=./fake.profile.yaml
export HELM_REPO:=https://helm.github.io/examples
export HELM_CHART:=examples/hello-world
export POD_NAME:=test-harness
export POD_NAMESPACE:=default
include Makefile.k8s.mk
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))
all: k8s-tools/__build__ clean init provision test

```

The `K3D_VERSION` part above is probably the most interesting, because it overrides defaults [in k8s-tools.yml](k8s-tools.yml), and effectively allows you to **pin tool versions inside scripts that use them, without editing with the compose file.**  Several of the compose-services support explicit overrides along these lines, and it's a convenient way to test upgrades.

Next we organize some targets for cluster-operations.  Below you can see there are two public targets declared for direct access, and two private targets that run inside the `k3d` tool container.

```Makefile 
clean: ▰/k3d/self.cluster.clean
init: ▰/k3d/self.cluster.init
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

```

Running `make clean` looks like this when it's tearing down the cluster:

<img src="img/e2e-clean.gif">

--------------------------------------------------

And running `make init` looks like this when it's setting up the cluster:

 <img src="img/e2e-init.gif">


The next section covers cluster provisioning.  Here we just want to install a helm chart, and to add a special "test-harness" pod to the default namespace.  

But we also want operations to be idempotent, and blocking operations where that makes sense, and we want to provide several entrypoints for the convenience of the user.

```Makefile 
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
	@# Creates/activates `default` namespace and launches a pod
	@# named `test-harness` into it, using the 'alpine/k8s:1.30.0'
	@# image.

```

Note that the `test_harness.provision` target above doesn't actually have a body!  The `k8s.*` targets coming from Makefile.k8s.mk (documented [here](#makefilek8smk-targets)) do all of the heavy lifting.  Meanwhile helm provisioning looks like this:

<img src="img/e2e-provision-helm.gif">

-----------------------------------------

Helm is just an example.  Volumes for file-sharing with the container are also already setup, so you can `kustomize` or `kubectl apply` referencing the file system directly.

The other part of our provisioning is bootstrapping the test-harness pod, which looks like this:

<img src="img/e2e-provision-test-harness.gif">

----------------------------------------------

With the test-harness in place, there's a block of target definitions for a miniature test-suite that checks properties of the cluster.

```Makefile 
test: test.cluster test.contexts 
test.cluster: ▰/k8s/self.cluster.test
test.contexts: get.host.ctx get.compose.ctx get.pod.ctx 
self.cluster.test: k8s.namespace.wait/default k8s.cluster_info
	@# Waits for anything in the default namespace to finish and show cluster info
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

```

Running `make test` looks like this:

<img src="img/e2e-test.gif">

----------------------------------------------

The tests are not a bad start for exercising the cluster.  Since we blocked on pods or whole-namespacing being ready, we know that nothing is stuck in crash loop or container-pull.  We know that there were not errors with the helm charts, and that we can communicate with test-harness pods.  

What if you want to inspect or interact with things though?  The next block of target definitions provides a few aliases to help with this.

```Makefile 
# tests/Makefile.e2e.mk

cluster.shell: k8s.shell/${POD_NAMESPACE}/${POD_NAME}
	@# Interactive shell for the test-harness pod 
	@# (See also'provision' steps for the setup of same)
cluster.show: k9s/${POD_NAMESPACE}
	@# TUI for browsing the cluster

```

Again, no target bodies because `k8s.*` targets for stuff like this already exist, and we just need to pass in the parameters for our setup.  

Shelling into a pod is easy.  Actually `make k8s.shell/<namespace>/<pod_name>` was *always* pretty easy, but now there's an entry-point that we can use interactively.  

<img src="img/e2e-interactive-shell.gif">

The `*k8s.shell/<namespace>/<pod_name>*` target is interactive, but there's also a streaming version of this target at `k8s.shell/<namespace>/<pod>/pipe`, which was used as part of testing earlier in the `get.pod.ctx` target.

Well, how about something to inspect the full k3d context?  Here's a side-by-side view of the kubernetes namespace (visualized with `k9s`), and the local docker containers (via `lazydocker`).

<img src="img/e2e-interactive-tui.gif">


So that's how about ~100 lines of mostly-aliases-and-documentation Makefile is enough to describe a simple cluster lifecycle, and can give access to ~20 versioned platforming tools, all with no host dependencies except docker-compose + make.  It's simple, structured, portable, and lightweight.

No container orchestration logic was harmed during the creation of this demo, nor confined into a Jenkinsfile or github action, and yet [it all works from github actions](https://github.com/elo-enterprises/k8s-tools/actions).  

Happy platforming =D

---------------------------------------------------------------

# Known Limitations and Issues

### KUBECONFIG should already be set 

We fake it for builds/tests, but note that **`KUBECONFIG` generally must be set for things to work!**  Sadly, lots of tools will fail even simple invocations like `helm version` or even `--help` if this is undefined or set incorrectly, and it will often crash with errors that aren't very clear.

Dealing with per-project KUBECONFIGs is best, where you can set that inside your project Makefile and be assured of no interference with your main environment.  Alternatively, use bashrc if you really want globals, or provide it directly as environment variable per invocation using something like `KUBECONFIG=.. make <target_name>`.

### Working Directories

By default, the compose file shares the working directory with containers it's using as volumes.  **This means files you're using should be inside or somewhere below the working directory!**  The compose file itself can be anywhere though, so instead of keeping it in your projects source-tree you can decide to deploy it separately to `/opt` or `~/.config`

### General Argument Passing

Unfortunately, there's not a good way to convince `make` to just proxy arguments without parsing them.  **For example `make kubectl apply -f` looks convenient, but it won't work.**  (It will instead parse `apply -f` as arguments to make.)

### Docker and File Permissions 

The usual problem with root-user-in-containers vs normal-user on host and file permissions.  The alpine base is a container using root, as are many other things.  And there is a long-standing [known bug in the compose spec](https://github.com/compose-spec/compose-go/pull/299) that makes fixing this from the compose file hard.  

Invoking compose exclusively from a Makefile actually helps with this though.  By default with [Makefile.compose.mk](#makefilecomposemk), these variables are set and available for use in [k8s-tools.yml](k8s-tools.yml): 

```Makefile
export DOCKER_UID?=$(shell id -u)
export DOCKER_GID?=$(shell getent group docker | cut -d: -f3 || id -g)
export DOCKER_UGNAME?=user
```

If you're not working with Makefiles, you can export these in .bashrc or .env files you use.

If none of this is appealing, and you mix host-local and dockerized usage of things like helm, then you'll probably end up with weird file ownership.  You can fix this if it comes up using `sudo chown -R $USER:$USER .`.  

### Pipes & Temp Files 

Working with streaming pipes generates temporary files with `mktemp`, removing them when the process exits with `trap`.  Pure streams would be better.
