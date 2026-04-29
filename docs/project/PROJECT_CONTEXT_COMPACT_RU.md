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
- The device is one coordinated organism, not a bag of features: every subsystem must fit a shared ownership/arbitration model, and when resource conflicts are unavoidable they must be resolved by explicit policy, queueing, retry/backoff, or priority scheduling rather than by accidental timing.
- Architecture law 1: display owns frame timing. Web/UI/OTA/Wi-Fi/filesystem layers are command-status infrastructure and must not behave like realtime executors in the hot path.
- Architecture law 2: audio capture service owns microphone/I2S. Voice is an always-on core service; spectrum and other audio-reactive visuals are only clients of shared audio features and must not own I2S directly.

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
- Current tabs: `Настройки`, `Интерфейс`, `Погода`, `Voice`, `Инфо`.
- Core behavior: clock first, internet services second.
- Time: NTP primary correction, optional DS3231 backup/offline source.
- RTC: DS3231 validated; AT24C32 detected but not used.
- Wi-Fi: NVS credentials, AP onboarding, GPIO21 recovery reset.
- Wi-Fi dev bootstrap hardcoded in source is disabled by default; local test fallbacks should stay in machine-local config, not in product firmware behavior.
- Wi-Fi runtime transitions after `disconnect` are now deferred/non-blocking inside `wifi_service`: setup AP, stored-credentials apply, and AP-close-to-STA no longer rely on hot-path `delay(100)`.
- Shared I2C bus now has a central lock in `hardware/i2c_bus.*`; RTC and sensor transactions must go through that guarded bus path instead of raw concurrent `Wire` ownership.
- Weather: Open-Meteo backend, location in NVS, browser-side city search, `/state` status, plus separate matrix weather settings in Web UI (`on/off`, interval, compact/full, cards/ticker, ticker speed).
- Weather UI should speak human language: sky cover, precipitation chance, precipitation type/intensity, wind direction, and pressure in familiar units; raw WMO code is diagnostics only, not the main user-facing description.
- Fire: standalone visual effect in `src/effects/fire_animation.*`, file animation from LittleFS with RAM/PSRAM preload.
- Audio/spectrum: async FFT/audio-reactive lifecycle exists; Fire must not depend on FFT/audio readiness.
- Spectrum audio ownership is now lazy: FFT/I2S must start only for real audio-reactive modes (`bars`, `waterfall`, `symmetric`, `VU`), not on boot and not for `Fire`.
- Audio start failures now use retry backoff in the shared audio-capture path: broken/missing microphone or I2S init must not trigger task-start thrash on every `loop()`.
- Microphone ownership now belongs to `audio/audio_capture_service.*`, not to `spectrumMode`: `spectrum` and future `voice` must request the same shared input path instead of starting competing I2S owners.
- `voice_service.*` now has the first real listening pipeline: enable flag, sensitivity, shared-audio wait state, RMS-based activity detection, noise-floor adaptation, and runtime telemetry via `/state`.
- Voice is now a fundamental always-on capability path: if `voiceEnabled` is persisted on, boot/runtime must preserve that listening intent instead of silently disabling it during service init.
- `voice_command_service.*` now owns the command-dispatch layer above listening: persisted command slots (`label`, `phrase`, `URL`), queued HTTP delivery, runtime status, and separation between shared audio listening and relay/network side effects.
- `voice_service.*` now also emits speech-segment telemetry (`count`, last duration, last peak RMS, age) so future parsing/ASR layers can attach to explicit voice events instead of inferring state from raw VAD booleans alone.
- `speech_recognition_service.*` is no longer just a bridge stub: the main `s3` product build now compiles a real `ESP-SR` runtime path (`WakeNet + MultiNet`) on top of shared PCM frames and queues matched command slots through `voice_command_service.*`.
- `audio/audio_capture_service.*` can now surface the latest shared PCM frame in addition to RMS/timestamp, and the main product voice path uses that shared capture at `16 kHz`; this is now the active bridge for `ESP-SR` without reintroducing a second I2S owner.
- Matrix rendering now treats `frame[]` as a logical render buffer; brightness scaling and LED output belong only to the scanout/present path, so the display pipeline stays deterministic and easier to diagnose under load.
- Main loop priority model is now frame-first: display cadence is fixed, realtime audio/voice servicing runs in tiny quanta, and Wi-Fi/RTC/weather/web/save/sensor bootstrap are serviced only in slack between frames instead of competing directly with present timing.
- Display smoothness is a non-negotiable product rule: any code path that can steal time from frame generation/present must either move behind the scheduler, become asynchronous, or justify itself as display-critical work.
- Web layer should be treated as command/status gateway, not as display-time owner: route handlers should acknowledge quickly and hand heavy work to deferred services, scheduled actions, or queues.
- `/ui-state` and `/state` must fail loudly on JSON-capacity overflow instead of silently dropping fields; partial status JSON is considered a diagnostic defect, not an acceptable degradation mode.
- Display cadence is now a shared contract, not local folklore: new motion/animation code should go through `display_timing.h` helpers so elapsed time, progress, and per-step delays stay aligned with frame cadence by default.

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
- `hardware/i2c_bus.*` — central I2C init + shared bus lock for RTC/sensors.
- `audio/audio_capture_service.*` — central microphone/I2S ownership, client mask, retry/backoff, shared audio-capture runtime status.
- `weather_service.*` — weather task/cache/location/status.
- `voice_service.*` — future voice-command lifecycle/status as a client of shared audio capture, not an I2S owner.
- `voice_command_service.*` — queued HTTP action dispatcher and persisted smart-home command slot model for future speech control.
- `speech_recognition_service.*` — product speech-recognition layer: wake word + command recognition runtime, separated from both raw listening and HTTP side effects.
- `ui/*_routes.*` — web endpoints.
- `data/index.html` — single-page Web UI.

## Stage Status

- Stage 1 firmware foundation is closed via `PASS with hardware note`.
- The remaining cold-start instability and offline Wi-Fi display glitches belong to the current `ESP32-S3 N16R8` dev board / stand hardware, not to the Stage 1 firmware gate.
- Stage 2 separation is strongly advanced: services are split, `main.cpp` is thin.
- Do not start large new feature stacks without checking whether current stage gate/risk is being bypassed.

## Known Open Risks

- OTA discovery/fallback is still dev-local: `platformio.local.ini` is acceptable for this machine but not final product discovery.
- Weather now has MVP matrix output as a separate online slideshow block in the clock minute cycle: `ПОГОДА` intro, then current weather, humidity, pressure, wind, and a short human-readable condition card, driven only by cached `WeatherSnapshot`.
- Weather matrix runtime now has its own user settings and cadence. It must not depend on the local `sensorInterval`, and if weather and local sensors fall on the same minute, weather takes priority instead of mixing both flows.
- Weather snapshot was extended with richer current conditions from Open-Meteo (`is_day`, `cloud_cover`, `wind_direction_10m`, `wind_gusts_10m`, `precipitation`, `visibility`) so matrix/UI can present friendlier weather logic instead of raw machine-ish status.
- Radio is planned but not yet designed.
- External notifications are possible later, but likely need phone/server bridge; do not put heavy OAuth/API secrets on ESP32 by default.
- AP mode is onboarding-only, not a multi-user web server.
- Wi-Fi scan can still feel imperfect on phones; keep it simple and non-blocking.
- Async service lifecycle (`sensors_async`, `spectrum_async`, `weather_service`) is stabilized but still should be changed carefully: avoid duplicate ownership of task state, handles, or status strings.
- The shared microphone policy is now explicit, and product voice control is wired into the real `s3` firmware path via `ESP-SR`, but the current command model is still intentionally narrow: English command phrases only, fixed wake word family (`Hi ESP` model), and real-hardware tuning is still required before calling it production-quiet in every room.
- The `s3sr` hybrid scaffold remains a diagnostic/research track only. Product voice work must continue in `s3`, not by stripping features into the scaffolded build.
- Product voice flashing is now a multi-artifact operation, not a simple firmware upload: `bootloader`, `partitions`, `firmware`, `artifacts/srmodels.bin`, and `LittleFS` must be written together, and `otadata` must be reset so the board boots the new `app0`.
- This voice rollout is still not fully stabilized on hardware: after the `ESP-SR` product path was enabled, the board can enter a reboot loop during early runtime around Wi-Fi / OTA / speech-start interaction. This is a firmware/runtime bug still under investigation, not a user flashing mistake.
- Current voice-stability debugging assumes explicit core ownership: `spectrum_async` remains on `Core 1` as the realtime audio producer, while non-realtime background tasks (`weather`, `sensors_async`, `voice_command_service`) and the current `speech_recognition_service` runtime should be kept off that hot audio core unless a later measurement proves otherwise.
- A post-refactor calendar glitch was fixed in `clock_visuals.*`: the maze pixel inside the date digits must advance only while that calendar block is actually visible, otherwise it "sprints" after weather/sensor overlays return.
- Voice priority rule: if audio consumers compete for processing budget, voice-command detection wins and visual audio consumers may degrade first.
- `voice_command_service.*` worker must not read mutable command `String` state directly across task boundaries; it should operate on locked snapshots/copies of command slots.

## Verification Defaults

- `data/index.html` or LittleFS assets changed: run `scripts/check_literal_newlines.ps1` and `platformio run -e s3 -t buildfs`; upload filesystem.
- C++ changed: run `platformio run -e s3`; upload firmware if behavior changed.
- Docs-only changed: run `scripts/check_literal_newlines.ps1`.
- UI text/flow changed: mention whether firmware or only LittleFS upload is needed.
- Current voice-build flashing note: do not rely on plain PlatformIO `Upload`; use the full flash path (`platformio run -e s3`, `platformio run -e s3 -t buildfs`, then `scripts/flash_all_voice.ps1`) because the voice target needs model partition content in addition to normal firmware assets.

## Next Bias

Prefer stabilizing and clarifying current features over adding new ones:
1. Upload latest firmware/LittleFS if pending.
2. Treat current S3 board cold-start/offline-glitch behavior as stand hardware risk, not firmware churn target.
3. Start the next single feature track: radio preparation on dual MCU.
4. Do not mix radio architecture work with unrelated feature expansion.
