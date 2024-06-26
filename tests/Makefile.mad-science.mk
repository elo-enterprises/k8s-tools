##
# exercising 'make.def.dispatch' and friends for bad ideas.  
# have you ever wondered if you could implement make targets in other languages?  
# the answer is yes.
#
# Usage: 
#
#   # from project root
#   $ make mad
##
SHELL := bash
MAKEFLAGS=-s --warn-undefined-variables
.SHELLFLAGS := -eu -c

include compose.mk

.DEFAULT_GOAL := all 
all: demo.env demo.python demo.python.pipes

# Minimal boilerplate to couple the '_demo.python' def-block with 
# a specific interpretter (python3), plus a specific target ('demo.python').
# The business with the '@' below is referring to "this target name",
# and prepends it with _ so that the symbols for target and the 
# corresponding def-block remain unique
demo.python:; make make.def.dispatch/python3/_${@}
define _demo.python
import sys
print('hello world')
endef

# Similar to the above, but this example uses pipes
demo.python.pipes:;  echo '{"hello":"bash"}' | make make.def.pdispatch/python3/_${@}
define _demo.python.pipes
import sys, json
input=json.loads(sys.stdin.read())
input.update(hello="python")
output=input
print(json.dumps(output))
for x in [1,2,3]:
	print(f"{x} testing loops, indention, and string interpolation", file=sys.stderr)
endef


demo.env: io.env

make.def.dispatch.python/%:; make make.def.dispatch/python3/${*}:
	@#
	@#
	@#

make.def.dispatch.python.pipe/%:; cat /dev/stdin | make make.def.dispatch.python/${*}
	@#
	@#
	@#
