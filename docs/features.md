
## Features

{#[k8s-tools.yml](#) | [compose.mk](#) | [k8s.mk](#)#}

**[k8s-tools.yml](k8s-tools.yml)** is a compose file with 20+ container specifications covering popular platforming tools and other utilities for working with Kubernetes.  This file makes use of the [dockerfile_inline directive](https://docs.docker.com/compose/compose-file/build/#dockerfile_inline), plus the fact that tool-containers  *tend to involve layering really small customizations*.  Now you can version these tools explicitly, customize them if you need to, and still avoid having N Dockerfiles cluttering up your whole repository.  Here's a quick overview of the manifest and some details about versioning:

{{macros.collapsed_details('Tool Manifest', level='h4')}}

* **Local parts of the tool bundle** ([See the latest here](k8s-tools.yml))
  * <ins>Cluster management:</ins> [kind](https://github.com/kubernetes-sigs/kind), [k3d](https://k3d.io/)
  * <ins>Workflows, FaaS, and Misc Platforming Tools:</ins> [argocli](https://argo-workflows.readthedocs.io/en/latest/walk-through/argo-cli/), [kn](https://knative.dev/docs/client/install-kn/), [fission](https://fission.io/docs/installation/), [rancher](https://github.com/rancher/cli)
  * <ins>Lower-level helpers:</ins> [helmify](https://github.com/arttor/helmify), [kompose](https://kompose.io/), [kubefwd](https://github.com/txn2/kubefwd)
  * <ins>Monitoring and metrics tools:</ins> [promtool](https://prometheus.io/docs/prometheus/latest/command-line/promtool/), [k9s](https://k9scli.io/), [lazydocker](https://github.com/jesseduffield/lazydocker)
  * <ins>Krew plugins:</ins> [sick-pods](https://github.com/alecjacobs5401/kubectl-sick-pods), [ktop](https://github.com/vladimirvivien/ktop), [kubectx, and kubens](https://github.com/ahmetb/kubectx) available by default, and more on demand.
  * <ins>TUI and user-messaging utilities</ins>: [gum](https://github.com/charmbracelet/gum), [pv](https://www.ivarch.com/programs/pv.shtml), [spark](https://raw.githubusercontent.com/holman/spark/), [tte](https://github.com/ChrisBuilds/terminaltexteffects)
  * <ins>General Utilities:</ins> Fixed (i.e. non-busybox) versions of things like date, ps, uuidgen, etc
  * **Tooling in the local bundle is all versioned independently:**
    * Defaults are provided, but [overrides allowed from environment variables](docs/env-vars.md#k8stoolsyml).
* **Upstream parts of the tool bundle** ([See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.)
  * <ins>Cluster management:</ins> [eksctl](https://github.com/weaveworks/eksctl)
  * <ins>Core Utilities:</ins> [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [kustomize](https://github.com/kubernetes-sigs/kustomize), [helm](https://github.com/helm/helm), [krew](https://github.com/kubernetes-sigs/krew)
  * <ins>Misc Utilities:</ins> [helm-diff](https://github.com/databus23/helm-diff), [helm-unittest](https://github.com/helm-unittest/helm-unittest), [helm-push](https://github.com/chartmuseum/helm-push), [kubeseal](https://github.com/bitnami-labs/sealed-secrets), [vals](https://github.com/helmfile/vals), [kubeconform](https://github.com/yannh/kubeconform)
  * <ins>Cloud Utilities:</ins> [awscli v1](https://github.com/aws/aws-cli), [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
  * <ins>General Utilities:</ins> Such as bash, curl, jq, yq, etc
  * **Upstream tool versioning is determined by the alpine-k8s base,**
    * But *k8s-tools.yml* has service-stubs for quick overrides if you need something specific.
</details>

{#{macros.collapsed_details('Bonus Features', level='h4')}#}

**Tool containers are just-in-time & on-demand,** so that having these declared in case of eventual use won't saddle you with an enormous bootstrap process.  As usual with docker-compose, containers aren't pulled until they are used, and build-when-changed mostly works as you'd expect.  

**Sane defaults for volumes & environments are included for each tool-container,** meaning that sharing the working directory, docker socket, and kubeconfigs is done automatically.  For host vs. container file permissions, `k8s-tools.yml` also attempts to provide *smoother operations with root-user containers* (*[more details here](#docker-and-file-permissions)*.  

For advanced usage of the tool containers defined in `k8s-tools.yml` it's best to pair with `k8s.mk`, but the compose file also works in stand-alone mode.  The file is even executable: 🚀 *./k8s-tools.yml ...*  <==> *docker compose -f k8s-tools.yml ...*

{#</details>#}

**The focus for k8s-tools.yml is to stand alone with no host dependencies, not even Dockerfiles, yet provide boilerplate that's parametric enough to work pretty well across different projects, without changing the compose file.**  If the default tool versions don't work for your use-cases, [k8s-tools.yml probably has an environment variable you can override](docs/environment-variables).

-------

After you've made your whole tool chain portable in one swipe, you might want to focus on *driving* those tools with something that offers more structure than a shell script, and something that also *won't add to your host dependencies*.  If that sounds interesting, you might like to meet `compose.mk` and `k8s.mk`.

<ins>**[compose.mk](#composemk)** is simultaneously a Makefile automation library and a stand-alone CLI tool.</ins>  It defines targets and macros that can extend Make's core functionality in a variety of ways, especially in terms of making it very simple to work with docker-compose files and services, and docker in general.

{{macros.collapsed_details('Importing Compose Services:', level='strong')}}
* **Tool containers can be 'imported' as a group of related make-targets.**
  * Interact with them using the [Make/compose bridge](#makecompose-bridge)
  * [Use container-dispatch syntax](#container-dispatch) to run existing make-targets **inside** tool containers
  * Use the containers effectively from "outside", or drop into debugging shell "inside"
* <ins>Tool containers can be anything, defined anywhere:</ins>
    * No explicit dependency for k8s-tools.yml
    * [Multiple compose-files are supported](#multiple-compose-files)
</details>

Besides adding docker-compose support, there are [many other features](#composemk) that might be interesting.

-------

<ins>**[k8s.mk](#k8smk)** inherits all the *compose.mk* features, then adds implicit integration with *k8s-tools.yml*.</ins>  Both *compose.mk* and *k8s-tools.yml* files are a soft-dependency for *k8s.mk*, because the emphasis is on seamless usage of those containers.  All the simple targets described by the [Make/Compose Bridge](#makecompose-bridge) are available for k8s-tools.yml services.  (See [the full API here](/docs/api#api-k8smk))

`k8s.mk` also provides some primitives for common tasks (*like waiting for all pods to be ready*), context management (*like setting the active namespace*), and the usual patterns (*like idempotent usage of `helm`*).  It can help to smooth over lots of other typical difficulties in places where things like `kubefwd` or `ansible` are difficult to use.  `k8s.mk` also inherits and extends the [TUI support from compose.mk](#embedded-tui), including the ability to automate the TUI itself (*like sending specific targets to specific panes*).

{{macros.collapsed_details('k8s.mk Features', level='strong')}}
* **Main features:**
  * Useful as a library, especially if you're building cluster lifecycle automation
  * Useful as an interactive debugging/inspection/development tool.
  * Helps to do the common tasks quickly, and can do this interactively or from other automation
    * Launch a pod in a namespace, or a shell in a pod, without lots of kubectling
    * Stream and pipe commands to/from pods, or between pods
* **Other Features:** 
  * **[Curated collection of automation interfaces](#k8smk-api)**, arranged into a few namespaces:
    * [**`k8s.*` targets:**](/docs/api#api-k8s) Default namespace with debugging tools, cluster life-cycle primitives, etc.
    * [**`ansible.*` targets:**](/docs/api#api-ansible) A direct interface to containerized versions of things like [kubernetes.core.k8s](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html) or [kubernetes.core.helm](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/helm_module.html), no playbooks required.
    * Plus more specific interfaces to [k3d](/docs/api#api-k3d), [kubefwd](/docs/api#api-kubefwd), etc. [See the full API here.](#k8smk-api)
  * 🚀 *Executable file:*
    * `./k8s.mk ...  <==> make -f k8s.mk ...`
</details>  
