> Machine context first: this compact file is the first project document to read before routine edits. Open the larger docs only when a task touches their area or this file points to them.

# MatrixClock Compact Context RU

## Purpose

`PROJECT_CONTEXT_COMPACT_RU.md` — короткий машинный слой контекста для Codex/AI.
Он не заменяет большие документы, а экономит ресурс: сначала читается этот файл, потом точечно нужный раздел `PROJECT_GUIDE_RU.md`, `REFACTOR_PLAN_RU.md`, `PROJECT_EDIT_RULES.md` или `PROJECT_TREE_RU.md`.

## Source Order

1. `PROJECT_EDIT_RULES.md` — контракт правок и дисциплина.
2. `REFACTOR_PLAN_RU.md` — техническая история, stage-status, event log.
3. `PROJECT_GUIDE_RU.md` — человеческий путеводитель, простое объяснение.
4. `PROJECT_TREE_RU.md` — карта файлов и модулей.
5. `STAGE1_VALIDATION_RU.md` — короткий gate-checklist для проверки фундамента на железе.
6. `docs/chatgpt_git/*` — только внешний ChatGPT workflow.

## Active Rules

Integration authority:

- External ChatGPT is an inspector/draft worker, not the project authority.
- Codex is the coordinator/integrator and must verify every external suggestion against the whole project flow: UI -> API -> state -> service -> runtime -> storage.
- A locally correct patch is rejected or reshaped if it creates duplicate ownership, conflicting write paths, stale state semantics, or hidden lifecycle coupling.

- Работать точечно, без самовольного расширения scope.
- Не ломать рабочее ради идеальной архитектуры.
- Не добавлять фичи, если не закрыт текущий риск.
- Русские комментарии и русские UI-тексты сохранять как UTF-8; не доверять искажённому выводу PowerShell как доказательству порчи файла.
- Английские документы не обновлять на каждом шаге; финальный перевод позже.
- Проект ведётся как локальная папка без Git: отсутствие `.git` не считать проблемой и не упоминать в отчётах, если пользователь сам не спросил.
- Документы синхронизировать пакетно, кроме смысловых поворотов.

## Resource Policy

- Read this compact file first.
- Do not reread full `REFACTOR_PLAN_RU.md` unless stage/risk/history is directly affected.
- Use `Select-String` and small fragments instead of opening large docs fully.
- Do not document routine or obvious edits just to keep a diary.
- Document only durable value: root cause, nonstandard problem, repeated trap, stage decision, architecture/lifecycle rule, hardware pin, storage/network behavior, or important user scenario.
- If a note will not help avoid future mistakes or make a project decision clearer, skip the doc update.
- Update `PROJECT_GUIDE_RU.md` only for human-visible meaning.
- Update `REFACTOR_PLAN_RU.md` only for engineering decisions, stage status, event log, risks.
- Update `PROJECT_TREE_RU.md` only when files/modules change.
- Update `docs/chatgpt_git` only when external ChatGPT workflow changes.

## Current Project

- Device: ESP32-S3 N16R8 + 32x8 WS2812 matrix.
- UI: Web UI from LittleFS.
- Current tabs: `Настройки`, `Интерфейс`, `Погода`, `Инфо`.
- Core behavior: clock first, internet services second.
- Time: NTP primary correction, optional DS3231 backup/offline source.
- RTC: DS3231 validated; AT24C32 detected but not used.
- Wi-Fi: NVS credentials, AP onboarding, GPIO21 recovery reset.
- Weather: Open-Meteo backend, location in NVS, browser-side city search, `/state` status.
- Fire: standalone visual effect in `src/effects/fire_animation.*`, file animation from LittleFS with RAM/PSRAM preload.
- Audio/spectrum: async FFT/audio-reactive lifecycle exists; Fire must not depend on FFT/audio readiness.

## Current Architecture

- `main.cpp` — thin entrypoint and orchestration only.
- `app_state.*` — shared runtime/user state.
- `clock_runtime.*` — clock phase render logic.
- `clock_visuals.*` — calendar/date/sensor visual helpers.
- `display_runtime.*` — display lifecycle, overlays, clock/spectrum route.
- `wifi_service.*` — Wi-Fi credentials, AP onboarding, scan/apply/recovery.
- `ota_service.*` — ArduinoOTA lifecycle/status/reboot path.
- `filesystem_service.*` — LittleFS mount/status/unmount-for-OTA.
- `rtc_service.*` — optional DS3231 detection/sync.
- `weather_service.*` — weather task/cache/location/status.
- `ui/*_routes.*` — web endpoints.
- `data/index.html` — single-page Web UI.

## Stage Status

- Stage 1 foundation is effectively ready for gate decision, but still verify real device behavior after UI/filesystem changes.
- Use `STAGE1_VALIDATION_RU.md` as the real device checklist before calling Stage 1 closed.
- Stage 2 separation is strongly advanced: services are split, `main.cpp` is thin.
- Do not start large new feature stacks without checking whether current stage gate/risk is being bypassed.

## Known Open Risks

- OTA discovery/fallback is still dev-local: `platformio.local.ini` is acceptable for this machine but not final product discovery.
- Weather on matrix is not designed yet; backend and UI exist.
- Radio is planned but not yet designed.
- External notifications are possible later, but likely need phone/server bridge; do not put heavy OAuth/API secrets on ESP32 by default.
- AP mode is onboarding-only, not a multi-user web server.
- Wi-Fi scan can still feel imperfect on phones; keep it simple and non-blocking.

## Verification Defaults

- `data/index.html` or LittleFS assets changed: run `scripts/check_literal_newlines.ps1` and `platformio run -e s3 -t buildfs`; upload filesystem.
- C++ changed: run `platformio run -e s3`; upload firmware if behavior changed.
- Docs-only changed: run `scripts/check_literal_newlines.ps1`.
- UI text/flow changed: mention whether firmware or only LittleFS upload is needed.

## Next Bias

Prefer stabilizing and clarifying current features over adding new ones:
1. Upload latest firmware/LittleFS if pending.
2. Run `STAGE1_VALIDATION_RU.md`.
3. Decide Stage 1 gate.
4. Then choose one next feature: weather on matrix or radio prep, not both at once.
