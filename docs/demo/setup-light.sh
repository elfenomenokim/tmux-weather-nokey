#!/bin/sh
set -eu
cache=/tmp/weather-demo-light-cache
cd "$(dirname "$0")/../.."   # the plugin root, from a checkout or the monorepo
mkdir -p "$cache"
expires=$(($(date +%s) + 3600))
# Synthetic weather only: pin the options the cache key and the tmux server use,
# so a user config file cannot point the demo at live weather.
export WEATHER_CONFIG=/dev/null WEATHER_LOCATION= WEATHER_UNITS=metric WEATHER_HUMIDITY=on WEATHER_LANG=en
key=$(printf '%s\n' "$WEATHER_LOCATION" "$WEATHER_UNITS" "$WEATHER_HUMIDITY" "$WEATHER_LANG" | cksum | awk '{print $1 "-" $2}')
printf '%s\n%s\n' "$expires" '☀️ 14°C 70%' > "$cache/current-$key"
export WEATHER_CACHE_DIR="$cache"
tmux -L weather-demo-light kill-server 2>/dev/null || true
tmux -L weather-demo-light -f /dev/null new-session -d -s demo -c /tmp 'PS1="$ " bash --noprofile --norc -i'
tmux -L weather-demo-light set-environment -t demo WEATHER_CACHE_DIR "$cache"
tmux -L weather-demo-light set-option -g status-style 'bg=#eff1f5,fg=#4c4f69'
tmux -L weather-demo-light set-option -g status-interval 1
tmux -L weather-demo-light set-option -g status-right-length 120
tmux -L weather-demo-light set-option -g status-left ' demo | main '
tmux -L weather-demo-light set-option -g status-right '#{weather_pill}'
tmux -L weather-demo-light run-shell 'bash weather.tmux'
