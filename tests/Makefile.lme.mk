SHELL := bash
MAKEFLAGS=-s -S --warn-undefined-variables
.SHELLFLAGS := -eu -c

# export KUBECONFIG:=./fake.profile.yaml
# export _:=$(shell umask 066;touch ${KUBECONFIG})

include compose.mk
$(eval $(call compose.import, ▰, TRUE, lme.yml))

.DEFAULT_GOAL := all 
all: lme.build bootstrap 
bootstrap:
	make platform1.setup | make flux.dmux/logging,metrics,events
platform1.setup: ▰/terraform/self.infra.setup ▰/ansible/self.app.setup
logging: ▰/elk/self.logging
metrics: ▰/prometheus/self.metrics
events: ▰/datadog/self.events
self.infra.setup:
	$(info '{"event":"doing things in terraform container", "log":"infra setup done", "metric":123}')
self.app.setup:
	$(info '{"event":"doing things in ansible container", "log":"app setup done", "metric":123}')
self.logging:
	cat /dev/stdin | jq .log
self.metrics:
	cat /dev/stdin | jq .metric
self.events:
	cat /dev/stdin | jq .event