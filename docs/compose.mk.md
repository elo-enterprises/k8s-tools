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

{% include "macro-arguments.md" %}

----------------------------------------------------

{% include "dispatch-syntax.md" %}

----------------------------------------------------

{% include "multiple-compose-files.md" %}

---------------------------------------------------------------

{% include "platform-example.md" %}

---------------------------------------------------------------

### compose.mk API

Besides the `compose.import` macro and [the auto-generated targets per service], there are several static targets you might find useful.  They are divided up into two main namespaces:

* [*`io.*`*](#apicomposemkio) targets: Including IO helpers, text-formatters, and other utilities
* [*`docker.*`]*(#apicomposemkdocker) targets: Helpers for working with docker.


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

