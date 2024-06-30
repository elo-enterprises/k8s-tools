# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/tui-7.gif 
Require "make"
Require "docker"
Set Shell "bash --norc --noprofile"
Set FontSize 16
Set Width 1200
Set Height 800
Set TypingSpeed .055
Set PlaybackSpeed 2
Set CursorBlink false
Type "# Look ma, working help:"
Enter
Enter
Sleep 3.0
Set PlaybackSpeed 3
Type "./compose.mk help"
Sleep 2.8
Enter
Sleep 10

