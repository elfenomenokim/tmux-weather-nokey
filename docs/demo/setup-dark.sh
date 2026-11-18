#!/bin/sh
set -eu
cache=/tmp/weather-demo-dark-cache
mkdir -p "$cache"
expires=$(($(date +%s) + 3600))
printf '%s\n%s\n' "$expires" '☀️ 14°C 70%' > "$cache/current"
export WEATHER_CACHE_DIR="$cache"
cd docs/products/dotfiles/tmux/plugins/tmux-weather-nokey
tmux -L weather-demo-dark kill-server 2>/dev/null || true
tmux -L weather-demo-dark -f /dev/null new-session -d -s demo -c /tmp 'PS1="$ " bash --noprofile --norc -i'
tmux -L weather-demo-dark set-environment -t demo WEATHER_CACHE_DIR "$cache"
tmux -L weather-demo-dark set-option -g status-style 'bg=#1e1e2e,fg=#cdd6f4'
tmux -L weather-demo-dark set-option -g status-interval 1
tmux -L weather-demo-dark set-option -g status-right-length 120
tmux -L weather-demo-dark set-option -g status-left ' demo | main '
tmux -L weather-demo-dark set-option -g status-right '#{weather_pill}'
tmux -L weather-demo-dark run-shell 'bash weather.tmux'
