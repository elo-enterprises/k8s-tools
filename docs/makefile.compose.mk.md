## Makefile.compose.mk

*`Makefile.compose.mk`* includes macros which can **[build a bridge between docker-compose services and make-targets](#makecompose-bridge)** at the same time as it provides a [**minimum viable pattern for container-dispatch.**](#container-dispatch)

The main macro is called *`compose.import`*, which can be used/included from any Makefile, used with any compose file, and used with *multiple* compose files (more on that later).  

If you prefer to learn from examples, you might want to just [get started](#makecompose-bridge) or skip to the main [cluster automation demo](#demo-cluster-automation).  If you're the type that needs to hear the motivation first, read on in the next section.

----------------------------------------------------

### But Why?

There's many reasons why you might want these capabilities if you're working with tool-containers, builds, deploys, and complex task orchestration.  People tend to have strong opions about this topic, but here are some observations that probably aren't too controversial:

* **Orchestration *between* or *across* tool containers is usually awkward.** This is a challenge that needs some structure imposed.  You can get that structure in lots of ways, but it's always frustrating to see your work locked into esoteric JenkinsFile / GitHubAction blobs where things get complicated to describe, run, or read.  *Project automation ideally needs to run smoothly both inside and outside of CI/CD.*
* **If running commands with different containers is easy, then there is less need to try and get everything into *one* tool container.**  The omnibus approach is usually time-consuming, and can be pretty hard if very different base images are involved.
* **Tool containers are much more useful when you can easily dispatch commands to them,** especially without a long, fragile CLI invocation.  A compose file specifying volumes and such helps a lot, but *you don't want `docker run ...` littered all over your scripts for builds and orchestration*.
* **Plain shell scripts won't take you far.** There's lots of reasons for this but to name a few... features involving option/argument parsing, multiple entrypoints, code-reuse, partial-execution for partial-updates, dry-runs, parallelism, and other things you're going to need *just aren't simple to get.*  Maintainability also isn't great. Configuration management tools like Ansible can fix some of this, but bring their own problems, including: significant setup, significant dependencies, ongoing upstream changes, and the fact that many people cannot read or write it.

Much more controversially: **Make is the happy medium here**, despite the haters, the purists, and the skeptics who argue that *make is not a task-runner*.  That's because `make` is too good to ignore, and there are several major benefits.  It is old but it is everywhere, it's expressive but has relatively few core concepts, and it's fast.  It's the lingua franca for engineers, devops, and data-science, probably because easy things stay easy and advanced things are still possible.  It's the lingua franca for javascript, python, or golang enthusiasts who need to be able to somehow work together.  Most importantly: `make` is probably the *least* likely thing in your toolkit to be affected by externalities like pip breakage, package updates, or changing operating systems completely.  If you need something *outside* of docker that you want stability & ubiquity from, it's hard to find a better choice.  Make also has built-in support for dry-runs and parallel execution.

The only problem is.. **Makefiles have nothing like native support for running tasks in containers**, but this is exactly what *`Makefile.compose.mk`* fixes.  Makefiles are already pretty good at describing task execution, but describing the containers themselves is outside of that domain.  Meanwhile, docker-compose is exactly the opposite, and so Make/Compose is a perfect combination.

Enough philosophy, more examples.

----------------------------------------------------

### Make/Compose Bridge

*`Makefile.compose.mk`* provides lots of interfaces (i.e. automatically generated make targets) which are suitable for interactive use.  

Let's forget about the k8s-tools.yml for now and walk through a more minimal example, starting with a hypothetical compose file:

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
# Makefile
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))
```

The arguments *`(▰, TRUE)`* above allow for control of namespacing and syntax.  (More on that later in the [Macro Arguments section](#macro-arguments)).

That's it for the Make/Compose boilerplate, but we already have lots of interoperability.  

In general, the autogenerated targets fall into these categories: [**`<svc_name>`**](#target-svc_name), [**`<svc_name>/shell`**](#target-svc_nameshell), [**`<svc_name>/shell/pipe`**](#target-svc_nameshellpipe), [**`<svc_name>/__shell__`**](#target-svc_namespecial), [**`<compose_stem>/<svc>`**], (#target-svc_nameshell), [**`<compose_stem>/__services__`**](#target-compose_stemspecial), [**`<compose_stem>`/__build__**](#target-compose_stemspecial), [**`<compose_stem>`/__clean__**](#target-compose_stemspecial).

See the sections below for more concrete examples.

----------------------------------------------------

#### Target: **`<svc_name>/shell`** 

The **`<svc_name>/shell`** target drops to a containter shell for the named service, and is usually interactive.

```bash 

# Interactive shell on debian container
$ make debian/shell

# Interactive shell on "alpine" container
$ make alpine/shell
```

<img src="img/demo-bridge-shell.gif">


----------------------------------------------------

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

----------------------------------------------------

#### Target: **`<svc_name>`** 

The top-level **`<svc_name>`** target is more generic and can be used without arguments, or with optional, explicit overrides for the compose-service defaults.

```bash 
# Runs an arbitrary command on debian container (overriding compose defaults)
$ entrypoint=ls cmd='-l' make debian

# Streams data into an arbitrary command on alpine container
$ echo hello world | pipe=yes entrypoint=cat cmd='/dev/stdin' make alpine
```

----------------------------------------------------

#### Target: **`<svc_name>`/__special__**

Besides targets for working *with* services there are targets for answering questions *about* services.

The *`<svc_name>/__shell__`* targets answers what shell can be used as an entrypoint for the container. Usually this is `bash`, `sh`, or an error, but when there's an answer you'll get it in the form of an absolute path.

```bash

$ make debian/__shell__
/bin/bash
```

----------------------------------------------------

#### Target: **`<compose_stem>/<svc>`**

Namespaced aliases are also available. So due to the stem of the compose-file we imported, all of the stuff above will work on targets like you see below.

```bash
$ make docker-compose/debian
$ make docker-compose/debian/shell
```

Note that if `compose.import` uses a file name like `k8s-tools.yml` instead, the namespace is *`k8s-tools/<svc_name>`*.

----------------------------------------------------

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

----------------------------------------------------

#### Target: Misc

There are a few other utility-targets, including `make help` for displaying all the autogenerated targets.

```bash 
# Lists user-facing make-targets (skipping internal ones)
make help
```

See [the static targets list for a complete list](#static-targets-for-makefilecomposemk).

----------------------------------------------------

### Make/Compose Bridge with k8s-tools.yml

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

<ins>**This simple pattern for dispatching targets in containers is the main feature of `Makefile.compose.mk` as a library, and it's surprisingly powerful.**</ins>  The next sections will cover macro arguments, and dispatch syntax/semantics in more detail.  If you're interested in a demo of how you can use this with k8s-tools.yml, you can skip to [this section](#cluster-automation-demo).

Container-dispatch with `Makefile.compose.mk` can also autodetect what shell to use with the container (via the [`<svc_name>/__shell__` target](#target-compose_stemspecial)).  Even better, the Makefile-based approach scales to lots of utility-containers in separate compose files, and can detect and prevent whole categories of errors (like typos in the name of the compose-file, service name, entrypoint, etc) at the start of a hour-long process instead of somewhere in the middle.  (See [docs for `make --reconn`](https://www.gnu.org/software/make/manual/html_node/Instead-of-Execution.html) to learn more about dry-runs).  If you are thoughtful about the ways that you're using volumes and file state, you can also consider using [`make --jobs` for parallel execution](https://www.gnu.org/software/make/manual/make.html#Parallel-Execution).

**To make this work as expected though, we do have to add more stuff to the compose file.**  In practice the containers you use might be ready, but if they are slim, perhaps not.  Basically, **if the subtarget is going to run on the container, the container needs to at least have:**  `make`, `bash` (or whatever shell the Makefile uses), and a volume mount to read the `Makefile`.  

```yaml
{{open('tests/docker-compose.yml','r').read()}}
```

The debian/alpine compose file above and most of the interfaces described so far are all exercised inside [this repo's test suite](tests/).

----------------------------------------------------

### Macro Arguments

Make isn't big on named-arguments, so let's unpack the `compose.import` macro invocation.

```Makefile
include Makefile.compose.mk
$(eval $(call compose.import, ▰, TRUE, docker-compose.yml))
```

 **The 1st argument for `compose.import` is called `target_namespace`**.  You can swap the unicode for `▰` out, opting instead for different symbols, path-like prefixes, whatever.  If you're bringing in services from several compose files, one way to control syntax and namespacing is to use different symbols for different calls to `compose.import`.  (For a 2-file example, see the [Multiple Compose Files](#multiple-compose-files) section.)

**The 2nd argument for `compose.import` controls whether service names are available as top-level Makefile targets.**  The only value that means True is *`TRUE`*, because Make isn't big on bool types.  Regardless of the value here, service targets are always under `<compose_file_stem>/<compose_service_name>`. 

**The last argument for `compose.import` is the compose-file to load services from.**  It will be tempting to quote this and the other arguments, but that won't work, so resist the urge!

----------------------------------------------------

### Container Dispatch Syntax/Semantics

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

----------------------------------------------------

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

Besides the `compose.import` macro and the auto-generated targets per service, there are several static targets you might find useful.  In many cases these are just I/O helpers, text-formatters, and other utilities, but there's also targets for working with docker.

*This documentation is pulled automatically from [source](Makefile.compose.mk)*


{% set targets=bash('pynchon makefile parse Makefile.compose.mk', load_json=True) %}
{% for tname in targets %}
#### **`{{tname.replace('%','<arg>')}}`**

```bash 
{{ "\n".join(targets[tname].docs).strip()}}
```
{% endfor %}
