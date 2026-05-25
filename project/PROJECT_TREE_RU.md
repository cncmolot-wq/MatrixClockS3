> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

Codex entry map: `docs/project/CODEX_PROJECT_MAP_RU.md`.

> Важно: перед правкой этого файла сначала ознакомься с файлами в папке `docs/project/`, чтобы сохранить синхронизацию документации.

# Project Tree RU

Этот файл — компактная карта структуры проекта.

Он нужен, чтобы:
- быстро понять, где что лежит;
- дать внешнему ChatGPT или другому агенту опорную картину репозитория;
- не показывать модель только по отдельным файлам без общего контекста.

Это не технический план и не инструкция правок.
Источник истины по смыслу проекта и правилам остаётся здесь:
- `docs/project/PROJECT_GUIDE_RU.md`
- `docs/project/PROJECT_CONTEXT_COMPACT_RU.md`
- `docs/project/REFACTOR_PLAN_RU.md`
- `docs/project/PROJECT_EDIT_RULES.md`

---

## Корень проекта

```text
.
├── boards/
├── data/
├── docs/
├── pixel_editor/
├── png/
├── scripts/
├── src/
├── partitions_ota_16mb.csv
├── partitions_ota_8mb.csv
├── platformio.ini
├── platformio.archived.ini
├── platformio.local.ini.example
└── README.md
```

---

## Ключевые папки

### `src/`

Основной код прошивки.

```text
src/
├── audio/
├── core_affinity.h
├── effects/
├── hardware/
├── icons/
├── sensors/
├── ui/
├── config.h
├── display_timing.h
├── display_runtime.cpp
├── display_runtime.h
├── filesystem_service.cpp
├── filesystem_service.h
├── main.cpp
├── ota_service.cpp
├── ota_service.h
├── runtime_metrics.cpp
├── runtime_metrics.h
├── rtc_service.cpp
├── rtc_service.h
├── sensor_bootstrap.cpp
├── sensor_bootstrap.h
├── system_services.cpp
├── system_services.h
├── voice_command_service.cpp
├── voice_command_service.h
├── voice_service.cpp
├── voice_service.h
├── weather_service.cpp
├── weather_service.h
├── weather_display_classifier.cpp
├── weather_display_classifier.h
├── weather_display_phrases.h
├── danger_display.cpp
├── danger_display.h
├── danger_provider.h
├── danger_provider_meteoalarm_atom.cpp
├── danger_provider_meteoalarm_atom.h
├── danger_provider_stub.cpp
├── danger_provider_stub.h
├── danger_service.cpp
├── danger_service.h
├── weather_alert_display.cpp
├── weather_alert_display.h
├── weather_alerts_service.cpp
├── weather_alerts_service.h
├── weather_ticker_builder.cpp
├── weather_ticker_builder.h
├── wifi_service.cpp
└── wifi_service.h
```

Роли по смыслу:
- `audio/` — shared audio capture service, spectrum и raw I2S capture backend
- `core_affinity.h` — канонический policy-слой pinning/ownership по `Core 0 / Core 1`; изменения core-affinity должны начинаться отсюда, а не с локальных `0/1` в сервисах
- `effects/` — визуальные и информационные эффекты, включая Fire animation playback
- `hardware/` — матрица, NTP и привязка к железу
- `sensors/` — датчики и sensor async
- `ui/` — webserver, Wi-Fi/weather routes, state, web/backend связь
- `display_runtime.*` — экранный runtime flow
- `display_timing.h` — канонический helper для frame-cadence alignment: quantize/progress/delay normalization для motion и animation path-ов
- `filesystem_service.*` — LittleFS mount/status/unmount-for-OTA
- `ota_service.*` — OTA lifecycle, status и delayed reboot
- `rtc_service.*` — optional DS3231 RTC fallback и AT24C32 detect-only status
- `audio/audio_capture_service.*` — единый владелец микрофонного/I2S capture path, client mask и runtime-status общего аудиоресурса
- `audio/audio_capture_backend_i2s.*` — backend сырого I2S/capture path; публикует shared PCM/RMS кадры и не тащит на себе визуальный FFT
- `audio/audio_capture_telemetry.*` — publish/read-timeout/frame-drop/stack telemetry для shared audio hot path
- `weather_service.*` — weather lifecycle/cache/status/location для погодного контура
- `weather_display_classifier.*` — единый display-layer интерпретации сырых weather полей для Web UI, ticker и matrix weather cards
- `weather_display_phrases.h` — единый редактируемый словарь пользовательских погодных фраз; если wording не нравится, править сначала здесь
- `danger_service.*` — настоящий owner danger-state: lifecycle/cadence, cached snapshot, status и export через `/danger-state`
- `danger_display.*` — настоящий owner danger-visual path: fullscreen strobe, danger marquee, reminder policy и critical overlay вне weather-card lifecycle
- `danger_provider.h` — общая граница source-adapter слоя для внешних warning providers
- `danger_provider_stub.*` — stub/manual provider для fake-тестов и локальной верификации danger-контура
- `danger_provider_meteoalarm_atom.*` — первый реальный proof-provider для Украины; читает MeteoAlarm Atom feed, фильтрует CAP polygon/expiry/status по текущим weather-координатам и не владеет cadence/cache сам по себе
- `weather_alerts_service.*` — compatibility-only legacy adapter к `danger_service.*`; в живом runtime больше не считается owner-слоем
- `weather_alert_display.*` — compatibility-only legacy adapter к `danger_display.*`; оставлен только для переходной совместимости
- `weather_ticker_builder.*` — firmware-side конструктор погодной бегущей строки; текущий cadence/render path зафиксирован как эталонно плавный: без глюков, запинок и спотыканий, и именно это поведение считается каноном будущих правок ticker-вывода
- `voice_service.*` — отдельный voice lifecycle/status слой, который запрашивает shared audio capture как клиент, а не владеет I2S напрямую
- `voice_command_service.*` — queued HTTP-action layer для voice/smart-home команд, который отделяет сетевые side effects от display-critical loop
- `speech_build_config.h` — канонический слой speech build-mode флагов, который разводит product/debug/lab semantics без scattered macro-mix в сервисах
- `wifi_service.*` — Wi‐Fi lifecycle, AP onboarding, recovery и apply-path
- `system_services.*` — тонкий coordinator базовых сервисов
- `sensor_bootstrap.*` — безопасный bootstrap датчиков
- `runtime_metrics.*` — минимальные runtime-метрики
- `main.cpp` — главный entrypoint прошивки

### `data/`

Файлы Web UI и runtime-ассеты для `LittleFS`.

```text
data/
├── anim/
└── index.html
```

- `index.html` — основной Web UI
- `anim/` — анимации для runtime, включая `Fire`

### `boards/`

Локальные board profiles для PlatformIO.

```text
boards/
└── matrixclock_esp32s3_n16r8.json
```

### `scripts/`

Служебные проектные проверки.

```text
scripts/
└── check_literal_newlines.ps1
```

### `docs/`

Документация разделена на два слоя.

```text
docs/
├── chatgpt_git/
└── project/
```

---

## Документация проекта

### `docs/project/`

Внутренняя документация и источник смысла проекта.

```text
docs/project/
├── GIT_REPO_REFERENCE_RU.md
├── GIT_REPO_STRUCTURE_EXAMPLE.png
├── N16R8_PROFILE_BIBLE_EN.md
├── N16R8_PROFILE_BIBLE_RU.md
├── VOICE_COMMAND_MATCHER_ARCHIVE_RU.md
├── PROJECT_EDIT_RULES.md
├── PROJECT_CONTEXT_COMPACT_RU.md
├── PROJECT_GUIDE_RU.md
├── PROJECT_TREE_RU.md
├── README_EN.md
├── REFACTOR_PLAN.md
├── REFACTOR_PLAN_EN.md
├── REFACTOR_PLAN_RU.md
└── STAGE1_VALIDATION_RU.md
```

Главные роли:
- `PROJECT_GUIDE_RU.md` — человеческий путеводитель по проекту
- `PROJECT_CONTEXT_COMPACT_RU.md` — компактный машинный контекст для экономии ресурса
- `REFACTOR_PLAN_RU.md` — техническая истина, стадии, история, риски
- `PROJECT_EDIT_RULES.md` — контракт правок
- `PROJECT_TREE_RU.md` — карта структуры проекта
- `STAGE1_VALIDATION_RU.md` — короткий checklist закрытия Stage 1 на железе

### `docs/chatgpt_git/`

Минимальный внешний пакет для обычного ChatGPT.

```text
docs/chatgpt_git/
├── CHATGPT_PROJECT_SETTINGS_RU.md
└── CHATGPT_TASK_CAPSULE_RU.md
```

Главные роли:
- `CHATGPT_PROJECT_SETTINGS_RU.md` — единый внешний файл правил
- `CHATGPT_TASK_CAPSULE_RU.md` — единый внешний шаблон задачи

---

## Что не считать ядром структуры

Эти вещи существуют, но не являются основой проектной модели:
- `.pio/` — build artifacts
- `platformio.local.ini` — machine-local override, не часть обычного review/handoff архива
- ad-hoc `*.log` / `*.err.log` рядом с проектом — локальные build/debug следы, не часть обычного review/handoff архива
- `managed_components/` — включать только если нужен именно полный ESP-IDF/local-debug snapshot; для обычного product-review архива это не ядро
- `.vscode/` — локальная среда редактора
- `.continue/` — служебный локальный контур
- `chat.json`, `package-lock.json` — служебные/вспомогательные файлы
- `pixel_editor/`, `png/` — вспомогательные проектные ресурсы, но не ядро runtime-архитектуры

---

## Практический смысл

Если внешнему ChatGPT показываются отдельные файлы, этот документ можно использовать как:
- краткую карту проекта;
- пояснение, где лежит код, где лежат правила, а где лежит человеческий guide;
- опорный слой, чтобы модель не путала `src`, `data`, `docs/project` и `docs/chatgpt_git`.
