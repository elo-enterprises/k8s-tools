





<table align=center style="width:100%">
  <tr>
    <td colspan=2><strong>k8s-tools &nbsp; // &nbsp; <strong>But Why?</strong></strong>&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
  </tr>
  <tr>
    <td align=center width=10%>
      <center>
        <img src=../img/docker.png style="width:75px"><br/>
        <img src=../img/kubernetes.png style="width:75px"><br/>
        <img src=../img/make.png style="width:75px"><br/>
      </center>
    </td>
    <td width=90%>
      <table align=center border=1>
        <tr align=center><td align=center width="13%"><a href=/README.md#overview>Overview</a></td>
<td align=center width="13%"><a href=/README.md#features>Features</a></td>
<td align=center width="13%"><a href=/README.md#integration>Integration</a></td>
<td align=center width="13%"><a href=/README.md#composemk>compose.mk</a></td>
<td align=center width="13%"><a href=/README.md#k8smk>k8s.mk</a></td>
<td align=center width="13%"><a href=/docs/api/>API</a></td>
<td align=center width="13%"><a href=/docs/demos>Demos</a></td></tr>
      </table>
      <hr style="border-bottom:1px solid black;"><center><span align=center>&nbsp;<a href="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml"><img src="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml/badge.svg"></a>&nbsp;<a href="/docs/env-vars.md"><img alt=":alpine/k8s:1.30.0" src="https://img.shields.io/badge/alpine%2Fk8s%3A1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="alpine_k8s:alpine/k8s:1.30.0" src="https://img.shields.io/badge/alpine_k8s%3Aalpine%2Fk8s%3A1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="argo:v3.4.17" src="https://img.shields.io/badge/argo%3Av3.4.17-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="debian_container:debian:bookworm" src="https://img.shields.io/badge/debian_container%3Adebian%3Abookworm-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helmify:v0.4.12" src="https://img.shields.io/badge/helmify%3Av0.4.12-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="jq:1.7.1" src="https://img.shields.io/badge/jq%3A1.7.1-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="k3d:v5.6.3" src="https://img.shields.io/badge/k3d%3Av5.6.3-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="k9s:v0.32.4" src="https://img.shields.io/badge/k9s%3Av0.32.4-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kind:v0.23.0" src="https://img.shields.io/badge/kind%3Av0.23.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kn:v1.14.0" src="https://img.shields.io/badge/kn%3Av1.14.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kompose:v1.33.0" src="https://img.shields.io/badge/kompose%3Av1.33.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="kubefwd:1.22.5" src="https://img.shields.io/badge/kubefwd%3A1.22.5-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="prometheus:v2.52.0" src="https://img.shields.io/badge/prometheus%3Av2.52.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="rancher:v2.8.4" src="https://img.shields.io/badge/rancher%3Av2.8.4-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="yq:4.43.1" src="https://img.shields.io/badge/yq%3A4.43.1-blue"></a>&nbsp;&nbsp;<a href="/docs/env-vars.md"><img alt="kubectl:v1.30.0" src="https://img.shields.io/badge/kubectl%3Av1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helm:v3.14.4" src="https://img.shields.io/badge/helm%3Av3.14.4-blue"></a>&nbsp;</span></center><hr style="border-bottom:1px solid black;">
    </td>
  </tr>
</table><center><span align=center>Completely dockerized version of a kubernetes toolchain, plus a zero-dependency automation framework for extending and interacting it.  Project-local clusters, customized TUIs, and more.</span></center><hr style="border-bottom:1px solid black;">


# Motivation & Design Philosophy

### Why compose.mk?

 There's many reasons why you might want these capabilities if you're working with tool-containers, builds, deploys, and complex task orchestration.  

#### The Usual Problems

People tend to have strong opions about this topic, but here are some observations that probably aren't too controversial: 

* **Orchestration *between* or *across* tool containers is usually awkward.** This is a challenge that needs some structure imposed.  You can get that structure in lots of ways, but it's always frustrating to see your work locked into esoteric JenkinsFile / GitHubAction blobs where things get complicated to describe, run, or read.  *Project automation ideally needs to run smoothly both inside and outside of CI/CD.*
* **If running commands with different containers is easy, then there is less need to try and get everything into *one* tool container.**  The omnibus approach is usually time-consuming, and can be pretty hard if very different base images are involved.
* **Tool containers are much more useful when you can easily dispatch commands to them,** especially without a long, fragile CLI invocation.  A compose file specifying volumes and such helps a lot, but *you don't want `docker run ...` littered all over your scripts for builds and orchestration*.
* **Plain shell scripts won't take you far.** There's lots of reasons for this but to name a few... features involving option/argument parsing, multiple entrypoints, code-reuse, partial-execution for partial-updates, dry-runs, parallelism, and other things you're going to need *just aren't simple to get.*  Maintainability also isn't great. &* **CM tools like Ansible can fix some of this, but bring their own problems**.  A few examples of those problems are: Significant setup, significant dependencies, ongoing upstream changes, and the fact that many people cannot read or write it.

#### The Happy Medium

Much more controversially: **Make is the happy medium here**, despite the haters, the purists, and the skeptics who argue that *make is not a task-runner*.  That's because `make` is too good to ignore, and there are several major benefits.  It is old but it is everywhere, it's expressive but has relatively few core concepts, and it's fast.  It's the lingua franca for engineers, devops, and data-science, probably because easy things stay easy and advanced things are still possible.  It's the lingua franca for javascript, python, or golang enthusiasts who need to be able to somehow work together.  Most importantly: `make` is probably the *least* likely thing in your toolkit to be affected by externalities like pip breakage, package updates, or changing operating systems completely.  If you need something *outside* of docker that you want stability & ubiquity from, it's hard to find a better choice.  As a bonus, most likely tab-completion for make-targets already works out of the box with your OS and shell, and to a certain extent, `make` can even support plan/apply workflows (via `--dry-run`) and parallel execution (via `--jobs`).  

The only problem is.. *Makefiles have nothing like native support for running tasks in containers*, **but this is exactly what *`compose.mk`* fixes.**  Makefiles are already pretty good at describing task execution, but describing the containers themselves is far outside of that domain.  Meanwhile, docker-compose is exactly the opposite, and so Make/Compose is a perfect combination.  

#### The Top of the Stack

Whether you're running ansible, cloudformation, docker, docker-compose or eksctl, lots of our tools have complex invocations that are very depend on environment variables and other config-context for correct behaviour.  You can't get around this with bash aliases, because developers won't have those in sync, and plain bash scripts have problems already discussed.  Sourcing .env files or loading bash functions all tends to create issues, because people lose track of the state in 1 tabbed terminal vs another, or the state is unavailable to IDEs, etc.  Complicating the matter further, some of these tools actually need access to the same config data, and some operations require multiple tools, or data-flow *between* tools.

Having a well defined "top" of your stack that sets some context, and provides aliased entrypoints for cumbersome-but-common stuff becomes really important.  Just as important, that context needs to be project based, and shouldn't leak out into your shell in general.  **Makefiles are the obvious choice here,** because they enable everything and require nothing, allowing for a pretty seamless mixture of config, overrides, entrypoint aliases, context management, task orchestration, and new automation layers that connect and recombine existing ones.



#### No Golden Version for Frameworks

If you're using large frameworks like Terraform/Ansible at all, then there's a good chance you'll eventually need multiple versions of that framework at least temporarily.  You can even see this at the level of tools like `awscli`, where there's a much anticipated split for v1/v2.   Basically your options at a time like this are to:

1. Start building a "do everything" golden container or VM, put both versions in the same place.
1. Start messing around with tools like `virtualenv`, `tox`, and `terragrunt` for sandboxing different versions.
1. Start replacing lots of `foo-tool` invocations with awkward-but-versioned `docker run foo/foo-tool:VERSION ...` commands.
1. Rely completely on CI/CD like Jenkins/Github or workflow-engines like Atlantis or Argo for mapping your tasks onto versioned containers.

Choices 1 & 2 are labor intensive and fragile, choice 3 is ugly, fragile, and particularly hard to maintain.  Choice 4 is *maybe* fine once it's actually working, but it's also basically punting on *all local development forever*, so it can be pretty painful to change or debug.  In the worst-case, Choice 4 also has the downsides that you're accepting platform lock-in as well as betting everything on a single point of failure.

**Alternatively, you could start managing tool-containers with compose, then launch any target in any container with compose.mk's approach to [target dispatch](#container-dispatch).**  You can still call `make` from Jenkins, Argo, or Github.  While you added smooth workflows for local development, you also just fixed lots of bad coupling because now you can switch your whole CI/CD backend from any of these choices to the others and it's not a big deal.

#### Pragma

Lots of people have been traumatized by Makefiles in the past, but using `make` can be painless, and writing it can be done responsibly.  As much as possible, avoid advanced features and treat it like a tabby superset of plain old shell script.  That's enough to immediately fix the option-parsing, entrypoints, and partial execution problems mentioned before, plus adding DAG flows & orchestration, and you still end up with something most people can read, write, and run.  

To the extent you really *need* advanced Makefile features like macros, well..  you probably don't, but what if you do?  First, come to terms with the fact that *this is practically guaranteed to be hideously difficult to read/write/reason about*, because that is the nature of macros anywhere.  In rare cases though, it's the only option and it's worth it; implementations of make-macros can be powerful, and eventually reach a place where they are maintenance-free.  The first trick to this is, macros are best understood by how they are used, and not by how they are implemented.  *If use-cases and usage are clear*, then implementation won't matter much as long it's stable and portable.  The other trick is that there is no trick: keep it small, separate things into external libraries, and test your public interfaces extensively.  Just like any other software =) This repository is hopefully a good example of that.


For both `make` and `docker compose`, much ink (and maybe some blood) has been spilled on both advocacy and protest. [Reference](https://matt-rickard.com/the-unreasonable-effectiveness-of-makefiles), [Reference](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/03/hadrian.pdf), [Reference](https://aegis.sourceforge.net/auug97.pdf), and many, many more over many years, with lots of ~raging~ interesting discussion on the orange site and elsewhere.  Much of the criticism *and* the advocacy arises from misunderstandings or myopic treatment of the tools or the use-cases involved.  Working theory: philosophy rarely changes hearts and minds, but tooling and examples might?  

If you're still unconvinced, try skipping around the docs to check out [this small example,](#), [this more detailed tutorial](#), or this [full project](#) that's building on these techniques.  

<hr style="width:80%;border-bottom: 5px dashed black;background: #efefef;">

### Why k8s.mk?

The previous section describes why combining Make/Compose with *`compose.mk`* is a good idea. *`k8s.mk`* is a sibling library basically, but can be used in a stand-alone mode and has it's own distinct goals/motivations.  

The primary focus is on simplifying few categories of frequent interactions:

* Reusable implementations for common cluster automation tasks (like waiting for pods to get ready)
* Context-management tasks (like setting the currently active namespace)
* Interactive debugging tasks (like shelling into a new or existing pod inside some namespace)

More philosophically.. using `k8s-tools.yml` and `*.mk` adds a bit of boilerplate to your automation projects, but potentially helps you to strip away lots of other complicated abstraction layers.

#### DAGs Rule Everything Around Me

You probably already know that [directed acyclic graphs](https://en.wikipedia.org/wiki/Directed_acyclic_graph) aren't just for Airflow, and these come up practically any time you're thinking about dependency trees, scheduling, and lots of other stuff.  DAGs are pretty much what `make` *does*, and it's good at it.  

For lots of automation work, and *especially* lifecycle automation, DAGs of tasks/prerequisites are the most natural way model things.  **Engines for resolving "desired state" like Terraform/Ansible are great at what they do, but they are not really built for describing DAGs.**  If you're spending lots of time messing around with hooks and plugins, it might be a sign that you're struggling to turn your desired-state-management tools into DAG processors.

#### Just Use Tasks in Containers 

Here's a typical workflow for devops:

1. You want new software available on your Kubernetes.
1. You go read the installation instructions, which tell you to  `helm repo add ..` then `helm install ..` or to `kubectl` something.
1. You dutifully translate those instructions into your preferred ecosystem's tool wrappers.  (Maybe it's a [terraform helm provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs) or an [ansible helm module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/helm_module.html) or a [jenkins container-step](https://www.jenkins.io/doc/pipeline/steps/kubernetes/#-container-run-build-steps-in-a-container))
1. That's not a ton of work by itself, but soon you find you're deep into fiddling with the abstraction.
1. Looks like you need another version of your core tooling (yay, Terraform upgrade), 
1. Or maybe another version of the plugin (yay, sifting Jenkins ecosystem abandonware)
1. Or maybe you have to pull in lots of config you *don't* need to access some config that you *do* need (yay, our Ansible needs a submodule full of plugins/tasks/inventory just to get started)
1. Oops, any upgrades or changes at the "top" or the "outside" of your tool chain like this fixes one thing and breaks something else
1. Now changes are hard, or scary, or both.

If this goes on for long enough to block other work, things start to get ugly.

* Pressure is mounting to *"simplify things"*, i.e. calling who-knows-what-version of system helm directly, usually from a tangle of disorganized shell scripts.
* Pressure is mounting to *split up things that belong together* because isolation, separation and breaking with all existing standards looks like the easiest way to work around the problems.
* Pressure is mounting to *randomly switch* your terraform to ansible, or ansible to terraform, hoping you're lucky enough that swapping one complex ecosystem for another just makes the whole problem disappear.

Frustratingly, none of this actually has anything to do with `helm`, or the problem we were trying to solve with it.  None of the options above is very good functionally or aesthetically, and longer term they'll wreck your chances for reproducibility, maintainability, or sane organization.  

**Simply using tool containers as directly as possible is a better way,** and compose.mk makes it simple to invoke them.  Unlike the "*helm bolted on to terraform/ansible/jenkins*" approach, the make/compose approach also means you can more directly use *multiple versions* of the actual tools you care about, and without affecting existing work.  If a tool breaks, you can debug that issue directly, without re-running ansible you don't care about, without digging in terraform core dumps, without trying to connect to weird remote runtimes via ssh or kubectl, and without looking up that one weird environment variable to enable plugin traces.  If you need a tool, then you just use it!  And for those who find the "translation" step in #3 above relaxing.. you'll still have opportunity to do that, because targets like [helm.repo.add](#helmrepoaddarg) do exist to provide idempotent operations when you want them.

#### Just Use Project-local Clusters

Convenient local development workflows are something application/pipeline developers want, and they want it to be as close to production as possible.  It's common that the answer for this is some kind of "host local" kubernetes, where you minikube, or docker-desktop, or rancher-desktop your way to development bliss.

This abstraction is awkward if not exactly bad.  For one thing, all the solutions in this space are pretty resource-hungry and still threaten to set laptops on fire.  Working on multiple projects or having a lot of churn in just one project involves lots of cluster bootstrap/teardown, which is time-consuming, and in some cases will make docker itself unavailable for the duration.  If you *don't* tear-down your host-local cluster constantly, then it's probably accumulating state that you're not sure you can reproduce from scratch, some of that state is unused clutter that's bogging it down, and now the host is getting overwhelmed and you either need a faster laptop or you need to go back to the cloud.  This puts more traffic in your cloud's dev environment, which isn't great for costs or stability.   It can also mean that developers are waiting in line for feature environments, or getting frustrated by constant breakage in shared environments.

**Project-local clusters are a better abstraction than host-local ones,** and tools like kind/k3d have made very significant progress on both speed and reliability.  Treating cluster create/delete as something routine, something we *require* to be fast and reliable is just good practice, and it also means there's no time spent on "uninstall" processes.  k8s.mk lowers the barrier to entry for project-local clusters by making it easy to express cluster-lifecycle processes simply and succintly.  In the spirit of integrating early and often, it also enables more applications to run *pre-deployment* integration tests on miniature clusters, i.e. during CI and *before* CD, which buys you more stability in cloud dev environments.  Since you need pre-deployment tests on a miniature cluster anyway, it makes sense to embrace it for local iterative development too.

#### Just Use Simple Tools

Working with Kubernetes certainly has some intrinsic complexity, but in response to that we shouldn't just blindly accept an unlimited amount of *extra* complexity and hope it cancels out.  

If we're being honest, the dream of using kubernetes/docker to provide "runs anywhere" guarantees and to have better parity between dev/prod environments has been gradually eroded by the fragmentation and constantly shifting landcscape of alternatives.  Sometimes these alternatives are intentionally looking to create walled gardens, and sometimes they mean well but just tend resist efforts at automation.  Here's a few examples:

1. Docker Desktop Licensing changes, and increasingly divergent behaviour for Mac/Windows/Linux Docker installations.
1. Rancher Desktop tooling like [rdctl](https://docs.rancherdesktop.io/references/rdctl-command-reference/) doesn't always cover configuration options available inside the UI
1. IDEs or IDE plugins, open or otherwise, which are scope-creeping their way towards various pod & cluster-management duties

Options are good, but in practice we often get dragged into negotiating with or debugging our tools instead of just using them.  Just getting location/contents for the kubeconfig file will be different for the scenarios above.  But to illustrate, let's consider a slightly more complex task like forwarding cluster ports for local-development.  

Somce you may have at least 1 developer using each of the approaches above, there's at least 3 ways ways to do this.  Automating *or* documenting the "idiomatic way" to port-forward in [each](https://docs.k8slens.dev/cluster/use-port-forwarding/) of [these](https://docs.rancherdesktop.io/ui/port-forwarding/) systems is [tedious](https://minikube.sigs.k8s.io/docs/handbook/accessing/), because if that's doable outside of the GUI at all, then there's probably 6 different paths that need to be addressed (3 systems, each with different config-locations on each of MacOS/Linux).  And it's all a moving target, because what works today will very likely break tomorrow.  And yet if you refuse to automate/document every path, then you're increasing bootstrap friction for new developers on your project, and support-requests for newbies just getting started will become a time-suck for more senior people.  Yuck.

There's no reason a task as simple as port-forwarding should be mixed up with these choices for backends though.  Preferring simple tools that are automation friendly and promote correct coupling pays off, because you'll want integration tests that's using these forwarded ports anyway.  **The fix for this scenario is use simple tools and completely avoid dealing with all this churn**.  You could go with [`kubectl port-forward`](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_port-forward/) directly, but working with [kubefwd can be a nicer alternative](/docs/api#api-kubefwd). The only challenges for using `kubefwd` for local development are context-management (like what KUBECONFIG/namespace/services to target), and how to foreground / background the port-forwarding while ensuring it can be cleanly torn down later.  A bit of helper automation goes a long way here to reduce bootstrap friction & documentation burden, especially if you're up for adopting project-local clusters.  For an example of working with forwarded ports, see [the Cluster Demo docs](#development).

<hr style="width:80%;border-bottom: 5px dashed black;background: #efefef;">
