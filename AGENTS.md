# AGENTS.md — tmux-weather-nokey

Instructions for an AI agent asked to install or configure this plugin for a user.

## Repository work

- TPM entry point: `weather.tmux`; weather and clock scripts: `scripts/`.
- Keep `scripts/weather.sh` POSIX `sh`; do not add an API key or a runtime dependency beyond `curl` (with optional `jq` for fallback parsing).
- The project has no configured test or lint command. For a manual local check, run `sh -n scripts/weather.sh` and `bash -n weather.tmux`.
- Use only synthetic weather and isolated tmux socket names in demos. Never inspect or change an existing user tmux server while recording.
- Keep cache writes atomic and reject malformed upstream replies before replacing the last good value.
- Do not shorten the documented minimum 600-second interval; both weather services are free and rate-limited.

## Install for the user

1. Check prerequisites: `tmux -V` (any 3.x), `command -v curl`. `jq` is optional (enables the Open-Meteo fallback); install it with the system package manager if the user agrees.
2. If `~/.tmux/plugins/tpm` exists, add `set -g @plugin 'elfenomenokim/tmux-weather-nokey'` to `~/.tmux.conf` before the line `run '~/.tmux/plugins/tpm/tpm'`, then run `~/.tmux/plugins/tpm/bin/install_plugins`.
   Without TPM: `git clone https://github.com/elfenomenokim/tmux-weather-nokey ~/.tmux/plugins/tmux-weather-nokey` and append `run-shell ~/.tmux/plugins/tmux-weather-nokey/weather.tmux` to `~/.tmux.conf`.
3. Ask the user for a location (city name or `lat,lon`) and units; set `@weather-location` / `@weather-units`. Do not guess the user's home location.
4. Put `#{weather}` (or `#{weather_icon}` and `#{weather_temp}`, plus `#{clock_icon}` if wanted) into the existing `status-right`, or `#{weather_pill}` when the user wants the finished coloured segment; keep that `set` line above the TPM `run` line. Preserve the user's other status content.
5. Apply: `tmux source-file ~/.tmux.conf`.

## Verify

- `WEATHER_LOCATION='<location>' ~/.tmux/plugins/tmux-weather-nokey/scripts/weather.sh full` prints one line such as `☀️ 14°C 70%`; `n/a` means both sources failed and nothing is cached yet.
- `tmux show -gv status-right` should contain `scripts/weather.sh` (and `scripts/clock.sh`) instead of the placeholders.
- `~/.tmux/plugins/tmux-weather-nokey/scripts/clock.sh` prints one clock-face emoji.

## Do not

- Do not shorten `@weather-interval` below 600 seconds; both services are free and rate-limited.
- Do not delete the cache to "fix" a stale value unless the user changed an option.
- Do not add API keys; the plugin needs none.

## Code Review Rules

A change is a real defect when it:

- uses a shell feature that POSIX `sh` does not have, or adds a runtime dependency beyond `curl` and the optional `jq`.
- makes a cache write non-atomic, or replaces the last good value with a malformed upstream reply.
- lets `@weather-interval` run below 600 seconds, or adds an API key requirement.
- changes the source order (wttr.in first, Open-Meteo fallback) or the `n/a` result when both fail and nothing is cached.
- renames a placeholder or segment without updating the README, so the documented `status-right` value stops working.
- breaks `sh -n scripts/weather.sh` or `bash -n weather.tmux`.

Not defects: wording, formatting, comment style, requested extra tests, or a renamed helper.
