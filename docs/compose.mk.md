## compose.mk

A tool / library / automation framework for working with containers.

  * Library-mode extends `make`, adding native support for working with (external) container definitions
  * Stand-alone mode also available, i.e. a tool that requires no external Makefile / compose file.
  * A small-but-powerful built-in TUI framework with no host dependencies. (See the [Embedded TUI docs](#embedded-tui) and the [tux.* API](/docs/api#api-tux))
  * **Zero host-dependencies,** as long as you have docker + make.  Even the [TUI backend](#embedded-tui) is dockerized.
  * **Container-dependencies are minimal too,** so that almost any base can work with [container-dispatch](#container-dispatch).
  * A minimal, elegant, and dependency-free approach to describing workflow pipelines. (See the [flux.* API](/docs/api#api-flux))

**In library Mode,** `compose.mk` is used as an `include` from your project Makefile.  With that as a starting place, you can **[build a bridge between docker-compose services and make-targets](#makecompose-bridge)** and use [**minimum viable patterns for container-dispatch.**](#container-dispatch).  The main macro is called *`compose.import`*, which can be used/included from any Makefile, used with any compose file, and [used with *multiple* compose files](#multiple-compose-files).  


If you prefer to learn from examples, you might want to just [get started](#makecompose-bridge) or skip to the main [cluster automation demo](#demo-cluster-automation) or to a [tui demo](#demo-tui).  If you're the type that needs to hear the motivation first, read on in the next section.

----------------------------------------------------

### But Why?

There's many reasons why you might want these capabilities if you're working with tool-containers, builds, deploys, and complex task orchestration.  People tend to have strong opions about this topic, and it's kind of a long story.  

The short version is this: Makefiles run practically everywhere and most people can read/write them.  They're also really good at describing DAGs, and lots of automation, but *especially life-cycle automation*, is a natural fit for this paradigm.  The only trouble is that **a)** *make has nothing like native support for tasks in containers*, and **b)** *describing the containers themselves is even further outside of its domain*.  Meanwhile, docker-compose is exactly the opposite.  
Make & Compose are already a strong combination for this reason, and by adding some syntactic sugar using compose.mk, you can orchestrate make-targets across several containers without cluttering your host.  More than that.. you can also bootstrap surprisingly sophisticated automation-APIs with surprisingly little effort.

If you're interested in the gory details of a longer-format answer, see [the Design Philosophy docs](docs/but-why.md).

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

----------------------------------------------------

{% include "loadf.md" %}

----------------------------------------------------

{% include "embedded-tui.md" %}
