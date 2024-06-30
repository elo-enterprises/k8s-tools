
## Features

[k8s-tools.yml](#) | [compose.mk](#) | [k8s.mk](#)

**[k8s-tools.yml](k8s-tools.yml)** is a compose file with 20+ container specifications covering popular platforming tools and other utilities for working with Kubernetes.  This file makes use of the [dockerfile_inline directive](https://docs.docker.com/compose/compose-file/build/#dockerfile_inline), plus the fact that tool-containers  *tend to involve layering really small customizations*.  Now you can version these tools explicitly, customize them if you need to, and still avoid having N Dockerfiles cluttering up your whole repository.  Here's a quick overview of the manifest and some details about versioning:

* **Local parts of the tool bundle** ([See the latest here](k8s-tools.yml))
  * <ins>Cluster management:</ins> [kind](https://github.com/kubernetes-sigs/kind), [k3d](https://k3d.io/)
  * <ins>Workflows, FaaS, and Misc Platforming Tools:</ins> [argocli](https://argo-workflows.readthedocs.io/en/latest/walk-through/argo-cli/), [kn](https://knative.dev/docs/client/install-kn/), [fission](https://fission.io/docs/installation/), [rancher](https://github.com/rancher/cli)
  * <ins>Lower-level helpers:</ins> [helmify](https://github.com/arttor/helmify), [kompose](https://kompose.io/), [kubefwd](https://github.com/txn2/kubefwd)
  * <ins>Monitoring and metrics tools:</ins> [promtool](https://prometheus.io/docs/prometheus/latest/command-line/promtool/), [k9s](https://k9scli.io/), [lazydocker](https://github.com/jesseduffield/lazydocker)
  * <ins>Krew plugins:</ins> [sick-pods](https://github.com/alecjacobs5401/kubectl-sick-pods), [ktop](https://github.com/vladimirvivien/ktop), [kubectx, and kubens](https://github.com/ahmetb/kubectx) available by default, and more on demand.
  * <ins>TUI and user-messaging utilities</ins>: [gum](https://github.com/charmbracelet/gum), [pv](https://www.ivarch.com/programs/pv.shtml), [spark](https://raw.githubusercontent.com/holman/spark/)
  * <ins>General Utilities:</ins> Fixed (i.e. non-busybox) versions of things like date, ps, uuidgen, etc
* **Upstream parts of the tool bundle** ([See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.)
  * <ins>Cluster management:</ins> [eksctl](https://github.com/weaveworks/eksctl)
  * <ins>Core Utilities:</ins> [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [kustomize](https://github.com/kubernetes-sigs/kustomize), [helm](https://github.com/helm/helm), [krew](https://github.com/kubernetes-sigs/krew)
  * <ins>Misc Utilities:</ins> [helm-diff](https://github.com/databus23/helm-diff), [helm-unittest](https://github.com/helm-unittest/helm-unittest), [helm-push](https://github.com/chartmuseum/helm-push), [kubeseal](https://github.com/bitnami-labs/sealed-secrets), [vals](https://github.com/helmfile/vals), [kubeconform](https://github.com/yannh/kubeconform)
  * <ins>Cloud Utilities:</ins> [awscli v1](https://github.com/aws/aws-cli), [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
  * <ins>General Utilities:</ins> Such as bash, curl, jq, yq, etc
* **Versioning for Tools:**
  * *Tooling in the local bundle is all versioned independently:*
    * Defaults are provided, but [overrides allowed from environment variables](docs/env-vars.md#k8stoolsyml).
  * *Upstream tool versioning is determined by the alpine-k8s base,*
    * But *k8s-tools.yml* has service-stubs and layout that can be easily changed if you need something specific.
* **Other Features:**
  * *Just-in-Time & On-Demand:*
    * As usual with docker-compose, containers aren't pulled until they are used, and build-when-changed mostly works as you'd expect.
    * *Having these declared in case of eventual use won't saddle you with an enormous bootstrap process!*
  * *Sane default volumes for tool-containers,* including:
    * Sharing the working directory, docker socket, and kubeconfigs for you automatically.  
  * *Fixes docker file-permissions for root-user containers* (*[more details here](#docker-and-file-permissions)*).
  * 🚀 *Executable file:*  
    * `./k8s-tools.yml ...  <==> docker compose -f k8s-tools.yml ...`

The focus for k8s-tools.yml is to stand alone with no host dependencies, not even Dockerfiles, yet provide boilerplate that's parametric enough to work pretty well across different projects, without changing the compose file.  If the default tool versions don't work for your use-cases, [k8s-tools.yml probably has an environment variable you can override](#environment-variables).

-------

After you've made your whole tool chain portable in one swipe, you might also be interested in *driving* those tools with something that offers more structure than a shell script, and something that also *won't add to your dependencies*.  If that sounds interesting, you might like to meet `compose.mk` and `k8s.mk`.

<ins>**[compose.mk](#composemk)** is simultaneously a Makefile automation library and a stand-alone CLI tool. It defines targets and macros that can extend Make's core functionality in a variety of ways.</ins> One of the most important goals for these extensions is **working with compose files & services**, and describing the `compose.import` macro so that it's very simple to write automation that works with tool containers:

* <ins>Importing Compose Services:</ins>
  * **Tool containers can be 'imported' as a group of related make-targets.**
    * Interact with them using the [Make/compose bridge](#makecompose-bridge)
    * [Use container-dispatch syntax](#container-dispatch) to run existing make-targets **inside** tool containers
    * Use the containers effectively from "outside", or drop into debugging shell "inside"
  * <ins>Tool containers can be anything, defined anywhere:</ins>
      * No explicit dependency for k8s-tools.yml
      * [Multiple compose-files are supported](#multiple-compose-files)
  
  Besides adding docker-compose support, there are many other features that might be interesting:
  
  * **Make Extensions:**  
    * 🚀 **Executable file:** `./compose.mk ...  <==> make -f compose.mk ...`
    * Built-in supervisor process and improved support for signal handling
    * **[Curated collection of reusable utility targets](#composemk-api)**, which can be used as a library with the rest of this automation framework or can be used from the CLI, to complement or simplify existing bash script, etc.  These targets are arranged into a few namespaces:
      * [**`flux.*` targets:**](/docs/api#api-flux) A tiny but powerful workflow/pipelining API, roughly comparable to something like [declarative pipelines in Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/).  This provides composable concurrency & staging operators, where the primitives are usually make-target names.  
      * [**`tux.*` targets:**](#embedded-tui) Control-surface for a tmux-backed console geometry manager.
        * **No host dependencies.** This uses the `compose.mk:tux` tool container to dockerize tmux itself.
        * **Supports docker-in-docker style host-socket sharing with zero configuration,** so your TUI can generally do all the same container orchestration tasks as the docker host.
        * Open split-screen displays, shelling into 1 or more of the tool containers in k8s-tools.yml (or any other compose file).
        * Combines well with `flux.*` targets to quickly create dashboards / custom development environments.
      * [**`stream.*`:**](/docs/api#api-stream) Support for working with streams, including newline/comma/space delimited streams, common use cases with JSON, etc.  Everything here is used with pipes, and reads from stdin.  It's not what you'd call "typed", but it reduces error-prone parsing and moves a little bit closer to structured data.
      * [**`io.*`:**](/docs/api#api-io) Misc. utilities for printing, formatting, timers, etc.
    * **Core**
      * [**`docker.*`:**](/docs/api#api-docker) An interface for working with docker.
      * [**`mk.*`:**](/docs/api#api-docker) Meta-tooling for 'make' itself. This enables help functions, signals and supervisors, some utilities for reflection, etc.
      * [**`compose.*`:**](/docs/api#api-docker) An interface for working with compose.  

-------

<ins>**[k8s.mk](#k8smk)** inherits all the compose.mk features, then adds implicit integration with k8s-tools.yml.</ins>  Both `compose.mk` and `k8s-tools.yml` files are a soft-dependency for `k8s.mk`, because the emphasis is on seamless usage of those containers.  All the simple targets described by the [Make/Compose Bridge](#makecompose-bridge) are available for k8s-tools services.

`k8s.mk` also provides some primitives for common tasks (like waiting for all pods to be ready), context management (*like setting the active namespace*), and the usual patterns (*like idempotent usage of `helm`*).  It can help to smooth over lots of other typical difficulties, like places where `kubefwd` or `ansible` are difficult to use.  `k8s.mk` also inherits and extends the TUI support from compose.mk, including the ability to automate the TUI itself (*like sending specific targets to specific panes*).

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

