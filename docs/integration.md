## Integration With Your Project

You can embed the k8s-tools suite in your project in two ways, either with some kind of global compose file and global aliases, or with a more project-based approach using Makefiles.

----------------------------------------------------

### Compatibility Notes

Platforms used in development include modern docker (say `25+`), make (`3.8+`), and bash `(~5`) on both Linux and MacOS, but testing in github-actions only uses Linux and won't try every possible combination of versions.  

In general, the goal *is* to support most things you'll encounter in the wild, including OSX, out of the box.  But you may see some of the usual problems with certain arguments to OSX default `sed` / `ps` / `xargs`, etc.  Please report issues!

----------------------------------------------------

### Embedding Tools With Aliases

To use this pattern with your existing projects, you might want to maintain separated compose files and setup aliases.

```bash
$ cd myproject

# or use your fork/clone..
$ curl -sL {{github.raw_url}}/master/k8s-tools.yml > k8s-tools.yml

$ alias helm=docker compose -f myproject/k8s-tools.yml run helm

$ helm ....
```

Aliases are convenient but rather fragile (obviously this will break if you move your `myproject` folder around).  

See the next section for something that is a more durable and flexible.

----------------------------------------------------

### Embedding Tools With Makefiles

You'll probably want to read over the [compose.mk](#composemk) section to understand what's going on here.  In case you've already seen it though, here's the quick start with the copy/paste stuff.

{% set integration_block %}
First, copy the files from this repo into your project:

```bash
$ cd myproject 

# Download the compose file with the tool containers
$ curl -sL \
  {{github.raw_url}}/master/k8s-tools.yml \
    > k8s-tools.yml

# Download the compose.mk automation lib
$ curl -sL \
  {{github.raw_url}}/master/compose.mk \
    > compose.mk

# Optional.  
# Download the k8s.mk automation lib.
$ curl -sL \
  {{github.raw_url}}/master/k8s.mk \
    > k8s.mk
```

These 3 files are usually working together, but in some cases they are useful in a stand-alone mode.  Make them all executable like this:

```bash
$ chmod ugo+x k8s-tools.yml compose.mk k8s.mk

# equivalent to `make -f k8s.mk ..`
./k8s.mk ... 

# equivalent to `make -f compose.mk ..`
$ ./compose.mk ... 

# equivalent to `docker compose -f k8s-tools.yml run ...`
$ ./k8s-tools.yml run ...
```

If you're interested in setting up the [Make/Compose bridge](#makecompose-bridge) or preparing for [Container Dispatch](#container-dispatch), here's and example of what your Makefile should look like:

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

----------------------------------------------------

### Stand-Alone Tools

If you're not interested in custom automation that requires project-Makefile integration, some features of `compose.mk` and `k8s.mk` can be used without that.  See the [Loading Compose Files](#loading-compose-files) docs, plus the [full CLI docs](/api) for more details.
