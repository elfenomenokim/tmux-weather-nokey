# Security policy

## Supported versions

Security fixes go into the latest commit on `main`; TPM installs that commit, so update before
reporting.

| Version | Supported |
| --- | --- |
| Latest `main` | Yes |
| Older commits | No |

## Reporting a vulnerability

Report it privately, not in a public issue: use the
[Report a vulnerability](https://github.com/elfenomenokim/tmux-weather-nokey/security/advisories/new)
form on the repository's Security tab.

Include the command, the options you set, your tmux version, and what an attacker could do with the
result. You get a reply within a few days.

## In scope

- A cache file written outside the documented cache directory, or written with wider permissions
  than the caller's umask allows.
- A reply from wttr.in or Open-Meteo that changes what the status line runs, rather than what it
  prints.
- A location, language or unit value that reaches a shell command unquoted.
- A request that continues below the documented 600-second floor, or a loop that keeps requesting
  while both services fail.

## Not a vulnerability

- A weather value that is wrong, stale or empty, because both services failed or rate-limited you.
  The plugin keeps the last good value on purpose.
- Your location being sent to wttr.in or Open-Meteo. That is how a no-key weather plugin works; the
  README says so.
- Anything a third-party segment in your own `status-right` does.

## Disclosure

Once a fix is released, the advisory is published with credit to the reporter unless they prefer
otherwise.
