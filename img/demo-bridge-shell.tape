# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/demo-bridge-shell.gif 
Require "make"
Require "docker"
Set Shell "bash"
Set FontSize 20
Set Width 1000
Set Height 350
Set TypingSpeed 70ms
Type "make debian/shell"
Enter
Sleep 3s
Ctrl+D
Sleep 1 
Type "make alpine/shell"
Enter
Sleep 3s
Ctrl+D
