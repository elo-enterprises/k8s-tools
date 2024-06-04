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

If you're interested in the gory details of the longer-format answer, there's more detailed discussion in the [Design Philosophy section](#why-makefilek8smk).

Documentation per-target is included in the next section, but these tools aren't that interesting in isolation.  See the [Cluster Automation Demo](#demo-cluster-automation) for an example of how you can put all this stuff together.

----------------------------------------------------

### k8s.mk API 

You'll need to have setup KUBECONFIG before running most of these targets.

*This documentation is pulled automatically from [source](compose.mk)*

#### API::k8s.mk::k8s

The *`k8s.*`* targets cover .....

{% set targets=bash('pynchon makefile parse k8s.mk| jq \'with_entries(select(.key | startswith("k8s")))\'', load_json=True) %}
{% for tname in targets %}
#### **`{{tname.replace('%','<arg>')}}`**

```bash 
{{ "\n".join(targets[tname].docs).strip()}}
```
{% endfor %}

#### API::k8s.mk::kubefwd

The *`kubefwd.*`* targets cover .....

{% set targets=bash('pynchon makefile parse k8s.mk| jq \'with_entries(select(.key | startswith("kubefwd")))\'', load_json=True) %}
{% for tname in targets %}
#### **`{{tname.replace('%','<arg>')}}`**

```bash 
{{ "\n".join(targets[tname].docs).strip()}}
```
{% endfor %}

#### API::k8s.mk::k3d

The *`k3d.*`* targets cover .....

{% set targets=bash('pynchon makefile parse k8s.mk| jq \'with_entries(select(.key | startswith("k3d")))\'', load_json=True) %}
{% for tname in targets %}
#### **`{{tname.replace('%','<arg>')}}`**

```bash 
{{ "\n".join(targets[tname].docs).strip()}}
```
{% endfor %}

#### API::k8s.mk::helm

The *`helm.*`* targets cover .....

{% set targets=bash('pynchon makefile parse k8s.mk| jq \'with_entries(select(.key | startswith("helm")))\'', load_json=True) %}
{% for tname in targets %}
#### **`{{tname.replace('%','<arg>')}}`**

```bash 
{{ "\n".join(targets[tname].docs).strip()}}
```
{% endfor %}
