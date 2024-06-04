### Example: Platform Setup

Using compose.mk means that `make` feels like a very different animal.

Consider this hypothetical snippet:

``` Makefile
# fake setup for platform bootstrap:
#   1. infrastructure is configured by the terraform container, 
#   2. application is configured by the ansible container,
#   3. we assume both emit json events (simulating terraform state output, etc)

platform.setup: ▰/terraform/self.infra.setup ▰/ansible/self.app.setup

self.infra.setup:
    echo '{"event":"doing things in terraform container", "log":"infra setup done", "metric":123}'

self.app.setup:
    echo '{"event":"doing things in ansible container", "log":"app setup done", "metric":123}'
```

It's powerful, concise, expressive, and already orchestrating tasks across two containers.  The syntax is configurable, and it's even starting to look object-oriented.  

Let's consider an extension.  Suppose `platform.setup` output needs to be used separately by subsequent bootstrap, like using the platform info to configure separate backends for `logging`, `metrics`, and `events`.  

For this kind of thing it's most natural to think in terms of process algebra, and you can express it like this:

```Makefile

# fake some handlers for logging, metrics, events.
#   1. logging uses the `elk` container,
#   2. metrics uses the `prometheus` container,
#   3. events uses the `datadog` container.

logging: ▰/elk/self.logging
self.logging:
    cat /dev/stdin | jq .log

metrics: ▰/prometheus/self.metrics
self.metrics:
    cat /dev/stdin | jq .metric

events:▰/datadog/self.events
self.events:
    cat /dev/stdin | jq .event

# pipes the platform.setup output to a handler for each LME backend
bootstrap:
    make platform.setup | make io.tee.targets targets="logging,metrics,events"
```

Above, the builtin [io.tee.target](#) target is used to send data to our three backends, and each backend pulls out the piece of the input it cares about, simulating further setup using that info.  The `bootstrap` entrypoint kicks everything off.  It's flexible, and so easy to read that it's easy to forget: we just orchestrated a few tasks across 5 containers.
