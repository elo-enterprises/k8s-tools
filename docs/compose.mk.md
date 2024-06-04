## compose.mk

*`compose.mk`* includes macros which can **[build a bridge between docker-compose services and make-targets](#makecompose-bridge)** at the same time as it provides a [**minimum viable pattern for container-dispatch.**](#container-dispatch)

The main macro is called *`compose.import`*, which can be used/included from any Makefile, used with any compose file, and used with *multiple* compose files (more on that later).  

If you prefer to learn from examples, you might want to just [get started](#makecompose-bridge) or skip to the main [cluster automation demo](#demo-cluster-automation).  If you're the type that needs to hear the motivation first, read on in the next section.

----------------------------------------------------

### But Why?

There's many reasons why you might want these capabilities if you're working with tool-containers, builds, deploys, and complex task orchestration.  People tend to have strong opions about this topic, and it's kind of a long story.  

The short version is this: Makefiles run practically everywhere and most people can read/write them.  They're also really good at describing DAGs, and lots of automation, but *especially life-cycle automation*, is a natural fit for this paradigm.  The only trouble is that a) *make has nothing like native support for tasks in containers*, and b) *describing the containers themselves is even further outside of it's domain*.  Meanwhile, docker-compose is exactly the opposite.Make/Compose are already a strong combination for this reason, and by adding some syntactic sugar using compose.mk, you can orchestrate make-targets across several containers without cluttering your host.  More than that, you can also bootstrap surprisingly sophisticated automation-APIs with surprisingly little effort.

If you're interested in the gory details of the longer-format answer, there's more detailed discussion in the [Design Philosophy section](#why-makefilecomposemk).

----------------------------------------------------

{% include "bridge.md" %}

----------------------------------------------------

{% include "container-dispatch.md" %}

----------------------------------------------------

### Macro Arguments

Make isn't big on named-arguments, so let's unpack the `compose.import` macro invocation.

```Makefile
include compose.mk
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

{% include "multiple-compose-files.md" %}

---------------------------------------------------------------

{% include "platform-example.md" %}

---------------------------------------------------------------

### compose.mk API

Besides the `compose.import` macro and [the auto-generated targets per service], there are several static targets you might find useful.  These are divided up into two main namespaces:

* *`io.*`* targets: Including IO helpers, text-formatters, and other utilities
* *`docker.*`* targets: Helpers for working with docker.


#### API::compose.mk::io

The *`io.*`* targets cover various I/O helpers, text-formatters, and other utilities.

*This documentation is pulled automatically from [source](compose.mk)*

{% set targets=bash('pynchon makefile parse compose.mk| jq \'with_entries(select(.key | startswith("io")))\'', load_json=True) %}
{% for tname in targets %}
#### **`{{tname.replace('%','<arg>')}}`**

```bash 
{{ "\n".join(targets[tname].docs).strip()}}
```
{% endfor %}

#### API::compose.mk::docker

The *`docker.*`* targets cover a few helpers for working with docker.

*This documentation is pulled automatically from [source](compose.mk)*

{% set targets=bash('pynchon makefile parse compose.mk| jq \'with_entries(select(.key | startswith("docker")))\'', load_json=True) %}
{% for tname in targets %}
#### **`{{tname.replace('%','<arg>')}}`**

```bash 
{{ "\n".join(targets[tname].docs).strip()}}
```
{% endfor %}

