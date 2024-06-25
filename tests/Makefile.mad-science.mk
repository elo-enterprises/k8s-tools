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
all: demo.env demo.dockerfile demo.python demo.python.pipes
demo.env: #io.envp


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

# make.def.dispatch.python/%:; make make.def.dispatch/python3/${*}:
# make.def.dispatch.python.pipe/%:; cat /dev/stdin | make make.def.dispatch.python/${*}
