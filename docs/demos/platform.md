# Demo: Platform Setup

## Basic Platforming 

Consider this hypothetical snippet:

``` Makefile
# Project Makefile
#
# Implementing a fake setup for platform bootstrap:
#   1. infrastructure is configured by the terraform container, 
#   2. application is configured by the ansible container,
#   3. we assume both emit json events (simulating terraform state output, etc)

platform1.setup: ▰/terraform/self.infra.setup ▰/ansible/self.app.setup
self.infra.setup:
    echo '{"event":"doing things in terraform container", "log":"infra setup done", "metric":123}'
self.app.setup:
    echo '{"event":"doing things in ansible container", "log":"app setup done", "metric":123}'
```

It's powerful, concise, expressive, and already orchestrating tasks across two containers defined in some external compose-file.  The syntax is configurable, and it's even starting to look object-oriented.  

Typically app-setup and infra-setup might further split into stages, but you get the idea.  And the infrastructure/app split always comes up, but it might look different.. for example your setup might replace `terraform` with `eksctl`, and `ansible` with `helm`.

## Extension with LME

Let's consider an extension of this.  Suppose output from `platform.setup` needs to be used separately by the next bootstrap processes.  For example, sending the platform output to different backends for `logging`, `metrics`, and `events`, respectively.  

For this kind of thing it's most natural to think in terms of process algebra, and you can express it like this:

```Makefile

# Fake some handlers for logging, metrics, events.
#   1. logging uses the `elk` container,
#   2. metrics uses the `prometheus` container,
#   3. events uses the `datadog` container.

logging: ▰/elk/self.logging
self.logging:
    # pretending to push data somewhere with curl
    cat /dev/stdin | jq .log

metrics: ▰/prometheus/self.metrics
self.metrics:
    # pretending to do stuff with the promtool CLI
    cat /dev/stdin | jq .metric

events: ▰/datadog/self.events
self.events:
    echo 'pretending to do stuff with the datadog CLI'
    cat /dev/stdin | jq .event

bootstrap:
    # pipes all the platform.setup output into a handler-target for each LME backend
    make platform1.setup | make flux.dmux/logging,metrics,events
```

Above, the builtin [flux.dmux target](/api#fluxdmux) is used to send platform-setup's output into the three backend handlers.  This is just syntactic sugar for a 1-to-many pipe (aka a demultiplexer, or "dmux").  Each handler pulls out the piece of the input that it cares about, simulating further setup using that info.  The `bootstrap` entrypoint kicks everything off.  

This is actually a lot of control and data-flow that's been expressed.  Ignoring ordering, graphing it would look something like this:

<p align="center"><a href="/k8s-tools/img/example-platform-1.png"><img width="90%" src="/k8s-tools/img/example-platform-1.png"></a></p>

Whew.  We know what happens next is probably *more* platforms, more tools/containers, and more data flows.  Not to belabor the point but let's watch how it blows up with just one more platform:

<p align="center"><a href="/k8s-tools/img/example-platform-2.png"><img width="90%" src="/k8s-tools/img/example-platform-2.png"></a></p>

The stripped-down and combined automation is included below. It feels pretty organized and maintainable, and weighs in at only ~20 lines.  That's almost exactly the same number of lines in the [mermaid source-code for the diagram](docs/example-platform-1.mmd), which is kind of remarkable, because usually implementations are usually *orders of magnitude larger* than the diagrams that describe them!  Zeroing in on a minimum viable description length?

```Makefile 
include compose.mk
$(eval $(call compose.import, ▰, TRUE, my-containers.yml))

all: bootstrap 
bootstrap:
    make platform1.setup | make flux.dmux/logging,metrics,events
platform1.setup: ▰/terraform/self.infra.setup ▰/ansible/self.app.setup
logging: ▰/elk/self.logging
metrics: ▰/prometheus/self.metrics
events: ▰/datadog/self.events
self.infra.setup:
    echo '{"event":"doing things in terraform container", "log":"infra setup done", "metric":123}'
self.app.setup:
    echo '{"event":"doing things in ansible container", "log":"app setup done", "metric":123}'
self.logging:
    cat /dev/stdin | jq .log
self.metrics:
    cat /dev/stdin | jq .metric
self.events:
    cat /dev/stdin | jq .event
```

There are many other `flux.*` targets ([see the API docs](/api#api-flux)), and while it's not recommended to go crazy with this stuff, when you need it you need it.

This tight expression of complex flow will already be familiar to lots of people: whether they are bash wizards, functional programming nerds, or the Airflow/MLFlow/ArgoWF users.  *But this example pipes data between 5 containers, with no dependencies, and in remarkably direct way that feels pretty seamless!*  It neatly separates the automation itself from the context that it runs in, all with no platform lock-in.  Plus.. compared to the alternatives, doesn't it feel more like working with a programming language and less like jamming bash into yaml? 🤔

It's a neat party trick that `compose.mk` has some features that look like Luigi or Airflow if you squint, but of course it's not *really* made for ETLs.  Flux is similar in spirit to things like [declarative pipelines in Jenkins](https://www.jenkins.io/doc/book/pipeline/syntax/#declarative-pipeline).

This example mostly runs as written, but properly escaping the JSON properly is awkward, etc. (Actually [`jb`](/api#jb) or [`stream.json.object.append`](/api#api-stream) can help with this, but it tends to obfuscate the example.)  If you want to see something that actually runs, check out the [simple dispatch demo](#container-dispatch) (which runs as part of [integration tests](https://github.com/elo-enterprises/k8s-tools/tree/master/tests/Makefile.itest.mk)), or check out the [cluster lifecycle demo](/demos#demo-cluster-automation) (which is just a walk-through of the [end-to-end tests](https://github.com/elo-enterprises/k8s-tools/tree/master/tests/Makefile.e2e.mk)).

For a full blown project, check out [k3d-faas.git](https://github.com/elo-enterprises/k3d-faas), which also breaks down automation into platforms, infrastructure, and app phases.
