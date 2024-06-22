## Overview

This repository aggregates 20+ individual utilities for working with kubernetes into one dockerized toolchain, hosted inside a single compose file as [k8s-tools.yml](k8s-tools.yml).  It's useful for CI/CD pipelines but can also be [embedded alongside your existing project](#integration-with-your-project), which helps to fix the problem of different project developers using different local versions of things like `helm`, `kubectl`, etc.

* The containers defined here aren't built from scratch, and official sources are used where possible.  Most tools (like `kubectl`, `helm`, etc) come from [alpine/k8s](https://hub.docker.com/r/alpine/k8s) but many other tools are also included (like `k9s`, `k3d`).  This isn't an attempt to build an omnibus "do-everything" container.. it's more a response to the fact that there are a lot of diverse tools that really can't be unified, so it's better to just learn how to work with that.

Besides bundling some tooling, this repository is the reference implementation of a pattern for [bridging compose services and Makefile targets](#composemk), **providing a minimum viable automation framework for orchestrating tasks across tool containers that is expressive and flexible, while also focusing on minimizing both conceptual overhead and software dependencies.**  This pattern is incredibly useful for lots of things, but this reference focuses on a few use-cases in particular:

1. Decoupling project automation from the choice of CI/CD backend
1. Proper separation of automation tasks from specifications for runtime / container context.
1. Per-project tool-versioning, providing defaults but allowing overrides, and generally ensuring versions match everywhere.
1. Project-local kubernetes clusters & corresponding lifecycle automation using kind or k3d.
1. Cluster lifecycle / development / debugging workflows in general.
1. Less shell code in general, but where we need it: it should be reasonably structured, and it <u>shouldn't</u> be embedded in YAML.

There's a lot of hate for `make` (especially for "creative" usage of it!), but you'll find that these are not the Makefile's of your ancestors.

**Working with [compose.mk](#composemk) and [k8s.mk](#k8smk) makes `make` hit different.**  Beyond addressing the issues above, these tools generally produce carefully curated output that's emphasizing human-friendly readability *and* machine-friendly output for downstream processing.  They can add new capabilities to `make` itself, including some support for [quickly building custom TUIs](#embedded-tui).  

<img src=img/tui-5.gif>

Support for [container dispatch](#container-dispatch) feels like a tiny, unobtrusive DSL layer on top of tech you already know, and you can run it anywhere you are, and spend less time negotiating with bolted-on plugin-frameworks, hook systems, and build-bots.  (And the build-bots themselves will be happy to run it too.)

On the one hand, lots of `compose.mk` functionality is just syntactic sugar for string-rewriting.  But the other hand.. the result actually feels like a new paradigm, and tends to encourage better design for your automation.  Things like [simple workflow support](#api-flux) and [stream support](#api-stream) means that working with `make` feels more like a programming language, and as used from "outside" these can also help to cleanup existing bash scripts.

{#This diagram shows the way that the elements of the compose.mk / k8s.mk / k8s-tools.yml trifecta are related to each other:<center><img src="docs/trifecta.png"></center>#}
