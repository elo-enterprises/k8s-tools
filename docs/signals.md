## Signals and Supervisors


 
 ### Motivation 
 
 Without [forking make](https://remake.readthedocs.io/en/latest/), there's no simple method to get hooks into the default way that it handles interrupts and signals.  But why would you want to anyway?  Most of the time this occurs to people [it's about cleanup](https://www.gnu.org/software/make/manual/html_node/Interrupts.html), but `compose.mk` doesn't exactly look like traditional use-cases.
 
The main reason to care is that short-circuiting make's default CLI option parsing is *really useful*.  Especially since `compose.mk` allows us to "wrap" lots of containerized tools, we want to be able to proxy arguments over to those tools without `make` being greedy about parsing everything.

The [`loadf` command](#loading-compose-file) is a typical example: the 2nd argument, a filename, must not be parsed as a Makefile target:

```bash
# Opens all shells for each service in the given file inside the TUI
./compose.mk loadf tests/docker-compose.yml
```
 
Sometimes we want individual targets to essentially be able to consume the rest of the command line.  In this case, the filename is best understood as an argument to the first target, and not a target itself.
 
The [wrapper for jb](docs/api/#jb) is another example of an invocation that requires reading the whole command-line.  And for targets created with [`compose.import`](#makecompose-bridge), the [special form with '--'] (#special-form) also requires this kind of short-circuiting.

### Implementation






 
* [mk.supervisor.enter/<arg>](docs/api#mk.supervisor.enterarg) 
* [mk.supervisor.exit/<arg>](docs/api#mk.supervisor.exitarg) 
* [mk.supervisor.interrupt](docs/api#mk.supervisor.interrupt) 
* [mk.supervisor.interrupt/<arg>](docs/api#mk.supervisor.interruptarg) 
* [mk.supervisor.pid](docs/api#mk.supervisor.pid) 
* [mk.supervisor.trap/<arg>](docs/api#mk.supervisor.traparg) 
* [mk.interrupt](docs/api#mk.interrupt) 
* [mk.interrupt/<arg>](docs/api#mk.interruptarg) 
* [mk.interrupt/SIGINT](docs/api#mk.interruptSIGINT) 


