{% import 'macros.j2' as macros -%}

### API: k8s.mk: (Static Targets)

This is the complete list of namespaces & targets available from k8s.mk, along with their documentation.  Most documentation is pulled automatically from [the latest source](compose.mk). First, some important notes about how these targets work.

The best way to use these targets is in combination with `compose.mk` and `k8s-tools.yml`, following the [makefile integration docs](#embedding-tools-with-makefiles).  See also the docs for the [Make/Compose Bridge](#makecompose-bridge) and [Container Dispatch](#container-dispatch).

Still, many of these targets can run "natively" if your host already has the relevant tools, and some targets like `k8s.shell` can default to using containers if present, then fall-back to using kubectl directly.

Target names are reserved names after declaration, but collisions aren't likely because things are organized into a few namespaces:

1. You'll need to have setup KUBECONFIG before running most of these
1. Targets are usable interactively from your shell as `make <target>` or `k8s.mk <target>`
1. Targets are usable as an API, either as target prereqs or as part of the body in your targets

* **Most targets depend on compose.mk.** When used in stand-alone mode, k8s.mk will attempt to import compose.mk from the same directory.
* **Most targets have a soft-requirement k8s-tools.yml.** This isn't always a hard-requirement if you have tools like `kubectl` available already on the docker-host.
* **Targets are usable interactively from your shell** as `make <target>` or `./k8s.mk <target>`.  If you use k8s.mk directly here, you need to set vars like `KUBECONFIG` yourself instead of relying on your project Makefile to set them up.
* **Targets are usable as an API,** either as prereq-targets or as part of the body in your targets.
* **Target names are reserved names after declaration.**

Things are organized into a few namespaces, which hopefully avoids collisions with your project targets.

* [k8s.* targets:](/docs/api#api-k8s) Default namespace with general helpers.  These targets only use things available in the [k8s:base container](k8s.yml).
* [k3d.* targets:](/docs/api#api-k3d):  Helpers for working with the `k3d` tool / container
* [kubefwd.* targets:](/docs/api#api-kubefwd) Helpers for working with `kubefwd` tool / container
* [helm.* targets:](/docs/api#api-helm) Helpers for working with `helm` tool / container

{% set help_extra="Docs below typically refer to `compose.mk` as the executable involved, but if you're using integrated rather than stand-alone mode, you should use `make` instead to work with your own project's context!" %}


#### API: k8s

This is the default target-namespace for `k8s.mk`.  It covers general helpers.  For more details, read on into the API, or see the [k8s:base container spec in k8s-tools.yml]({{macros.search_link('k8s-tools.yml', 'k8s:base',github)}})

{{macros.parse_help('k8s.mk', 'k8s')}}

#### API k3d

The *`k3d.*`* targets describe a small interface for working with `k3d`.  Most targets in this namespace will use k3d directly, and so are usually **dispatched**, and not run from the host.  Most targets are small utilities that can help to keep common tasks idempotent, but there's also a TUI that provides a useful overview of what's going on with K3d:

For more details, read on into the API, or see the [k8s:k3d container spec in k8s-tools.yml]({{macros.search_link('k8s-tools.yml', 'k3d', github)}})
  
{{macros.parse_help('k8s.mk', 'k3d')}}

#### API: kubefwd

The *`kubefwd.*`* targets describe a small interface for working with kubefwd.  It aims to cleanly background / foreground `kubefwd` in an unobtrusive way, with clean setup/teardown and reasonable defaults for usage per-project.  These targets use [the kubefwd container]({{macros.search_link('k8s-tools.yml','k8s:kubefwd',github)}}), but are generally safe to run from the docker-host.  Forwarding is not just for ports but for DNS as well.  This takes effect everywhere, including the containers in k8s-tools.yml (via /etc/hosts bind-mount), as it does the docker-host.

{{macros.parse_help('k8s.mk','kubefwd')}}

#### API: helm

Nothing fancy, just a very small interface for idempotent operations with `helm`.  For more details, read on into the API, or see the [`k8s:helm` container spec in k8s-tools.yml]({{macros.search_link('k8s-tools.yml', 'helm', github)}}).

{{macros.parse_help('k8s.mk', 'helm')}}
