#!/usr/bin/env -S make -s -f
##
# k8s.mk: An automation library/framework/tool building on compose.mk and k8s-tools.yml
#
# DOCS: https://github.com/elo-enterprises/k8s-tools#k8smk
#
# LATEST: https://github.com/elo-enterprises/k8s-tools/tree/master/k8s.mk
#
# FEATURES:
#   1) ....................................................
#   2) Stand-alone mode also available, i.e. a tool that requires no Makefile and no compose file.
#   3) ....................................................
#   4) A small-but-powerful built-in TUI framework with no host dependencies. (See the tui.* API) 
#
# USAGE: ( For Integration )
#   # Add this to your project Makefile
#   include k8s.mk
#   include compose.mk
#   $(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))
#   demo: ▰/k8s/self.demo
#   self.demo:
#       kubectl --help
#		helm --help
#
# USAGE: ( Stand-alone tool mode )
#   ./k8s.mk help
#
# USAGE: ( Via CLI Interface, after Integration )
#   # drop into debugging shell for the container
#   make <stem_of_compose_file>/<name_of_compose_service>/shell
#
#   # stream data into pod
#   echo echo hello-world | make <stem_of_compose_file>/<name_of_compose_service>/shell/pipe
#
# APOLOGIES: 
#   In advance if you're checking out the implementation.  This is unavoidably gnarly in a lot of places.
#   Make-macros are not the most fun stuff to read or write.  Pull requests are welcome :)
########################################################################

_GLYPH_K8S=⑆${dim}
GLYPH_K8S=${green}${_GLYPH_K8S}${dim}

# Hints for compose files to fix file permissions (see k8s-tools.yml for an example of how this is used)
# This is not DRY with compose.mk, but we need it any in case this is stand-alone mode.
OS_NAME:=$(shell uname -s)
ifeq (${OS_NAME},Darwin)
export MAKE_CLI:=$(shell echo `which make` `ps -o args -p $$PPID | tail -1 | cut -d' ' -f2-`)
else 
export MAKE_CLI:=$(shell \
	( cat /proc/$(strip $(shell ps -o ppid= -p $$$$ 2> /dev/null))/cmdline 2>/dev/null \
		| tr '\0' ' ' ) ||echo '?')
endif

# Hints for exactly how k8s.mk is being invoked 
ifeq ($(findstring k8s.mk, ${MAKE_CLI}),)
export K8S_MK_LIB=1
export K8S_MK_STANDALONE=0
export K8S_MK_SRC=
else
export K8S_MK_SRC=$(shell echo ${MAKEFILE_LIST}|sed 's/ /\n/g' | grep k8s.mk)
export K8S_MK_LIB=0
export K8S_MK_STANDALONE=1
export K8S_MK_SRC=$(findstring k8s.mk, ${MAKE_CLI})
endif

# Import compose.mk iff we're stand-alone mode.
ifeq ($(K8S_MK_STANDALONE),1)
include $(shell dirname ${K8S_MK_SRC}||echo .)/compose.mk
loadf: self.loadf
endif

# How long to wait when checking if namespaces/pods are ready (yes, 'export' is required.)
export K8S_POLL_DELTA?=23

#
export ALPINE_K8S_VERSION?=alpine/k8s:1.30.0

ICON_K3D:=https://github.com/elo-enterprises/k8s-tools/raw/mainline/img/k3d.png

## END Data & macros
## BEGIN 'helm.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/docs/api#api-helm
helm.repo.add/%:
	@# Idempotent version 'helm repo add'
	@#
	@# USAGE:
	@#   ./k8s.mk helm.repo.add/<repo_name> url=<repo_url>
	@#  
	set -x \
	&& (helm repo list 2>/dev/null | grep ${*}) \
	|| helm repo add ${*} $${url} 

helm.chart.install/%:
	@# Idempotent version of a 'helm install'
	@#
	@# USAGE:
	@#   ./k8s.mk helm.chart.install/<name> chart=<chart>
	@#  
	set -x \
	&& ( helm list | grep ${*} ) \
	|| helm install ${*} $${chart}

## END 'helm.*' targets
## BEGIN 'k3d.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/docs/api#api-k3d
k3d.cluster.delete/%:
	@# Idempotent version of k3d cluster delete 
	@#
	@# USAGE:
	@#   ./k8s.mk k3d.cluster.delete/<cluster_name>
	@#
	printf "${dim}${GLYPH_K8S} ${@} ${sep} Deleting cluster ${sep}${underline}${*}${no_ansi}\n" > ${stderr}
	( k3d cluster list | grep ${*} > /dev/null ) \
	&& ( set -x && k3d cluster delete ${*} ) || true

k3d.help: help.namespace/k3d
	@# Shows targets for just the 'k3d' namespace.

k3d.panic:
	@# Non-graceful stop for everything that is k3d related. 
	@# 
	@# USAGE:  
	@#   ./k8s.mk k3d.panic
	@# 
	printf "${dim}${GLYPH_K8S} ${@} ${sep} ${no_ansi_dim}Stopping all k3d containers..${no_ansi}\n" > ${stderr}
	(make k3d.ps || echo -n) | xargs -I% bash -x -c "docker stop -t 1 %"

k3d.ps:
	@# Container names for everything that is k3d related.
	@#
	@# USAGE:  
	@#   ./k8s.mk k3d.ps
	@# 
	printf "${dim}${GLYPH_K8S} ${@} ${sep} ${no_ansi_dim}Listing k3d containers...${no_ansi}\n" > ${stderr}
	(docker ps --format json \
	| jq -r '.Names' \
	| grep ^k3d- \
	|| printf "${yellow}No containers found.${no_ansi}\n" > ${stderr} ) ${stderr_stdout_indent}

k3d.cluster.list k3d.list: 
	@# Returns cluster-names, newline delimited.
	@#
	@# USAGE:  
	@#   ./k8s.mk k3d.cluster.list
	@# 
	printf "${dim}${GLYPH_K8S} ${@} ${sep}${dim} Listing clusters..${no_ansi}\n" > ${stderr}
	cmd="k3d cluster list -o json | jq -r '.[].name'" \
	&& (case "$${COMPOSE_MK:-0}" in \
		0) printf "$${cmd}" | COMPOSE_MK_DEBUG=0 make k8s-tools/k3d/shell/pipe; ;; \
		*) eval $${cmd}; ;;  \
	esac) | tr -d '\n' ${stderr_stdout_indent}; printf '\n' 
k3d.commander:
	@# Starts a 4-pane TUI dashboard, using the commander layout.  
	@# This opens 'lazydocker', 'ktop', and other widgets that are convenient for working with k3d.
	@#
	@# USAGE:  
	@#   KUBECONFIG=.. ./k8s.mk k3d.commander/<namespace>
	@# 
	printf "${GLYPH_K8S} k3d.commander ${sep} ${no_ansi_dim}Opening commander TUI for k3d...${no_ansi}\n" > ${stderr}
	TUI_CMDR_PANE_COUNT=5 \
	TUI_LAYOUT_CALLBACK=.k3d.commander.layout \
	${make} tux.commander

k3d.commander/%:
	@# Like 'k3d.commander', but additionally sends the given target(s) to the main pane.
	@#
	@# USAGE:
	@#   ./k8s.mk k3d.commander/<target1>,<target2>
	@#
	export k8s_commander_targets="${*}" && ${make} k3d.commander

.k3d.commander.layout: .tux.layout.spiral
	@# A 5-pane layout for k3d command/control
	@#
	@# USAGE:  
	@#   ./k8s.mk k3d.commander/<namespace>
	@# 
	printf "${GLYPH_K8S} ${@} ${sep}${dim} Starting widgets and setting geometry..${no_ansi}\n" > ${stderr}
	geometry="${GEO_K3D}" ${make} \
		.tux.pane/1/flux.apply/k3d.stat,$${k8s_commander_targets:-io.bash} \
		.tux.pane/2/k9s \
		.tux.geo.set 
	tmux send-keys -t 0.4 "sleep 3; entrypoint=bash make k3d/shell" C-m
	tmux send-keys -t 0.5 "COMPOSE_MK_DEBUG=0 interval=10 ${make} flux.loopf/k8s.cluster.wait" C-m
	# WARNING: can't use .tux.pane/... here, not sure why 
	make .tux.widget.lazydocker/3/k3d

k3d.stat: 
	@# Show status for k3d.
	@# 
	@#
	printf "${GLYPH_K8S} k3d.stat ${no_ansi_dim}\n" > ${stderr}
	${make} k3d.ps ${stderr_stdout_indent}
	${make} k3d.cluster.list ${stderr_stdout_indent}
	${make} k8s.stat.ns ${stderr_stdout_indent}

GEO_K3D="5b40,111x56,0,0[111x41,0,0{55x41,0,0,1,55x41,56,0[55x16,56,0,2,55x24,56,17,3]},111x14,0,42{55x14,0,42,4,55x14,56,42,5}]"

k3d.stat.widget:
	clear=1 verbose=1 interval=10 ${make} flux.loopf/flux.apply/k3d.stat

## END 'k3d.*' targets
## BEGIN 'k8s.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/docs/api#api-k8s

k8s.get/%:
	@# Returns resources under the given namespace, for the given kind.
	@# This can also be used with a 'jq' query to grab deeply nested results.
	@# Pipe Friendly: results are always JSON.  Caller should handle errors.
	@#
	@# USAGE: 
	@#	 ./k8s.mk k8s.get/<namespace>/<kind>/<resource_name>/<jq_filter>
	@#
	@# Argument for 'kind' must be provided, but may be "all".  
	@# Argument for 'filter' is optional.
	@#
	$(eval export pathcomp:=$(shell echo ${*}| sed -e 's/\// /g'))
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}')))
	$(eval export kind:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}')))
	$(eval export name:=$(strip $(shell echo ${*} | awk -F/ '{print $$3}')))
	$(eval export filter:=$(strip $(shell echo ${*} | awk -F/ '{print $$4}')))
	export cmd_t="kubectl get $${kind} $${name} -n $${namespace} -o json | jq -r $${filter}" \
	&& printf "${GLYPH_K8S} k8s.get${no_ansi_dim} // $${cmd_t}\n${no_ansi}" > ${stderr} \
	&& eval $${cmd_t}

k8s.graph/%:
	@# Graphs resources under the given namespace, for the given kind, in dot-format.
	@# Pipe Friendly: results are always dot files.  Caller should handle any errors.
	@#
	@# This requires the krew plugin "graph" (installed by default with k8s-tools.yml).
	@#
	@# USAGE: 
	@#	 ./k8s.mk k8s.graph/<namespace>/<kind>/<field_selector>
	@#
	@# Argument for 'kind' must be provided, but may be "all".  
	@# Argument for field-selector is optional.  (Default value is 'status.phase=Running')
	@#
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}')))
	$(eval export kind:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}')))
	export scope=`[ "$${namespace}" == "all" ] && echo "--all-namespaces" || echo "-n $${namespace}"` \
	&& export KUBECTL_NO_STDERR_LOGS=1 \
	&& kubectl graph $${kind:-pods} $${scope} ${stderr_devnull};

k8s.graph: k8s.graph/all/pods 
	@#

k8s.graph.tui: k8s.graph.tui/all/pods
	@#

k8s.graph.tui.loop: k8s.graph.tui.loop/kube-system/pods
	@# Loops the graph for the kube-system namespace

k8s.graph.tui.loop/%:
	@# Display an updating, low-resolution image of the given namespace topology.
	@#
	@# USAGE:  
	@#   ./k8s.mk k8s.graph.tui.loop/<namespace>
	@# 
	failure_msg="${yellow}Waiting for cluster to get ready..${no_ansi}" \
	make flux.loopf/k8s.graph.tui/${*}

k8s.graph.tui/%:
	@# Previews topology for a given kubernetes <namespace>/<kind> in a way that's terminal-friendly.
	@#
	@# This is a human-friendly way to visualize progress or changes, because it supports 
	@# very large input data from complex deployments with lots of services/pods, either in 
	@# one namespace or across the whole cluster. To do that, it has throw away some 
	@# information compared with raw kubectl output, and node labels on the graph aren't visible.  
	@#
	@# This is basically a pipeline from graphs in dot format, 
	@# generated by kubectl-graph, then passed through some image-magick 
	@# transformations, and then pushed into the 'chafa' tool for 
	@# generating ASCII-art from images.
	@#
	@# USAGE: (same as k8s.graph)
	@#   ./k8s.mk k8s.graph.tui/<namespace>/<kind>
	@#
	case $${COMPOSE_MK_DIND} in \
		0) \
			entrypoint=make \
			cmd="${MAKE_FLAGS} .k8s.graph.tui/${*}" \
			COMPOSE_MK_DEBUG=0 ${make} k8s-tools/tui; ;; \
		*) ${make} .k8s.graph.tui/${*}; ;; \
	esac
.k8s.graph.tui/%:
	@# (Private helper for k8s.graph.tui)
	@#
	$(call io.mktemp) \
	&& make k8s.graph/${*} > $${tmpf} \
	&& cat $${tmpf} \
		| dot /dev/stdin -Tsvg -o /tmp/tmp.svg \
			-Gbgcolor=transparent -Gsize=200,200 \
			-Estyle=bold -Ecolor=red -Eweight=150 > /dev/null \
		&& convert /tmp/tmp.svg -transparent white png:- > /tmp/tmp.png \
		&& default_size=`echo .5*\`tput cols||echo 30\`|bc`x \
		&& chafa \
			--invert -c full --size $${size:-$${default_size}} \
			--center=on $${clear:-} /tmp/tmp.png
.k8s.graph.tui.clear/%:; clear="--clear" make .k8s.graph.tui/${*}

k8s.help: help.namespace/k8s
	@# Shows targets for just the 'k8s' namespace.

k8s.kubens/%: 
	@# Context-manager.  Activates the given namespace.
	@# NB: This modifies state in the kubeconfig, so that it can effect contexts 
	@# outside of the current process, therefore this is not thread-safe.
	@#
	@# USAGE:  
	@#   ./k8s.mk k8s.kubens/<namespace>
	@#
	TERM=xterm kubens ${*} 2>&1 > ${stderr}

k8s.kubens.create/%:
	@# Context-manager.  Activates the given namespace, creating it first if necessary.
	@#
	@# NB: This modifies state in the kubeconfig, so that it can effect contexts 
	@# outside of the current process, therefore this is not thread-safe.
	@#
	@# USAGE: 
	@#    ./k8s.mk k8s.kubens.create/<namespace>
	@#
	make k8s.namespace.create/${*}
	make k8s.kubens/${*}

k8s.namespace/%:
	@# Context-manager.  Activates the given namespace.
	@#
	@# NB: This modifies state in the kubeconfig, so that it can effect contexts 
	@# outside of the current process, therefore this is not thread-safe.
	@#
	@# USAGE:  
	@#	 ./k8s.mk k8s.namespace/<namespace>
	@#
	make k8s.kubens/${*}
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

k8s.namespace.list:
	@# Returns all namespaces in a simple array.
	@# NB: Must remain suitable for use with `xargs`!
	@#
	kubectl get namespaces -o json \
	| jq -r '.items[].metadata.name'

k8s.namespace.purge/%:
	@# Wipes everything inside the given namespace
	@#
	@# USAGE: 
	@#    k8s.namespace.purge/<namespace>
	@#
	printf "${GLYPH_K8S} k8s.namespace.purge /${no_ansi}${green}${*}${no_ansi} Waiting for delete (cascade=foreground) \n" > ${stderr} \
	&& set +x \
	&& kubectl delete namespace --cascade=foreground ${*} -v=9 2>/dev/null || true

k8s.namespace.purge.by.prefix/%:
	@# Runs a separate purge for every matching namespace.
	@# NB: This isn't likely to clean everything, see the docs for your dependencies.
	@#
	@# USAGE: 
	@#    ./k8s.mk k8s.namespace.purge.by.prefix/<prefix>
	@#
	make k8s.namespace.list \
	| grep ${*} \
	|| (\
		printf "${dim}Nothing to purge: no namespaces matching \`${*}*\`${no_ansi}\n" \
		> ${stderr} )\
	| xargs -I% bash -x -c "make k8s.namespace.purge/%"

k8s.namespace.wait/%:
	@# Waits for every pod in the given namespace to be ready.
	@#
	@# This uses only kubectl/jq to loop on pod-status, but assumes that 
	@# the krew-plugin 'sick-pods'[1] is available for formatting the 
	@# user-message.  See `k8s.wait` for an alias that waits on all pods.
	@#
	@# NB: If the parameter is "all" then this uses --all-namespaces
	@#
	@# USAGE: 
	@#   ./k8s.mk k8s.namespace.wait/<namespace>
	@#
	@# REFS:
	@#   [1]: https://github.com/alecjacobs5401/kubectl-sick-pods
	@#
	$(trace_maybe) \
	&& [ "$${COMPOSE_MK}" = "1" ] \
	&& ${make} .k8s.namespace.wait/${*} \
	|| COMPOSE_MK_DEBUG=0 make k8s/dispatch/.k8s.namespace.wait/${*}

.k8s.namespace.wait/%:
	@export scope=`[ "${*}" == "all" ] && echo "--all-namespaces" || echo "-n ${*}"` \
	&& export header="${GLYPH_K8S} k8s.namespace.wait ${sep} " \
	&& export header="$${header}${green}${*}${no_ansi}" \
	&& wait_cmd="gum \
		spin --spinner $${spinner:-jump} \
		--spinner.foreground=$${color:-39} \
		--title=\"Waiting ${K8S_POLL_DELTA}s\" \
		-- sleep ${K8S_POLL_DELTA}" \
	&& printf "$${header} ${sep}${dim} Looking for pending pods.. ${no_ansi}\n" > ${stderr} \
	&& until \
		kubectl get pods $${scope} -o json 2> /dev/null \
		| jq '[.items[].status.containerStatuses[]|select(.state.waiting)]' 2> /dev/null \
		| jq '.[] | halt_error(length)' 2> /dev/null \
	; do \
		kubectl sick-pods $${scope} 2>&1 \
			| sed 's/^[ \t]*//'\
			| sed "s/FailedMount/$(shell printf "${yellow}Failed${no_ansi}")/g" \
			| sed "s/streaming log results:/streaming log results:\n\t/g" \
			| sed "s/is not ready! Reason Provided: None/$(shell printf "${bold}not ready!${no_ansi}")/g" \
			| sed 's/ in pod /\n\t\tin pod /g' \
			| sed -E 's/assigned (.*) to (.*)$$/assigned \1/g' \
			| sed "s/Failed\n\n/$(shell printf "${yellow}Failed${no_ansi}")/g" \
			| sed "s/Scheduled/$(shell printf "${yellow}Scheduled${no_ansi}")/g" \
			| sed "s/Pulling/$(shell printf "${green}Pulling${no_ansi}")/g" \
			| sed "s/Warning/$(shell printf "${yellow}Warning${no_ansi}")/g" \
			| sed "s/Pod Conditions:/$(shell printf "☂${dim_green}${underline}Pod Conditions:${no_ansi}")/g" \
			| sed "s/Pod Events:/$(shell printf "${underline}${dim_green}Pod Events:${no_ansi}")/g" \
			| sed "s/Container Logs:/$(shell printf "${underline}${dim_green}Container Logs:${no_ansi}")/g" \
			| sed "s/ContainerCreating/$(shell printf "${green}ContainerCreating${no_ansi}")/g" \
			| sed "s/ErrImagePull/$(shell printf "${yellow}ErrImagePull${no_ansi}")/g" \
			| sed "s/ImagePullBackOff/$(shell printf "${yellow}ImagePullBackOff${no_ansi}")/g" \
			| sed ':a;N;$$!ba;s/\n\n/\n/g' \
			| tr '☂' '\n' 2>/dev/null | make stream.dim > ${stderr} \
		&& printf "\n${dim}`date`${no_ansi} ${bold}Pods aren't ready yet${no_ansi}\n" > ${stderr} \
		&& eval $${wait_cmd}; \
	done \
	&& printf "${dim}$${header} ${sep} ✨ ${no_ansi}`[ ${*} == all ] && echo Cluster || echo Namespace` ready.${no_ansi}\n" > ${stderr}


k8s.stat: 
	@# Describes status for cluster, cluster auth, and namespaces.
	@# Not pipe friendly, and not suitable for parsing!  
	@#
	@# This is just for user information, as it's generated from 
	@# a bunch of tools that are using very different output styles.
	@#
	@# For a shorter, looping version that's suitable as a tmux widget, see 'k8s.stat.widget'
	@#
	printf "\n${GLYPH_K8S} k8s.stat ${no_ansi_dim}ctx=${green}${underline}`kubectx -c||true`${no_ansi_dim} ns=${green}${underline}`kubens -c ||true`${no_ansi}\n" \
	| ${make} stream.to.stderr
	${make} k8s.stat.env \
		&& ${make} k8s.stat.cluster \
		&& ${make} k8s.stat.node_info k8s.stat.auth  \
		&& ${make} k8s.stat.ns k8s.stat.ctx 

# k8s.stat.widget:
# 	make k8s.stat

k8s.test_harness.random:; ${make} k8s.test_harness/default/`uuidgen`
	@# Starts a test-pod with a random name in the given namespace, optionally blocking until it's ready.
	@#
	@# USAGE: 
	@#	`k8s.test_harness.random`
	@#

k8s.test_harness/%:
	@# Starts a test-pod in the given namespace, optionally blocking until it's ready.
	@# When no image is provided, this will use 'ALPINE_K8S_VERSION' as default.
	@#
	@# USAGE: 
	@#	`k8s.test_harness/<namespace>/<pod_name>` or 
	@#	`k8s.test_harness/<namespace>/<pod_name>/<image>` 
	@#
	$(eval export pathcomp:=$(shell echo ${*}| sed -e 's/\// /g'))
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}'))) \
	$(eval export pod_name:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}'))) \
	$(eval export rest:=$(strip \
		$(shell echo $(wordlist 3,99,$${pathcomp}) | sed -e 's/ /\//g')))
	@export pod_name=$${pod_name:-test-harness} \
	&& export pod_image=$${rest:-$${ALPINE_K8S_VERSION}} \
	&& export header="${GLYPH_K8S} k8s.test_harness // ${no_ansi}" \
	&& printf "$${header}${green}$${namespace}${no_ansi}\n" > ${stderr} \
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
	&& printf "${dim}$${manifest}\n${no_ansi}" > ${stderr} \
	&& printf "$${manifest}" \
		| jq . \
		| (set -x && kubectl apply --namespace $${namespace} -f -) \
	&& [ -z $${wait:-} ] && true || ${make} k8s.namespace.wait/$${namespace}

k8s.shell/%:
	@# This drops into a debugging shell for the named pod using `kubectl exec`,
	@# plus a streaming version of the same which allows for working with pipes.
	@#
	@# NB: This target assumes that the named pod actually exists.  If you want
	@# an idempotent create-operation for such a pod.. see `k8s.test_harness`.
	@#
	@# NB: This target attempts to be "universal", so that it may run from the 
	@# docker host or inside the `k8s:base` container.  This works by detecting 
	@# aspects of the caller context.  In general, it tries to use k8s-tools.yml 
	@# when that makes sense and if it's present, falling back to kubectl.
	@#
	@# USAGE: Interactive shell in pod:
	@#   ./k8s.mk k8s.shell/<namespace>/<pod_name>
	@#
	@# USAGE: Stream commands into a pod:
	@#   echo uname -a | ./k8s.mk k8s.shell/<namespace>/<pod_name>/pipe
	@#
	$(eval export namespace:=$(shell echo ${*}|awk -F/ '{print $$1}'))
	$(eval export pod_name:=$(shell echo ${*}|awk -F/ '{print $$2}'))
	$(eval export rest:=$(shell echo ${*}|awk -F/ '{print $$3}'))
	$(eval export cmd:=$(shell [ "${rest}" == "pipe" ] \
			&& echo "exec -n ${namespace} -i ${pod_name} -- bash" \
			|| echo "exec -n ${namespace} -it ${pod_name} -- bash" ))
	$(call io.mktemp) && \
	printf "${GLYPH_K8S} k8s.shell${no_ansi_dim} ${sep} $${namespace} ${sep} ${underline}$${pod_name}${no_ansi}\n" >${stderr}  \
	&& case "$${rest}" in \
		pipe) \
			cat /dev/stdin > $${tmpf}; \
			([ "$${COMPOSE_MK}" = "0" ] \
				&& (cat $${tmpf} \
					| pipe=yes cmd="$${cmd}" entrypoint=kubectl make k8s-tools/k8s ) \
				|| ( \
					printf "${GLYPH_K8S} k8s.shell${no_ansi_dim} // ${no_ansi}${green}$${namespace}${no_ansi_dim} // ${no_ansi}${green}${underline}$${pod_name}${no_ansi_dim} \n${cyan}[${no_ansi}${bold}kubectl${no_ansi_dim}${cyan}]${no_ansi} ${no_ansi_dim}${ital}${cmd}${no_ansi}\n${cyan_flow_left} ${dim_ital}`cat $${tmpf}|make io.fmt.strip`${no_ansi}\n" > ${stderr} \
					&& cat $${tmpf} | kubectl $${cmd} \
				  ) \
			); ;; \
		*) \
			[ "$${COMPOSE_MK:-0}" = "0" ] \
				&& (cmd="$${cmd}" entrypoint=kubectl make k8s-tools/k8s) \
				|| kubectl $${cmd}; ;; \
        esac
k8s.wait k8s.cluster.wait: k8s.namespace.wait/all
	@# Waits until all pods in all namespaces are ready.  (Alias for 'k8s.namespace.wait/all')

## END 'k8s.*' targets
## BEGIN '.k8s.*' private targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/docs/api#api-k8s

k8s.stat.auth:
	printf "${GLYPH_K8S} ${@} ${no_ansi}${no_ansi}\n" > ${stderr}
	auth_info=`\
		kubectl auth whoami -ojson 2>/dev/null \
		|| printf "${yellow}Failed to retrieve auth info with command:${no_ansi_dim} kubectl auth whoami -ojson${no_ansi}"` \
	&& printf "${dim}$${auth_info}${no_ansi}\n" | make stream.indent

k8s.stat.env:
	printf "${GLYPH_K8S} ${@} ${no_ansi}${no_ansi}\n" > ${stderr}
	(   (env | grep CLUSTER || true) \
	  ; (env | grep KUBE    || true) \
	  ; (env | grep DOCKER  || true) \
	) | make stream.indent

k8s.stat.cluster:
	@#
	@#
	printf "${GLYPH_K8S} ${@} ${sep}${no_ansi_dim}Showing cluster status..${no_ansi}\n" > ${stderr}
	kubectl version -o json 2>/dev/null | jq . || true
	kubectl cluster-info -o json 2>/dev/null  | jq . || true

k8s.stat.node_info:
	@# Status for nodes. 
	@# Not machine-friendly.  See instead 'k8s.get'.
	@#
	node_count=`kubectl get nodes -oname|wc -l` \
	&& printf "${GLYPH_K8S} ${@} (${no_ansi}${green}$${node_count}${no_ansi_dim} total)\n" > ${stderr}
	code=`kubectl get nodes` ${make} gum.format.code 

gum.format.code:
	$(trace_maybe) && gum format -t code "$${code}" | tail +3 | head -n -1

k8s.stat.ns:
	@#
	@#
	printf "${GLYPH_K8S} ${@} ${sep} ${dim}Listing namespaces..${no_ansi}\n" > ${stderr}
	kubens | make stream.indent

k8s.stat.ctx:
	@#
	@#
	printf "${GLYPH_K8S} ${@} ${sep}${no_ansi_dim}Showing cluster context..${no_ansi}\n" > ${stderr}
	kubectx | make stream.indent

## END 'kubefwd.*' targets
## BEGIN Misc targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/docs/api#api-k8smk
kubefwd.panic:
	@# Non-graceful stop for everything that is kubefwd related.
	@# 
	@# Emergency use only; this can clutter up your /etc/hosts
	@# file as kubefwd may not get a chance to clean things up.
	@# 
	@# USAGE:  
	@#   ./k8s.mk kubefwd.panic
	@# 
	printf "${GLYPH_K8S} ${@} ${sep}${no_ansi_dim}Killing all kubefwd containers..${no_ansi}\n" > ${stderr}
	(make kubefwd.ps || echo -n) | xargs -I% bash -x -c "docker stop -t 1 %"

kubefwd.ps:
	@# Container names for everything that is kubefwd related
	@# 
	@# USAGE:  
	@#   ./k8s.mk kubefwd.ps
	@# 
	printf "${GLYPH_K8S} ${@} ${sep}${no_ansi_dim}Finding containers..${no_ansi}\n" > ${stderr}
	$(trace_maybe) \
	&& (docker ps --format json \
	| jq -r '.Names' \
	| grep kubefwd \
	|| printf "${yellow}No containers found.${no_ansi}\n" > ${stderr} )

.kubefwd.container_name/%:
	@# Gets an appropriate container-name for the given kubefwd context.
	@# This is for internal usage (you won't need to call it directly)
	@#
	@# USAGE:
	@#	./k8s.mk .kubefwd.container_name/<namespace>/<svc_name>
	@#
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}')))
	$(eval export svc_name:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}')))
	cname=kubefwd.`basename ${PWD}`.$${namespace}.$${svc_name:-all} \
	&& printf $${cname}

kubefwd.help: help.namespace/kubefwd
	@# Shows targets for just the 'kubefwd' namespace.

kubefwd.stop/%:
	@# Stops the named kubefwd instance.
	@# This is mostly for internal usage, usually you want 'kubefwd.start' or 'kubefwd.panic'
	@#
	@# USAGE:
	@#	./k8s.mk kubefwd.stop/<namespace>/<svc_name>
	@#
	${make} docker.stop \
		timeout=30 \
		name=`${make} .kubefwd.container_name/${*}` \
	|| true

kubefwd.stat: kubefwd.ps
	@# Display status info for all kubefwd instances that are running

kubefwd.start/% k8s.namespace.fwd/%:
	@# Runs kubefwd for the given namespace, finding and forwarding ports/DNS for the given 
	@# service, or for all services. This is idempotent, and implicitly stops port-forwarding 
	@# if it is running, then restarts it. 
	@#
	@# NB: This target should only run from the docker host (not from the kubefwd container),  
	@# and it assumes k8s-tools.yml is present with that filename. Simple port-mapping and 
	@# filtering by name is supported; other usage with selectors/labels/reservations/etc 
	@# should just invoke kubefwd directly.
	@#
	@# USAGE: 
	@#   ./k8s.mk kubefwd/<namespace>
	@#   ./k8s.mk kubefwd/<namespace>/<svc_name>
	@#	 mapping="8080:80" ./k8s.mk kubefwd/<namespace> 
	@#   mapping="8080:80" ./k8s.mk kubefwd/<namespace>/<svc_name>
	@#
	$(eval export pathcomp:=$(shell echo ${*}| sed -e 's/\// /g'))
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}')))
	$(eval export svc_name:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}')))
	mapping=$${mapping:-} \
	&& header="${GLYPH_K8S} ${@} ${sep} ${dim_green}$${namespace}" \
	&& case "$${svc_name}" in \
		"") filter=$${filter:-}; ;; \
		*) \
			filter="-f metadata.name=$${svc_name}"; \
			header="$${header} ${sep} ${bold_green}$${svc_name}"; ;; \
	esac \
	&& case "$${mapping}" in \
		"") true; ;; \
		*) mapping="--mapping $${mapping}"; ;; \
	esac \
	&& ${make} kubefwd.stop/${*} \
	&& cname=`${make} .kubefwd.container_name/${*}` \
	&& fwd_cmd="kubefwd svc -n $${namespace} $${filter} $${mapping} -v" \
	&& fwd_cmd_wrapped="docker compose -f k8s-tools.yml run --name $${cname} --rm -d $${fwd_cmd}" \
	&& printf "$${header}${no_ansi}\n" > ${stderr} \
	&& echo {} \
		| ${make} stream.json.object.append key=namespace val="$${namespace}" \
		| ${make} stream.json.object.append key=svc val="$${svc_name}" \
		| ${make} stream.dim.indent > ${stderr} \
	&& echo {} \
		| ${make} stream.json.object.append key=container val="$${cname}" \
		| ${make} stream.json.object.append key=cmd val="$${fwd_cmd}" \
		| ${make} stream.dim.indent > ${stderr} \
	&& printf "$${fwd_cmd_wrapped}\n" | ${make} stream.dim > ${stderr} \
	&& cid=`$${fwd_cmd_wrapped}` && cid=$${cid:0:8} \
	&& cmd="docker logs -f $${cname}" timeout=3 ${make} flux.timeout.sh 
	
## END 'kubefwd.*' targets
## BEGIN Misc targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/docs/api#api-k8smk


ktop: ktop/all
	@# Launches ktop tool.  
	@# (This assumes 'ktop' is mentioned in 'KREW_PLUGINS')

ktop/%:
	@# Launches ktop tool for the given namespace.
	@# This works from inside a container or from the host.
	@#
	@# NB: It's the default, but this does assume 'ktop' is mentioned in 'KREW_PLUGINS'
	@#
	@# USAGE:
	@#   ./k8s.mk ktop/<namespace>
	@#
	@scope=`[ "${*}" == "all" ] && echo "--all-namespaces" || echo "-n ${*}"` \
	&& [ "$${COMPOSE_MK:-0}" = "0" ] \
		&& cmd="ktop $${scope}" entrypoint=kubectl ${make} k8s \
		|| kubectl ktop $${scope}


k9s/%:; ${make} k9s cmd="-n ${*}"
	@# Starts the k9s pod-browser TUI, opened by default to the given namespace.
	@# 
	@# NB: This assumes the `compose.import` macro has already imported k8s-tools services
	@# 
	@# USAGE:  
	@#   ./k8s.mk k9s/<namespace>
	@#
	

k9: k9s
	@# Starts the k9s pod-browser TUI, using whatever namespace is currently activated.
	@# This is just an alias to cover the frequent typo, and it assumes the 
	@# `compose.import` macro has already imported k8s-tools services.
	@#
	@# USAGE:  
	@#   ./k8s.mk k9

## END misc targets
## BEGIN 'tui.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/docs/api#api-tui

# Override compose.mk defaults 
export TUI_SVC_NAME:=tui
export TUI_CONTAINER_IMAGE:=k8s:tui
export TUI_COMPOSE_EXTRA_ARGS:=-f k8s-tools.yml
export TUI_THEME_HOOK_PRE:=.tui.theme.custom
export TUI_THEME_NAME:=powerline/double/red

.tui.theme.custom: .tux.init.theme
	setter="tmux set -goq" \
	&& $${setter} @theme-status-interval 1 \
	&& $${setter} @themepack-status-left-area-middle-format \
		"ctx=#(kubectx -c||echo ?) ns=#(kubens -c||echo ?)" \

k8s.commander:
	@# TUI layout providing an overview for docker.  
	@# This has 3 panes by default, where the main pane is lazydocker, plus two utility panes.
	@# Automation also ensures that lazydocker always starts with the "statistics" tab open.
	@#
	printf "${GLYPH_DOCKER} ${@} ${sep}${dim} Opening commander TUI for k8s..${no_ansi}\n" > ${stderr}
	TUI_LAYOUT_CALLBACK=.tui.k8s.commander.layout \
		TUI_CMDR_PANE_COUNT=4 ${make} tux.commander

k8s.commander/%:
	@# Sends the given target(s) to the main pane.
	@#
	@# USAGE:
	@#   ./k8s.mk k8s.commander/<target1>,<target2>
	@#
	export k8s_commander_targets="${*}" && ${make} k8s.commander

.tui.k8s.commander.layout: 
	printf "${GLYPH_DOCKER} ${@} ${sep} ${no_ansi_dim}Starting widgets and setting geometry..${no_ansi}\n" > ${stderr}
	${make} .tux.pane/4/.tui.widget.k8s.topology.clear/kube-system
	${make} .tux.pane/3/.tui.widget.k8s.topology.clear/default
	${make} .tux.pane/2/flux.loopf/.tux.widget.env/K
	${make} .tux.pane/1/flux.wrap/docker.stat,k8s.stat,$${k8s_commander_targets:-}
	${make} .tux.commander.layout
	title="main" ${make} .tux.pane.title/1
	title="default namespace" ${make} .tux.pane.title/3
	title="kube-system namespace" ${make} .tux.pane.title/4

tui.help:
	@# Shows help information for 'tui.*' targets
	make help.private | grep -E '^(tui|[.]tui)' | uniq | sort --version-sort


tui.panic: 
	@# Non-graceful stop for the TUI (i.e. all the 'k8s:tui' containers).
	@#
	printf "${GLYPH_K8S} tui.panic ${sep} ... ${no_ansi}\n" > ${stderr}
	${make} tux.ps | xargs -I% sh -c "id=% ${make} docker.stop"

.tui.widget.k8s.topology.clear/%:
	clear="--clear" ${make} .tui.widget.k8s.topology/${*}

.tui.widget.k8s.topology/%: io.time.wait/2
	${make} gum.style label="${*} topology"; 
	${make} flux.loopfq/k8s.graph.tui/${*}/pod