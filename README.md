
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
<li><a href="#embedding-pattern-in-existing-projects">Embedding Pattern in Existing Projects</a></li>
<li><a href="#hacks-for-working-with-makefiles">Hacks for Working with Makefiles</a></li>
</ul>
</li>
<li><a href="#debugging">Debugging</a></li>
</ul>
</div>


-------------------------------------------------------------

# Overview

This repository just aggregates a bunch of individual utilities for working with kubernetes into one dockerized toolchain.  It's useful for CI/CD pipelines but also fixes the problem of different project developers using different local versions of things like `helm`.

The containers defined here aren't built from scratch and leverage official sources where possible.  Most tools (like `kubectl`, `helm`, etc) come from [alpine/k8s](https://hub.docker.com/r/alpine/k8s) but other tools are also included (like `k9s`, `k3d`).

Using the pattern described here, it's pretty easy to describe/test/deploy tool upgrades that affect your whole team, or pin different versions of tools for different projects, or use multiple versions of the tools in the same project.

-------------------------------------------------------------

## Features

Unique parts of the bundle. See the [docker-compose.yml](docker-compose.yml) for more details.

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

## Embedding Pattern in Existing Projects

For using this with your existing projects, you probably want to maintain separated compose files and setup aliases.

```bash
$ cp docker-compose.yml myproject/k8s-tools.yml
$ alias helm=docker compose -f myproject/k8s-tools.yml run helm
$ helm ....
```

Aliases are convenient but rather fragile (obviously this will break if you move your `myproject` folder around).  See the next section for something that is a little more durable.

## Hacks for Working with Makefiles

If you're already frequently working with Makefiles in your automation, you might be interested in the following fairly magical incantation to help with proxying commands towards docker-compose:

```Makefile
# myproject/Makefile

k8s/%:
	docker compose -f docker-compose.yml run ${*} $${cmd:-}
```

Here *`k8s/%`* is a namespaced parametric target and basically it sends commands like `make k8s/helm cmd="version"` to `docker compose run helm version`.  The *`cmd`* argument is optional if you have nothing to pass to the container's run command.  This style is a bit shorter than the full invocation, but longer than a bash alias.  The benefits are that aliases across many projects won't get tangled, developers do not have to sync their personal .bashrcs, and your Makefile probably already includes project environment variables (like an appropriate `KUBECONFIG`)

Here's another trick: If your project requires several environment variables (say `KUBECONFIG` & `CLUSTER_NAME`), you can drop into a shell *starting* from the Makefile using `make shell` and have access to those variables, or a subset of those variables.  This is not just a convenience, but it's also *safer* than potentially mixing up your dev/prod KUBECONFIGs =)

```Makefile
# myproject/Makefile

shell:
	@# Full shell, inheriting the parent environment (including `export`s from this Makefile)
  env bash -l

ishell:
  @# An isolated shell, no environment passed through.
	env -i bash -l

pshell:
  @# Passing a partial environment, only the $USER var
	env -i `env|grep USER` bash -l

dshell:
  @# a container shell, jumping into the base defined in the compose file
  docker compose -f docker-compose.yml run --entrypoint bash base
```

-------------------------------------------------------------

# Debugging

1. Note that `KUBECONFIG` must be set for things to work!  Sadly, lots of tools will fail even simple invocations like `kubectl version` or `--help` if this is undefined or set incorrectly, and will often crash with confusing messages.
1. By default, the compose file shares the working directory with containers it's using.  This means your manifests need to be in or below the working directory!  The compose file itself can be anywhere though, so instead of keeping it in your projects source-tree you can opt to deploy it separately to `/opt` or `~/.config`
