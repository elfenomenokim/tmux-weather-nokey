#!/usr/bin/env bash
# TPM entry point: replaces the placeholders below in status-right and status-left.
#   #{weather}  #{weather_icon}  #{weather_temp}  #{clock_icon}  #{weather_pill}
# #{weather_pill} is a ready-made two-tone segment: weather icon | temperature, clock face | time.
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CURRENT_DIR/scripts/weather.sh"
CLOCK="$CURRENT_DIR/scripts/clock.sh"

opt() { local v; v="$(tmux show-option -gqv "$1")"; printf '%s' "${v:-$2}"; }

pill() {
  local sep wbg wsoft wfg cbg csoft cfg ifg fmt
  sep="$(opt @weather-pill-separator '')"
  wbg="$(opt @weather-pill-weather-bg '#179299')"; wsoft="$(opt @weather-pill-weather-soft '#d0f0f0')"; wfg="$(opt @weather-pill-weather-fg '#0a5050')"
  cbg="$(opt @weather-pill-clock-bg '#dc8a78')"; csoft="$(opt @weather-pill-clock-soft '#fde0d8')"; cfg="$(opt @weather-pill-clock-fg '#7a3020')"
  ifg="$(opt @weather-pill-icon-fg '#dce0e8')"; fmt="$(opt @weather-pill-time-format '%H:%M')"
  printf '%s' "#[fg=$ifg,bg=$wbg,bold] #($SCRIPT icon) #[fg=$wbg,bg=$wsoft]$sep#[fg=$wfg,bg=$wsoft,nobold] #($SCRIPT temp) "
  printf '%s' "#[fg=$wsoft,bg=$cbg]$sep#[fg=$ifg,bg=$cbg,bold] #($CLOCK) #[fg=$cbg,bg=$csoft]$sep#[fg=$cfg,bg=$csoft,nobold] $fmt #[fg=$csoft,bg=default]$sep#[default]"
}

interpolate() {
  local value="$1"
  case "$value" in *'#{weather_pill}'*) value="${value//\#\{weather_pill\}/$(pill)}" ;; esac
  value="${value//\#\{weather_icon\}/#($SCRIPT icon)}"
  value="${value//\#\{weather_temp\}/#($SCRIPT temp)}"
  value="${value//\#\{clock_icon\}/#($CLOCK)}"
  value="${value//\#\{weather\}/#($SCRIPT full)}"
  printf '%s' "$value"
}

for option in status-right status-left; do
  tmux set-option -gq "$option" "$(interpolate "$(tmux show-option -gqv "$option")")"
done
