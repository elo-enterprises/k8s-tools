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

export GREEN?=\033[92m
export NO_ANSI?=\033[0m
export DIM?=\033[2m
export UNDERLINE?=\033[4m
export BOLD?=\033[1m
export RED?=\033[91m

export K8S_POLL_DELTA?=23
export ALPINE_K8S_VERSION?=alpine/k8s:1.30.0

k3d.panic:
	@# Non-graceful stop for everything that is k3d related
	@# 
	@# USAGE:  
	@#   make k3d.panic
	@# 
	(make k3d.ps || echo -n) | xargs -I% bash -x -c "docker stop -t 1 %"

k3d.ps:
	@# Container names for everything that is k3d related
	@# 
	@# USAGE:  
	@#   make k3d.ps
	@# 
	set -x \
	&& (docker ps --format json \
	| jq -r '.Names' \
	| grep ^k3d- \
	|| printf "${RED}No containers found.${NO_ANSI}\n" > /dev/stderr )

k3d.cluster.delete/%:
	@# Idempotent version of k3d cluster delete 
	@#
	@# USAGE:
	@#   k3d.cluster.delete/<cluster_name>
	@#
	@( k3d cluster list | grep ${*} > /dev/null ) \
	&& ( set -x && k3d cluster delete ${*} ) || true
k8s.commander: k8s.commander/default
	@# Opens k8s.commander for the "default" namespace

k8s.commander/%:
	@# A split-screen TUI dashboard that opens 'lazydocker' and 'ktop'.
	@# (Requires tmux)
	@#
	@# USAGE:  
	@#   make k3d.commander/<namespace>
	@# 
	tmux new-session \; set-option -g default-command "exec /bin/bash -x" \; split-window -h \; send-keys "make k8s.ktop/${*}; tmux kill-session" C-m \; select-pane -t 0 \; send-keys "make lazydocker; tmux kill-session" C-m

k8s.purge_namespaces_by_prefix/%:
	@# Runs a separate purge for every matching namespace
	@#
	@# USAGE: 
	@#    k8s.purge_namespaces_by_prefix/<prefix_>
	@#
	make k8s.namespace.list \
	| grep ${*} \
	|| (\
		printf "${DIM}Nothing to purge: no namespaces matching \`${*}*\`${NO_ANSI}\n" \
		> /dev/stderr )\
	| xargs -n1 -I% bash -x -c "make k8s.namespace.purge/%"

k8s.kubens/%: 
	@# Context-manager.  Activates the given namespace.
	@# Note that this modifies state in the kubeconfig,
	@# so it can effect contexts outside of the current
	@# process, therefore this is not thread-safe.
	@#
	@# USAGE:  
	@#   make k8s.kubens/<namespace>
	@#
	TERM=xterm kubens ${*} 2>&1 > /dev/stderr

k8s.kubens.create/%:
	@# Context-manager.  Activates the given namespace, creating it first if necessary.
	@# This has side-effects and those will persist for subprocesses!
	@#
	@# USAGE: 
	@#    k8s.kubens.create/<namespace>
	@#
	make k8s.namespace.create/${*}
	make k8s.kubens/${*}

k8s.namespace/%:
	@# Context-manager.  Activates the given namespace.
	@# This has side-effects and those will persist for subprocesses!
	@#
	@# USAGE:  
	@#	 k8s.namespace/<namespace>
	@#
	make k8s.kubens/${*}

k8s.stat:
	@# Describes status for cluster, cluster auth, and namespaces
	@#
	printf "\n${GREEN}⑆ ${DIM}k8s.stat ${NO_ANSI}${GREEN}${UNDERLINE}`kubectx`${NO_ANSI} \n"
	printf "${DIM}⑆ k8s.stat.env ${NO_ANSI}${NO_ANSI}\n" > /dev/stderr
	env|grep CLUSTER 
	env|grep KUBE 
	env|grep DOCKER
	printf "${DIM}⑆ k8s.stat.cluster_info ${NO_ANSI}${NO_ANSI}\n" > /dev/stderr
	kubectl version | make io.indent 
	kubectl cluster-info | grep -v cluster-info | awk NF | make io.indent
	printf "${DIM}⑆ k8s.stat.node_info (${NO_ANSI}${GREEN}`kubectl get nodes -oname|wc -l`${NO_ANSI_DIM} total)\n" > /dev/stderr
	printf "${DIM}`kubectl get nodes | make io.indent`${NO_ANSI}\n"
	printf "${DIM}⑆ k8s.stat.auth_info ${NO_ANSI}${NO_ANSI}\n" > /dev/stderr
	printf "${DIM}`kubectl auth whoami -ojson | make io.indent`${NO_ANSI}\n"
	printf "${DIM}⑆ k8s.stat.namespace_info ${NO_ANSI}${NO_ANSI}\n" > /dev/stderr
	printf "`kubens | make io.indent`\n"

k8s.get/%:
	@# Returns resources under the given namespace, for the given kind.
	@# Pipe Friendly: results are always JSON.  Caller should handle errors.
	@#
	@# Argument for 'kind' must be provided, but may be "all".  
	@# Argument for 'filter' is optional.
	@#
	@# USAGE: 
	@#	 k8s.get/<namespace>/<kind>/<resource_name>/<jq_filter>
	@#
	$(eval export pathcomp:=$(shell echo ${*}| sed -e 's/\// /g'))
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}')))
	$(eval export kind:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}')))
	$(eval export name:=$(strip $(shell echo ${*} | awk -F/ '{print $$3}')))
	$(eval export filter:=$(strip $(shell echo ${*} | awk -F/ '{print $$4}')))
	export cmd_t="kubectl get $${kind} $${name} -n $${namespace} -o json | jq -r $${filter}" \
	&& printf "${GREEN}⑆ ${DIM}k8s.get${NO_ANSI_DIM} // $${cmd_t}\n${NO_ANSI}" > /dev/stderr \
	&& eval $${cmd_t}

k8s.namespace.create/%:
	@# Idempotent version of namespace-create
	@#
	@# USAGE: 
	@#    k8s.namespace.create/<namespace>
	@#
	kubectl create namespace ${*} \
		--dry-run=client -o yaml \
	| kubectl apply -f - \
	2>&1

k8s.namespace.purge/%:
	@# Wipes everything inside the given namespace
	@#
	@# USAGE: 
	@#    k8s.namespace.purge/<namespace>
	@#
	printf "${GREEN}⑆ ${DIM}k8s.namespace.purge /${NO_ANSI}${GREEN}${*}${NO_ANSI} Waiting for delete (cascade=foreground) \n" > /dev/stderr \
	&& set +x \
	&& kubectl delete namespace --cascade=foreground ${*} -v=9 2>/dev/null || true
k8s.namespace.list:
	@# Returns all namespaces in a simple array.
	@# NB: Must remain suitable for use with `xargs`!
	@#
	kubectl get namespaces -o json \
	| jq -r '.items[].metadata.name'

k8s.namespace.wait/%:
	@# Waits for every pod in the given namespace to be ready.
	@# This uses kubectl/jq to loop on pod-status, but assumes that 
	@# the krew-plugin 'sick-pods' is available for formatting the 
	@# user-message.
	@#
	@# NB: If the parameter is "all" then this uses --all-namespaces
	@#
	@# USAGE: 
	@#   k8s.namespace.wait/<namespace>
	@#
	@export scope=`[ "${*}" == "all" ] && echo "--all-namespaces" || echo "-n ${*}"` \
	&& export header="${DIM_GREEN}k8s.namespace.wait // ${NO_ANSI}" \
	&& export header="$${header}${GREEN}${*}${NO_ANSI}" \
	&& printf "$${header} :: Looking for pending pods.. \n" \
		> /dev/stderr \
	&& until \
		kubectl get pods $${scope} -o json \
		| jq '[.items[].status.containerStatuses[]|select(.state.waiting)]' \
		| jq '.[] | halt_error(length)' 2> /dev/null \
	; do \
		printf "${DIM}`\
			kubectl sick-pods $${scope} \
			| sed 's/^[ \t]*//'\
			| sed "s/Failed/$(shell printf "${RED}Failed${NO_ANSI}")/g" \
			| sed "s/Scheduled/$(shell printf "${YELLOW}Scheduled${NO_ANSI}")/g" \
			| sed "s/Pulling/$(shell printf "${GREEN}Pulling${NO_ANSI}")/g" \
			| sed "s/Warning/$(shell printf "${YELLOW}Warning${NO_ANSI}")/g" \
			| sed "s/ContainerCreating/$(shell printf "${GREEN}ContainerCreating${NO_ANSI}")/g" \
			| sed "s/ErrImagePull/$(shell printf "${RED}ErrImagePull${NO_ANSI}")/g" \
			| sed "s/ImagePullBackOff/$(shell printf "${YELLOW}ImagePullBackOff${NO_ANSI}")/g" \
		`${NO_ANSI}\n" > /dev/stderr \
		&& printf "${DIM}`date`${NO_ANSI} ${BOLD}Pods aren't ready yet${NO_ANSI_DIM} (waiting $${K8S_POLL_DELTA}s)${NO_ANSI}\n" > /dev/stderr \
		&& sleep $${K8S_POLL_DELTA}; \
	done \
	&& printf "${DIM}$${header} :: ${GREEN}Namespace looks ready.${NO_ANSI}\n" > /dev/stderr

k8s.pods.wait_until_ready: 
	@# Waits until all pods in every namespace are ready.
	@# (No parameters; kube context should already be configured)
	@#
	make k8s.namespace.wait/all
	
k8s.test_pod_in_namespace/%:
	@# Starts a test-pod in the given namespace, then blocks until it's ready.
	@#
	@# USAGE: 
	@#	`k8s.test_pod_in_namespace/<namespace>/<pod_name>` or 
	@#	`k8s.test_pod_in_namespace/<namespace>/<pod_name>/<image>` 
	@#
	$(eval export pathcomp:=$(shell echo ${*}| sed -e 's/\// /g'))
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}'))) \
	$(eval export pod_name:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}'))) \
	$(eval export rest:=$(strip \
		$(shell echo $(wordlist 3,99,$${pathcomp}) | sed -e 's/ /\//g')))
	@export pod_image=$${rest:-$${ALPINE_K8S_VERSION}} \
	&& export header="${GREEN}⑆ ${DIM}k8s.test_pod_in_namespace // ${NO_ANSI}" \
	&& printf "$${header}${GREEN}$${namespace}${NO_ANSI}\n" > /dev/stderr \
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
	&& printf "$${DIM}$${manifest}\n$${NO_ANSI}" > /dev/stderr \
	&& printf "$${manifest}" \
		| jq . \
		| (set -x && kubectl apply --namespace $${namespace} -f -)
	make k8s.namespace.wait/$${namespace}


k8s.shell/%:
	@# This drops into a debugging shell for the named pod using `kubectl exec`,
	@# plus a streaming version of the same which allows for working with pipes.
	@#
	@# NB: This target may run from the docker host or the k8s.  In the former case, 
	@# we assume that k8s-tools.yml is present with that filename and `compose.import` 
	@# was used as usual. Port-mapping with '-m' arguments to kubefwd and similar 
	@# are not supported.. other usage should invoke kubefwd directly.
	@#
	@# USAGE: Interactive shell in pod:
	@#   make k8s.shell/<namespace>/<pod_name>
	@#
	@# USAGE: Stream commands into a pod:
	@#   echo uname -a | make k8s.shell/<namespace>/<pod_name>/pipe
	@#
	$(eval export namespace:=$(shell echo ${*}|awk -F/ '{print $$1}'))
	$(eval export pod_name:=$(shell echo ${*}|awk -F/ '{print $$2}'))
	$(eval export rest:=$(shell echo ${*}|awk -F/ '{print $$3}'))
	$(eval export cmd:=$(shell [ "${rest}" == "pipe" ] \
			&& echo "exec -n ${namespace} -i ${pod_name} -- bash" \
			|| echo "exec -n ${namespace} -it ${pod_name} -- bash" ))
	$(eval export tmpf2:=$$(shell mktemp))
	cat /dev/stdin > $${tmpf2} \
	&& ([ "$${rest}" == "pipe" ] && \
		([ "$${COMPOSE_MK:-0}" = "0" ] \
			&& (cat $${tmpf2} | pipe=yes cmd="$${cmd}" entrypoint=kubectl make k8s-tools/k8s) \
			|| ( printf "${GREEN}⑆ ${DIM}k8s.shell${NO_ANSI_DIM} // ${NO_ANSI}${GREEN}$${namespace}${NO_ANSI_DIM} // ${NO_ANSI}${GREEN}${UNDERLINE}$${pod_name}${NO_ANSI_DIM} \n${CYAN}[${NO_ANSI}${BOLD}kubectl${NO_ANSI_DIM}${CYAN}]${NO_ANSI} ${NO_ANSI_DIM}${ITAL}${cmd}${NO_ANSI}\n${CYAN_FLOW_LEFT} ${DIM_ITAL}`cat $${tmpf2}|make io.strip`${NO_ANSI}\n" > /dev/stderr && cat $${tmpf2} | kubectl $${cmd}) ) \
	|| (\
		[ "$${COMPOSE_MK:-0}" = "0" ] \
			&& (cmd="$${cmd}" entrypoint=kubectl make k8s-tools/k8s) \
			|| kubectl $${cmd}))

kubefwd.panic:
	@# Non-graceful stop for everything that is kubefwd related.
	@# 
	@# NB: this can clutter up your /etc/hosts file if kubefwd doesn't clean up things.
	@# 
	@# USAGE:  
	@#   make kubefwd.panic
	(make kubefwd.ps || echo -n) | xargs -I% bash -x -c "docker stop -t 1 %"

kubefwd.ps:
	@# Container names for everything that is kubefwd related
	@# 
	@# USAGE:  
	@#   make kubefwd.ps
	@# 
	set -x \
	&& (docker ps --format json \
	| jq -r '.Names' \
	| grep kubefwd \
	|| printf "${RED}No containers found.${NO_ANSI}\n" > /dev/stderr )

kubefwd.namespace/%:
	@# Runs kubefwd for the provided namespace, finding and forwarding ports/DNS for all services.
	@#
	@# NB: This target should only run from the docker host (not from the kubefwd container),  
	@# i.e. it assumes k8s-tools.yml is present with that filename. Port-mapping and such is
	@# not supported.. any other usage should invoke kubefwd directly.
	@#
	@# USAGE: 
	@#   kubefwd/<namespace>
	@#
	$(eval export pathcomp:=$(shell echo ${*}| sed -e 's/\// /g'))
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}')))
	set -x \
	&& export cname=kubefwd.`basename ${PWD}`.$${namespace} \
	&& (timeout=30 name=$${cname} make docker.stop || true) \
	&& export cid=`docker compose -f k8s-tools.yml run --name $${cname} --rm -d kubefwd svc -n $${namespace} -v` \
	&& export cid=$${cid:0:8} \
	&& cmd="docker logs -f $${cid}" timeout=3 make io.wait_for_command 


k8s.ktop: k8s.ktop/all
	@# Launches ktop tool.  
	@# (This assumes 'ktop' is mentioned in 'KREW_PLUGINS')

k8s.ktop/%:
	@# Launches ktop tool for the given namespace.
	@# This works from inside a container or from the host.
	@#
	@# NB: It's the default, but this does assume 'ktop' is mentioned in 'KREW_PLUGINS'
	@#
	@# USAGE:
	@#   k8s.ktop/<namespace>
	@#
	@export scope=`[ "${*}" == "all" ] && echo "--all-namespaces" || echo "-n ${*}"` \
	&& [ "$${COMPOSE_MK:-0}" = "0" ] \
		&& cmd=ktop entrypoint=kubectl make k8s \
		|| kubectl ktop $${scope}


k9s/%:
	@# Starts the k9s pod-browser TUI, opened by default to the given namespace.
	@# 
	@# NB: This assumes the `compose.import` macro has already imported k8s-tools services
	@# 
	@# USAGE:  
	@#   make k9s/<namespace>
	@#
	make k9s cmd="-n ${*}"

k9: k9s
	@# Starts the k9s pod-browser TUI, using whatever namespace is currently activated.
	@# 
	@# NB: This assumes the `compose.import` macro has already imported k8s-tools services
	@#
	@# USAGE:  
	@#   make k9
	@# 
