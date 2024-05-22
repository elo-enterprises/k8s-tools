## Overview

This repository aggregates a bunch of individual utilities for working with kubernetes into one dockerized toolchain, hosted inside a single compose file as [k8s-tools.yml](k8s-tools.yml).  It's useful for CI/CD pipelines but can also be [embedded alongside your existing project](#integration-with-your-project), which helps to fix the problem of different project developers using different local versions of things like `helm`, `kubectl`, etc.

The containers defined here aren't built from scratch, and official sources are used where possible.  Most tools (like `kubectl`, `helm`, etc) come from [alpine/k8s](https://hub.docker.com/r/alpine/k8s) but many other tools are also included (like `k9s`, `k3d`).

This isn't an attempt to build an omnibus "do-everything" container, it's more a response to the fact that there are a lot of diverse tools that really can't be unified, so it's better to just learn how to work with that.

Besides bundling some tooling, this repository is the reference implementation of a pattern for [bridging compose services and Makefile targets](#makefilecomposemk), **providing a minimum viable framework for orchestrating tasks across those tool containers.** This pattern makes it easy to read/write/run/organize those tasks, and makes it easier to avoid lock-in from things like Jenkinsfiles or Github Actions.

{#Using this approach, it's easy to describe/test/deploy tool versioning that affect your whole team, or pins different versions of tools for different projects, or uses multiple versions of the tools in the same project.  Bonus: none of your automation will get locked up in Jenkinsfile's, github actions, etc where it's difficult to run.#}
