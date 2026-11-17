# tmux-weather-nokey

[English](README.md)

tmux 상태줄에 지금 날씨와 시계를 보여 줍니다. **API 키가 필요 없습니다.**

![날씨와 시계 칸](docs/pill.png)

```
☀️ 14°C 70%
```

- [wttr.in](https://wttr.in)을 쓰고, 느리거나 막히면 [Open-Meteo](https://open-meteo.com)로 넘어갑니다.
- "Unknown location", HTML 오류 페이지, 시간 초과 같은 잘못된 응답은 캐시에 남기지 않습니다. 두 곳이 다 실패하면 오류 대신 마지막 정상 값을 계속 보여 줍니다.
- 캐시가 살아 있으면 네트워크도 tmux도 부르지 않습니다. 상태줄을 15초마다 갱신해도 부담이 거의 없습니다.
- 일반 POSIX `sh`로 돌아갑니다. `curl`이 필요하고, `jq`는 예비 소스에만 씁니다.

## 설치

[TPM](https://github.com/tmux-plugins/tpm)을 쓰면 `~/.tmux.conf`에 넣습니다.

```tmux
set -g @plugin 'elfenomenokim/tmux-weather-nokey'
set -g @weather-location 'Seoul'
set -g status-right '#{weather} | %H:%M'
```

그다음 `prefix` + `I`를 누릅니다. `set -g status-right`는 TPM `run` 줄보다 **위에** 둡니다.

직접 설치하려면 저장소를 받고 `~/.tmux.conf`에 `run-shell /경로/tmux-weather-nokey/weather.tmux`를 넣습니다.

## 자리표시자

| 자리표시자 | 출력 |
|---|---|
| `#{weather}` | `☀️ 14°C 70%` |
| `#{weather_icon}` | `☀️` |
| `#{weather_temp}` | `14°C 70%` |
| `#{clock_icon}` | 지금 시각의 시계 이모지 `🕓`. 30분 단위까지 맞춥니다(🕐 1시, 🕜 1시 반) |
| `#{weather_pill}` | 위 사진의 완성된 칸: 날씨 아이콘, 기온, 시계, 시각 |

아이콘과 기온을 나누면 catppuccin, dracula 같은 테마에서 칸을 따로 꾸밀 수 있습니다. 바로 쓰려면 `#{weather_pill}`을 넣습니다.

```tmux
set -g status-right '#{weather_pill}'
```

### `#{weather_pill}` 옵션

| 옵션 | 기본값 | 뜻 |
|---|---|---|
| `@weather-pill-weather-bg` / `-soft` / `-fg` | `#179299` / `#d0f0f0` / `#0a5050` | 아이콘 칸, 기온 칸, 기온 글자 색 |
| `@weather-pill-clock-bg` / `-soft` / `-fg` | `#dc8a78` / `#fde0d8` / `#7a3020` | 시계 칸, 시각 칸, 시각 글자 색 |
| `@weather-pill-icon-fg` | `#dce0e8` | 진한 칸의 글자 색 |
| `@weather-pill-time-format` | `%H:%M` | `strftime` 형식. 예: `%I:%M %p` |
| `@weather-pill-separator` | 비움 | 글꼴에 Powerline 기호가 있으면 ``처럼 넣습니다 |

이 옵션들도 `status-right`처럼 TPM `run` 줄보다 위에 둡니다.

## 옵션

| 옵션 | 기본값 | 뜻 |
|---|---|---|
| `@weather-location` | 비움 | 도시 이름 또는 `위도,경도`. 비우면 wttr.in이 IP로 추정합니다. 예비 소스를 쓰려면 값이 필요합니다. |
| `@weather-units` | `metric` | `metric`(섭씨) 또는 `imperial`(화씨) |
| `@weather-interval` | `1800` | 캐시 유지 시간(초) |
| `@weather-timeout` | `3` | 요청 하나의 시간 제한(초) |
| `@weather-humidity` | `on` | `off`면 습도를 숨깁니다 |
| `@weather-lang` | `en` | wttr.in 언어 코드 |

여러 tmux 서버가 같은 설정을 쓰게 하려면 `~/.config/tmux-weather-nokey/config`에 한 줄에 하나씩 `key=value`로 적습니다(예: `location=Seoul`, `units=imperial`). 우선순위는 환경변수, tmux 옵션, 설정 파일, 기본값 순입니다.

옵션은 같은 뜻의 환경변수(`WEATHER_LOCATION`, `WEATHER_UNITS` 등)로도 줄 수 있습니다. tmux 밖에서 시험할 때 편합니다.

```sh
WEATHER_LOCATION=Paris scripts/weather.sh temp
```

캐시는 `${XDG_CACHE_HOME:-~/.cache}/tmux-weather-nokey/current`에 있습니다. 옵션을 바꾼 뒤 바로 반영하려면 이 파일을 지우세요.

## 왜 또 날씨 플러그인인가

wttr.in은 무료 서버 한 대입니다. 연결은 받아 놓고 몇 시간씩 답을 안 하기도 하고, "위치를 찾을 수 없음" 응답이 단순한 캐시에 한 시간 동안 남기도 합니다. 둘 다 실제로 겪은 뒤 만든 플러그인이라, 예비 소스를 두고 정상 응답만 캐시합니다.

## 라이선스

MIT
