# Contributing to tmux-weather-nokey

Fixes and reports are welcome. You do not need to ask before opening a pull request for a bug fix.

## Before you start

- **A wrong or stale value:** open an
  [issue](https://github.com/elfenomenokim/tmux-weather-nokey/issues/new/choose) with the command
  you ran, its output, the options you set and your tmux version.
- **A new format or segment:** open an issue first. The placeholders are documented and other
  people's `status-right` lines depend on them.
- **A security problem:** do not open a public issue. See [SECURITY.md](SECURITY.md).

## Set up

```sh
git clone https://github.com/elfenomenokim/tmux-weather-nokey
cd tmux-weather-nokey
sh -n scripts/weather.sh
bash -n weather.tmux
WEATHER_LOCATION='Seoul' scripts/weather.sh full
```

There is no test runner. The check is the printed line: a weather value from wttr.in, the
Open-Meteo fallback, or the last cached value.

To try a change in a tmux server, start a separate one with `tmux -L test -f /dev/null` so your own
sessions are untouched.

## Rules a patch must keep

- POSIX `sh` only in `scripts/`. No runtime dependency beyond `curl` and the optional `jq`.
- Cache writes stay atomic, and a malformed upstream reply never replaces the last good value.
- The cache identity includes the effective options: location, units, humidity and language.
- `@weather-interval` never runs below 600 seconds.
- No API key, ever.
- Placeholders and segment names are documented behaviour; renaming one is a breaking change.

## What a good patch has

- **A note on what you ran** before and after, with the real line it printed.
- **A line under Unreleased** in [CHANGELOG.md](CHANGELOG.md) when a user will notice.
- **The platforms you did not test** written in the pull request. The `tests` workflow checks shell
  syntax and `scripts/clock.sh` on Ubuntu and macOS; live tmux 3.x sessions, remote hosts and
  network weather fetches stay manual.

## Review

Every pull request runs an automatic DeepSeek review. Ask for another pass with `@codex review` or
`@claude review` in a comment. If a finding looks wrong, say why in the pull request.

## Licence

Contributions are licensed under the MIT licence in [LICENSE](LICENSE).
