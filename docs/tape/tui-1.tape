# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/tui-1.gif 
Require "make"
Require "docker"
Set Shell "bash --norc --noprofile"
Set FontSize 12
Set Width 1000
Set Height 800
Set TypingSpeed .03
Set PlaybackSpeed 1
Set CursorBlink false
Type "# Let's launch a split-screen shell context, one pane for each of the named tool containers."
Enter
Type "# The names here will come from the services defined in k8s-tools.yml."
Enter
Sleep 3
Type "make tui.shell/k8s,eksctl,argo,kn"
Sleep 2.3
Enter
Sleep 30

