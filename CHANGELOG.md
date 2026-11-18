# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The plugin is installed from git, so
entries are dated and no version number is attached.

## Unreleased

### Fixed

- An expired cache no longer re-queries the weather services on every status refresh while both
  fail: the last good value, or `n/a` when nothing is cached, is kept and the expiry is renewed for
  one interval.
- `@weather-timeout` now applies to both Open-Meteo requests, not only to wttr.in.
- Without `jq`, a location is percent-encoded by byte, so `#`, `?`, `%`, comma and non-ASCII names no
  longer truncate or mangle the wttr.in request.
- A refresh interrupted before the cache write leaves no `.weather.*` temporary file.
- The demo setup resolves the plugin root from its own path and seeds the hashed cache key with
  pinned options, so a recording reads the synthetic value instead of live weather; the tapes use
  repository-relative paths.

- A malformed upstream reply (`Bad Gateway` and similar) is rejected before it replaces the last
  good value, and the fallback runs instead of caching the failure.
- The cache identity includes location, units, humidity and language, so a changed option shows a
  new value immediately and separate tmux servers no longer share the wrong city.
- Each cache writer uses its own temporary file, so concurrent icon and temperature commands cannot
  publish a half-written cache.

## 2026-11-17

### Added

- First public release: `#{weather}`, `#{weather_icon}` and `#{weather_temp}` segments with
  location, units, interval, timeout, humidity and language options.
- wttr.in first with an Open-Meteo fallback, no API key, and a cache that keeps the last good value.
- Clock face (`#{clock_icon}`) and a ready-made weather and clock segment (`#{weather_pill}`).
- One config file shared by every tmux server: environment variable, then tmux option, then
  `~/.config/tmux-weather-nokey/config`, then the default.
