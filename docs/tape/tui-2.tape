# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/tui-2.gif 
Require "make"
Require "docker"
Set Shell "bash --norc --noprofile"
Set FontSize 16
Set Width 1200
Set Height 800
Set TypingSpeed .055
Set PlaybackSpeed 1
Set CursorBlink false
Type "# Launches a split-screen shell context for each of the named make-targets"
Enter
Sleep 2
Type "# This combines several instances of the 'io.time.wait/<seconds>' target, "
Type "# into separate tmux panels.  Each exists, leaving only the default shell at the end."
Enter
Sleep 3
Type "make tux.mux/io.time.wait/5,io.time.wait/7,io.time.wait/9,io.time.wait/11"
Sleep 2.3
Enter
Sleep 35

