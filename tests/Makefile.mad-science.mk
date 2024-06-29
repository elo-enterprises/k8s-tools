##
# Exercising 'make.def.dispatch' and friends for bad ideas.  
# Have you ever wondered if you could implement make targets in other languages?  
# The answer is yes.
#
# USAGE: ( from project root)
#   $ make mad
#
##
SHELL := bash
MAKEFLAGS=-s --warn-undefined-variables
.SHELLFLAGS := -eu -c

include compose.mk

.DEFAULT_GOAL := all 
all: demo.dockerfile demo.python demo.python.pipes demo.ansible


# Minimal boilerplate to couple the 'Dockerfile.demo.dockerfile' block with 
# the 'demo.dockerfile' target, running the self.demo.dockerfile target 
# in the resulting container.
demo.dockerfile:; ${make} docker.from.def/${@} docker.run/${@}/self.${@}
define Dockerfile.demo.dockerfile 
FROM alpine
RUN echo building container spec from inlined dockerfile
RUN apk add --update --no-cache coreutils alpine-sdk bash procps-ng
endef
self.demo.dockerfile:
	echo "testing target from inside inlined-container"
	uname -a

# Minimal boilerplate to couple the '_demo.python' def-block with 
# a specific interpretter (python3), plus a specific target ('demo.python').
# The business with the '@' below is referring to "this target name",
# and prepends it with _ so that the symbols for target and the 
# corresponding def-block remain unique
demo.python:; make make.def.dispatch/python3/Python.${@}
define Python.demo.python
# python script
import sys
print('hello world')
endef

# Similar to the above, but this example uses pipes
demo.python.pipes:;  echo '{"hello":"bash"}' | make make.def.pdispatch/python3/Python.${@}
define Python.demo.python.pipes
# python script
import sys, json
input=json.loads(sys.stdin.read())
input.update(hello="python")
output=input
print(json.dumps(output))
for x in [1,2,3]:
	print(f"{x} testing loops, indention, and string interpolation", file=sys.stderr)
endef

# Minimal boilerplate to expose a container-internal API to make. 
# This example builds a minimal ansible container from an inlined dockerfile,
# then wraps ansible-adhoc[1] commands as make-targets.
# [1]: https://docs.ansible.com/ansible/latest/command_guide/intro_adhoc.html
# [2]: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/debug_module.html
# [3]: https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ping_module.html
demo.ansible:
	make ansible.adhoc/ping
	args="msg='testing'" make ansible.adhoc/ansible.builtin.debug
ansible.adhoc/%:; module=${*} make ansible_adhoc
ansible_adhoc:; env="args,module" ${make} docker.from.def/${@} docker.run/${@}/self.${@}
self.ansible_adhoc:
	$(trace_maybe) \
	&& module=$${module:-ping} \
	&& args="$${args:-}" \
	&& printf "${GLYPH_DOCKER} ${@} ${sep}${dim} ${dim_cyan}$${module}${no_ansi_dim} ${sep}${no_ansi_dim} args=${green}$${args} ${no_ansi}\n" > ${stderr} \
	&& ANSIBLE_LOAD_CALLBACK_PLUGINS=1 \
	ANSIBLE_STDOUT_CALLBACK=ansible.posix.json \
	ansible all -i localhost, \
		--connection local \
		--module-name $${module} \
		--args "$${args:-}" | jq .plays[0].tasks[0].task
define Dockerfile.ansible_adhoc
FROM python:3.11-slim-bookworm
RUN echo building container spec from inlined dockerfile
RUN apt-get update && apt-get install -y ansible make procps jq
RUN ansible --version
endef