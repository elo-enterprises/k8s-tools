# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/tui-3.gif 
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
Type "./compose.mk loadf tests/docker-compose.yml"
Sleep 2.3
Enter
Sleep 20

