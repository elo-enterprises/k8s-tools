

% set subtitle = "Demo --  MadScience" %}




<table align=center style="width:100%">
  <tr>
    <td colspan=2><strong>k8s-tools </strong>&nbsp;&nbsp;&nbsp;&nbsp;
    </td>
  </tr>
  <tr>
    <td align=center width=10%>
      <center>
        <img src=img//docker.png style="width:75px"><br/>
        <img src=img//kubernetes.png style="width:75px"><br/>
        <img src=img//make.png style="width:75px"><br/>
      </center>
    </td>
    <td width=90%>
      <table align=center border=1>
        <tr align=center><td align=center width="13%"><a href=/README.md#overview>Overview</a></td>
<td align=center width="13%"><a href=/README.md#features>Features</a></td>
<td align=center width="13%"><a href=/README.md#integration>Integration</a></td>
<td align=center width="13%"><a href=/README.md#composemk>compose.mk</a></td>
<td align=center width="13%"><a href=/README.md#k8smk>k8s.mk</a></td>
<td align=center width="13%"><a href=/docs/api/>API</a></td>
<td align=center width="13%"><a href=/docs/demos>Demos</a></td></tr>
      </table>
      <hr style="border-bottom:1px solid black;"><center><span align=center>&nbsp;<a href="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml"><img src="https://github.com/elo-enterprises/k8s-tools/actions/workflows/docker-test.yml/badge.svg"></a>&nbsp;<a href="/docs/env-vars.md"><img alt=":" src="https://img.shields.io/badge/-blue"></a>&nbsp;&nbsp;<a href="/docs/env-vars.md"><img alt="kubectl:v1.30.0" src="https://img.shields.io/badge/kubectl%3Av1.30.0-blue"></a>&nbsp;<a href="/docs/env-vars.md"><img alt="helm:v3.14.4" src="https://img.shields.io/badge/helm%3Av3.14.4-blue"></a>&nbsp;</span></center><hr style="border-bottom:1px solid black;">
    </td>
  </tr>
</table><center><span align=center>
  Completely dockerized version of a kubernetes toolchain, plus a zero-dependency automation framework for extending and interacting it. Project-local clusters, cluster lifecycle automation, customizable TUIs, and more.
</span></center>

<div class="toc">
<ul>
<li><a href="#_1">}</a><ul>
<li><a href="#working-with-foreign-languages">Working with Foreign Languages</a></li>
<li><a href="#inlined-docker-files">Inlined Docker Files</a></li>
<li><a href="#extending-inlined-docker-files">Extending Inlined Docker Files</a></li>
<li><a href="#local-interpretters-without-a-container">Local Interpretters, Without a Container</a></li>
<li><a href="#exotic-targets-pipes">Exotic Targets &amp; Pipes</a></li>
<li><a href="#passing-data-structures-to-externally-managed-containers">Passing Data Structures to Externally Managed Containers</a></li>
<li><a href="#how-it-works">How it Works</a></li>
</ul>
</li>
</ul>
</div>



#}
<h2>Demo: Mad Science</h2>




This section is a small walk-through of some of the bad ideas in the [mad science test-suite](tests/Makefile.mad-science.mk).  You can run this test-suite from the project root with `make mad`.

Most of the demonstrations here are frankly nuts, and most likely no one will thank you for introducing these techniques into real projects!  Now, with that stern warning out of the way.. Here are some powerful techniques for "polyglotting" your Makefiles, or in other words **implementing different targets in different languages** and things like that.  This is useful for prototyping, and with some judicious restraint then you can potentially improve on many things that are otherwise very awkward from `make` or `bash`.  But if you use it with wild abandon you'll probably regret it.  Choose wisely ;)

### Working with Foreign Languages

```Makefile 
# tests/Makefile.mad-science.mk

# Minimal boilerplate for working with elixir-lang.  
# This picks an image for the language kernel 
# allowing overrides from the environment, 
# then runs a script with it.

export IMG_ELIXIR?=elixir:otp-27-alpine

demo.elixir:
	img=$${IMG_ELIXIR} \
	entrypoint=elixir \
	def=Elixir.hello_world \
	make docker.run.def

define Elixir.hello_world 
import IO, only: [puts: 1]
puts("elixir World!")
System.halt(0)
endef

```

### Inlined Docker Files

```Makefile 
# tests/Makefile.mad-science.mk

## Inlined Docker Files

# Minimal inlined dockerfile.  
# You can install anything or nothing here, 
# but let's have the minimal stuff required for target dispatch.
define Dockerfile.demo_dockerfile
FROM alpine
RUN echo building container spec from inlined dockerfile
RUN apk add --update --no-cache coreutils alpine-sdk bash procps-ng
endef


# Wrapper target that's using the container.
# This sets the container-build as a pre-req, so that
# within the body we can assume the base image exists.
demo.dockerfile: docker.from.def/demo_dockerfile
	# Working with the image directly, note the 'compose.mk' prefix.
	docker image inspect compose.mk:demo_dockerfile > /dev/null
	docker run -it --entrypoint sh compose.mk:demo_dockerfile -x -c "true" > /dev/null
	
	# Working with compose.mk builtins omits prefix, 
	# and can do dispatch targets to run inside the new image
	img=demo_dockerfile make mk.docker.run/self.demo.dockerfile
	
	# Add the prefix explicitly, and you can use `docker.run` instead of private `.docker.run`
	img=compose.mk:demo_dockerfile make docker.run/self.demo.dockerfile
	entrypoint=sh cmd='-c "ls"' img=compose.mk:demo_dockerfile make docker.run.sh 
	# Subsequent runs will use the cached image.  
	# Pass 'force' to work around this.
	force=1 make docker.from.def/demo_dockerfile

self.demo.dockerfile:
	echo "Testing target from inside the inlined-container"
	uname -a

```

### Extending Inlined Docker Files

Inlined containers can actually be extended with other inlines, but notice again the 'compose.mk' prefix which is used as a "repository".

```Makefile 
# tests/Makefile.mad-science.mk

## Extending Inlined Docker Files
# Minimal inlined dockerfile.  
# You can install anything or nothing here, 
# but let's have the minimal stuff required for target dispatch.
define Dockerfile.demo.extend.container
FROM compose.mk:demo_dockerfile
RUN echo hello-docker
endef


# Wrapper target that's using the container.
# This basically sets the container-build as a pre-req,
# so that within the body we can assume the base image exists.
demo.container.extension: docker.from.def/demo.extend.container
	# # Working with the image directly, note the 'compose.mk' prefix.
	docker image inspect compose.mk:demo.extend.container > /dev/null
	docker run -it --entrypoint sh compose.mk:demo.extend.container -x -c "true" > /dev/null
	
	# Working with compose.mk builtins omits prefix, 
	# and can dispatch targets to run inside the new image
	img=demo.extend.container make mk.docker.run/self.demo.container.extension
	
	# Add the prefix explicitly, and you can use `docker.run` instead of private `.docker.run`
	img=compose.mk:demo.extend.container make docker.run/self.demo.container.extension
	
	# Subsequent runs will use the cached image.  
	# Pass 'force' to work around this.
	force=1 make docker.from.def/demo.extend.container

self.demo.container.extension:
	echo "Testing target from inside the inlined-container"
	uname -a

```

### Local Interpretters, Without a Container

```Makefile 
# tests/Makefile.mad-science.mk

## Local Interpretters, Without a Container

# Look, here's a simple python script 
define Python.demo
import sys
print('python world')
print('dollarsigns are safe: $')
endef

# Minimal boilerplate to run the script,
# using a specific interpretter (python3).
# No container here, so this requires that 
# the interpretter is actually available.
demo.python:
	make mk.def.dispatch/python3/Python.demo

```

### Exotic Targets & Pipes

```Makefile 
# tests/Makefile.mad-science.mk

## Exotic Targets & Pipes

# A more complex python script, 
# testing comments, indention, & using pipes
define Python.demo.python.pipes
# python script
import sys, json
input = json.loads(sys.stdin.read())
input.update(hello_python=sys.platform)
output = input
print(json.dumps(output))
for x in [1, 2, 3]:
  msg=f"{x} testing loops, indents, string interpolation"
  print(msg, file=sys.stderr)
endef

# Runs the script, passing data into the pipe
demo.python.pipes:
	echo '{"hello":"bash"}' \
	| make mk.def.dispatch/python3/Python.${@}

```

### Passing Data Structures to Externally Managed Containers

So far we've seen examples of passing code, but of course the process is much the same for data.

Let's embed a playbook, then run it with the `ansible` container defined in `k8s-tools.yml`.

```Makefile 
# tests/Makefile.mad-science.mk

### Passing Data Structures to Externally Managed Containers

# Look, it's a simple ansible playbook 
define Ansible.example_playbook
- name: Example Playbook with Debug Task
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Print a debug message
      debug:
        msg: "Hello, this is a debug message!"
endef

# Writes the playbook to a temp file,
# then runs it from inside the 'ansible' container
demo.ansible.playbook: 
	$(call io.mktemp) \
	&& make mk.def.to.file/Ansible.example_playbook/$${tmpf} \
	&& entrypoint=ansible-playbook \
		cmd="-i localhost, $${tmpf}" \
			make k8s-tools/ansible

```

This is just an example, and anyway you may prefer to work with the [ansible.adhoc](/docs/api#ansibleadhocarg) tooling which is better for simple use-cases.  

But of course the playbook above could just as easily be an `eksctl` config or `kubectl` manifest.

### How it Works 

Most of this stuff hinges on multi-line defines, plus the ability of `compose.mk` to handle reflection, which is possible because it has some ability to parse its own contents.  See the API for [*`mk.*`*](/docs/api#api-mk) and [*`docker.*`*](/docs/api#api-docker) for more details.  Note also that the [*`mk.def.*`* targets](/docs/api#api-mk) leave the data inside the defs completely unmolested, which means that there's no requirement for escaping the contents, and things like '$' are always left alone.  This also means the **content is fairly static**, and not typically amenable to pre-execution templating.  It *is* possible to work around this, but that's an even worse idea than the rest of this is, and so left as an exercise to the reader. =P

</details>
