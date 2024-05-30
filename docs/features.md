
## Features

**[k8s-tools.yml](k8s-tools.yml)**, a compose file.

* **Local parts of the tool bundle** ([See the latest here](k8s-tools.yml))
  * [kind](https://github.com/kubernetes-sigs/kind), [argocli](https://argo-workflows.readthedocs.io/en/latest/walk-through/argo-cli/), [kn](https://knative.dev/docs/client/install-kn/), [k3d](https://k3d.io/), [k9s](https://k9scli.io/), [fission](https://fission.io/docs/installation/), [helmify](https://github.com/arttor/helmify), [kompose](https://kompose.io/), [kubefwd](https://github.com/txn2/kubefwd), [rancher](https://github.com/rancher/cli), [lazydocker](https://github.com/jesseduffield/lazydocker)
* **Upstream part of the tool bundle** ([See the latest here](https://github.com/alpine-docker/k8s/blob/master/README.md#installed-tools) for more details on that.)
  * [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/), [kustomize](https://github.com/kubernetes-sigs/kustomize), [helm](https://github.com/helm/helm), [helm-diff](https://github.com/databus23/helm-diff), [helm-unittest](https://github.com/helm-unittest/helm-unittest), [helm-push](https://github.com/chartmuseum/helm-push), [aws-iam-authenticator](https://github.com/kubernetes-sigs/aws-iam-authenticator), [eksctl](https://github.com/weaveworks/eksctl), [awscli v1](https://github.com/aws/aws-cli), [kubeseal](https://github.com/bitnami-labs/sealed-secrets), [krew](https://github.com/kubernetes-sigs/krew), [vals](https://github.com/helmfile/vals), [kubeconform](https://github.com/yannh/kubeconform).  Plus general tools, such as bash, curl, jq, yq, etc
* As usual with docker-compose, containers aren't pulled until they are used, and build-when-changed mostly works as you'd expect.  **Having these declared in case of eventual use won't saddle you with an enormous boostrap process.**
* If you're only interested in the upstream stuff from `alpine/k8s`, the compose file is nicer than the alternative huge `docker run ..` commands, because it sets up volumes for you to share the docker socket, and shares kubeconfigs for you automatically.  
* Also provides an approach for fixing root-user docker file-permissions (see [this section for more details](#docker-and-file-permissions)).

After you've made your whole tool chain portable in one swipe, you might also be interested in *driving* those tools with something that offers more structure than a shell script, and something that *also* won't add to your dependencies.  Check out the detailed docs for:

* **[Makefile.compose.mk](#makefilecomposemk)**, which defines various make-targets and macros for working with compose files & compose services.
* **[Makefile.k8s.mk](#makefilek8smk)**, which defines some make-targets for working with kubernetes from Makefiles.