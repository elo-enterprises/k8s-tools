# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/e2e-interactive-tui.gif 
Require "make"
Require "docker"
Set Shell "bash"
Set FontSize 18
Set Width 1100
Set Height 900
Set TypingSpeed .15
Set PlaybackSpeed 5
Set CursorBlink false
Type "make k8s.commander"
Enter
Sleep 4
Down 1
Sleep 5
Down 1
Sleep 5
Enter
Sleep 55
Ctrl+C
Ctrl+C