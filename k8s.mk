#!/usr/bin/env -S make -s -f
##
# k8s.mk
#
# This is designed to be used as an `include` from your project's main Makefile.
#
# DOCS: https://github.com/elo-enterprises/k8s-tools#k8smk
#
# LATEST: https://github.com/elo-enterprises/k8s-tools/tree/master/k8s.mk
#
# USAGE: (Add this to your project Makefile)
#
#      include k8s.mk
#	   include compose.mk
#      $(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))
#      demo: ▰/k8s/self.demo
#      self.demo:
#      		kubectl --help
#			helm --help
#
# APOLOGIES: In advance if you're checking out the implementation.
#      Make-macros are not the most fun stuff to read or write.
#      Pull requests are welcome! =P
########################################################################

# ANSI constants.  Usually these are defined already by 'compose.mk', 
# but we (re)define them anyway to ensure that this file can stand-alone.
bold?=\033[1m
dim?=\033[2m
green?=\033[92m
no_ansi?=\033[0m
underline?=\033[4m
yellow=\033[33m
cyan=\033[96m

bold_cyan:=${bold}${cyan}
no_ansi_dim:=${no_ansi}${dim}
cyan_flow_left:=${bold_cyan}⋘${dim}⋘${no_ansi_dim}⋘${no_ansi}

sep:=${no_ansi}//
_GLYPH_K8S=⑆${dim}
GLYPH_K8S=${green}${_GLYPH_K8S}${dim}

export TERM?=xterm

# Defaults for working with charmbracelet/gum
GUM_SPIN_DEFAULTS=--spinner.foreground=231 --spinner meter
GUM_STYLE_DEFAULT:=--border double --foreground 139 --border-foreground 109
GUM_STYLE_DIV:=--border double --align center --width `echo "x=\`tput cols\` - 5;if (x < 0) x=-x; default=30; if (default>x) default else x" | bc`

# How long to wait when checking if namespaces/pods are ready (yes, 'export' is required.)
export K8S_POLL_DELTA?=23

export ALPINE_K8S_VERSION?=alpine/k8s:1.30.0

# Define 'help' target iff it's not already defined.  This should be inlined 
# for all files that want to be simultaneously usable in stand-alone 
# mode + library mode (with 'include')
_help_id:=$(shell (uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s) | head -c 8 | tail -c 8)
define _help_gen
(LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | grep -E -v -e '^[^[:alnum:]]' -e '^$@$$' || true)
endef
_help_${_help_id}:
	@# Attempts to autodetect the targets defined in this Makefile context.  
	@# Older versions of make dont have '--print-targets', so this uses the 'print database' feature.
	@# See also: https://stackoverflow.com/questions/4219255/how-do-you-get-the-list-of-targets-in-a-makefile
	@#
	@$(call _help_gen)
_help_namespaces_${_help_id}:
	@# Returns only the top-level target namespaces
	@$(call _help_gen) | cut -d. -f1 |cut -d/ -f1 | uniq|grep -v ^all$$
_help_private_${_help_id}:
	@# Returns all targets, including private ones
	(LC_ALL=C $(MAKE) -pRrq -f $(firstword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#]") {print $$1}}' | sort | grep -E -v -e '^_help' -e '^$@$$' || true)
$(eval help: _help_${_help_id})
$(eval help.private: _help_private_${_help_id})
$(eval help.namespaces: _help_namespaces_${_help_id})

flux.tmux/%:; make tux.mux/${*}
	@# This alias is an extension of the 'flux.*' API in compose.mk, 
	@# since the names/arguments are so similar.  Still, this strictly
	@# depends on compose-services at k8s-tools.yml, so it's part of 'k8s.mk'
	@#

helm.repo.add/%:
	@# Idempotent version 'helm repo add'
	@#
	@# USAGE:
	@#   make helm.repo.add/<repo_name> url=<repo_url>
	@#  
	set -x \
	&& (helm repo list 2>/dev/null | grep ${*}) \
	|| helm repo add ${*} $${url} 

helm.chart.install/%:
	@# Idempotent version of a 'helm install'
	@#
	@# USAGE:
	@#   make helm.chart.install/<name> chart=<chart>
	@#  
	set -x \
	&& ( helm list | grep ${*} ) \
	|| helm install ${*} $${chart}

k3d.panic:
	@# Non-graceful stop for everything that is k3d related. 
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
	(docker ps --format json \
	| jq -r '.Names' \
	| grep ^k3d- \
	|| printf "${yellow}No containers found.${no_ansi}\n" > /dev/stderr )

k3d.stat:
	@# Show status for k3d.
	@# 
	@#
	printf "${GLYPH_K8S} k3d.stat ${no_ansi_dim}\n" > /dev/stderr
	(printf "${dim}⑆ k3d.ps ${no_ansi}${no_ansi}\n" \
	&& make k3d.ps 2>/dev/null | make stream.dim.indent) | make stream.indent

k3d.cluster.delete/%:
	@# Idempotent version of k3d cluster delete 
	@#
	@# USAGE:
	@#   k3d.cluster.delete/<cluster_name>
	@#
	@( k3d cluster list | grep ${*} > /dev/null ) \
	&& ( set -x && k3d cluster delete ${*} ) || true

k3d.tui/%:
	@# A split-screen TUI dashboard that opens 'lazydocker' and 'ktop'.
	@#
	@# This requires `tmux` on the host, and use assumes `compose.import` has 
	@# already made `ktop` & `lazydocker` targets available.
	@#
	@# USAGE:  
	@#   make k3d.commander/<namespace>
	@# 
	make tux.ui/ktop/${*},lazydocker

k3d.tui: 
	@# Opens k3d.tui for the "default" namespace
	make k3d.tui/default

k8s.get/%:
	@# Returns resources under the given namespace, for the given kind.
	@# This can also be used with a 'jq' query to grab deeply nested results.
	@# Pipe Friendly: results are always JSON.  Caller should handle errors.
	@#
	@# USAGE: 
	@#	 k8s.get/<namespace>/<kind>/<resource_name>/<jq_filter>
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
	&& printf "${GLYPH_K8S} k8s.get${no_ansi_dim} // $${cmd_t}\n${no_ansi}" > /dev/stderr \
	&& eval $${cmd_t}

k8s.graph/%:
	@# Graphs resources under the given namespace, for the given kind, in dot-format.
	@# Pipe Friendly: results are always dot files.  Caller should handle any errors.
	@#
	@# This requires the krew plugin "graph" (installed by default with k8s-tools.yml).
	@#
	@# USAGE: 
	@#	 k8s.graph/<namespace>/<kind>/<field_selector>
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
	@#
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
	@#   make k8s.graph.tui/<namespace>/<kind>
	@#
	export COMPOSE_MK_DEBUG=1 \
	; case $${COMPOSE_MK_DIND} in \
		0) \
			script="make .k8s.graph.tui/${*}" \
			target=krux/shell/pipe \
			make compose.dind.stream; ;; \
		*) \
			make .k8s.graph.tui/${*}; ;; \
	esac
.k8s.graph.tui/%:
	@# (Private helper for k8s.graph.tui)
	@#
	$(call io.mktemp) && \
	make k8s.graph/${*} > $${tmpf} \
	&& cat $${tmpf} \
		| dot /dev/stdin -Tsvg -o /tmp/tmp.svg \
			-Gbgcolor=transparent -Gsize=200,200 \
			-Estyle=bold -Ecolor=red -Eweight=150 > /dev/null \
		&& convert /tmp/tmp.svg -transparent white png:- > /tmp/tmp.png \
		&& default_size=`echo .75*\`tput cols||echo 30\`|bc`x \
		&& chafa --invert --fill braille -c full \
			--center=on --scale max $${clear:-} /tmp/tmp.png
.k8s.graph.tui.clear/%:; clear="--clear" make .k8s.graph.tui/${*}

k8s.kubens/%: 
	@# Context-manager.  Activates the given namespace.
	@# NB: This modifies state in the kubeconfig, so that it can effect contexts 
	@# outside of the current process, therefore this is not thread-safe.
	@#
	@# USAGE:  
	@#   make k8s.kubens/<namespace>
	@#
	TERM=xterm kubens ${*} 2>&1 > /dev/stderr

k8s.kubens.create/%:
	@# Context-manager.  Activates the given namespace, creating it first if necessary.
	@#
	@# NB: This modifies state in the kubeconfig, so that it can effect contexts 
	@# outside of the current process, therefore this is not thread-safe.
	@#
	@# USAGE: 
	@#    k8s.kubens.create/<namespace>
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
	@#	 k8s.namespace/<namespace>
	@#
	make k8s.kubens/${*}

k8s.purge_namespaces_by_prefix/%:
	@# Runs a separate purge for every matching namespace.
	@# NB: This isn't likely to clean everything, see the docs for your dependencies.
	@#
	@# USAGE: 
	@#    k8s.purge_namespaces_by_prefix/<prefix>
	@#
	make k8s.namespace.list \
	| grep ${*} \
	|| (\
		printf "${dim}Nothing to purge: no namespaces matching \`${*}*\`${no_ansi}\n" \
		> /dev/stderr )\
	| xargs -I% bash -x -c "make k8s.namespace.purge/%"

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
	printf "${GLYPH_K8S} k8s.namespace.purge /${no_ansi}${green}${*}${no_ansi} Waiting for delete (cascade=foreground) \n" > /dev/stderr \
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
	@#
	@# This uses only kubectl/jq to loop on pod-status, but assumes that 
	@# the krew-plugin 'sick-pods'[1] is available for formatting the 
	@# user-message.  See `k8s.wait` for an alias that waits on all pods.
	@#
	@# NB: If the parameter is "all" then this uses --all-namespaces
	@#
	@# USAGE: 
	@#   k8s.namespace.wait/<namespace>
	@#
	@# REFS:
	@#   [1]: https://github.com/alecjacobs5401/kubectl-sick-pods
	@#
	@export scope=`[ "${*}" == "all" ] && echo "--all-namespaces" || echo "-n ${*}"` \
	&& export header="${GLYPH_K8S} k8s.namespace.wait ${sep} " \
	&& export header="$${header}${green}${*}${no_ansi}" \
	&& printf "$${header} ${dim}:: Looking for pending pods.. ${no_ansi}\n" > /dev/stderr \
	&& until \
		kubectl get pods $${scope} -o json \
		| jq '[.items[].status.containerStatuses[]|select(.state.waiting)]' \
		| jq '.[] | halt_error(length)' 2> /dev/null \
	; do \
		kubectl sick-pods $${scope} \
			| sed 's/^[ \t]*//'\
			| sed "s/FailedMount/$(shell printf "${yellow}Failed${no_ansi}")/g" \
			| sed "s/Failed\n/$(shell printf "${yellow}Failed${no_ansi}")/g" \
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
			| tr '☂' '\n' 2>/dev/null | make stream.dim > /dev/stderr \
		&& printf "\n${dim}`date`${no_ansi} ${bold}Pods aren't ready yet${no_ansi}\n" > /dev/stderr \
		&& gum spin \
			--title "Waiting ${K8S_POLL_DELTA}s" \
			${GUM_SPIN_DEFAULTS} -- sleep ${K8S_POLL_DELTA}; \
	done \
	&& printf "${dim}$${header} :: ${no_ansi}Namespace looks ready.${no_ansi}\n" > /dev/stderr

k8s.pods.wait_until_ready: 
	@# Waits until all pods in every namespace are ready.
	@# No parameters; kube context should already be configured
	@#
	make k8s.namespace.wait/all
	
k8s.stat.widget:
	printf "\n${GLYPH_K8S} k8s.stat ${no_ansi_dim}ctx=${green}${underline}`kubectx -c||true`${no_ansi_dim} ns=${green}${underline}`kubens -c ||true`${no_ansi}\n" \
	| make stream.to.stderr

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
	| make stream.to.stderr
	( make .k8s.stat.env .k8s.stat.cluster \
		   .k8s.stat.node_info .k8s.stat.auth  \
		   .k8s.stat.ns .k8s.stat.ctx \
	) | make stream.indent | make stream.to.stderr 
.k8s.stat.env:
	printf "${dim}⑆ k8s.stat.env ${no_ansi}${no_ansi}\n"
	( \
		(env | grep CLUSTER || true) \
		; (env | grep KUBE  || true) \
		; (env | grep DOCKER  || true) \
	) | make stream.indent
.k8s.stat.cluster:
	printf "${dim}⑆ k8s.stat.cluster_info ${no_ansi}${no_ansi}\n"
	kubectl version -o json 2>/dev/null | jq . || true
	kubectl cluster-info -o json 2>/dev/null  | jq . || true
.k8s.stat.node_info:
	node_count=`kubectl get nodes -oname|wc -l` \
	&& printf "${dim}⑆ k8s.stat.node_info (${no_ansi}${green}$${node_count}${no_ansi_dim} total)\n" 
	kubectl get nodes | make stream.indent
.k8s.stat.auth:
	printf "${dim}⑆ k8s.stat.auth ${no_ansi}${no_ansi}\n"
	auth_info=`\
		kubectl auth whoami -ojson 2>/dev/null \
		|| printf "${yellow}Failed to retrieve auth info with command:${no_ansi_dim} kubectl auth whoami -ojson${no_ansi}"` \
	&& printf "${dim}$${auth_info}${no_ansi}\n" | make stream.indent
.k8s.stat.ns:
	printf "${dim}⑆ k8s.stat.namespace ${no_ansi}${no_ansi}\n" 
	kubens | make stream.indent
.k8s.stat.ctx:
	printf "${dim}⑆ k8s.stat.context ${no_ansi}${no_ansi}\n" 
	kubectx | make stream.indent

k8s.test_harness/%:
	@# Starts a test-pod in the given namespace, then blocks until it's ready.
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
	&& printf "$${header}${green}$${namespace}${no_ansi}\n" > /dev/stderr \
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
	&& printf "${dim}$${manifest}\n${no_ansi}" > /dev/stderr \
	&& printf "$${manifest}" \
		| jq . \
		| (set -x && kubectl apply --namespace $${namespace} -f -)
	make k8s.namespace.wait/$${namespace}

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
	$(call io.mktemp) && \
	printf "${GLYPH_K8S} k8s.shell${no_ansi_dim} ${sep} $${namespace} ${sep} ${underline}$${pod_name}${no_ansi}\n" >/dev/stderr  \
	&& case "$${rest}" in \
		pipe) \
			cat /dev/stdin > $${tmpf}; \
			([ "$${COMPOSE_MK:-0}" = "0" ] \
				&& (\
					cat $${tmpf} \
					| make k8s-tools/k8s \
						pipe=yes cmd="$${cmd}" \
						entrypoint=kubectl \
					) \
				|| ( \
					printf "${GLYPH_K8S} k8s.shell${no_ansi_dim} // ${no_ansi}${green}$${namespace}${no_ansi_dim} // ${no_ansi}${green}${underline}$${pod_name}${no_ansi_dim} \n${cyan}[${no_ansi}${bold}kubectl${no_ansi_dim}${cyan}]${no_ansi} ${no_ansi_dim}${ital}${cmd}${no_ansi}\n${cyan_flow_left} ${dim_ital}`cat $${tmpf}|make io.fmt.strip`${no_ansi}\n" > /dev/stderr \
					&& cat $${tmpf} | kubectl $${cmd} \
				  ) \
			); ;; \
		*) \
			[ "$${COMPOSE_MK:-0}" = "0" ] \
				&& (cmd="$${cmd}" entrypoint=kubectl make k8s-tools/k8s) \
				|| kubectl $${cmd}; ;; \
        esac
k8s.wait: k8s.namespace.wait/all
	@# Alias for 'k8s.namespace.wait/all'

kubefwd.panic:
	@# Non-graceful stop for everything that is kubefwd related.
	@# 
	@# Emergency use only; this can clutter up your /etc/hosts
	@# file as kubefwd may not get a chance to clean things up.
	@# 
	@# USAGE:  
	@#   make kubefwd.panic
	@# 
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
	|| printf "${yellow}No containers found.${no_ansi}\n" > /dev/stderr )

k8s.namespace.fwd/%:
	@# Alias for 'kubefwd.start'
	@#
	make kubefwd.start/${*}

self.kubefwd.container_name/%:
	@# Gets an appropriate container-name for the given kubefwd context.
	@# This is for internal usage (you won't need to call it directly)
	@#
	@# USAGE:
	@#	self.kubefwd.container_name/<namespace>/<svc_name>
	@#
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}')))
	$(eval export svc_name:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}')))
	cname=kubefwd.`basename ${PWD}`.$${namespace}.$${svc_name:-all} \
	&& printf $${cname}
	
## END 'flux.*' targets
## BEGIN 'stream.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-stream

kubefwd.stop/%:
	@# Stops the named kubefwd instance.
	@# This is mostly for internal usage, usually you want 'kubefwd.start' or 'kubefwd.panic'
	@#
	@# USAGE:
	@#	kubefwd.stop/<namespace>/<svc_name>
	@#
	make docker.stop \
		timeout=30 \
		name=`make self.kubefwd.container_name/${*}` \
	|| true

kubefwd.stat: kubefwd.ps
	@# Display status info for all kubefwd instances that are running

kubefwd.start/%:
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
	@#   make kubefwd/<namespace>
	@#	 make kubefwd/<namespace> mapping="8080:80"
	@#   make kubefwd/<namespace>/<svc_name>
	@#   make kubefwd/<namespace>/<svc_name>  mapping="8080:80"
	@#
	$(eval export pathcomp:=$(shell echo ${*}| sed -e 's/\// /g'))
	$(eval export namespace:=$(strip $(shell echo ${*} | awk -F/ '{print $$1}')))
	$(eval export svc_name:=$(strip $(shell echo ${*} | awk -F/ '{print $$2}')))
	mapping=$${mapping:-} \
	&& header="${GLYPH_K8S} kubefwd.start ${sep} ${dim_green}$${namespace}" \
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
	&& make kubefwd.stop/${*} \
	&& cname=`make self.kubefwd.container_name/${*}` \
	&& fwd_cmd="kubefwd svc -n $${namespace} $${filter} $${mapping} -v" \
	&& fwd_cmd_wrapped="docker compose -f k8s-tools.yml run --name $${cname} --rm -d $${fwd_cmd}" \
	&& printf "$${header}${no_ansi}\n" > /dev/stderr \
	&& echo {} \
		| make io.json.builder key=namespace val="$${namespace}" \
		| make io.json.builder key=svc val="$${svc_name}" \
		| make stream.dim.indent > /dev/stderr \
	&& echo {} \
		| make io.json.builder key=container val="$${cname}" \
		| make io.json.builder key=cmd val="$${fwd_cmd}" \
		| make stream.dim.indent > /dev/stderr \
	&& printf "$${fwd_cmd_wrapped}\n"|make stream.dim > /dev/stderr \
	&& cid=`$${fwd_cmd_wrapped}` && cid=$${cid:0:8} \
	&& cmd="docker logs -f $${cname}" timeout=3 make flux.sh.timeout 

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
	@#   ktop/<namespace>
	@#
	@scope=`[ "${*}" == "all" ] && echo "--all-namespaces" || echo "-n ${*}"` \
	&& [ "$${COMPOSE_MK:-0}" = "0" ] \
		&& cmd="ktop $${scope}" entrypoint=kubectl make k8s \
		|| kubectl ktop $${scope}


k9s/%:; make k9s cmd="-n ${*}"
	@# Starts the k9s pod-browser TUI, opened by default to the given namespace.
	@# 
	@# NB: This assumes the `compose.import` macro has already imported k8s-tools services
	@# 
	@# USAGE:  
	@#   make k9s/<namespace>
	@#
	

k9: k9s
	@# Starts the k9s pod-browser TUI, using whatever namespace is currently activated.
	@# This is just an alias to cover the frequent typo, and it assumes the 
	@# `compose.import` macro has already imported k8s-tools services.
	@#
	@# USAGE:  
	@#   make k9


## END misc targets
## BEGIN 'tui.*' targets
## DOCS: 
##   [1] https://github.com/elo-enterprises/k8s-tools/#api-tui

# export TUI_THEME_PRE_HOOK:=.krux.theme.custom
export TUI_COMPOSE_EXTRA_ARGS:=-f k8s-tools.yml
export TUI_CONTAINER_NAME:=krux
export TUI_THEME_NAME:=powerline/double/cyan
export TUI_THEME_POST_HOOK:=.tux.theme.buttons
export TUI_THEME_PRE_HOOK=.krux.theme.custom
# export TUI_LAYOUT_CALLBACK:=.tui.k8s.commander.layout
# export TUI_INIT_CALLBACK:=.tui.init
export TUI_THEME_NAME:=powerline/default/cyan

.krux.theme.custom: .tux.theme.custom
	setter="tmux set -goq" \
	&& $${setter} @theme-status-interval 1 \
	&& $${setter} @themepack-status-left-area-middle-format \
		"ctx=#(kubectx -c||echo ?) ns=#(kubens -c||echo ?)" \

k8s.commander:
	TUI_LAYOUT_CALLBACK=.tui.k8s.commander.layout make tux.ui/4

tui.pane/%:
	@# Sends a make-target into a pane.
	@# This is a public interface safe to call from the docker-host.
	@# It works by dispatching commands into the 
	@# k8s:krux container to work with tmux.
	pane_id=`printf "${*}"|cut -d/ -f1` \
	&& target=`printf "${*}"|cut -d/ -f2-` \
	&& make k8s-tools.dispatch/krux/.tux.pane/${*}

.tui.k8s.commander.layout: 
	make .tux.pane/4/.tui.widget.k8s.topology.clear/kube-system
	make .tux.pane/3/.tui.widget.k8s.topology.clear/default
	make .tux.pane/2/flux.loopf/
	make .tux.pane/1/flux.wrap/docker.stat,k8s.stat
	make .tux.commander.layout
	title="main" make .tux.pane.title/1
	title="default namespace" make .tux.pane.title/3
	title="kube-system namespace" make .tux.pane.title/4

.tui.widget.k8s.topology.clear/%:; clear="--clear" make .tui.widget.k8s.topology/${*}
.tui.widget.k8s.topology/%: io.time.wait/2
	make gum.style text="${*} topology"; 
	make flux.loopf/k8s.graph.tui/${*}/pod

tui.help:
	@# Shows help information for 'tui.*' targets
	make help.private | grep -E '^(tui|[.]tui)' | uniq | sort --version-sort

tui.panic: 
	@# Non-graceful stop for the TUI (i.e. all the 'k8s:krux' containers).
	@#
	printf "${GLYPH_K8S} tui.panic ${sep} ... ${no_ansi}\n" > /dev/stderr
	make tux.ps | xargs -I% sh -c "id=% make docker.stop"

TUI_CONTAINER_IMAGE:=k8s:krux
# TUI_CONTAINER_IMAGE?=compose.mk:tux

tux.ps:
	@# Lists ID's for containers related to the TUI.
	@#
	set -x && docker ps --format json |jq -r 'select(.Image=="${TUI_CONTAINER_IMAGE}").ID'

tui.all: \
	flux.delay/2/tui.pane/1/panel1 \
	k8s.commander 

# pane2:
# 	make io.bash
pane3: 
	curl -sL https://github.com/elo-enterprises/k8s-tools/raw/master/img/icon.png|chafa --size 30
	make gum.style text='kube-system topology'; sleep 5

## BEGIN '.tui.*' targets
## These targets require tmux, and so are only executed *from* the 
## TUI, i.e. inside either the compose.mk:tux container, or inside k8s:krux.  
## See instead 'tui.*' for public (docker-host) entrypoints.

.tui.init: 
	@# Initialization for the TUI (a tmuxinator-managed tmux session).
	@# This needs to be called from inside the TUI container, with tmux already running.
	@#
	@# Typically this is used internally during TUI bootstrap, but you can call this to 
	@# rexecute the main setup for things like default key-bindings and look & feel.
	@#
	printf "${GLYPH_K8S} .tui.init ${sep} ... ${no_ansi}\n" > /dev/stderr
	make .tux.config 

	
# run-shell ~/.tmux/plugins/tmux-sidebar/sidebar.tmux
# set -g @sidebar-tree-command 'make k8s.namespace.list'
# set -g @sidebar-tree-command 'tree -C'


# k8s.graph.ez/%:
# 	@#
# 	@#
# 	$(call io.mktemp) && \
# 	make ▰/k8s/k8s.graph/${*} > $${tmpf} \
# 	&& ./k8s-tools.yml run graph-easy $${tmpf}

# primitive metrics with no deps: https://stackoverflow.com/questions/54531646/checking-kubernetes-pod-cpu-and-memory-utilization
# k8s.metrics:
# 	kubectl exec -it pod_name -n namespace -- /bin/bash
# 	Run cat /sys/fs/cgroup/cpu/cpuacct.usage for cpu usage
# 	Run cat /sys/fs/cgroup/memory/memory.usage_in_bytes

k8s.help: help.namespace/k8s
k3d.help: help.namespace/k3d
kubefwd.help: help.namespace/kubefwd

