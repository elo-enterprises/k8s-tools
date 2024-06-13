
## Features

[k8s-tools.yml](#) | [compose.mk](#) | [k8s.mk](#)

**[k8s-tools.yml](k8s-tools.yml)** is a compose file with 20+ container specifications covering popular platforming tools and other utilities for working with Kubernetes.  This file makes use of the [dockerfile_inline directive](https://docs.docker.com/compose/compose-file/build/#dockerfile_inline), plus the fact that tool-containers  *tend to involve layering really small customizations*.  Now you can version these tools explicitly, customize them if you need to, and still to avoid having N Dockerfiles cluttering up your whole repository.  

Here's a quick overview of the manifest:

* **Local parts of the tool bundle** ([See the latest here](k8s-tools.yml))
  * **Cluster management:** [kind](https://github.com/kubernetes-sigs/kind), [k3d](https://k3d.io/)
  * **Workflows, FaaS, and Misc Platforming Tools:** [argocli](https://argo-workflows.readthedocs.io/en/latest/walk-through/argo-cli/), [kn](https://knative.dev/docs/client/install-kn/), [fission](https://fission.io/docs/installation/), [rancher](https://github.com/rancher/cli)
  * **Lower level helpers:** [helmify](https://github.com/arttor/helmify), [kompose](https://kompose.io/), [kubefwd](https://github.com/txn2/kubefwd)
  * **Monitoring and metrics tools:** [promtool](https://prometheus.io/docs/prometheus/latest/command-line/promtool/), [k9s](https://k9scli.io/), [lazydocker](https://github.com/jesseduffield/lazydocker)
  * **Krew plugins:** [sick-pods](https://github.com/alecjacobs5401/kubectl-sick-pods), [ktop](https://github.com/vladimirvivien/ktop), [kubectx, and kubens](https://github.com/ahmetb/kubectx) available by default, and more on demand.
  * **TUI and user-messaging utilities**: [gum](https://github.com/charmbracelet/gum), [pv](https://www.ivarch.com/programs/pv.shtml), [spark](https://raw.githubusercontent.com/holman/spark/)
  * **General Utilities:** Fixed (i.e. non-busybox) versions of things like date, ps, uuidgen, etc
* **Upstream parts of the tool bundle** ([See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.)
  * **Cluster management:** [eksctl](https://github.com/weaveworks/eksctl)
  * **Core Utilities:** [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [kustomize](https://github.com/kubernetes-sigs/kustomize), [helm](https://github.com/helm/helm), [krew](https://github.com/kubernetes-sigs/krew)
  * **Misc Utilities:** [helm-diff](https://github.com/databus23/helm-diff), [helm-unittest](https://github.com/helm-unittest/helm-unittest), [helm-push](https://github.com/chartmuseum/helm-push), [kubeseal](https://github.com/bitnami-labs/sealed-secrets), [vals](https://github.com/helmfile/vals), [kubeconform](https://github.com/yannh/kubeconform)
  * **Cloud Utilities:** [awscli v1](https://github.com/aws/aws-cli), [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
  * **General Utilities:** Such as bash, curl, jq, yq, etc

**Versioning for Tools:**

* *Tooling in the local bundle is all versioned independently:*
  * Defaults are provided, but overrides allowed from environment variables.
* *Upstream tool versioning is determined by the alpine-k8s base,*
  * But *k8s-tools.yml* has service-stubs and layout that can be easily changed if you need something specific.

**Other Features:**

* *Just-in-Time & On-Demand:*
  * As usual with docker-compose, containers aren't pulled until they are used, and build-when-changed mostly works as you'd expect.
  * *Having these declared in case of eventual use won't saddle you with an enormous bootstrap process!*
* *Sane default volumes for tool-containers,* including:
  * Sharing the working directory, docker socket, and kubeconfigs for you automatically.  
* *Fixes docker file-permissions for root-user containers* (probably).  
  * Seems to work pretty well in Linux and Mac ([more details](#docker-and-file-permissions)).
* 🚀 *Executable file:*  
  * `./k8s-tools.yml ...  <==> docker compose -f k8s-tools.yml ...`

The focus for k8s-tools.yml is to stand alone with no host dependencies, not even Dockerfiles, yet provide boilerplate that's parametric enough to work pretty well across different projects, without changing the compose file.  If the default tool versions don't work for your use-cases, [k8s-tools.yml probably has an environment variable you can override](#environment-variables).

------

After you've made your whole tool chain portable in one swipe, you might also be interested in *driving* those tools with something that offers more structure than a shell script, and something that also *won't add to your dependencies*.  If that sounds interesting, you might like to meet `compose.mk` and `k8s.mk`.

<ins>**[compose.mk](#composemk)**, a Makefile automation library / CLI tool, defining targets and macros for working with compose files & services.</ins>

**Importing Compose Services:**

The main focus for `compose.mk` is providing the `compose.import` macro:

  * **Tool containers can be 'imported' as a group of related make-targets.**
    * Interact with them using the [Make/compose bridge](#makecompose-bridge)
    * [Use container-dispatch syntax](#container-dispatch) to run existing make-targets **inside** tool containers
    * Use the containers effectively from "outside", or drop into debugging shell "inside"
  * **Tool containers can be anything, defined anywhere:**
      * No explicit dependency for k8s-tools.yml
      * [Multiple compose-files are supported](#) 

**Other Features:** 

  * **[Curated collection of reusable utility targets](#composemk-api)**, which are arranged into a few namespaces:
    * **`flux.*` targets:** A tiny but powerful workflow/pipelining API, roughly comparable to something like [declarative pipelines in Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/).  This provides concurrency/staging operators that compose over make-target names.
    * **`stream.*`:** Primitives for working with streams, including support for newline/comma/space delimited streams, common use cases with JSON, etc.  Everything here is used with pipes, and reads from stdin.  It's not what you'd call "typed", but it reduces error-prone parsing and moves a little bit closer to structured data.
    * **`docker.*`:** A small interface for working with docker.  
    * **`io.*`:** Misc. utilities for printing, formatting, timers, etc.
  * 🚀 *Executable file:*
    * `./compose.mk ...  <==> make -f compose.mk ...`

---

<ins>**[k8s.mk](#k8smk)**, a Makefile automation library/CLI tool, defining various targets for working with Kubernetes.</ins>

  * Useful as a library, especially if you're building cluster lifecycle automation
  * Useful as an interactive debugging/inspection/development tool.
  * Do the common tasks quickly, interactively or from other automation
    * Launch a pod in a namespace, or a shell in a pod, without lots of kubectling
    * Stream and pipe commands to/from pods, or between pods

****

**Other Features:** 

  * **[Curated collection of automation interfaces](#k8smk-api)**, arranged into a few namespaces:
    * **`k8s.*`:** Default namespace with debugging tools, cluster life-cycle primitives, etc.
    * **`tui.*`:** Control-surface for a tmux-backed console geometry manager.
      * **No host dependencies.** This uses the `k8s:dux` tool container to dockerize tmux.
      * Uses docker-in-docker to interact with your other containers seamlessly.
      * Open split-screen displays, shelling into 1 or more of the tool containers in k8s-tools.yml.
      * Combine with `flux.*` target and quickly create dashboards / custom development environments.
    * Plus more specific interfaces to k3d, kubefwd, etc. [Full API here.](#k8smk-api)
  * 🚀 *Executable file:*
    * `./k8s.mk ...  <==> make -f k8s.mk ...`

Both `compose.mk` and `k8s-tools.yml` files are a soft-dependency for `k8s.mk`, because the emphasis is on seamless usage of those containers.  But you can still use many targets "natively" if your host already has the relevant tools.  It also provides some primitives for common tasks (like waiting for all pods to be ready), context management (like setting the active namespace), the usual patterns (like idempotent usage of `helm`), and the automate the TUI itself (like sending specific targets to specific panes).