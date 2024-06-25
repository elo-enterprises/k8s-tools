
### Loading Compose Files

For the simplest use-cases where you have a compose-file, and want some of the compose.mk features, but don't have a project makefile, it's possible to skip some of the steps in the [usual integration](#embedding-tools-with-makefiles) by letting `loadf` generate integration for you just in time.

```bash 
$ ./compose.mk loadf <path_to_compose_file> <other_instructions>
```

Since `make` can't modify available targets from inside recipes, this basically works by creating temporary files that use the [compose.import macro](#macro-arguments) on the given compose file, then proxying subsequent CLI arguments over to *that* automation.  When no other instructions are provided, the default is to [open container shells in the TUI](#embedded-tui).

<img src=img/tui-3.gif>

Actually any type of instructions you pass will get the compose-file context, so you can use any of the other targets documented as [part of the bridge](#make-compose-bridge) or the [static targets](#api-compose.mk).  For example:

<img src=img/tui-4.gif>

Despite all the output this is pipe-safe, in case the commands involved might return JSON for downstream parsing, etc.  See the [Embedded TUI](#embedded-tui) docs for other examples that are using `loadf`.
