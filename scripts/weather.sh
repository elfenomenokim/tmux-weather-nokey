#!/bin/sh
# tmux-weather-nokey: current weather for the tmux status line, no API key.
# wttr.in first, Open-Meteo as the fallback; a bad reply never reaches the cache.
#
# Usage: weather.sh [full|icon|temp]   (emoji = icon, text = temp are accepted too)
# Options: environment variable > tmux `set -g` option > config file > default.
# Config file: ${XDG_CONFIG_HOME:-~/.config}/tmux-weather-nokey/config, lines like "location=Seoul".
#   @weather-location   WEATHER_LOCATION   city name or "lat,lon"; empty = wttr.in guesses from your IP
#   @weather-units      WEATHER_UNITS      metric (default) | imperial
#   @weather-interval   WEATHER_INTERVAL   cache lifetime in seconds (default 1800)
#   @weather-timeout    WEATHER_TIMEOUT    seconds per request (default 3)
#   @weather-humidity   WEATHER_HUMIDITY   on (default) | off
#   @weather-lang       WEATHER_LANG       wttr.in language code (default en)
# Runs under /bin/sh from tmux: POSIX only. Needs curl; jq only for the Open-Meteo fallback.
set -u

PART="${1:-full}"
CACHE_DIR="${WEATHER_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/tmux-weather-nokey}"
CACHE="$CACHE_DIR/current"

emit() {
  case "$PART" in
    icon|emoji) printf '%s' "${1%% *}" ;;
    temp|text) case "$1" in *" "*) printf '%s' "${1#* }" ;; *) printf '%s' "$1" ;; esac ;;
    *) printf '%s' "$1" ;;
  esac
}

# Cache line 1 = expiry epoch, line 2 = value. A hit costs one `date`, no tmux or network call.
now="$(date +%s)"
expires=0; cached=""
if [ -r "$CACHE" ]; then
  { read -r expires; read -r cached; } < "$CACHE" || true
  case "$expires" in ''|*[!0-9]*) expires=0 ;; esac
  if [ "$now" -lt "$expires" ] && [ -n "$cached" ]; then emit "$cached"; exit 0; fi
fi

# Optional shared config file (key=value per line, keys without "@weather-"), read once on a miss.
CONFIG="${WEATHER_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/tmux-weather-nokey/config}"
conf() {
  [ -r "$CONFIG" ] || return 0
  while IFS='=' read -r key val; do
    [ "$key" = "$1" ] && { printf '%s' "$val"; return 0; }
  done < "$CONFIG"
}
opt() {  # opt <tmux option> <env value> <default>; env > tmux option > config file > default
  if [ -n "$2" ]; then printf '%s' "$2"; return; fi
  value=""
  [ -n "${TMUX:-}" ] && value="$(tmux show-option -gqv "$1" 2>/dev/null)"
  [ -n "$value" ] || value="$(conf "${1#@weather-}")"
  printf '%s' "${value:-$3}"
}
location="$(opt @weather-location "${WEATHER_LOCATION:-}" "")"
units="$(opt @weather-units "${WEATHER_UNITS:-}" metric)"
interval="$(opt @weather-interval "${WEATHER_INTERVAL:-}" 1800)"
timeout="$(opt @weather-timeout "${WEATHER_TIMEOUT:-}" 3)"
humidity="$(opt @weather-humidity "${WEATHER_HUMIDITY:-}" on)"
lang="$(opt @weather-lang "${WEATHER_LANG:-}" en)"
case "$interval" in ''|*[!0-9]*) interval=1800 ;; esac

urlencode() { printf '%s' "$1" | jq -sRr @uri 2>/dev/null || printf '%s' "$1" | sed 's/ /%20/g'; }
format="%c+%t"; [ "$humidity" = off ] || format="$format+%h"
wunit="m"; [ "$units" = imperial ] && wunit="u"

weather="$(curl -s --max-time "$timeout" "https://wttr.in/$(urlencode "$location")?format=$format&$wunit&lang=$lang" 2>/dev/null | tr -d '+' | xargs 2>/dev/null || true)"
case "$weather" in
  ""|*[Uu]nknown*|*"not available"*|*"not found"*|*Sorry*|*error*|*ERROR*|*"<"*) weather="" ;;
esac

# Fallback: Open-Meteo needs coordinates; a name is resolved once with its geocoder.
if [ -z "$weather" ] && [ -n "$location" ] && command -v jq >/dev/null 2>&1; then
  case "$location" in
    *[0-9],*[0-9]*) lat="${location%%,*}"; lon="${location#*,}" ;;
    *) geo="$(curl -s --max-time 5 "https://geocoding-api.open-meteo.com/v1/search?count=1&name=$(urlencode "$location")" 2>/dev/null || true)"
       lat="$(printf '%s' "$geo" | jq -r '.results[0].latitude // empty' 2>/dev/null)"
       lon="$(printf '%s' "$geo" | jq -r '.results[0].longitude // empty' 2>/dev/null)" ;;
  esac
  if [ -n "${lat:-}" ] && [ -n "${lon:-}" ]; then
    tunit=""; sym="°C"; [ "$units" = imperial ] && { tunit="&temperature_unit=fahrenheit"; sym="°F"; }
    reply="$(curl -s --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto$tunit" 2>/dev/null || true)"
    weather="$(printf '%s' "$reply" | jq -r --arg sym "$sym" --arg hum "$humidity" '.current | (
      (.weather_code) as $c |
      (if $c == 0 then "☀️" elif $c <= 2 then "⛅" elif $c == 3 then "☁️" elif $c == 45 or $c == 48 then "🌫️"
       elif $c >= 51 and $c <= 57 then "🌦️" elif ($c >= 61 and $c <= 67) or ($c >= 80 and $c <= 82) then "🌧️"
       elif ($c >= 71 and $c <= 77) or $c == 85 or $c == 86 then "❄️" elif $c >= 95 then "⛈️" else "🌡️" end)
      + " " + (.temperature_2m | round | tostring) + $sym
      + (if $hum == "off" then "" else " " + (.relative_humidity_2m | tostring) + "%" end))' 2>/dev/null || true)"
  fi
fi

if [ -n "$weather" ]; then
  mkdir -p "$CACHE_DIR" 2>/dev/null && printf '%s\n%s\n' "$((now + interval))" "$weather" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
  emit "$weather"
elif [ -n "$cached" ]; then
  emit "$cached"   # both sources down: keep showing the last good value
else
  emit "n/a"
fi
