{% import 'macros.j2' as macros -%}

## Overview

**This repository aggregates 20+ individual utilities for working with kubernetes into one dockerized toolchain, hosted inside a single compose file as [k8s-tools.yml](k8s-tools.yml).**  It's useful for CI/CD pipelines or general development, and can be [embedded alongside your existing project](#integration-with-your-project), which helps to fix the problem of different project developers using different local versions of things like `helm`, `kubectl`, etc.

Containers defined here aren't built from scratch, and official sources are used where possible.  Low-level tools (like `kubectl`, `helm`, etc) mostly come from [alpine/k8s](https://hub.docker.com/r/alpine/k8s) but [many other tools](#features) (like `argo`, `k9s`, `k3d`, etc) are also included.  However, *this isn't an attempt to build an omnibus "do-everything" container..* it's more a response to the fact that there are a lot of diverse tools that really can't be unified, so it's better to just learn how to work with that.  Tools containers are versioned independently, and pulled only when they are used.

**Besides bundling some tooling, this repository is a reference implementation** for a pattern that [bridges compose services and Makefile targets](#composemk), describing a "minimum viable automation-framework" for [orchestrating tasks across tool containers](#container-dispatch).  It's expressive and flexible, yet also focused on minimizing both conceptual overhead and software dependencies.  It's incredibly useful for lots of things, and whether it is a tool, a library, or a framework  depends on how you decide to use it.  

This reference focuses on a few use-cases in particular:

1. Cluster lifecycle / development / debugging workflows in general.
1. Decoupling project automation from the choice of CI/CD backend.
1. Project-local kubernetes clusters & corresponding lifecycle automation using kind or k3d.
1. Proper separation of automation tasks from specifications for runtime / container context.
1. Less shell code in general, but where we need it: it <u>shouldn't</u> be embedded in YAML, Jenkinsfiles, etc.
1. Per-project tool-versioning, providing defaults but allowing overrides, and ensuring versions match everywhere.
1. Generally modernizing & extending `make` for containers, colors, and concurrency, making it ready for the 21st Century.

There's a lot of hate for `make` (especially for "creative" usage of it!), but you'll find that these are not the Makefile's of your ancestors.  Support for [container dispatch](#container-dispatch) feels like a tiny, unobtrusive DSL on top of tech you already know, and you can run it anywhere you are.  Less time spent negotiating with bolted-on plugin-frameworks, hook systems, and build-bots, more time for the problems you care about.  And yes, *the build-bots themselves will be happy to run your automation.*  See the [this repo's github actions](https://github.com/elo-enterprises/k8s-tools/actions?query=branch%3Amaster), which bootstrap and exercise a cluster as part of the [end to end tests](#demo-cluster-automation).

**Working with [compose.mk](#composemk) and [k8s.mk](#k8smk) makes `make` hit different.**  

Beyond addressing the issues above, these tools add new capabilities to `make` itself, including some support for [quickly building custom TUIs](#embedded-tui).  

<table>
    <tr>
        <td></td>
        <td></td>
        <td></td>
    </tr>
    </table>
{{macros.img_link("img/e2e-k3d.commander.gif", "90%")}}

With or without the TUI, all output is carefully curated, aiming to be readable and human-friendly while still remaining machine-friendly for downstream processing.

{#On the one hand, many `compose.mk` features are just syntactic sugar for string-rewriting.  But the other hand.. the result actually feels like a new paradigm, and tends to encourage better design for your automation.  The API also includes [workflow support](/docs/api.md#api-flux) and [stream support](/docs/api.md#api-stream), so that working with `compose.mk` feels more like a programming language, and can be used from "outside" to cleanup existing bash scripts.#}