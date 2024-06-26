{% import 'macros.j2' as macros -%}

#### API: k8s

This is the default target-namespace for `k8s.mk`.  It covers general helpers, and generally assumes the only requirements are things that are available in the [k8s:base container](k8s.yml).

{{macros.parse_help('k8s.mk','k8s')}}

#### API: kubefwd

The *`kubefwd.*`* targets describe a small interface for working with kubefwd.  It just aims to cleanly background/foreground kubefwd in an unobtrusive way.  Safe to use from host, these targets always use [the kubefwd container](https://github.com/search?q=repo%3Aelo-enterprises%2Fk8s-tools+path%3Ak8s-tools.yml+kubefwd&type=code).

{{macros.parse_help('k8s.mk','kubefwd')}}

#### API k3d

The *`k3d.*`* targets describe a small interface for working with `k3d`, just to make the common tasks idempotent.  These targets use k3d directly, so are usually **dispatched**, and not run from the host.  (See also the demos & examples for more usage info).  Uses the [k3d container](https://github.com/search?q=repo%3Aelo-enterprises%2Fk8s-tools+path%3Ak8s-tools.yml+k3d&type=code)

{{macros.parse_help('k8s.mk','k3d')}}

#### API: helm

A very small interface for idempotent operations with `helm`.

{{macros.parse_help('k8s.mk','helm')}}
