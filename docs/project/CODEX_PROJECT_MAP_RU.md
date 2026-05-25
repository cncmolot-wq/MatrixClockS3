# CODEX_PROJECT_MAP_RU

Короткая рабочая карта проекта для Codex. Читать перед кодовыми правками. Цель файла - не история проекта, а быстрое восстановление целостной картины без повторного чтения всего репозитория.

## Как Пользоваться

- Сначала читать этот файл.
- Потом, если задача затрагивает конкретную область, читать только указанные файлы-владельцы.
- Большие документы открывать точечно:
  - `PROJECT_CONTEXT_COMPACT_RU.md` - текущие выводы и устойчивые решения.
  - `REFACTOR_PLAN_RU.md` - история технических решений и долги.
  - `PROJECT_TREE_RU.md` - карта файлов, если меняется структура.
  - `DISPLAY_LAYER_ISOLATION_DEBUG_RU.md` - только для display/render расследований.
  - `VOICE_COMMAND_MATCHER_ARCHIVE_RU.md` - только если сознательно возвращаемся к onboard speech research.

## Главный Контракт

- Часы важнее всех вторичных сервисов.
- `Core 1` - владелец display/output cadence.
- Web, Wi-Fi, OTA, FS, NVS, weather, sensors и speech не должны становиться realtime-владельцами кадра.
- `AudioCapture/I2S` - общий сервис потока, а не часть одной фичи.
- `Voice`, `Spectrum`, reactive visuals и debug - клиенты audio capture.
- Не чинить системную проблему локальной затычкой. Сначала классифицировать дефект: локальный он или часть цепочки ownership/lifecycle/scheduler.

## Build-Контуры

- `s3` - нормальный продуктовый контур часов.
  - Без onboard `ESP-SR`.
  - Без onboard voice frontend.
  - Тихий serial.
  - Normal LittleFS UI.
- `s3ota` - OTA helper для того же normal baseline.
- `s3_2ch_ota` - OTA helper для того же `2-channel debug` bring-up контура.
- `s3_voice_base` - speech research base.
  - Возвращает voice partition, ESP-SR libs, template matching.
- `s3_voice_debug` - основной диагностический speech/debug контур.
  - Diagnostic LittleFS UI.
  - Wake/lab/debug features.
- `s3_two_channel_debug` - практический matrix split контур для bring-up.
  - Сохраняет normal `s3` service/runtime policy без новых архитектурных сдвигов.
  - Включает multi-channel `MatrixOutput` только для debug/wiring проверки.
  - Текущий intended split: `CH0=GPIO12` и `CH1=GPIO13`.
- Старые `s3_audio_off_debug`, `s3_voice_*`, `s3_pm_stability_test`, `s3_dbg_*` вынесены в `platformio.archived.ini` как архивные A/B env, не ежедневный маршрут.

## Текущее Состояние Voice

- Onboard `ESP-SR` на главном S3 заморожен как основной путь.
- Onboard `ESP-SR` остаётся в проекте как `experimental/debug subsystem`, а не как product baseline normal `s3`.
- Доказано:
  - wake word был доведён до рабочего состояния;
  - template files/readiness diagnostics были доведены до честного состояния;
  - post-wake template matching снова давит runtime/display timing.
- В normal `s3` onboard voice должен быть полностью отключён:
  - `voiceEnabled=false`;
  - `audioCaptureVoiceWanted=false`;
  - `audioCaptureClientMask=4` при keepalive;
  - `speechRecognitionBackendCompiled=false`;
  - `speechRecognitionCore=-1`.
- Future voice direction:
  - отдельный voice MCU/node;
  - или более простой trigger path;
  - не возвращаться к broad onboard tuning по инерции.

## Core-Карта

- `core_affinity.h` - единственный владелец pinning policy.
- `Core 1`:
  - `DisplayTask`;
  - `handleDisplayRuntime()`;
  - render/present path;
  - `matrixShow()`;
  - hot `AudioCapture` producer task;
  - `loop()` как тонкий realtime shell.
- `Core 0`:
  - `background_infra`;
  - deferred services;
  - WebServer service path;
  - Wi-Fi/RTC/weather/sensors;
  - voice command worker;
  - speech research task only in voice contours.
- `[CORE_MAP]` в startup serial - дешёвая проверка intended policy.

## Runtime Scheduler

- `main.cpp`:
  - `setup()` инициализирует FS, state, services, Wi-Fi, display runtime, task creation.
  - `DisplayTask` каденсит кадры через `vTaskDelayUntil`.
  - `backgroundInfraTask` крутит именованные maintenance slices:
    - `sensor bootstrap`;
    - `deferred control`;
    - `deferred infra`;
    - `persistence`.
  - `background_maintenance_schedule.h` теперь держит каноническую карту этих slices; `main.cpp` больше не должен быть единственным местом, где зашито само перечисление maintenance policy.
  - `main.cpp` не должен знать policy maintenance slices ради одних только assert/enum checks; эта валидация закреплена рядом с самим maintenance dispatcher.
  - `loop()` остаётся тонким shell и вызывает только `handleRealtimeServices()`.
- `service_metadata.h`:
  - не является новым scheduler framework;
  - не переопределяет `core_affinity.h`, `system_service_schedule.h` или `background_maintenance_schedule.h`;
  - даёт человекочитаемый индекс поверх уже существующих owner-слоёв:
    - realtime / Core 1;
    - deferred control / Core 0;
    - deferred infra / Core 0;
    - background maintenance / Core 0;
  - хранит только metadata: `name`, `group`, `role`, `expectedCore`, `cadenceOwner`, `telemetryOwner`, `product/debug`.
  - `ui/debug_routes.cpp` отдает эту карту через read-only debug endpoint `/service-map`; endpoint не участвует в обычном UI polling и не смешивается с `/perf-state`.
- `system_services.cpp`:
  - `handleRealtimeServices()` выставляет быстрые audio intent bits: keepalive, spectrum.
  - `handleDeferredServices()` разделён на два ownership-среза:
    - control slice: `voice -> speech -> audio lifecycle`;
    - infra slice: `wifi -> rtc -> weather -> webserver`.
  - Cadence и slot policy больше не спрятаны в россыпи локальных `lastXxx`: `system_service_schedule.h` держит канонические `DeferredControlServiceSlot` / `DeferredInfraServiceSlot` и их interval policy.
  - `system_services.cpp` собирает runtime schedule table поверх этой policy-карты, добавляя только handler ownership; interval source-of-truth остаётся в `system_service_schedule.h`, а не дублируется в локальной schedule-таблице.
  - Внутри control/infra slice используется именованный round-robin по сервисным слотам, а не неявная мешанина `switch`/`lastXxx`.
  - `handleDeferredControlServicesStep()` и `handleDeferredInfraServicesStep()` можно вызывать отдельно, если нужно локализовать давление `Core 0`.
- Важный риск:
  - deferred service, который задерживает Core 0, может накапливать web/runtime давление, но не должен напрямую красть display ownership.

## Display Path

- Владельцы:
  - `display_runtime.cpp` - выбор режима кадра, overlays, final `matrixShow()`.
  - `clock_runtime.cpp` - логика часов.
  - `clock_visuals.cpp` - calendar/date/sensor visual helpers.
- `hardware/matrix.cpp` - scanout/present, brightness/output.
  - `hardware/matrix_output.*` - output abstraction boundary.
  - `hardware/single_channel_matrix_output.*` - текущая single-channel physical output implementation.
  - `hardware/four_channel_matrix_output.*` - disabled skeleton only; not active in normal `s3`.
  - Current mapping-ready contract already describes single-channel as channel `0` on `GPIO12` covering the full logical matrix; future multi-channel split must extend this contract, not bypass it.
  - `effects/*` - отдельные визуальные блоки.
- Правила:
  - никакие speech/web/weather/sensor задачи не пишут в display buffer напрямую;
  - display-owned overlays рисуются только в render path;
  - логический `frame[]` не смешивать с output scaling/scanout.
- Полезные поля `/state`:
  - `frameTimeMaxUs`;
  - `displayFrameBudgetUs`;
  - `displayFrameUsedUs`;
  - `displaySlackLastUs`;
  - `displaySlackMinUs`;
  - `displaySlackAvgUs`;
  - `displayOverBudgetCount`;
  - `matrixPresentTimeMaxUs`;
  - `frameSlowCount`;
  - `frameDeadlineMissCount`;
  - `displayWriteViolationCount`;
  - `displayStateSnapshotAgeMs`.

## Audio Path

- Владельцы:
  - `audio/audio_capture_control.cpp` - client mask, start/stop lifecycle intent.
  - `audio/audio_capture_backend_i2s.cpp` - hot I2S producer on Core 1.
  - `audio/audio_capture_snapshots.cpp` - shared PCM/RMS snapshots.
  - `audio/spectrum.cpp` - visual FFT consumer, not I2S owner.
- Клиенты:
  - `KEEPALIVE`;
  - `SPECTRUM`;
  - `VOICE` only in voice contours.
- Normal baseline:
  - keepalive keeps backend alive;
  - voice client must be off.
- Полезные поля `/state`:
  - `audioCaptureActive`;
  - `audioCaptureClientMask`;
  - `audioCaptureKeepaliveWanted`;
  - `audioCaptureVoiceWanted`;
  - `audioCaptureSpectrumWanted`;
  - `audioCaptureReadTimeoutCount`;
  - `audioCaptureFrameDropCount`;
  - `audioCaptureStartStopSeq`.

## GPIO And Peripheral Map

- Current code-owned pins:

| Function | GPIO | Source | Status | Notes |
|---|---:|---|---|---|
| LED data, single-channel output | 12 | `config.h` | active | Current WS2812 matrix data line in normal `s3` |
| I2S data in | 4 | `audio_capture_backend_i2s.cpp` | active | Shared audio-capture backend input |
| I2S BCLK | 5 | `audio_capture_backend_i2s.cpp` | active | Shared audio-capture clock |
| I2S WS/LRCLK | 6 | `audio_capture_backend_i2s.cpp` | active | Shared audio-capture word select |
| I2C SDA | 17 | `hardware/i2c_bus.h` | active | Shared RTC/sensors bus |
| I2C SCL | 18 | `hardware/i2c_bus.h` | active | Shared RTC/sensors bus |
| Wi-Fi recovery button | 21 | `wifi_service.cpp` | active | Boot-time credentials reset input |

- Reserved-by-policy before 4-channel:

| Area | GPIO / Range | Status | Notes |
|---|---|---|---|
| Future LED channel 1 | TBD | reserved | Do not assign before physical map is approved |
| Future LED channel 2 | TBD | reserved | Do not assign before physical map is approved |
| Future LED channel 3 | TBD | reserved | Do not assign before physical map is approved |
| Native USB | board-default / review needed | reserved | Not explicitly owned by current firmware; avoid reuse before board-level review |
| Boot strap | GPIO0 and board boot path | reserved | Treat as boot-sensitive; not for matrix channels |
| Flash / PSRAM related lines | board/module internal | forbidden | Do not repurpose; outside current firmware map |

## Future 4-Channel Placeholder

- Four-channel physical split is not implemented yet.
- Until a board-level review is completed, this table is a planning placeholder, not an assignment.
- Central compile-time owner for current/future channel layout: `hardware/matrix_channel_config.*`.

| Channel | GPIO | Logical area | Row / segment range | Direction | Layout | Notes |
|---|---:|---|---|---|---|---|
| CH0 | 12 | full current matrix | current 32x8 path | current single direction | current single-chain | Present single-channel output |
| CH1 | 13 (debug candidate) | right `16x8` | `x=16..31`, `y=0..7` | current single-channel order per half | current per-half chain | Used only in `s3_two_channel_debug` bring-up |
| CH2 | TBD | TBD | TBD | TBD | TBD | Future mapping only |
| CH3 | TBD | TBD | TBD | TBD | TBD | Future mapping only |

## MatrixOutput Contract

- Render/effects remain purely logical and must not know physical channel wiring.
- `frame[]` remains the logical framebuffer.
- Physical channel split, GPIO ownership, serpentine/reverse mapping, and present strategy live only below `MatrixOutput`.
- `SingleChannelMatrixOutput` is the current physical implementation.
- `SingleChannelMatrixOutput` now builds a precomputed logical-to-physical LUT at init time; per-frame present path should not recompute mapping math for every pixel.
- `FourChannelMatrixOutput` may exist in the tree as a disabled skeleton, but must not own real GPIO or runtime behavior until the physical mapping is approved.
- `FourChannelMatrixOutput` may be added later only after the GPIO/peripheral map and physical mapping table are approved.
- Mapping validation rules now belong to the shared output layer, not to one backend:
  - valid `channelCount`;
  - assigned GPIO for enabled channels;
  - non-zero area;
  - area inside logical matrix;
  - no overlapping channel regions.

## Web/UI Path

- Владельцы:
  - `webui/index.template.html` - source UI template.
  - `scripts/select_ui_variant.py` - normal/debug LittleFS variant generation.
  - `data/index.html` - generated/served LittleFS UI.
  - `ui/webserver.cpp` - HTTP transport/gateway, route registration, request/response wiring.
  - `ui/web_static.cpp` - static frontend serving for `/` and future static assets.
  - `ui/web_state.cpp` - runtime state snapshot serialization for `/ui-state`, `/voice-state`, `/weather-state`, `/perf-state`.
    - including the full `/state` debug snapshot assembly.
  - `ui/debug_routes.cpp` - debug/system HTTP route group: `/state`, `/perf-state`, `/perf-debug-state`, `/runtime-log`, `/matrix-frame`, `/fs-status`.
  - `ui/voice_routes.cpp` - voice, voice-lab, template and phrase-test HTTP route group.
  - `ui/update_apply.cpp` - apply-path for UI mutations.
  - `ui/state.cpp` - persisted state + dirty debounce save.
  - `ui/weather_routes.cpp`, `ui/wifi_routes.cpp` - other feature route groups.
- Endpoint split:
  - `/ui-state` - light essentials;
  - `/voice-state` - voice/speech/template state;
  - `/weather-state` - weather payload;
  - `/perf-state` - lightweight product perf snapshot;
  - `/perf-debug-state` - heavy perf/debug snapshot;
  - `/state` - full manual debug dump.
- Route ownership split:
  - `webserver.cpp` registers routes and common wrappers only;
  - `debug_routes.cpp` owns debug/system handlers;
  - `voice_routes.cpp`, `weather_routes.cpp`, `wifi_routes.cpp` own feature-specific HTTP surfaces.
- Endpoint telemetry:
  - per-route timing is tracked for `/`, `/state`, `/ui-state`, `/weather-state`, `/perf-state`, `/runtime-log`, `/voice-state`, `/voice-lab-list`, `/matrix-frame`, `/update`;
  - `/perf-state` and `/state` expose `webEndpointSlowestName`, `webEndpointSlowestUs`, `webEndpointSlowCount` and compact `webEndpointsTop[]`;
  - this telemetry is for identifying the exact slow route before changing serializers, polling cadence or static file serving.
- Static root telemetry:
  - `/perf-debug-state` exposes `webStaticRootTotalUs`, `webStaticRootOpenUs`, `webStaticRootStreamUs`, `webStaticRootLastBytes`, `webStaticRootUsedGzip`, `webStaticRootFallbackCount`, `webStaticRootOpenFailCount`, `webStaticRootLastPath`;
  - this separates route overhead from `LittleFS.open()` and `streamFile()` when `/` is the slowest endpoint.
- Known separate line:
  - browser refresh / `handleClient` burst can still be visible as pixel freeze.
  - Do not mix this with old `Voice OFF / aud=0` line.

## State And Persistence

- `ui/state.cpp` owns persisted settings and NVS writes.
- `markStateDirty()` + `checkAndSave()` already implement delayed save debounce.
- Do not add a second delayed-save mechanism unless current one is proven insufficient.
- Web write path should be:
  - HTTP parse in `webserver.cpp`;
  - apply in `update_apply.cpp`;
  - setters/state owners update values;
  - `markStateDirty()` for persistent changes.

## Weather/Sensors/RTC/Wi-Fi

- `weather_service.cpp` - Open-Meteo task/cache/location/status.
- `sensors/sensors_async.cpp` - async local sensor reads.
- `rtc_service.cpp` - DS3231 backup/offline time.
- `hardware/i2c_bus.cpp` - central I2C lock; do not bypass with raw competing `Wire` ownership.
- `wifi_service.cpp` - STA/AP onboarding, scan/apply/recovery.
- `hardware/ntp.cpp` - time sync support.

## Current Confirmed Lines

- Old line closed enough:
  - `Voice OFF -> aud=0 -> constant freezes`.
  - Fixed by shared audio keepalive policy.
- Voice research paused:
  - not default path for normal clock stability.
- Current normal baseline reality:
  - voice detached;
  - if фризы remain, treat them as a new current defect, not as ESP-SR proof.
- Display A/B line is active again:
  - archived `s3_dbg_no_calendar`, `s3_dbg_no_progress`, `s3_dbg_no_calendar_progress`, `s3_dbg_no_ticker_date` had no visual freezes;
  - current display investigation must start from `calendar + progress + ticker/date/weather ticker`, not from voice;
  - fixed local trap: `showCalendar` must actually disable the small-font calendar layer and release the left-zone reservation.
- Web refresh line remains separate:
  - use fresh evidence before claiming it as root cause.

## Work Rules For Codex

- Before broad code work, read this file and only the owner modules touched by the task.
- Update this file only for durable facts:
  - new owner boundary;
  - changed build contour;
  - confirmed root cause;
  - repeated trap;
  - verification rule.
- Do not update this file for routine bugfixes or temporary observations.
- If this file disagrees with code, code wins; update the file after verifying.
- If an external suggestion is locally correct but breaks ownership, reshape it.
- For residual freezes, do not reuse old explanations without current evidence.

## Verification Rules

- C++ changed:
  - `platformio run -e s3`
  - if debug/voice contour touched: `platformio run -e s3_voice_debug`
- `webui/index.template.html` or UI variant logic changed:
  - `platformio run -e s3 -t buildfs`
  - if diagnostic UI touched: `platformio run -e s3_voice_debug -t buildfs`
- Docs changed:
  - `powershell -ExecutionPolicy Bypass -File .\scripts\check_literal_newlines.ps1`
- Normal UI/LittleFS changed:
  - firmware upload may not be enough; LittleFS upload is required.
- Firmware C++ changed:
  - LittleFS is not required unless UI/assets changed.
