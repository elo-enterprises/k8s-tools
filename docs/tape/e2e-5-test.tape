# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/e2e-test.gif 
Require "make"
Require "docker"
Set Shell "bash"
Set FontSize 16
Set Width 1100
Set Height 800
Set TypingSpeed .15
Set PlaybackSpeed 3
Set CursorBlink false
Type "make test"
Enter
Sleep 65

