
## Features

**[k8s-tools.yml](k8s-tools.yml)**, a compose file.

* **Local parts of the tool bundle** ([See the latest here](k8s-tools.yml))
  * **Cluster management:** [kind](https://github.com/kubernetes-sigs/kind), [k3d](https://k3d.io/)
  * **Workflows, FaaS, and Misc Platforming Tools:** [argocli](https://argo-workflows.readthedocs.io/en/latest/walk-through/argo-cli/), [kn](https://knative.dev/docs/client/install-kn/), , [fission](https://fission.io/docs/installation/), [rancher](https://github.com/rancher/cli)
  * **Lower level helpers:** [helmify](https://github.com/arttor/helmify), [kompose](https://kompose.io/), [kubefwd](https://github.com/txn2/kubefwd), 
  * **Monitoring and metrics tools:** [promtool](https://prometheus.io/docs/prometheus/latest/command-line/promtool/), [k9s](https://k9scli.io/), [lazydocker](https://github.com/jesseduffield/lazydocker)
  * **Krew plugins:** [sick-pods](https://github.com/alecjacobs5401/kubectl-sick-pods), [ktop](https://github.com/vladimirvivien/ktop), [kubectx, and kubens](https://github.com/ahmetb/kubectx) available by default, and more on demand.
  * **TUI and user-messaging utilities**: [gum](https://github.com/charmbracelet/gum), [pv](https://www.ivarch.com/programs/pv.shtml), [spark](https://raw.githubusercontent.com/holman/spark/)
  * **General Utilities:** Fixed (i.e. non-busybox) versions of things like date, ps, etc

* **Upstream part of the tool bundle** ([See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.)
  * **Cluster management:** [eksctl](https://github.com/weaveworks/eksctl)
  * **Core Utilities:** [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [kustomize](https://github.com/kubernetes-sigs/kustomize), [helm](https://github.com/helm/helm), [krew](https://github.com/kubernetes-sigs/krew)
  * **Misc Utilities:** [helm-diff](https://github.com/databus23/helm-diff), [helm-unittest](https://github.com/helm-unittest/helm-unittest), [helm-push](https://github.com/chartmuseum/helm-push), [kubeseal](https://github.com/bitnami-labs/sealed-secrets), [vals](https://github.com/helmfile/vals), [kubeconform](https://github.com/yannh/kubeconform)
  * **Cloud Utilities:** [awscli v1](https://github.com/aws/aws-cli), [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator)
  * **General Utilities:** Such as bash, curl, jq, yq, etc

As usual with docker-compose, containers aren't pulled until they are used, and build-when-changed mostly works as you'd expect.  **Having these declared in case of eventual use won't saddle you with an enormous boostrap process.**  For the local parts of this bundle, tools are versioned independently, with defaults provided, but overrides allowed from environment vars (no need to edit the compose-file directly).  Upstream components are essentially assigned a single version number (that of the alpine-k8s base), but the compose-file provides service-stubs where that can be easily changed if you need something specific.

If you're only interested in the upstream stuff from `alpine/k8s` and fine with whatever versions it provides, the compose file is much nicer than the alternative huge `docker run ..` commands, because it sets up volumes for you to share the working directory, the docker socket, and kubeconfigs for you automatically.   It also provides an approach for fixing root-user docker file-permissions (see [this section for more details](#docker-and-file-permissions)).

After you've made your whole tool chain portable in one swipe, you might also be interested in *driving* those tools with something that offers more structure than a shell script, and something that *also* won't add to your dependencies.  Check out the detailed docs for:

* **[compose.mk](#makefilecomposemk)**, which defines various make-targets and macros for working with compose files & compose services.
* **[k8s.mk](#makefilek8smk)**, which defines some make-targets for working with kubernetes from Makefiles.