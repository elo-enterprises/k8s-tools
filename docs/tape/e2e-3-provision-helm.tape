# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/e2e-provision-helm.gif 
Require "make"
Require "docker"
Set Shell "bash"
Set FontSize 18
Set Width 1000
Set Height 800
Set TypingSpeed .42
Set CursorBlink false
Set PlaybackSpeed 10
Type "make deploy.helm"
Enter
Enter
Sleep 28
Type "make k8s.pods.wait_until_ready"
Enter
Sleep 150

