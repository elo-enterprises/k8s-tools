
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
<li><a href="#troubleshooting">TroubleShooting</a></li>
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

- [k3d](https://k3d.io/)
- [k9s](https://k9scli.io/)
- [kompose](https://kompose.io/)

Plus the stuff from upstream. [See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details.

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

## Hacks for Working with Makefiles 

If you're already frequently working with Makefiles in your automation, you might be interested in the following fairly magical incantations to help with proxying commands towards docker-compose:

```Makefile
# myproject/Makefile

export MAKECMDGOALS

k8s/%:
	docker compose -f k8s-tools.yml run ${*} $${MAKECMDGOALS#*k8s/${*}}

%:
	@# NOOP
```

This does a few things, which may or may not be a bad idea for your project setup, but it can give you some awesome powers.  We'll unpack how this works but first let's look at invocation examples.  This basically sends commands like `make k8s/helm version` to `docker compose run helm version`.

First, the line *`export MAKECMDGOALS`* takes a make-var and sends it to bash var (we need this later).  The *`k8s/%`* bit defines a parametric target under a namespace, ensuring that things like `k8s/helm`, `k8s/kubectl`, etc are all legal targets, where *`${*}`* refers to the parameter.  The *`$${MAKECMDGOALS#*k8s/${*}}`* part is truly the stuff of nightmares, mixing obscure syntax in make and bash at the same time, but it just splits the `make k8s/helm version` invocation around *`k8s/helm`* part, so we can proxy the remainder of the invocation to the container.  

You might have noticed that "version" part (or whatever command you're trying to pass through to helm) is not actually a defined target for Make.  That's where the [NOOP](https://en.wikipedia.org/wiki/NOP_(code)) catch-all target *`%`* comes in.

For argument parsing, we need some kind of additional trick, because `make k8s/helm --help` just gives back the help for Make, not for helm.  For this use "--" aka [the POSIX end of options indicator](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_02), and then `make k8s/helm -- --help` works as expected.


-------------------------------------------------------------

# TroubleShooting

1. Note that KUBECONFIG must be set for things to work!  Sadly `kubectl version` and others will often crash with confusing messages when it's undefined or set incorrectly.
1. By default, the compose file shares the working directory with containers it's using.  This means your manifests need to be in or below the working directory!

