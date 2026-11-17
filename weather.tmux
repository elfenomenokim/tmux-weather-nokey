#!/usr/bin/env bash
# TPM entry point: replaces #{weather}, #{weather_icon} and #{weather_temp} in the status line.
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CURRENT_DIR/scripts/weather.sh"

interpolate() {
  local value="$1"
  value="${value//\#\{weather_icon\}/#($SCRIPT icon)}"
  value="${value//\#\{weather_temp\}/#($SCRIPT temp)}"
  value="${value//\#\{weather\}/#($SCRIPT full)}"
  printf '%s' "$value"
}

for option in status-right status-left; do
  tmux set-option -gq "$option" "$(interpolate "$(tmux show-option -gqv "$option")")"
done
