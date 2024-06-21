# This file describes terminal videos with the `vhs` tool (https://github.com/charmbracelet/vhs)
Output img/e2e-provision-test-harness.gif 
Require "make"
Require "docker"
Set Shell "bash"
Set FontSize 18
Set Width 1000
Set Height 950
Set TypingSpeed 2.0
Set PlaybackSpeed 20
Set CursorBlink false
Type "make deploy.test_harness"
Enter
Sleep 340

