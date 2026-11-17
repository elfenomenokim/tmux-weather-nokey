# tmux-weather-nokey

[한국어](README.ko.md)

Current weather, plus a clock face, in your tmux status line. **No API key.**

![weather and clock segment](docs/pill.png)

```
☀️ 14°C 70%
```

- Uses [wttr.in](https://wttr.in) and falls back to [Open-Meteo](https://open-meteo.com) when wttr.in is slow or down.
- A bad reply ("Unknown location", HTML error pages, timeouts) never overwrites the cache. If both sources fail you keep seeing the last good value instead of an error.
- A cache hit runs no network or tmux call, so a 15-second `status-interval` costs almost nothing.
- Plain POSIX `sh`. Needs `curl`; `jq` only for the fallback.

## Install

With [TPM](https://github.com/tmux-plugins/tpm), add to `~/.tmux.conf`:

```tmux
set -g @plugin 'elfenomenokim/tmux-weather-nokey'
set -g @weather-location 'Seoul'
set -g status-right '#{weather} | %H:%M'
```

Then press `prefix` + `I`. Keep `set -g status-right` **above** the TPM `run` line.

Manual install: clone the repo and add `run-shell /path/to/tmux-weather-nokey/weather.tmux` to `~/.tmux.conf`.

## Placeholders

| Placeholder | Output |
|---|---|
| `#{weather}` | `☀️ 14°C 70%` |
| `#{weather_icon}` | `☀️` |
| `#{weather_temp}` | `14°C 70%` |
| `#{clock_icon}` | `🕓` clock face for the current time, to the nearest half hour (🕐 1:00, 🕜 1:30) |
| `#{weather_pill}` | The ready-made segment in the picture above: weather icon, temperature, clock face, time |

Split icon and temperature to style them in separate segments (for example with catppuccin or dracula themes), or use `#{weather_pill}` for a finished look:

```tmux
set -g status-right '#{weather_pill}'
```

### `#{weather_pill}` options

| Option | Default | Meaning |
|---|---|---|
| `@weather-pill-weather-bg` / `-soft` / `-fg` | `#179299` / `#d0f0f0` / `#0a5050` | Icon block, temperature block, temperature text |
| `@weather-pill-clock-bg` / `-soft` / `-fg` | `#dc8a78` / `#fde0d8` / `#7a3020` | Clock block, time block, time text |
| `@weather-pill-icon-fg` | `#dce0e8` | Text colour on the solid blocks |
| `@weather-pill-time-format` | `%H:%M` | `strftime` format, for example `%I:%M %p` |
| `@weather-pill-separator` | empty | Put a Powerline glyph such as `` here if your font has one |

Set these above the TPM `run` line, like `status-right`.

## Options

| Option | Default | Meaning |
|---|---|---|
| `@weather-location` | empty | City name or `lat,lon`. Empty lets wttr.in guess from your IP; the fallback needs a value. |
| `@weather-units` | `metric` | `metric` or `imperial` |
| `@weather-interval` | `1800` | Cache lifetime in seconds |
| `@weather-timeout` | `3` | Seconds per request |
| `@weather-humidity` | `on` | `off` hides the humidity |
| `@weather-lang` | `en` | wttr.in language code |

Every tmux server can share one setting through `~/.config/tmux-weather-nokey/config` (one `key=value` per line, for example `location=Seoul`, `units=imperial`). Order of precedence: environment variable, tmux option, config file, default.

Each option can also come from an environment variable (`WEATHER_LOCATION`, `WEATHER_UNITS`, ...), which is handy outside tmux:

```sh
WEATHER_LOCATION=Paris scripts/weather.sh temp
```

The cache lives in `${XDG_CACHE_HOME:-~/.cache}/tmux-weather-nokey/current`. Delete it to refresh at once after changing an option.

## Why another weather plugin?

wttr.in is a single free server. It sometimes accepts the connection and then never answers, and a "location not found" reply can sit in a naive cache for an hour. This plugin was written after both happened, so it keeps a second source and only caches good lines.

## License

MIT
