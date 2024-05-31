## Integration With Your Project

You can embed the k8s-tools suite in your project in two ways, either with some kind of global compose file and global aliases, or with a more project-based approach using Makefiles.

----------------------------------------------------

### Embedding Tools With Aliases

For using this pattern with your existing projects, you might want to maintain separated compose files and setup aliases.

```bash
$ cd myproject

# or use your fork/clone..
$ curl -sL {{github.raw_url}}/master/k8s-tools.yml > k8s-tools.yml

$ alias helm=docker compose -f myproject/k8s-tools.yml run helm

$ helm ....
```

Aliases are convenient but rather fragile (obviously this will break if you move your `myproject` folder around).  See the next section for something that is a more durable and flexible.

----------------------------------------------------

### Embedding Tools With Makefiles

You'll probably want to read over the [compose.mk](#makefilecomposemk) section to understand what's going on here.  In case you've already seen it though, here's the quick start with the copy/paste stuff for using the `compose.import` macro with your projects.

{% set integration_block %}
First, copy the files from this repo into your project:

```bash
$ cd myproject 

# or use your fork/clone..
$ curl -sL \
  {{github.raw_url}}/master/k8s-tools.yml \
    > k8s-tools.yml
$ curl -sL \
  {{github.raw_url}}/master/compose.mk \
    > compose.mk

# optional.  this can also just be appended to
# compose.mk if you want less clutter
$ curl -sL \
  {{github.raw_url}}/master/k8s.mk \
    > k8s.mk
```

Now include `compose.mk` inside your main project Makefile and call the `compose.import` macro.

```Makefile
# myproject/Makefile (Make sure you have real tabs, not spaces!)
 
# Include/invoke the target-building macros 
# somewhere near the top of your existing boilerplate
include compose.mk
$(eval $(call compose.import, ▰, TRUE, k8s-tools.yml))

# At this point, targets are defined for whatever services
# are mentioned in the external compose config, and they are
# ready to use. Now you can dispatch any task to any container!
test: ▰/k8s/self.test
self.test:
  kubectl --version
  echo hello world from `uname -n -v`
```
{% endset %}
{{integration_block}}

Skip to the sections describing the [Make/Compose bridge](#makecompose-bridge) and [Container Dispatch](#container-dispatch) for more details.

