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

emit() {
  case "$PART" in
    icon|emoji) printf '%s' "${1%% *}" ;;
    temp|text) case "$1" in *" "*) printf '%s' "${1#* }" ;; *) printf '%s' "$1" ;; esac ;;
    *) printf '%s' "$1" ;;
  esac
}

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

# Different locations and display options must not share cached weather.
key="$(printf '%s\n' "$location" "$units" "$humidity" "$lang" | cksum | awk '{print $1 "-" $2}')"
CACHE="$CACHE_DIR/current-$key"
# Cache line 1 = expiry epoch, line 2 = value. Entries are specific to effective output options.
now="$(date +%s)"
expires=0; cached=""
if [ -r "$CACHE" ]; then
  { read -r expires; read -r cached; } < "$CACHE" || true
  case "$expires" in ''|*[!0-9]*) expires=0 ;; esac
  if [ "$now" -lt "$expires" ] && [ -n "$cached" ]; then emit "$cached"; exit 0; fi
fi

urlencode() {  # jq is optional: encode every byte outside the unreserved set when it is absent
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$1" | jq -sRr @uri
    return
  fi
  encoded=""
  for byte in $(printf '%s' "$1" | od -An -v -tu1); do
    case "$byte" in
      45|46|95|126) encoded="$encoded$(printf "\\$(printf '%03o' "$byte")")" ;;
      *)
        if { [ "$byte" -ge 48 ] && [ "$byte" -le 57 ]; } \
          || { [ "$byte" -ge 65 ] && [ "$byte" -le 90 ]; } \
          || { [ "$byte" -ge 97 ] && [ "$byte" -le 122 ]; }; then
          encoded="$encoded$(printf "\\$(printf '%03o' "$byte")")"
        else
          encoded="$encoded$(printf '%%%02X' "$byte")"
        fi ;;
    esac
  done
  printf '%s' "$encoded"
}
format="%c+%t"; [ "$humidity" = off ] || format="$format+%h"
wunit="m"; [ "$units" = imperial ] && wunit="u"

weather="$(curl -s --max-time "$timeout" "https://wttr.in/$(urlencode "$location")?format=$format&$wunit&lang=$lang" 2>/dev/null | tr -d '+' | xargs 2>/dev/null || true)"
valid_weather() {
  if [ "$humidity" = off ]; then
    printf '%s\n' "$1" | grep -Eq '^[^ ]+ -?[0-9]+°[CF]$'
  else
    printf '%s\n' "$1" | grep -Eq '^[^ ]+ -?[0-9]+°[CF] [0-9]+%$'
  fi
}
valid_weather "$weather" || weather=""

# Fallback: Open-Meteo needs coordinates; a name is resolved once with its geocoder.
if [ -z "$weather" ] && [ -n "$location" ] && command -v jq >/dev/null 2>&1; then
  case "$location" in
    *[0-9],*[0-9]*) lat="${location%%,*}"; lon="${location#*,}" ;;
    *) geo="$(curl -s --max-time "$timeout" "https://geocoding-api.open-meteo.com/v1/search?count=1&name=$(urlencode "$location")" 2>/dev/null || true)"
       lat="$(printf '%s' "$geo" | jq -r '.results[0].latitude // empty' 2>/dev/null)"
       lon="$(printf '%s' "$geo" | jq -r '.results[0].longitude // empty' 2>/dev/null)" ;;
  esac
  if [ -n "${lat:-}" ] && [ -n "${lon:-}" ]; then
    tunit=""; sym="°C"; [ "$units" = imperial ] && { tunit="&temperature_unit=fahrenheit"; sym="°F"; }
    reply="$(curl -s --max-time "$timeout" "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto$tunit" 2>/dev/null || true)"
    weather="$(printf '%s' "$reply" | jq -r --arg sym "$sym" --arg hum "$humidity" '.current | (
      (.weather_code) as $c |
      (if $c == 0 then "☀️" elif $c <= 2 then "⛅" elif $c == 3 then "☁️" elif $c == 45 or $c == 48 then "🌫️"
       elif $c >= 51 and $c <= 57 then "🌦️" elif ($c >= 61 and $c <= 67) or ($c >= 80 and $c <= 82) then "🌧️"
       elif ($c >= 71 and $c <= 77) or $c == 85 or $c == 86 then "❄️" elif $c >= 95 then "⛈️" else "🌡️" end)
      + " " + (.temperature_2m | round | tostring) + $sym
      + (if $hum == "off" then "" else " " + (.relative_humidity_2m | tostring) + "%" end))' 2>/dev/null || true)"
  fi
fi

valid_weather "$weather" || weather=""

# Cache writes are atomic, and an interrupted write leaves the previous entry alone.
tmp=""
cleanup() { [ -z "${tmp:-}" ] || rm -f "$tmp"; }
trap cleanup EXIT
trap 'cleanup; exit 1' HUP INT TERM
write_cache() {  # write_cache <expiry> <value>
  mkdir -p "$CACHE_DIR" 2>/dev/null || return 0
  tmp="$(mktemp "$CACHE_DIR/.weather.XXXXXXXX" 2>/dev/null || true)"
  [ -n "$tmp" ] || return 0
  if printf '%s\n%s\n' "$1" "$2" > "$tmp" && mv "$tmp" "$CACHE"; then
    tmp=""
  else
    cleanup
    tmp=""
  fi
}

if [ -n "$weather" ]; then
  write_cache "$((now + interval))" "$weather"
  emit "$weather"
elif [ -n "$cached" ]; then
  # Both sources failed: keep showing the last good value, and retry only after one interval.
  write_cache "$((now + interval))" "$cached"
  emit "$cached"
else
  # Nothing cached yet: remember the miss so a down service is not queried on every refresh.
  write_cache "$((now + interval))" "n/a"
  emit "n/a"
fi
