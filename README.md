
<table with=100%>
  <tr>
    <td colspan=2><strong>
    k8s-tools
      </strong>&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
  </tr>
  <tr>
    <td width=15%><img src=img/icon.png style="width:150px"></td>
    <td>
      Dockerized version of a kubernetes toolchain
      <br/><br/>
      <a href="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml"><img src="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml/badge.svg"></a>
    </td>
  </tr>
</table>

-------------------------------------------------------------

<div class="toc">
<ul>
<li><a href="#overview">Overview</a><ul>
<li><a href="#features">Features</a></li>
</ul>
</li>
<li><a href="#quick-start">Quick Start</a><ul>
<li><a href="#clonebuildtest">Clone/Build/Test</a></li>
</ul>
</li>
<li><a href="#embedding-pattern-in-existing-projects">Embedding Pattern in Existing Projects</a></li>
<li><a href="#advanced-makefile-integration">Advanced Makefile Integration</a><ul>
<li><a href="#goal-container-dispatch-targets">Goal: Container Dispatch Targets</a></li>
<li><a href="#goal-default-targets-for-compose-services">Goal: Default Targets for Compose Services</a></li>
</ul>
</li>
<li><a href="#known-issues">Known Issues</a></li>
</ul>
</div>


-------------------------------------------------------------

# Overview

This repository aggregates a bunch of individual utilities for working with kubernetes into one dockerized toolchain.  It's useful for CI/CD pipelines but also fixes the problem of different project developers using different local versions of things like `helm`.

The containers defined here aren't built from scratch and leverage official sources where possible.  Most tools (like `kubectl`, `helm`, etc) come from [alpine/k8s](https://hub.docker.com/r/alpine/k8s) but other tools are also included (like `k9s`, `k3d`).

Besides bundling some tooling, this repository illustrates some patterns for [advanced integration of Makefiles & compose files](#-advanced-makefile-integration).  Using that, it's very easy to describe/test/deploy tool versioning that affect your whole team, or pins different versions of tools for different projects, or uses multiple versions of the tools in the same project.

-------------------------------------------------------------

## Features

Unique parts of the bundle. See the [docker-compose.yml](docker-compose.yml) for more details.

- [helmify](https://github.com/arttor/helmify)
- [kn](https://knative.dev/docs/client/install-kn/)
- [fission](https://fission.io/docs/installation/)
- [k3d](https://k3d.io/)
- [k9s](https://k9scli.io/)
- [kompose](https://kompose.io/)

Plus the stuff from upstream. [See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.

- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [kustomize](https://github.com/kubernetes-sigs/kustomize)
- [helm](https://github.com/helm/helm)
- [helm-diff](https://github.com/databus23/helm-diff)
- [helm-unittest](https://github.com/helm-unittest/helm-unittest)
- [helm-push](https://github.com/chartmuseum/helm-push)
- [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
- [eksctl](https://github.com/weaveworks/eksctl)
- [awscli v1](https://github.com/aws/aws-cli)
- [kubeseal](https://github.com/bitnami-labs/sealed-secrets)
- [krew](https://github.com/kubernetes-sigs/krew)
- [vals](https://github.com/helmfile/vals)
- [kubeconform](https://github.com/yannh/kubeconform)
- General tools, such as bash, curl, jq, yq, etc

Even if you're only interested in the upstream stuff from `alpine/k8s`, the compose file is a lot nicer than the alternative huge `docker run ..` commands, because it sets up volumes for you to share the docker socket, and shares kubeconfigs for you automatically.

-------------------------------------------------------------

# Quick Start

## Clone/Build/Test

```bash
# for ssh
git clone git@github.com:elo-enterprises/k8s-tools.git

# or for http
git clone https://github.com/elo-enterprises/k8s-tools

make clean build test
```

---------------------------------------------------------------

# Embedding Pattern in Existing Projects

For using this with your existing projects, you might want to maintain separated compose files and setup aliases.

```bash
$ cp docker-compose.yml myproject/k8s-tools.yml
$ alias helm=docker compose -f myproject/k8s-tools.yml run helm
$ helm ....
```

Aliases are convenient but rather fragile (obviously this will break if you move your `myproject` folder around).  See the next section for something that is a little more durable.

---------------------------------------------------------------

# Advanced Makefile Integration

Tool containers are much more useful when you can easily dispatch commands to them, especially without some extremely long CLI invocation.  The docker-compose.yml file specifying volumes and such helps a lot but you probably don't want `docker compose run ...` littered all over your build scripts.

If you're already frequently working with Makefiles in your automation, you might be interested in the following fairly magical approach to help with proxying commands and running Makefile targets from *inside* docker-compose.

We'll walk through this with the [k8s-tools compose file](docker-compose.yml), but it actually works with any compose file, or with multiple compose files (more on that later).

If you want to skip the walkthrough because you're interested in seeing a non-toy, in-situ example of how you can use this, see directly [the build for this FaaS-on-K3d cluster](https://github.com/elo-enterprises/faastk/tree/main/Makefile).  That bootstrap is fairly involved, and yet it has *zero* host dependencies except for docker.  This also has the effect of taming and pinning the (project) dependencies that you do have (like specific versions of k3d/kubectl/helm) and ensuring that they work together, and generally making workflows more reproducible.

Integration/implementation is covered later, but first let's get an idea of where we're going.  

## Goal: Container Dispatch Targets

In the words of Whitehead.. *By relieving the brain of all unnecessary work, a good notation sets it free to concentrate on more advanced problems*.  What notation might be convenient for spelling out "run this make target inside this container"?

```Makefile
# myproject/Makefile

bootstrap: ▰/kubectl/bootstrap
↪bootstrap:
  kubectl apply -f ....
```

What on earth is this?  It's not a programming language you've never seen before, it's just a (legal) Makefile that uses unicode symbols in some of the targets.

Partly, this decorator-inspired syntax is creating a convention similar to private methods: it's not easy to type the weird characters at the command line, and it's not supposed to be.  So here, users won't ever call anything except `make bootstrap`.  

But what about the semantics?  Well `make bootstrap` depends on `▰/kubectl/bootstrap`.  This line is meant to indicate that the 2nd target, `↪bootstrap`, will be executed inside the `kubectl` container.  **Notice that the `↪bootstrap` target directly uses the `kubectl` CLI, not a `docker compose run ..` invocation.  This should work as expected even though we're assuming `kubectl` is **not** available on the host, and only available in the tool container.**

This approach is surprisingly powerful.  What else can you do with it?  Suppose our compose file defines 2 services `{ubuntu, alpine}`, which each come from those base images. 

```Makefile
# myproject/Makefile

test: ▰/ubuntu/test ▰/alpine/test
↪test:
  # ... see if musl libc is breaking your code again =P ...
```

This just says that the user-facing `test` target will run the internal `↪test` target on each of the two containers.  

Besides testing, you can easily imagine how this comes in handy for organizing stuff like a big cluster bootstrap process that needs orchestration among several tool containers.  With this approach there is less need to try and get everything into *one* tool container (which can be pretty hard if very different bases are involved).

The best thing about this approach is, **it moves container orchestration functionality outside of esoteric platform-specific CI/CD**.  No weird groovy in Jenkinsfiles or yaml blobs inside .github that developers can't run locally.  As long as your CI/CD supports docker-in-docker.. you can just call `make` from Jenkinsfiles and .github.

## Goal: Default Targets for Compose Services

Aside from target-dispatch, there are some other typical use-cases.  For starters, `docker compose -f k8s-tools.yml run k9s` is awkwardly long, and it would be good if (for example) `make k9s` just worked to launch k9s.

Similarly, if you want to use piped input for commands like `helmify` that support it, then `cat manifest | docker compose -f k8s-tools.yml run -T helmify` is awkward and subtle.. better if it worked as something like `cat manifest.yml | make helmify`.  

In fact, to make this perfectly unambiguous we want the following defaults for each compose service to work as expected:

```bash
# simple alias, directly running the service as described in compose file
make my_compose_service

# explicitly specify entrypoints/commands, overriding compose file
entrypoint=bash cmd='-c uname' make my_compose_service

# drop into a container shell
make my_compose_service/shell

# run scripts inside the container
echo hello-world | make my_compose_service/shell/pipe

# pipe into the default entrypoint for the container (not bash)
echo yaml_or_json_or_whatever | make my_compose_service/pipe
```

Anticipating naming collisions with existing make-targets, compose-services, and maybe even services from multiple compose files, we also want some ability to do namespacing.  

If we don't want to opt in to populating the root target namespace, we should have file-based namespaces for all the `compose_service` targets:

```bash
# default namespacing uses a relative filename, without the .yml extension.
# so for myproject/docker-compose.yml, it's just `docker-compose`
make docker-compose/my_compose_service
make docker-compose/my_compose_service/pipe
make docker-compose/my_compose_service/shell
make docker-compose/my_compose_service/shell/pipe
```

### Integration

Enabling both the container-dispatch targets and all the magic default-targets for your project is fairly simple.  First, copy the files from this repo into your project:

```bash
$ cp k8s-tools/docker-compose.yml myproject/k8s-tools.yml
$ cp k8s-tools/Makefile.compose.mk myproject
```

Now include `Makefile.compose.mk` inside your main project Makefile and call the `compose.import` macro.

```Makefile 
# myproject/Makefile:
#   somewhere near the top of your existing boilerplate

include Makefile.compose.mk
$(eval $(call compose.import, ▰, ↪, TRUE, k8s-tools.yml))

# At this point, targets are defined for whatever services 
# are mentioned in the external compose config, and they are
# ready to use. Now you can dispatch any task to anywhere!
test: ▰/kubectl/test
↪test:
  kubectl --version 
  echo hello world from `uname -n -v`
```

Let's unpack the `compose.import` call.  As used above, it has four arguments: `▰, ↪, TRUE, k8s-tools.yml`.  

* The 1st argument *(▰)* is the **target namespace** to put compose services under.  
* The 2nd argument *(↪)* is the **dispatch prefix** for designating targets used *inside* the named compose service.  

Great, so now you can get rid of the unicode syntax if you want, or choose symbols you like better :)

* The third argument *(TRUE)* determines whether we should add compose-service targets to the *root* of the Makefile, or only under special namespaces.
* The last argument *(k8s-tools.yml)* should be the docker-compose file with services you want to import.

This can be easily adapted for working with *multiple* compose files, but you'll have to think about service-name collisions between those files.  If you have two compose files with the same service name, you can use multiple target-namespaces like this:

```Makefile
# myproject/Makefile
# somewhere near the top of your existing boilerplate
include Makefile.compose.mk

# load 1st compose file under paralleogram namespace 
$(eval $(call compose.import, ▰, ↪, FALSE, mycomposefiles/tools1.yml))

# load 2nd compose file under triangle namespace 
$(eval $(call compose.import, ▲, ↪, FALSE, mycomposefiles/tools2.yml))

test: ▰/service_from_tools1/test ▲/service_from_tools2/test
↪test:
  # Runs inside both containers!
  echo hello world from `uname -n -v`
```

Above `compose.import` is using `FALSE` for the import-to-root argument and so no services are magically available at the top-level.  To invoke the services, you'll have to use the file-based namespaces:

``` bash 
make tools1/service_from_tools1
make tools2/service_from_tools2
```

Confused about what targets are available after using `compose.integrate`?  

```bash 
# the 'help' target provided by Makefile.compose.mk lists 
# most targets, but not the dispatch-related ones.
make help

# the special target __services__ can list services per compose file 
 make tools1/__services__ 
 make tools2/__services__ 
```

These things are demonstrated inside [this projects Makefile](Makefile) and [the tests](tests/).

---------------------------------------------------------------

### Bonus: Host Shells

We've talked about container shells, but project-based manipulation of *host* shells can also be useful.

If your project requires several environment variables (say `KUBECONFIG` & `CLUSTER_NAME`), you can drop into a host shell *starting* from the Makefile using `make shell` and you'll have access to those variables, or a subset of those variables, without jamming stuff into your bashrc.  It's not just a convenience, but it's also *safer* than potentially mixing up your dev/prod KUBECONFIGs =)

```Makefile
# myproject/Makefile

bash:
	@# Full shell, inheriting the parent environment (including `export`s from this Makefile)
  env bash -l

ibash:
  @# An isolated shell, no environment passed through.
	env -i bash -l

pbash:
  @# Passing a partial environment, only the $USER var
	env -i `env|grep USER` bash -l
```

Now if you want to ensure that you've switched context as appropriate, you can run `make bash` from your project root.

-------------------------------------------------------------

# Known Issues

1. Note that `KUBECONFIG` generally must be set for things to work!  Sadly, lots of tools will fail even simple invocations like `helm version` or even `--help` can fail if this is undefined or set incorrectly, and will often crash with confusing messages.
1. By default, the compose file shares the working directory with containers it's using.  This means your manifests need to be in or below the working directory!  The compose file itself can be anywhere though, so instead of keeping it in your projects source-tree you can decide to deploy it separately to `/opt` or `~/.config`
1. Unfortunately, there's not a good way to convince `make` to just proxy arguments without parsing them.  For example `make kubectl apply -f` looks convenient, but it can't pass `apply -f` to the container, instead it will look for an `apply` target, and parse `-f` as a `make` argument.  
