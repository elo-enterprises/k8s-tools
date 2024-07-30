## compose.mk

A tool / library / automation framework for working with containers.  Also the biggest, baddest, and most highly-powered mutant Makefile you're ever likely to see, although this aspect is generally safe to ignore unless you're interested ;)

  * **Library-mode** extends `make` in a variety of ways, including support for working with containers (Docs: [[1]](#), [[2]](#), [[3]](#))
  * **Stand-alone mode also available,** i.e. a tool that requires no external Makefile / compose file. (Docs: [[1]](#))
  * **Zero host-dependencies,** as long as you have docker + make.  Even the [TUI backend](#embedded-tui) is dockerized.
  * **Container-dependencies are minimal too,** so that almost any base can work with [container-dispatch](#container-dispatch).
  * **Built-in TUI framework** that's small but powerful.  (See the [Embedded TUI docs](#embedded-tui) and the [tux.* API](/docs/api#api-tux))
  * **A minimal, elegant, and dependency-free approach to describing workflow pipelines** (See the [flux.* API](/docs/api#api-flux))
  
In many ways, `compose.mk` breaks all the rules that you can imagine for how you are *supposed* to use Makefiles, starting with the fact that it weighs in at ~3.5k lines.  But there's method to this madness, and hopefully you'll agree that the juice is worth the squeeze!  

Code-to-comment ratios throughout are roughly 1:1, and although it's not practical to measure code-coverage, [the test-suite](tests/) is pretty extensive.  The single-file approach used with `compose.mk` makes it easy to embed, and the API is quickly approaching a "frozen" status.  [Hacking is generally encouraged](#contributing), and users can feel free to rip out any parts of `compose.mk` they don't want or need.  With minor modifications, it's also easy to concatenate `compose.mk` and `k8s.mk` and use that, keeping one more piece of boilerplate out of your project repository.

#}
<strong>Library Mode:</strong>

In library-mode, `compose.mk` is used as an `include` from your project Makefile.  With that as a starting place, you can **[build a bridge between docker-compose services and make-targets](#makecompose-bridge)** and use [**minimum viable patterns for container-dispatch.**](#container-dispatch).  The main macro is called *`compose.import`*, which can be used/included from any Makefile, used with any compose file, and [used with *multiple* compose files](#multiple-compose-files).  

Besides support for compose-files, `compose.mk` has many other features that extend the core capabilities of make, plus a *[curated collection of reusable utility targets](#composemk-api).  Here's an overview:


* 🚀 **Executable file:** `./compose.mk ...  <==> make -f compose.mk ...`
* Built-in supervisor process, [improving support for signal handling](#signals-and-supervisors).
* [**`flux.*` targets:**](/docs/api#api-flux) A tiny but powerful workflow/pipelining API, roughly comparable to something like [declarative pipelines in Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/).  This provides composable concurrency & staging operators, where the primitives are usually make-target names.  
* [**`tux.*` targets:**](#embedded-tui) Control-surface for a tmux-backed console geometry manager.
  * **No host dependencies.** This uses the `compose.mk:tux` tool container to dockerize tmux itself.
  * **Supports docker-in-docker style host-socket sharing with zero configuration,** so your TUI can generally do all the same container orchestration tasks as the docker host.
  * Open split-screen displays, shelling into 1 or more of the tool containers in k8s-tools.yml (or any other compose file).
  * Combines well with `flux.*` targets to quickly create dashboards / custom development environments.
* [**`stream.*`:**](/docs/api#api-stream) Support for working with streams, including newline/comma/space delimited streams, common use cases with JSON, etc.  Everything here is used with pipes, and reads from stdin.  It's not what you'd call "typed", but it reduces error-prone parsing and moves a little bit closer to structured data.
* [**`io.*`:**](/docs/api#api-io) Misc. utilities for printing, formatting, timers, etc.
* [**`docker.*`:**](/docs/api#api-docker) An interface for working with docker.
* [**`mk.*`:**](/docs/api#api-docker) Meta-tooling for 'make' itself. This enables help functions, signals and supervisors, some utilities for reflection, etc.
* [**`compose.*`:**](/docs/api#api-docker) An interface for working with compose.  
</details>


#}
<strong>Stand Alone Mode</strong>

**In Stand-alone Mode,** you can still use most of the features above but skip [the usual project integration](#embedding-tools-with-makefiles). 

Highlighting just a few random use-cases, you can:

* [Load compose files into TUIs](#loading-compose-files) with 1 shell per service,
* [Syntax-highlight files](/docs/api/#iofilepreviewarg)
* [Build JSON with jb](/docs/api#jb)
* [Parse JSON with jq](/docs/api#jq)
* [Clean, refactor, or port existing bash script](#) towards something that's easier to read and write.

And lots more, all using local tools if available and falling back to dockerized tool-versions if necessary.
</details>

If you prefer to learn from examples, you might want to just [get started](#makecompose-bridge) or skip to the main [cluster automation demo](/docs/demos#demo-cluster-automation) or to a [tui demo](#embedded-tui).  If you're the type that needs to hear the motivation first, read on in the next section.

#}
<h3>But Why?</h3>

There's many reasons why you might want these capabilities if you're working with tool-containers, builds, deploys, and complex task orchestration.  But why `make`?  People tend to have strong opions about this topic, and it's kind of a long story.

The short version is this:

1. Makefiles run practically everywhere and most people can read/write them.  
1. They're also really good at describing DAGs, and lots of automation, but *especially life-cycle automation*, is a natural fit for this paradigm.  

The only trouble is that **a)** *make has nothing like native support for tasks in containers*, and **b)** *describing the containers themselves is even further outside of its domain*.  Meanwhile, docker-compose is exactly the opposite.  

Make & Compose are already a strong combination for this reason, and by adding some syntactic sugar using *compose.mk*, you can orchestrate make-targets across several containers without cluttering your host.  More than that.. you can also bootstrap surprisingly sophisticated and flexible automation-APIs with surprisingly little effort.  

One reason this works so well is because with `make`, *the programmatic API basically <ins>is</ins> the CLI interface,* or to put it another way, once you have finished one of these you automatically have the other.

If you're interested in the gory details of a longer-format answer, see [the Design Philosophy docs](docs/but-why.md).

</details>


#}
<h3>Make/Compose Bridge</h3>

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
</details>

#}
<h3>Dynamic API</h3>


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

</details>

#}
<h3>Make/Compose Bridge with k8s-tools.yml</h3>

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

</details>

#}
<h3>Container Dispatch</h3>

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

<img src="img/demo-dispatch.gif">

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

<img src="img/demo-double-dispatch.gif">


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

<ins>**This simple pattern for dispatching targets in containers is the main feature of `compose.mk` as a library, and it's surprisingly powerful.**</ins>  The next sections will cover macro arguments, and dispatch syntax/semantics in more detail.  If you're interested in a demo of how you can use this with k8s-tools.yml, you can skip to [this section](#cluster-automation-demo).

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

</details>

#}
<h3>Macro Arguments</h3>

Make isn't big on named-arguments, so let's unpack the typical `compose.import` macro invocation.

```Makefile
include compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))
```

 **The 1st argument for `compose.import` is called `target_namespace`**.  You can swap the unicode for `▰` out, opting instead for different symbols, path-like prefixes, whatever.  If you're bringing in services from several compose files, one way to control syntax and namespacing is to use different symbols for different calls to `compose.import`.  (For a 2-file example, see the [Multiple Compose Files](#multiple-compose-files) section.)

**The 2nd argument for `compose.import` controls whether service names are available as top-level Makefile targets.**  The only value that means True is *`TRUE`*, because Make isn't big on bool types.  Regardless of the value here, service targets are always under `<compose_file_stem>/<compose_service_name>`. 

**The last argument for `compose.import` is the compose-file to load services from.**  It will be tempting to quote this and the other arguments, but that won't work, so resist the urge!

</details>

#}
<h3>Container Dispatch Syntax/Semantics</h3>

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
</details>

#}
<h3>Multiple Compose Files</h3>


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

</details>

#}
<h3>Loading Compose Files</h3>

For the simplest use-cases where you have a compose-file, and want some of the compose.mk features, but don't have a project makefile, it's possible to skip some of the steps in the [usual integration](#embedding-tools-with-makefiles) by letting `loadf` generate integration for you just in time.

```bash 
$ ./compose.mk loadf <path_to_compose_file> <other_instructions>
```

Since `make` can't modify available targets from inside recipes, this basically works by creating temporary files that use the [compose.import macro](#macro-arguments) on the given compose file, then proxying subsequent CLI arguments over to *that* automation.  When no other instructions are provided, the default is to [open container shells in the TUI](#embedded-tui).

<a href=img/tui-3.gif><img src=img/tui-3.gif></a>

Actually any type of instructions you pass will get the compose-file context, so you can use any of the other targets documented as [part of the bridge](#make-compose-bridge) or the [static targets](/docs/api#api-compose.mk).  For example:

<a href=img/tui-4.gif><img src=img/tui-4.gif></a>

Despite all the output this is pipe-safe, in case the commands involved might return JSON for downstream parsing, etc.  See the [Embedded TUI](#embedded-tui) docs for other examples that are using `loadf`.

</details>

#}
<h3>Embedded TUI</h3>

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

Without actually writing any custom code, there are many ways to customize the way that the TUI starts and the stuff that's running inside it.  By combining the TUI with the [`loadf` target,](#loading-compose-files) you can leverage existing compose files but skip [the usual integration with a project Makefile](#embedding-tools-with-makefiles).


<img src=img/tui-1.gif>

One way to look at the TUI is that it's just a way of mapping make-targets into tmux panes.  So you don't actually have to use targets that are related to containers.

<img src=img/tui-2.gif>

#}
<h4>TUI Keybindings</h4>

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


</details>

</details>




#}
<h3>Signals and Supervisors</h3>



 
 
 #### Motivation 
 
 Without [forking make](https://remake.readthedocs.io/en/latest/), there's no simple method to get hooks into the default way that it handles interrupts and signals.  But why would you want to anyway?  Most of the time this occurs to people [it's about cleanup](https://www.gnu.org/software/make/manual/html_node/Interrupts.html), but `compose.mk` doesn't exactly look like traditional use-cases.
 
The main reason to care is that short-circuiting make's default CLI option parsing is *really useful*.  Especially since `compose.mk` allows us to "wrap" lots of containerized tools, we want to be able to proxy arguments over to those tools without `make` being greedy about parsing everything.

The [`loadf` command](#loading-compose-file) is a typical example: the 2nd argument, a filename, must not be parsed as a Makefile target:

```bash
# Opens all shells for each service in the given file inside the TUI
./compose.mk loadf tests/docker-compose.yml
```
 
Sometimes we want individual targets to essentially be able to consume the rest of the command line.  In this case, the filename is best understood as an argument to the first target, and not a target itself.
 
The [wrapper for jb](docs/api/#jb) is another example of an invocation that requires reading the whole command-line.  And for targets created with [`compose.import`](#makecompose-bridge), the [special form with '--'] (#special-form) also requires this kind of short-circuiting.

#### Implementation








 
* [mk.supervisor.enter/<arg>](docs/api#mk.supervisor.enterarg) 
* [mk.supervisor.exit/<arg>](docs/api#mk.supervisor.exitarg) 
* [mk.supervisor.interrupt](docs/api#mk.supervisor.interrupt) 
* [mk.supervisor.interrupt/<arg>](docs/api#mk.supervisor.interruptarg) 
* [mk.supervisor.pid](docs/api#mk.supervisor.pid) 
* [mk.supervisor.trap/<arg>](docs/api#mk.supervisor.traparg) 
* [mk.interrupt](docs/api#mk.interrupt) 
* [mk.interrupt/<arg>](docs/api#mk.interruptarg) 
* [mk.interrupt/SIGINT](docs/api#mk.interruptSIGINT) 

</details>
