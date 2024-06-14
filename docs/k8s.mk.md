## k8s.mk

`Makefiles.k8s.mk` includes lots of helper targets for working with kubernetes.  It works best in combination with compose.mk and k8s-tools.yml, but in many cases that isn't strictly required if things like `kubectl` are already available on your host.  There are a small number of macros available, but most of the public interface is static targets.

The focus is on simplifying few categories of frequent interactions:

1. Reusable implementations for common cluster automation tasks (like waiting for pods to get ready)
1. Context-management tasks (like setting the currently active namespace)
1. Interactive debugging tasks (like shelling into a new or existing pod inside some namespace)

----------------------------------------------------

### But Why?

There's many reasons why you might want these capabilities if you're working with cluster-lifecycle automation.  People tend to have strong opions about this topic, and it's kind of a long story.  

The short version is this: 

* Tool versioning, idempotent operations, & deterministic cluster bootstrapping are all hard problems, but not really the problems we *want* to be working on.
* IDE-plugins and desktop-distros that offer to manage Kubernetes are hard for developers to standardize on, and tend to resist automation.  
* Project-local clusters are much-neglected, but also increasingly important aspects of project testing and overall developer-experience.  
* Ansible/Terraform are great, but they have a lot of baggage, aren't necessarily a great fit for this type of problem, and they also have to be versioned.  

k8s.mk, especially combined with k8s-tools.yml and compose.mk, is aimed at fixing this stuff.  Less fighting with tools, more building things.

If you're interested in the gory details of the longer-format answer, there's more detailed discussion in the [Design Philosophy section](#why-k8smk).

Documentation per-target is included in the next section, but these tools aren't that interesting in isolation.  See the [Cluster Automation Demo](#demo-cluster-automation) for an example of how you can put all this stuff together.

----------------------------------------------------

### k8s.mk API 

This is the complete list of namespaces & targets available from k8s.mk, along with their documentation.  All documentation is pulled automatically from [the latest source](k8s.mk).

First, some important notes about how these targets work.

1. You'll need to have setup KUBECONFIG before running most of these
1. Targets are usable interactively from your shell as `make <target>` or `k8s.mk <target>`
1. Targets are usable as an API, either as target prereqs or as part of the body in your targets

The best way to use these targets is in combination with `compose.mk` and `k8s-tools.yml`, following the [makefile integration docs](#embedding-tools-with-makefiles).  See also the docs for the [Make/Compose Bridge](#makecompose-bridge) and [Container Dispatch](#container-dispatch).

Still, many of these targets can run "natively" if your host already has the relevant tools, and some targets like `k8s.shell` can default to using containers if present, then fall-back to using kubectl directly.

Target names are reserved names after declaration, but collisions aren't likely because things are organized into a few namespaces:

* [k8s.* targets:](#api-k8s) Default namespace with general helpers.  These targets only use things available in the [k8s:base container](k8s.yml).
* [k3d.* targets:](#api-k3d):  Helpers for working with the `k3d` tool / container
* [kubefwd.* targets:](#api-kubefwd) Helpers for working with `kubefwd` tool / container
* [helm.* targets:](#api-helm) Helpers for working with `helm` tool / container

{% include "api-k8s.md" %}