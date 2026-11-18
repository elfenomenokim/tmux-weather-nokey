Output docs/demo/weather-dark.gif
Set Shell bash
Set FontSize 18
Set Width 1200
Set Height 320
Set Padding 28
Set Theme "Catppuccin Mocha"
Set TypingSpeed 45ms
Set WindowBar Colorful
Set BorderRadius 10
Hide
Set TypingSpeed 0
Sleep 500ms
Type "export PS1='$ '"
Enter
Type "sh docs/demo/setup-dark.sh"
Enter
Sleep 1s
Type "clear"
Enter
Sleep 600ms
Show
Set TypingSpeed 45ms
Type "tmux -L weather-demo-dark attach-session -t demo"
Enter
Sleep 4s
Hide
Type "tmux -L weather-demo-dark kill-server"
Enter
Sleep 300ms
