## Makefile.k8s.mk

`Makefiles.k8s.mk` includes lots of helper targets for working with kubernetes.  It works best in combination with Makefile.compose.mk and k8s-tools.yml, but that isn't required if things like `kubectl` are already available on your host.  These targets assume that KUBECONFIG is already set when they are running.

The focus is on simplifying few categories of frequent interactions:

1. Reusable implementations for common cluster automation tasks (like waiting for pods to get ready)
1. Context-management tasks (like setting the currently active namespace)
1. Interactive debugging tasks (like shelling into a new or existing pod inside some namespace)

Documentation per-target is included in the next section, but these tools aren't that interesting in isolation.  See the [Cluster Automation Demo](#demo-cluster-automation) for an example of how you can put all this stuff together.

### Static Targets for Makefile.k8s.mk

Here's an overview of available targets.  

Note that almost all of these targets will [require KUBECONFIG to already be set](#kubeconfig-should-already-be-set).  

{% set targets=bash('pynchon makefile parse Makefile.k8s.mk', load_json=True) %}
{% for tname in targets %}
#### **`{{tname.replace('%','<arg>')}}`**

```bash 
{{ "\n".join(targets[tname].docs).strip()}}
```
{% endfor %}
