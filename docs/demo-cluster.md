## Demo: Cluster Automation

{% set div="\n###############################################################################\n" %}
{% set sections = open('tests/Makefile.e2e.mk','r').read().split(div) %}

This section is a walk-through of the [end-to-end test](tests/Makefile.e2e.mk) included in the test-suite.  

First up, there's some pretty standard boilerplate and setting values for constants.  

```Makefile 
# tests/Makefile.e2e.mk

{% for line in sections[0].strip().split('\n') %}{%if line.strip() and not line.lstrip().startswith('#')%}{{line+'\n'}}{% endif %}{% endfor %}
```

The `K3D_VERSION` part above is probably the most interesting, because it overrides defaults [in k8s-tools.yml](k8s-tools.yml), and effectively allows you to **pin tool versions inside scripts that use them, without editing with the compose file.**  Several of the compose-services support explicit overrides along these lines, and it's a convenient way to test upgrades.

Next we organize some targets for cluster-operations.  Below you can see there are two public targets declared for direct access, and two private targets that run inside the `k3d` tool container.

```Makefile 
# tests/Makefile.e2e.mk

{% for line in sections[1].strip().split('\n') %}{%if line.strip() and not line.lstrip().startswith('#')%}{{line+'\n'}}{% endif %}{% endfor %}
```

Running `make clean` looks like this when it's tearing down the cluster:

<img src="img/e2e-clean.gif">

--------------------------------------------------

The `list` part makes the create target idempotent in the way you'd expect.  Here we're using CLI arguments for most of the cluster spec, but depending on your version, k3d supports most of this in external config yaml.

Running `make init` looks like this when it's setting up the cluster:

<img src="img/e2e-init.gif">

The next section of the Makefile covers cluster provisioning.  Here we just want to install a helm chart, and to add a special "test-harness" pod to the default namespace.  

But we also want operations to be idempotent, and blocking operations where that makes sense, and we want to provide several entrypoints for the convenience of the user.

```Makefile 
# tests/Makefile.e2e.mk

{% for line in sections[2].strip().split('\n') %}{%if line.strip() and not line.lstrip().startswith('#')%}{{line+'\n'}}{% endif %}{% endfor %}
```

Note that the `test_harness.provision` target above doesn't actually have a body!  The `k8s.*` targets coming from Makefile.k8s.mk (documented [here](#static-targets-for-makefilek8smk)) do all of the heavy lifting.  Meanwhile helm provisioning looks like this:

<img src="img/e2e-provision-helm.gif">

-----------------------------------------

Helm is just an example.  Volumes for file-sharing with the container are also already setup, so you can `kustomize` or `kubectl apply` referencing the file system directly.

The other part of our provisioning is bootstrapping the test-harness pod, which looks like this:

<img src="img/e2e-provision-test-harness.gif">

----------------------------------------------

With the test-harness in place, there's a block of target definitions for a miniature test-suite that checks properties of the cluster.

```Makefile 
# tests/Makefile.e2e.mk

{% for line in sections[3].strip().split('\n') %}{%if line.strip() and not line.lstrip().startswith('#')%}{{line+'\n'}}{% endif %}{% endfor %}
```

Amongst other things, the section above is using a streaming version of the `k8s.shell/<namespace>/<pod>/pipe` (we'll get to an interative version in later secitons).

You can use this to assert things about the application pods you've deployed (basically a smoke test).  It's also useful for quick and easy checks that cover aspects of cluster internal networking, dns, etc.

Running `make test` looks like this:

<img src="img/e2e-test.gif">

----------------------------------------------

The tests are not a bad start for exercising the cluster.  Since we blocked on pods or whole-namespaces being ready, we know that nothing is stuck in crash loop or container-pull.  We also know that there were not errors with the helm charts, and that we can communicate with test-harness pods.  

What if you want to inspect or interact with things though?  The next block of target definitions provides a few aliases to help with this.

```Makefile 
# tests/Makefile.e2e.mk

{% for line in sections[4].strip().split('\n') %}{%if line.strip() and not line.lstrip().startswith('#')%}{{line+'\n'}}{% endif %}{% endfor %}
```

Again, no target bodies because `k8s.*` targets for stuff like this already exist, and we just need to pass in the parameters for our setup.  

Shelling into a pod is easy.  Actually `make k8s.shell/<namespace>/<pod_name>` was *always* easy if Makefile.k8s.mk is included, but now there's an even-easier alias that makes our project more self-documenting.  

<img src="img/e2e-interactive-shell.gif">

The `*k8s.shell/<namespace>/<pod_name>*` target used above is interactive, but there's also 

How about something to inspect the full k3d context?  Here's a side-by-side view of the kubernetes namespace (visualized with `k9s`), and the local docker containers (via `lazydocker`).

<img src="img/e2e-interactive-tui.gif">


So that's how about ~100 lines of mostly-aliases-and-documentation Makefile is enough to describe a simple cluster lifecycle, and can give access to ~20 versioned platforming tools, all with no host dependencies except docker-compose + make.  It's simple, structured, portable, and lightweight.

No container orchestration logic was harmed during the creation of this demo, nor confined into a Jenkinsfile or github action, and yet [it all works from github actions](https://github.com/elo-enterprises/k8s-tools/actions).  

Happy platforming =D
