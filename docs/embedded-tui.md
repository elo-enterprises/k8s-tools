{% import 'macros.j2' as macros -%}

## Embedded TUI 

### TUI Gallery

For the impatient, here's a small gallery that show-cases the type of stuff you can do with the TUI capabilities that `compose.mk` offers.  

<table align=center width=95%>
    <tr>
        <td>{{macros.img_link("tui-1.gif", mkdocs, "200px")}}</td>
        <td>{{macros.img_link("tui-4.gif", mkdocs, "200px")}}</td>
        <td>{{macros.img_link("tui-6.gif", mkdocs, "200px")}}</td>
    </tr>
    <tr>
        <td>{{macros.img_link("tui-2.gif", mkdocs, "200px")}}</td>
        <td>{{macros.img_link("tui-3.gif", mkdocs, "200px")}}</td>
        <td>{{macros.img_link("tui-5.gif", mkdocs, "200px")}}</td>
    </tr>
</table>

### TUI Overview

It's best to think of the TUI as an interface-builder rather than a specific interface.  One way to look at what the TUI does is that it's just a way of *mapping `make` targets into tmux panes*.  And since [`compose.import`]({{mkdocs.site_relative_url}}/compose.mk) basically allows you to map docker-compose services onto `make` targets, yet another way to think of the TUI is that it allows you to *map containers onto tmux panes*.

Besides leveraging [tmux](https://github.com/tmux/tmux) for core drawing and geometry, the basic components of the TUI are things like [tmuxp](https://github.com/tmux-python/tmuxp) for session management, and overridable defaults for [tmux themes](https://github.com/jimeh/tmux-themepack/), [tmux plugins](https://github.com/tmux-plugins/tpm), [keybindings](#tui-keybindings), etc.  These elements, plus other niceties like [gum](https://github.com/charmbracelet/gum) and [chafa](https://hpjansson.org/chafa/), are all setup in the embedded `compose.mk:tux` container so that there are no host requirements for any of this except docker.

### TUI Implementation

{{macros.img_link("tui-5.gif", mkdocs)}}

How does this work?  The behaviour above relies on a few things.  First, the `compose.mk:tux` container supports docker-in-docker style host-socket sharing with zero configuration.  This means that the TUI can generally do all the same container orchestration tasks as the docker host.  

Without actually writing any custom code, there are many ways to customize the way that the TUI starts and the stuff that's running inside it.  By combining the TUI with the [`loadf` target,]({{mkdocs.site_relative_url}}/compose.mk#loading-compose-files) you can leverage existing compose files but skip [the usual integration with a project Makefile]({{mkdocs.site_relative_url}}/integration).

{{macros.img_link("tui-1.gif", mkdocs)}}

As mentioned in the section above, at the most basic level the TUI just maps make-targets into tmux-panes, so there's no explicit requirement that you need to use targets that are related to containers.

{{macros.img_link("tui-2.gif", mkdocs)}}

### TUI Customization

Beyond the simple examples of customization mentioned in the last section, more advanced use-cases are also supported.  In general, this is usually accomplished by creating custom targets for different parts of the TUI's bootstrap process, then [overriding an appropriate environment variable]({{mkdocs.site_relative_url}}/config#tui-environment-variables) to use the new target.

Documentation for this process isn't great right now, but for a start, have a look at the differences between targets like [docker.commander]({{mkdocs.site_relative_url}}/api#dockercommander) vs the similar-but-different [k3d.commander]({{mkdocs.site_relative_url}}/api#k3dcommander).

### TUI Keybindings

The TUI ships with some default keybindings that are aimed at keeping things pretty user-friendly even for those who are not already familiar with tmux.  

{{bash("pattern='*Keybindings*' make mk.parse.block/compose.mk")}}

These are configurable of course, since there's no way guarantee that such defaults won't collide with whatever existing applications you're trying to stitch together.  See the previous section for more details.