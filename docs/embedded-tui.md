{% import 'macros.j2' as macros -%}
### Embedded TUI


#### TUI Overview

Since `compose.import` allows you to map containers onto make-targets, it's really useful to also be able to map make-targets onto panes.  Because, 🤔 ..well, this means we can map containers onto panes.  Eagled-eyed readers will have noticed that there's a preview of this functionality in the [last section, using `loadf`](#loading-compose-files), but it works for things that *aren't* just container-shells too, and sometimes that's more interesting.  

*Some of the containers in k8s-tools.yml are already TUIs*, so it's possible to basically treat those as widgets in bigger TUI.  We just need a geometry manager for all this, and tmux is the obvious choice.

The basic components of the TUI are things like [tmux](https://github.com/tmux/tmux) for core drawing and geometry, [tmuxp](https://github.com/tmux-python/tmuxp) for session management, and basic [tmux themes](https://github.com/jimeh/tmux-themepack/) / [plugins](https://github.com/tmux-plugins/tpm) / etc that are baked in.  These elements (plus other niceties like [gum](https://github.com/charmbracelet/gum) and [chafa](https://hpjansson.org/chafa/)) are all used from containers so that there are **no host requirements for any of this except docker.**  

#### TUI Features

Additional features include:

* Mouse-enabled, so click-to-focus works as expected.
* Clickable Buttons!
    * Although it doesn't ship with most operating systems yet, [tmux supports this lately](https://github.com/tmux/tmux/issues/3652).
    * Support for New-Pane / Exit buttons currently
    * Tmux-script is awkward to codegen, but support for dynamically defined buttons is possible.
* Keybindings:
    * Resize pane: *Alt + Arrow Keys*
    * Jump to pane: *Alt + Number Keys*
    * Split pane horizontally: *Ctrl+b -*
    * Split pane vertically: *Ctrl+b |*
* Flexible bootstrap supports customization and configuration.
    * See the examples below to get an idea of what's possible.  
    * See also the docs for [TUI Customization](#tui-customization)
    * See also the [TUI environment variables section](#tui-environment-variables)

{{macros.hr2()}}

#### Docker Commander 
 
The TUI container supports docker-in-docker style host-socket sharing with zero configuration.  This means that the TUI can generally do all of the same container orchestration tasks as the docker host.  The [`docker.commander`](#dockercommander) target is a good example of this.  It's a 3-pane layout with the lazydocker UI in the main pane, and a couple of ancillary panes for other work.

<a href=img/tui-5.gif><img width="50%" src=img/tui-5.gif></a>

{{macros.hr2()}}

#### On-Demand Shells for Tool-Containers

Without actually writing any custom code, there are many ways to customize how the TUI starts and the stuff that's running inside it.  By combining the TUI with the [`loadf` target,](#loading-compose-files) you can leverage existing compose files but skip [the usual integration with a project Makefile](#embedding-tools-with-makefiles).

If no arguments are passed except a compose file, the default is to open shells for each service the file describes.

{{macros.img_link("img/tui-3.gif","70%")}}

In the case of k8s-tools.yml, there's quite a lot of services, so there's simply not enough space to open all of them.  Since [`loadf`](#loading-compose-files) proxies additional instructions, you can use [`tux.mux.svc`](#tuxmuxsvcarg) to open named services like this:

{{macros.img_link("img/tui-1.gif","50%")}}

{{macros.hr2()}}

#### Generic Target Dispatch

One way to look at the TUI is that it's just a way of mapping make-targets into tmux panes.  You don't actually have to use targets that are related to containers.

{{macros.img_link("img/tui-2.gif","50%")}}

{{macros.hr2()}}

#### K8s Commander

The [`k8s.commander` target](#k8scommander) launches a 4-pane layout with a large central pane for running commands (usually deployments), plus some widgets for previewing cluster topology, etc.  See the [Demo for Cluster Automation](#demo-cluster-automation) for more context on this.

{{macros.img_link("img/e2e-k8s.commander.gif","50%")}}

{{macros.hr2()}}

#### K3d Commander

Since k3d builds kubernetes clusters where the nodes themselves are containers, this TUI is pretty similar to the [Docker Commander](#docker-commander) but also has some elements of the [K8s Commander](#k8s-commander).  This is a 5-pane layout that shows `k9s` and `lazydocker` prominently, for an overview of what's going with your host-system containers and your cluster,  plus ancillary panes for other use-cases.

{{macros.img_link("img/e2e-k3d.commander.gif","50%")}}

{{macros.hr2()}}

#### TUI Customization

The base container spec for the TUI is defined as the `tux` service.  With apologies to the linux penguin, the "tux" name here is short for "tmux UX", "terminal UI" (or whatever else you like :).  The `tux` service is *embedded* inside `compose.mk`.  If you're thinking that embedding a compose-file in a Makefile sounds insane, *you're not wrong!*, but the good news is that the file contents are effectively frozen, and **this ensures that for basic functionality `compose.mk` has no external dependencies.**  This container-spec provides a bare minimum of functionality, but it's possible to extend this base for further customization.  

Building on that base, k8s-tools.yml defines a separate TUI base (`k8s:tui`) that's used with k8s.mk to add more kubernetes-specific tooling to the base container.

Note the green `k8s:tui` on the righthand side of the status bar in the [K8s Commander](#k8s-commander) demo.  This indicates the `k8s:tui` container is being used and not the default `tux` container.  

See the next sections on the [private API](#tui-private-api) and [TUI Environment Variables](docs/env-vars.md#tui-environment-variables) for more details about configuring and customizing the TUI bootstrap.

##### TUI Private API

The [public API for `tux.*` targets](/docs/api#api-tux) describes several lower-level operations that can safely be performed inside or outside of the TUI (i.e. on the docker host).

There's also a "private" API, which targets are under the namespace `.tux.*`, and which is characterized by actually issuing commands to tmux directly.  The private API is intended to be used from *inside* the `tux` container or containers that extend it.  This ensures that your host doesn't actually require a tmux stack, and also ensures that usage of the TUI is always relatively stateless.  (It's not extensively tested yet, but in theory it should be generally safe to run multiple copies of the TUI, and embed TUIs in TUIs, etc.)

See the [API docs](/docs/api#tui-private-api).

{{macros.hr2()}}
