# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/e2e-interactive-tui.gif 
Require "make"
Require "docker"
Set Shell "bash"
Set FontSize 12
Set Width 1200
Set Height 900
Set TypingSpeed .25
Set PlaybackSpeed 2
Set CursorBlink false
Type "make k8s.commander"
Enter
Sleep 4
Down 1
Sleep 5
Down 1
Sleep 5
Enter
Sleep 35
Ctrl+C
Ctrl+C