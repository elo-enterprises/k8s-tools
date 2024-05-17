##
# Makefile.k8s.mk
#
# This is designed to be used as an `include` from your project's main Makefile.
#
# DOCS: https://github.com/elo-enterprises/k8s-tools#Makefile.k8s.mk
#
# LATEST: https://github.com/elo-enterprises/k8s-tools/tree/master/Makefile.k8s.mk
#
# USAGE: (Add this to your project Makefile)
#
#      include Makefile.k8s.mk
#
#      demo: ▰/debian/demo
#      .demo:
#      		uname -n -v
#
# APOLOGIES: In advance if you're checking out the implementation.
#      Make-macros are not the most fun stuff to read or write.
#      Pull requests are welcome! =P
########################################################################
## BEGIN: data

export ANSI_GREEN?=\033[92m
export NO_ANSI?=\033[0m
export ANSI_DIM?=\033[2m
export ANSI_UNDERLINE?=\033[4m
export ANSI_BOLD?=\033[1m
export ANSI_RED?=\033[91m

## END: data
########################################################################
## BEGIN: convenience targets (api-stable)

k9s/%:
	@# Opens k9s UI at the given namespace
	make k9s cmd="-n ${*}"
k9: k9s

k8s.kubens/%: 
	@# Context-manager.  Activates the given namespace.
	@# Note that this modifies state in the kubeconfig,
	@# so it can effect contexts outside of the current
	@# process, therefore this is not thread-safe.
	TERM=xterm kubens ${*} 2>&1 > /dev/stderr

.k8s.kubens/%: 
	@# Alias for the top-level target
	TERM=xterm kubens ${*} 2>&1 > /dev/stderr

k8s.kubens.create/%:
	@# Context-manager.  Activates the given namespace, creating it first if necessary.
	@# (This has side-effects and persists for subprocesses)
	make k8s.namespace.create/${*}
	make k8s.kubens/${*}

k8s.test_pod_in_namespace/%:
	@# Usage: 
	@#	 k8s.test_pod_in_namespace/<namespace>/<pod_name> or 
	@#   k8s.test_pod_in_namespace/<namespace>/<pod_name>/<image> 
	$(eval export pathcomp:=$(shell echo ${*}| sed -e 's/\// /g'))
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}'))) \
	$(eval export pod_name:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}'))) \
	$(eval export rest:=$(strip \
		$(shell echo $(wordlist 3,99,$${pathcomp}) | sed -e 's/ /\//g')))
	@export pod_image=$${rest:-alpine/k8s:1.30.0} \
	&& export header="${ANSI_GREEN}${ANSI_DIM}k8s.test_pod_in_namespace // ${NO_ANSI}" \
	&& printf "$${header}\n" > /dev/stderr \
	&& export data="{ \
		\"apiVersion\": \"v1\", \"kind\":\"Pod\", \
		\"metadata\":{\"name\": \"$${pod_name}\"}, \
		\"spec\":{ \
			\"containers\": [ {\
				\"name\": \"$${pod_name}-container\", \
				\"tty\": true, \"stdin\": true,\
				\"image\": \"$${pod_image}\", \
				\"command\": [\"sleep\", \"infinity\"] } ] } \
		}"\
	&& export manifest=`printf "$${data}" |jq .` \
	&& printf "$${ANSI_DIM}$${manifest}\n$${NO_ANSI}" > /dev/stderr \
	&& printf "$${manifest}" \
		| jq . \
		| (set -x && kubectl apply --namespace $${namespace} -f -)
	make k8s.namespace.wait/$${namespace}
.k8s.test_pod_in_namespace/%: 
	@# Alias
	make k8s.test_pod_in_namespace/${*}

k8s.namespace/%:
	@# Context-manager.  Activates the given namespace.
	@# (This has side-effects and persists for subprocesses)
	make k8s.kubens/${*}

k8s.namespace.create/%:
	@# Idempotent version of namespace-create
	kubectl create namespace ${*} \
		--dry-run=client -o yaml \
	| kubectl apply -f - \
	2>&1

k8s.namespace.purge/%:
	@# Wipes everything inside the given namespace
	printf "${ANSI_GREEN}${ANSI_DIM}k8s.namespace.purge /${NO_ANSI}${ANSI_GREEN}${*}${NO_ANSI} Waiting for delete (cascade=foreground) \n" > /dev/stderr \
	&& set +x \
	&& kubectl delete namespace \
		--cascade=foreground ${*} \
		-v=9 2>/dev/null || true
k8s.namespace.list:
	@# Returns all namespaces in a simple array 
	@# WARNING: Must remain suitable for use with `xargs`
	kubectl get namespaces -o json \
	| jq -r '.items[].metadata.name'

k8s.purge_namespaces_by_prefix/%:
	@# Runs a separate purge for every matching namespace
	make k8s.namespace.list \
	| grep ${*} \
	|| (\
		printf "${ANSI_DIM}Nothing to purge: no namespaces matching \`${*}*\`${NO_ANSI}\n" \
		> /dev/stderr )\
	| xargs -n1 -I% bash -x -c "make k8s.namespace.purge/%"

k8s.namespace.wait/%:
	@# Waits for every pod in the given namespace to be ready
	@# NB: If the parameter is "all" then this uses --all-namespaces
	$(eval export tmpf1:=$(shell mktemp))
	@export scope=`[ "${*}" == "all" ] && echo "--all-namespaces" || echo "-n ${*}"` \
	&& export header="${ANSI_GREEN}${ANSI_DIM}k8s.namespace.wait // ${NO_ANSI}" \
	&& export header="$${header}${ANSI_GREEN}${*}${NO_ANSI}" \
	&& printf "$${header} :: Looking for pending pods.. \n" \
		> /dev/stderr \
	&& until \
		kubectl get pods $${scope} -o json \
		| jq '[.items[].status.containerStatuses[]|select(.state.waiting)]' \
		> ${tmpf1} \
		&& printf "$(strip $(shell cat ${tmpf1} | sed -e 's/\[\]//'))" > /dev/stderr \
		&& cat ${tmpf1} | jq '.[] | halt_error(length)' \
	; do \
		export stamp="${ANSI_DIM}`date`${NO_ANSI}" \
		&& printf "$${stamp} Pods aren't ready yet (sleeping $${COMPOSE_MK_POLL_DELTA}s)\n" > /dev/stderr \
		&& sleep $${COMPOSE_MK_POLL_DELTA}; \
	done \
	&& printf "$${header} :: Namespace looks ready.${NO_ANSI}\n" > /dev/stderr
.k8s.namespace.wait/%:
	@# (Alias in case this is used as a private-target)
	make k8s.namespace.wait/${*}

k8s.pods.wait_until_ready: 
	@# Waits until all pods in every namespace are ready
	make k8s.namespace.wait/all
.k8s.pods.wait_until_ready: k8s.pods.wait_until_ready

k8s.shell/%:
	@# Usage: Interactive shell in pod:
	@#   k8s.shell/<namespace>/<pod>
	@# Usage: Stream commands into a pod:
	@#   echo uname -a | make k8s.shell/<namespace>/<pod>/pipe
	@#
	@# This drops into a debugging shell for the named pod,
	@# using `kubectl exec`.  This target is unusual because
	@# it MUST run from the host + also uses containers.  
	@# WARNING: 
	@#   This target assumes that k8s-tools.yml is imported
	@#   to the root namespace, and using the default syntax.  
	$(eval export namespace:=$(shell echo ${*}|awk -F/ '{print $$1}'))
	$(eval export pod_name:=$(shell echo ${*}|awk -F/ '{print $$2}'))
	$(eval export rest:=$(shell echo ${*}|awk -F/ '{print $$3}'))
	printf "${ANSI_GREEN}${ANSI_DIM}k8s.shell // ${NO_ANSI}${ANSI_GREEN}$${namespace}${ANSI_DIM} // ${NO_ANSI}${ANSI_GREEN}$${pod_name}${NO_ANSI} :: \n" > /dev/stderr \
	&& set -x \
	&& [ "$${rest}" == "pipe" ] && \
		(cat /dev/stdin |pipe=yes entrypoint=kubectl cmd="exec -n default -i test-harness -- bash -x" make kubectl) \
	|| (\
		cmd="exec -n $${namespace} -it ${pod_name} -- bash" make kubectl  )