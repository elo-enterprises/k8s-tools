### Embedded TUI

The basic components of the TUI are things like [tmux](https://github.com/tmux/tmux) for core drawing and geometry, [tmuxp](https://github.com/tmux-python/tmuxp) for session management, and basic [tmux themes](https://github.com/jimeh/tmux-themepack/) / [plugins](https://github.com/tmux-plugins/tpm) / etc that are baked in.  These elements (plus other niceties like [gum](https://github.com/charmbracelet/gum) and [chafa](https://hpjansson.org/chafa/)) are all setup in the embedded `compose.mk:tux` container so that there are no host requirements for any of this except docker.

<img src=img/tui-5.gif>

How does this work?  The behaviour above relies on a few things.  First, the `compose.mk:tux` container supports docker-in-docker style host-socket sharing with zero configuration.  This means that the TUI can generally do all the same container orchestration tasks as the docker host.  

Without actually writing any custom code, there are many ways to customize the way that the TUI starts and the stuff that's running inside it.  By combining the TUI with the [`loadf` target,](#loading-compose-files) you can leverage existing compose files but skip [the usual integration with a project Makefile](#embedding-tools-with-makefiles).


<img src=img/tui-1.gif>

One way to look at the TUI is that it's just a way of mapping make-targets into tmux panes.  So you don't actually have to use targets that are related to containers.

<img src=img/tui-2.gif>

