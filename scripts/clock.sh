#!/bin/sh
# tmux-weather-nokey: clock-face emoji for the current time, to the nearest half hour (🕐 1:00, 🕜 1:30).
# Usage: clock.sh   (prints one emoji; POSIX, no network)
set -u
h=$(date +%H); m=$(date +%M)
h=${h#0}; m=${m#0}
h=$(( ${h:-0} % 12 )); m=${m:-0}
half=0
if [ "$m" -ge 45 ]; then h=$(( (h + 1) % 12 )); elif [ "$m" -ge 15 ]; then half=1; fi
[ "$h" -eq 0 ] && h=12
set -- 🕐 🕑 🕒 🕓 🕔 🕕 🕖 🕗 🕘 🕙 🕚 🕛
[ "$half" -eq 1 ] && set -- 🕜 🕝 🕞 🕟 🕠 🕡 🕢 🕣 🕤 🕥 🕦 🕧
eval "printf '%s' \"\${$h}\""
