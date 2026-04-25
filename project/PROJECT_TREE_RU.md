> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

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
├── effects/
├── hardware/
├── icons/
├── sensors/
├── ui/
├── config.h
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
├── weather_service.cpp
├── weather_service.h
├── wifi_service.cpp
└── wifi_service.h
```

Роли по смыслу:
- `audio/` — spectrum и async FFT
- `effects/` — визуальные и информационные эффекты, включая Fire animation playback
- `hardware/` — матрица, NTP и привязка к железу
- `sensors/` — датчики и sensor async
- `ui/` — webserver, Wi-Fi/weather routes, state, web/backend связь
- `display_runtime.*` — экранный runtime flow
- `filesystem_service.*` — LittleFS mount/status/unmount-for-OTA
- `ota_service.*` — OTA lifecycle, status и delayed reboot
- `rtc_service.*` — optional DS3231 RTC fallback и AT24C32 detect-only status
- `weather_service.*` — weather lifecycle/cache/status/location для погодного контура
- `wifi_service.*` — Wi‑Fi lifecycle, AP onboarding, recovery и apply-path
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
