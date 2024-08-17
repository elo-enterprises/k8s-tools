## Signals and Supervisors

You can think of `compose.mk` as a long list of egregious hacks that can only be redeemed by a *'but look what you can do with this!'* moment.  On that list, **signals and supervisors** is perhaps the most absurd thing of all.

### Signals and Supervisors: Motivation

Without [forking make](https://remake.readthedocs.io/en/latest/), there's no simple method to get hooks into the default way that it handles interrupts and signals.  But why would you want to anyway?  Most of the time this occurs to people [it's about cleanup](https://www.gnu.org/software/make/manual/html_node/Interrupts.html), but `compose.mk` doesn't exactly look like traditional use-cases.

The main reason to care is that short-circuiting make's default CLI option parsing is *really useful*.  Especially since `compose.mk` allows us to "wrap" lots of containerized tools, we want to be able to proxy arguments over to those tools without `make` being greedy about parsing everything.

The [`loadf` command](#loading-compose-files) is a typical example: the 2nd argument, a filename, must not be parsed as a Makefile target:

```bash
# Opens all shells for each service in the given file inside the TUI
./compose.mk loadf tests/docker-compose.yml
```
 
Sometimes we want individual targets to essentially be able to consume the rest of the command line.  In this case, the filename is best understood as an argument to the first target, and not a target itself.
 
The [wrapper for jb](/k8s-tools/api#jb) is another example of an invocation that requires reading the whole command-line.  And for targets created with [`compose.import`](/k8s-tools/compose.mk#makecompose-bridge), the [special form with '--'] (#special-form) also requires this kind of short-circuiting.

### Signals and Supervisors: Implementation

Since the last section describes the goal, you might be wondering how this kind of semi-magical behavior can be achieved.   And since the answer to that question is frankly kind of ridiculous, this should probably be considered experimental :)  With that sternly worded warning out of the way... 

Signals and supervisors are implemented using [shebang hack](https://en.wikipedia.org/wiki/Shebang_(Unix)) and a [polyglot](https://en.wikipedia.org/wiki/Polyglot_(computing)), whereby `compose.mk` is simultaneously a Makefile, a Makefile library, *and* a bash script.  The bash script invokes make, but wraps it to catch signals that are thrown by make.  After throwing a supported signal causes `make` to exit, bash catches, and then passes the code for the caught signal back to another invocation of `make`.  

**As a consequence of this, signals can only be handled when `compose.mk` is invoked directly,** i.e. with `./compose.mk ...`.  Since `k8s.mk` also includes the same polyglot/shebang-hack, it also supports the same capabilities, but **note that project Makefile's that are using `include compose.mk` or `include k8s.mk` cannot inherit this ability!**

All targets related to signals/supervisors can be found under the `mk.interrupt` and `mk.super` namespaces, respectively.




 
* [`mk.supervisor.enter/<arg>`](docs/api#mk.supervisor.enterarg) 
* [`mk.supervisor.exit/<arg>`](docs/api#mk.supervisor.exitarg) 
* [`mk.supervisor.interrupt`](docs/api#mk.supervisor.interrupt) 
* [`mk.supervisor.interrupt/<arg>`](docs/api#mk.supervisor.interruptarg) 
* [`mk.supervisor.pid`](docs/api#mk.supervisor.pid) 
* [`mk.supervisor.trap/<arg>`](docs/api#mk.supervisor.traparg) 
* [`mk.interrupt`](docs/api#mk.interrupt) 
* [`mk.interrupt/<arg>`](docs/api#mk.interruptarg) 
* [`mk.interrupt/SIGINT`](docs/api#mk.interruptSIGINT) 

