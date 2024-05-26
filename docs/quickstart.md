## Quick Start

### Clone/Build/Test This Repo

```bash
# for ssh
$ git clone {{github.repo_ssh_url}}

# or for http
$ git clone {{github.repo_url}}

# build the tool containers & check them
$ make clean build test
```

----------------------------------------------------

### Tools via Compose CLI

```bash
{%- for svc in bash("make -s k8s-tools/__services__").split() %}
$ docker compose run -f k8s-tools.yml {{svc}} ...{% endfor %}
```

----------------------------------------------------

### Tools via Make 

Commands like this will work at the repository root.  

```bash 
# run k9s container (intreractive)
$ make k9s

# run helmify (which expects stdin)
$ cat manifest.yml | make helmify/pipe

# run kubectl, which can be used directly or with pipes 
$ cmd='apply -f manifest.yml' make kubectl
$ cat manifest.yml | make kubectl/pipe cmd='apply -f -'

# drop to a shell to work with helm (interactive; . is already a volume)
$ make helm/shell

# get cluster info from k3d
$ make k3d cmd='cluster list -o json'
```

For more details on other targets available, how this works in general, and what else you can do with it.. read on in [this section](#makecompose-bridge).

## Docs & Examples

This repository includes lots examples for Make/Compose integration, including:

* [A simple demo](#makecompose-bridge), 
* [A dispatch-demo](#container-dispatch), 
* A more [involved tutorial](#demo-cluster-automation), 
* Plus the [integration tests](tests/Makefile.itest.mk), 
* And [end-to-end tests](tests/Makefile.e2e.mk)

For a complete, external project that uses this approach to for cluster automation, see [k3d-faas.git](https://github.com/elo-enterprises/k3d-faas)