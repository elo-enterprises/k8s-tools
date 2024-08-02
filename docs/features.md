## Features

### Versioned Toolkit

**[k8s-tools.yml](k8s-tools.yml)** is a compose file with 20+ container specifications covering popular platforming tools and other utilities for working with Kubernetes.  This file makes use of the [dockerfile_inline directive](https://docs.docker.com/compose/compose-file/build/#dockerfile_inline), plus the fact that tool-containers  *tend to involve layering really small customizations*.  Now you can version these tools explicitly, customize them if you need to, and still avoid having N Dockerfiles cluttering up your whole repository.  **All tool containers are just-in-time & on-demand,** so that having these declared in case of eventual use won't saddle you with an enormous bootstrap process.  As usual with docker-compose, containers aren't pulled until they are used, and build-when-changed mostly works as you'd expect.  Here's a quick overview of the manifest and some details about versioning:

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

### Bonus Features

**Sane defaults for volumes & environments are included for each tool-container,** meaning that sharing the working directory, docker socket, and kubeconfigs is done automatically.  For host vs. container file permissions, `k8s-tools.yml` also attempts to provide *smoother operations with root-user containers* (*[more details here](/limitations#docker-and-file-permissions)*.  

For advanced usage of the tool containers defined in `k8s-tools.yml` it's best to pair it with the rest of the automation here, but the compose file also works in stand-alone mode.  The file is even executable, and  *./k8s-tools.yml ...*  is equivalent to *docker compose -f k8s-tools.yml ...*.

**The focus for k8s-tools.yml is to stand alone with no host dependencies, not even Dockerfiles, yet provide boilerplate that's parametric enough to work pretty well across different projects  without changing the compose file.**  If the default tool versions don't work for your use-cases, [k8s-tools.yml probably has an environment variable you can override](environment-variables).

-------

### Toolchain Automation

After you've made your whole kit portable in one swipe, you might want to focus on *driving* those tools with something that offers more structure than a shell script, and something that also *won't add to your host dependencies*.  If that sounds interesting, you might like to meet `compose.mk` and `k8s.mk`. 

<ins>**[compose.mk](/compose.mk)** is simultaneously a stand-alone CLI tool and an automation library for working with `make` + containers.</ins>  It defines targets and macros that can extend Make's core functionality in a variety of ways actually, but the main feature is ensuring that it's simple to work with docker-compose files and services, and docker in general.

#### Importing Compose Services

* **Tool containers can be "imported" as a group of related make-targets.**
  * This creates wrapper-targets that use the containers.
  * You can interact with them using the [Make/compose bridge](#makecompose-bridge).
  * You can [use container-dispatch syntax](#container-dispatch) to run existing make-targets **inside** tool containers.
  * You can use the containers effectively from "outside", or drop into debugging shell "inside".
* **Tool containers can be anything, defined anywhere:**
    * No explicit dependency for *k8s-tools.yml*.
    * [Multiple compose-files are supported](#multiple-compose-files)
    * Bring your own compose file and build automation APIs on those instead *(cm-tools.yml? docs-tools.yml? whatever)*

<ins>The best way to think of compose.mk is to consider it an extension of `make` that's written in `make`.</ins>  As a single file with no external dependencies, it can in principle work as a global-install, but the emphasis is on embedding it into existing projects.  Since it doesn't depend explicitly on either `k8s-tools.yml` or `k8s.mk`, it slots comfortably into many kinds of projects that have nothing to do with kubernetes.  Beyond the docker support, there are [many other features](/compose.mk).

-------

<ins>**[k8s.mk](/k8s.mk)** inherits all the *compose.mk* features, then integrates with *k8s-tools.yml*.</ins>  Both *compose.mk* and *k8s-tools.yml* files are a soft-dependency for *k8s.mk*, because the emphasis is on seamless usage of those containers.  

In terms of wrappers, all of the autogenerated targets for low-level container access described by [the Make/Compose Bridge](#makecompose-bridge) are available for the *k8s-tools.yml* services, plus more composite functionality.  

For example, `k8s.mk` provides some primitives for common tasks (*like waiting for all pods to be ready*), context management (*like setting the active namespace*), and the usual patterns (*like idempotent usage of `helm`*).  Besides helping to version tools, it can make it simpler to interact with them or make it simpler to script actions that involve multiple tools. Additionally, `k8s.mk` also inherits and extends the [TUI support from compose.mk](#embedded-tui), including the ability to automate the TUI itself. 

### k8s.mk Features

* **Main features:**
  * Useful as a library, especially if you're building cluster lifecycle automation
  * Useful as an interactive debugging/inspection/development tool.
  * Helps to do the common tasks quickly, either interactively or from other automation
    * Launch a pod in a namespace, or a shell in a pod, without lots of kubectl'ing
    * Stream and pipe commands to/from pods, or between pods
  * Assemble custom interactive dashboards with new or existing TUI elements
  * **[Curated collection of automation interfaces](#k8smk-api)**, arranged into a few namespaces:
      * [**`k8s.*` targets:**](/api#api-k8s) Default namespace with debugging tools, cluster life-cycle primitives, etc.
      * [**`ansible.*` targets:**](/api#api-ansible) A direct interface to containerized versions of things like [kubernetes.core.k8s](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html) or [kubernetes.core.helm](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/helm_module.html), no playbooks and no inventories required.
      * **Many more specific interfaces** to things like [k3d](/api#api-k3d), [kubefwd](/api#api-kubefwd), etc. [See the full API here.](#k8smk-api)
  

Whereas `compose.mk` is useful in general, `k8s.mk` is of course more focused on projects working with kubernetes, and is the best example of how to go about extending `compose.mk`.
