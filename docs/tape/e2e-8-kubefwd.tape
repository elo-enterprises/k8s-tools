# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/e2e-kubefwd.gif 
Require "make"
Require "docker"
Set Shell "bash"
Set FontSize 16
Set Width 1100
Set Height 800
Set TypingSpeed .1
Set PlaybackSpeed 2
Set CursorBlink false
Type "make kubefwd.start/default"
Enter
Sleep 6
Type "curl http://nginx-service:12000"
Enter
Sleep 8
