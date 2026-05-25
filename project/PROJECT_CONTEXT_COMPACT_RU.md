> Machine context first: for code work read `CODEX_PROJECT_MAP_RU.md` first, then this compact context only if current facts or decision history are needed.

Current override, 2026-05-15:
- Normal `s3` is a voice-free stable clock target.
- Onboard `ESP-SR` and onboard voice frontend are not part of normal `s3`.
- Onboard `ESP-SR` remains in the project as an experimental/debug subsystem and a future candidate either for a cleaned single-chip path or for a separate voice MCU/node.
- Before any `FourChannelMatrixOutput`, the project must first have:
  - a code-backed GPIO/peripheral map;
  - a reviewed future 4-channel physical mapping table;
  - the rule that effects/render stay logical and know nothing about channel wiring.
- Older notes below that describe voice as an always-on product path are historical context for the investigation, not the current baseline policy.
- Use `CODEX_PROJECT_MAP_RU.md` as the current owner/build map.

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
- Fix law: do not patch symptoms with local hacks when the defect belongs to a wider architecture/ownership/lifecycle chain.
- Fix law: first classify the problem as local or systemic; only isolated local defects should be fixed locally.
- Fix law: if the problem is systemic, either fix it at the correct ownership layer or record it as a dependent item for the planned architecture change instead of hiding it behind a workaround.

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
- Weather: Open-Meteo backend, location in NVS, `/state` status, plus separate matrix weather settings in Web UI (`on/off`, interval, compact/full, cards/ticker, ticker speed). City search is now routed through the device (`/weather-search`) instead of depending on direct browser-to-Open-Meteo fetches.
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
- `speech_recognition_service.*` still contains the real onboard `ESP-SR` runtime path (`WakeNet + MultiNet`) on top of shared PCM frames and queues matched command slots through `voice_command_service.*`, but this path is no longer part of the default normal clock contour.
- The onboard voice track still has a lab mode for custom command work: after wake word, firmware can capture a post-wake command window into numbered `LittleFS` WAV files (`/voice_lab_0001.wav` ...), reuses free slots after deletions, and no longer hard-freezes the display present path during active capture.
- Build modes are now intentionally separated one step further:
  - `env:s3` = clock-first baseline without onboard `ESP-SR`;
  - `env:s3_voice_base` / `env:s3_voice_debug` = onboard speech research contours;
  - `env:s3ota` = OTA helper for the quiet normal baseline.
- Current contour policy is intentionally narrow:
  - `env:s3` = normal working baseline;
  - `env:s3_voice_debug` = the only main debug contour for live investigation;
  - `env:s3ota` = OTA upload helper for that same baseline.
- Older envs in `platformio.archived.ini` (`s3_audio_off_debug`, `s3_voice_off_audio_forced_on`, `s3_voice_on_audio_forced_off`, `s3_pm_stability_test`, `s3_dbg_*`) are preserved only as archived reproducible diagnostics. They are not part of the normal daily workflow and should not be used by reflex.
- LittleFS/UI now mirrors the same policy:
  - normal envs render a lighter `index.html`;
  - debug envs render the diagnostic UI variant from the same shared template;
  - runtime terminal, perf/CPU monitor, online matrix preview, and voice-lab/debug blocks belong to the diagnostic surface, not to the default user UI.
- Serial telemetry should follow the same contour split:
  - `env:s3` is expected to stay operationally quiet;
  - heavy `PERF][HB/STATE/FRAME/WIFI/WEB` and verbose `SPEECH_SR` boot/runtime chatter belong to `env:s3_voice_debug`;
  - if normal `s3` still prints that chatter, assume stale firmware or an unfinished serial split before opening a new diagnosis line.
- The next cheap architecture-cleanup step is ownership on the web write path:
  - `webserver.cpp` should remain transport/gateway;
  - shared `/update` state-apply logic should live outside the transport layer;
  - voice config/template mutations should follow the same rule and not stay embedded in HTTP handlers;
  - do not add a second delayed-save layer here: `state.cpp` already owns `markStateDirty()` + debounce save via `checkAndSave()`;
  - continue cleanup in that direction before taking the separate `WEB refresh / handleClient` line.
- Core-affinity policy should now also be treated as centralized architecture, not scattered implementation detail:
  - `core_affinity.h` is the canonical owner of task pinning policy;
  - do not keep multiplying local `static constexpr ... CORE = 0/1` islands in service files;
  - keep one compact startup `[CORE_MAP]` log so the intended mapping is observable in normal `s3` without reopening heavy debug telemetry;
  - first centralize core ownership, then change the policy itself if telemetry justifies it.
- Current `Core 1` audit verdict:
  - allowed now: `DisplayTask`, render/present path, `matrixShow()`, hot `AudioCapture` producer, thin `loop()` shell;
  - questionable but tolerated for now: `handleSpeechRecognitionService()` and `handleAudioCaptureService()` being invoked from the `Core 1` shell;
  - not allowed on `Core 1`: web/json/fs/nvs/wifi/weather/sensors/heavy speech model work.
- `audio/audio_capture_service.*` can now surface the latest shared PCM frame in addition to RMS/timestamp, and the main product voice path uses that shared capture at `16 kHz`; this is now the active bridge for `ESP-SR` without reintroducing a second I2S owner.
- Shared audio snapshots now also keep a short ordered PCM ring for voice capture. `speech_recognition_service.*` no longer grabs only the latest frame; it consumes sequential PCM frames, which preserves real timing in saved WAVs and avoids the "accelerated word" artifact seen when intermediate frames were dropped.
- Audio capture ownership is now a bit stricter in the hot path too: client-mask access is protected, and PCM frame staging is prepared outside the snapshot lock so the critical section no longer performs the full source-buffer copy itself.
- Shared audio snapshot publishing is now tightened one step further: the producer-side critical section updates only buffer indices and metadata, while PCM sample arrays are copied outside the lock. The hot publish path must not memcpy `samples[512]` under the snapshot critical section.
- Wake-word gain and command-capture audio are now explicitly separated: wake/multinet can use an amplified working copy, while `voice_lab` saving and template matching operate on raw PCM so command samples do not inherit clipped wake gain.
- Shared audio producer no longer computes the public project FFT payload. Raw `I2S` capture now publishes only PCM/RMS snapshots, while `audio/spectrum.cpp` computes visual FFT locally from those shared PCM frames when spectrum modes actually need it.
- Matrix rendering now treats `frame[]` as a logical render buffer; brightness scaling and LED output belong only to the scanout/present path, so the display pipeline stays deterministic and easier to diagnose under load.
- Main loop priority model is now frame-first: display cadence is fixed, realtime audio/voice servicing runs in tiny quanta, and Wi-Fi/RTC/weather/web/save/sensor bootstrap are serviced only in slack between frames instead of competing directly with present timing.
- Display smoothness is a non-negotiable product rule: any code path that can steal time from frame generation/present must either move behind the scheduler, become asynchronous, or justify itself as display-critical work.
- Web layer should be treated as command/status gateway, not as display-time owner: route handlers should acknowledge quickly and hand heavy work to deferred services, scheduled actions, or queues.
- `/ui-state` and `/state` must fail loudly on JSON-capacity overflow instead of silently dropping fields; partial status JSON is considered a diagnostic defect, not an acceptable degradation mode.
- Web state is now intentionally split by polling weight: `/ui-state` is the light UI essentials snapshot, `/voice-state` carries speech/template/debug details, `/weather-state` carries weather payload, `/perf-state` carries frame/heap/deadline/runtime metrics, and `/state` remains the manual full debug dump.
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
- `audio/audio_capture_backend_i2s.*` — raw `I2S` capture backend on the hot audio core; publishes shared PCM/RMS frames and does not own the visual FFT layer anymore.
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
- Ownership rule for startup pressure is now explicit too: `speech_recognition_service.*` must not directly stop/start `sensors_async`; if command-model preparation needs temporary relief, it must go through a barrier/guard API owned by `sensors_async.*`.
- The shared microphone policy is now explicit, and product voice control is wired into the real `s3` firmware path via `ESP-SR`, but the current command model is still intentionally narrow: English command phrases only, fixed wake word family (`Hi ESP` model), and real-hardware tuning is still required before calling it production-quiet in every room.
- The `s3sr` hybrid scaffold remains a diagnostic/research track only. Product voice work must continue in `s3`, not by stripping features into the scaffolded build.
- Product voice flashing is now a multi-artifact operation, not a simple firmware upload: `bootloader`, `partitions`, `firmware`, `artifacts/srmodels.bin`, and `LittleFS` must be written together, and `otadata` must be reset so the board boots the new `app0`.
- After `erase flash`, plain PlatformIO `Upload` is not enough for voice-enabled behavior: firmware plus `LittleFS` plus the `model` partition content are all required before `Hi, ESP` can work again.
- This voice rollout is still not fully stabilized on hardware: after the `ESP-SR` product path was enabled, the board can enter a reboot loop during early runtime around Wi-Fi / OTA / speech-start interaction. This is a firmware/runtime bug still under investigation, not a user flashing mistake.
- Current voice-stability debugging assumes explicit core ownership: the raw audio capture backend remains on `Core 1` as the realtime producer, while non-realtime background tasks (`weather`, `sensors_async`, `voice_command_service`) and the current `speech_recognition_service` runtime should be kept off that hot audio core unless a later measurement proves otherwise.
- The current lightweight template matcher is now structurally usable, but still not product-final: recording quality, wake tuning, and per-word temporal discrimination remain active tuning areas, especially for similar multi-syllable real-world words such as `Проектор` / `Телевизор`.
- Command-template comparison no longer relies only on a fixed-bin summary of the word. The matcher now also compares the active speech contour as an ordered frame sequence with time alignment, because the old coarse shape-only view was producing too many near-tied `slot0/slot1` distances on similar long commands.
- Template acceptance is now also slightly adaptive near the "very strong match" zone: a clearly low best-distance can be accepted with a smaller absolute gap when the runner-up is still meaningfully worse by ratio, reducing needless `matched=false` on otherwise clean command captures.
- Command matching now also gives extra weight to the onset of the word and to attack dynamics between adjacent frames, because similar commands were carrying more discriminative information in the initial consonant than in the shared tail.
- For a fast resume of this exact voice-command investigation, use `docs/project/VOICE_COMMAND_MATCHER_ARCHIVE_RU.md`; it is the dedicated handoff note for the current matcher state, what is already fixed, and what should be investigated next.
- A later runtime review also found non-algorithmic freeze sources around voice: the display no longer hard-stops its present path during post-wake capture, and verbose speech diagnostics are no longer mirrored into the runtime log on every wake/template event, because both were creating avoidable pressure on the frame-critical path.
- `speech_recognition_service.*` is still too large, but before splitting it further the runtime foundation was tightened: product/debug voice modes are no longer conflated in one env, and ESP-SR startup / MultiNet load now log internal-heap and largest-block telemetry in addition to total free heap.
- Shared audio telemetry is now part of the runtime baseline: publish latency, read-timeout count, frame-drop count, and audio-task stack high-water are exposed so voice/runtime regressions can be judged from the device instead of guesswork.
- Runtime ownership audit is now observable from the device too: `/perf-state` and `/state` expose the currently observed core ids for `loop`, `display`, `audio capture`, `speech recognition`, `weather`, `sensors`, `voice command`, and the `realtime/deferred/Wi-Fi/WebServer` service paths. This is still telemetry, not the final `DisplayTask` split, but it gives a real dual-core map before any scheduler rewrite.
- Perf telemetry was extended for freeze hunting: `/perf-state` and `/state` now also retain `frameTimeMaxUs`, `matrixPresentTimeMaxUs`, `speechSlowStepCount`, `speechMaxStepUs`, and `speechLastSlowCore`, while serial adds one-time `matrixShow()` core logging and explicit `[PERF][FRAME] deadline miss ...` lines for visible cadence breaks.
- Display cadence is no longer owned by `Arduino loop()` itself: a minimal `DisplayTask` foundation now runs the frame schedule on `Core 1`, while `loop()` remains a thin realtime shell for non-display service coordination. This is intentionally not a full runtime rewrite yet, but it isolates frame cadence from plain loop scheduling jitter and keeps the existing telemetry intact.
- After `DisplayTask` removed deadline-miss starvation, the next audit layer focuses on frame ownership rather than timing. `/perf-state` now also exposes `displayScheduledFrameSeq`, `displayRenderedFrameSeq`, `displayPresentedFrameSeq`, `displayCurrentRenderMode`, `displayOverlayActive`, `displayAnimationFrameIndex`, `displaySecondsValue`, `displayRenderDeltaMs`, `displayRepeatedFrameCount`, `displaySkippedLogicStepCount`, `displayStateSnapshotAgeMs`, and `displayWriteViolationCount/displayLastViolationCore` so visible jitter can be classified as state/buffer corruption even when `frameMiss=0`.
- A dedicated A/B debug env now exists for isolating Core 1 audio pressure from the remaining visual defect: `s3_audio_off_debug` builds the same product path but hard-disables audio capture startup (`MATRIXCLOCK_AUDIO_CAPTURE_FORCE_DISABLED`). Use it only as a diagnostic split, not as the final product env. `/perf-state` additionally exposes `frameSlowCount`, `frameSlowMaxUs`, `frameLastSlowRenderMode`, `frameLastSlowAudioActive`, `frameLastSlowCore`, `audioCaptureClientMask`, `audioCaptureActive`, and `audioCaptureLastStartReason` so the difference between "local render glitch" and "audio-induced global stall" can be measured directly.
- The next diagnostic A/B env pair is now also present for the `voiceEnabled` vs `audioCaptureActive` split:
  - `s3_voice_off_audio_forced_on` — boots with `voiceEnabled=false`, but shared `AudioCapture/I2S` is forced active through the canonical audio-capture owner path;
  - `s3_voice_on_audio_forced_off` — boots with `voiceEnabled=true`, but shared `AudioCapture/I2S` is force-disabled. This is a diagnostic-only build and must not be interpreted as a valid production voice mode.
- A separate PM/Wi-Fi-sleep split env now also exists: `s3_pm_stability_test`.
  - It boots with `voiceEnabled=false`, `AudioCapture/I2S` forced off, and Wi-Fi sleep/power-save forced off via `WiFi.setSleep(false)` and `esp_wifi_set_ps(WIFI_PS_NONE)`.
  - Use it only to test whether the remaining `aud=0` instability follows Wi-Fi/PM/clock-state rather than audio lifecycle alone.
- That split is now no longer hypothetical: hardware A/B confirmed that the remaining display defect follows `audioCaptureActive/I2S active` rather than `voiceEnabled`.
  - `Voice OFF + AudioCapture ON` is visually clean.
  - `Voice ON + AudioCapture OFF` brings back freezes, sparkles, calendar jitter, and progress-pixel artifacts.
- Voice event-path hardening now also treats `LittleFS` sample saves and HTTP command delivery as non-display-critical side effects: product speech no longer mirrors frequent wake/template events into runtime logs by default, and WAV persistence is written in smaller yielding chunks instead of one large blocking write.
- A post-refactor calendar glitch was fixed in `clock_visuals.*`: the maze pixel inside the date digits must advance only while that calendar block is actually visible, otherwise it "sprints" after weather/sensor overlays return.
- Voice priority rule: if audio consumers compete for processing budget, voice-command detection wins and visual audio consumers may degrade first.
- `voice_command_service.*` worker must not read mutable command `String` state directly across task boundaries; it should operate on locked snapshots/copies of command slots.
- Recent display-isolation A/B runs established two separate problem lines and they must not be mixed:
  1. normal clock `calendar + progress + ticker/date` had a real layer/ownership bug;
  2. dynamic spark/twitch/ghost artifacts track voice/audio/runtime state and are not proven to be the same bug.
- The current layer fix helped the normal clock path but also introduced a regression in `5x3`: ticker/date clipping into the left block must be conditional on actual calendar-region ownership, not a global left-side ban.
- Current voice/runtime diagnosis is still open, but the center of gravity has shifted. Hash/baseline telemetry now shows that for the same render phases (`dyn=0x07` etc.) the pre-`matrixShow()` framebuffer can be identical in `voice ON` and `voice OFF`, while the user still sees the defect mainly in `voice OFF`.
- The diagnosis has now shifted one step further: the strongest proven divider is no longer `voice ON/OFF`, but `AudioCapture/I2S active vs stopped`.
- Therefore do not treat the remaining `voice OFF` symptom as a proven normal-clock render bug anymore. The leading suspects are now:
  - `AudioCapture/I2S active vs stopped` side effects on `Core 1`,
  - output/brightness/gamma/scanout behavior after the logical framebuffer,
  - signal/power/ground/LED-stream behavior,
  - or a much narrower display-output artifact that coarse region hashes do not classify as a stall.
- Do not declare `WakeNet` "simply too heavy" yet and do not move speech work to `Core 1` by instinct. First prove whether the visible instability follows:
  - `audioCaptureActive` rather than `voiceEnabled` — now strongly supported by hardware A/B,
  - post-buffer output behavior rather than render-buffer content,
  - shared memory / PSRAM / heap / interrupt pressure,
  - or a genuine lack of `Core 0` compute budget.
- Architecture correction from this verdict:
  - `AudioCapture/I2S` must be treated as a shared stream service, not as part of the voice feature itself.
  - `Voice`, `Spectrum/ReactiveSound`, and debug paths are consumers of the stream.
  - `Voice OFF` should disable the speech consumer, not necessarily stop the shared audio backend.
- The production lifecycle policy has now been corrected in that direction too: the shared audio service has a keepalive client in the main `s3` build, so `Voice OFF` no longer implies `AudioCapture/I2S OFF`. Speech/WakeNet still detach as consumers, but the backend remains alive as infrastructure unless a dedicated debug env forces audio capture off.
- A separate web/UI line remains open even after the contour cleanup:
  - page refresh can still produce visible pixel freeze;
  - the confirmed signal is slow `handleClient` bursts on the web path;
  - do not fold that back into the already-stabilized `Voice OFF / aud=0` lifecycle bug.
- `Core 1` remains the display-owner core. Any future borrowing of spare time on that core must be explicit, low-priority, short, and preemptible. No broad migration of speech/audio logic to `Core 1` is allowed without telemetry-backed proof.

## Verification Defaults

- `data/index.html` or LittleFS assets changed: run `scripts/check_literal_newlines.ps1` and `platformio run -e s3 -t buildfs`; upload filesystem.
- `webui/index.template.html` or UI-variant script changed:
  - normal UI: `platformio run -e s3 -t buildfs`
  - debug UI: `platformio run -e s3_voice_debug -t buildfs`
- C++ changed: run `platformio run -e s3`; upload firmware if behavior changed.
- Normal C++ verification: run `platformio run -e s3`.
- Debug-only voice/runtime verification: run `platformio run -e s3_voice_debug` only when the task actually touches the debug contour.
- Docs-only changed: run `scripts/check_literal_newlines.ps1`.
- UI text/flow changed: mention whether firmware or only LittleFS upload is needed.
- Current voice-build flashing note: do not rely on plain PlatformIO `Upload`; use the full flash path (`platformio run -e s3`, `platformio run -e s3 -t buildfs`, then `scripts/flash_all_voice.ps1`) because the voice target needs model partition content in addition to normal firmware assets.
- Normal review archives should stay hygienic: exclude `.pio/`, ad-hoc build logs, `platformio.local.ini`, and unnecessary `managed_components/` copies unless the archive is explicitly meant as a full local debug snapshot.

## Next Bias

Prefer stabilizing and clarifying current features over adding new ones:
1. Finish the current display/voice diagnosis before any new feature track.
2. First restore correctness in `5x3` by making calendar/ticker left clipping conditional on real calendar ownership.
3. The shared audio service is now the active fix surface:
   - production `s3` keeps `AudioCapture/I2S` alive through a keepalive client even when `Voice OFF` disables speech/WakeNet;
   - physical microphone/I2S shutdown must not be coupled directly to the voice toggle anymore.
4. After this keepalive fix, keep the current voice/audio/render telemetry as the baseline and interpret it correctly:
   - matching `frameHash/leftHash/progHash` across `voice ON/OFF` means the logical framebuffer is not the strongest remaining suspect for that phase;
   - visible difference with matching hashes shifts attention below render-buffer level.
5. The `audioCaptureActive vs voiceEnabled` split has already been proven strongly enough to guide the next implementation step; further telemetry should now prefer output-side context instead of more coarse render repeats:
   - brightness state,
   - effective/post-scale brightness,
   - any post-buffer staging hash or tx-hash if a debug seam exists.
6. After validating the keepalive/lifecycle fix on hardware, continue with the narrow root-cause track:
   - PM / Wi-Fi sleep / DFS / clocking behavior when `I2S` stops,
   - output-path investigation,
   - only later, if still needed, speech throttling/yield on `Core 0`.
7. A smaller follow-up bug now remains on top of the fixed keepalive policy:
   - rapid `Voice ON/OFF` clicking can still cause occasional transition hiccups;
   - this is no longer the old `aud=0` freeze path because `aud` stays `1`;
   - the next implementation step is transition smoothing: coalesced/deferred voice toggle apply, with heavy toggle diagnostics kept out of normal `s3`;
   - this has now been further hardened by stricter debounce/cooldown and a UI/API single-flight toggle policy.
8. The older telemetry wishlist remains useful where still applicable:
   `voiceEnabled`, `voiceActive`, `audioCaptureActive`, `audioCaptureClientMask`, `audioCaptureLastStartReason`, `audioCaptureStartStopSeq`, `currentRenderMode`, `fontMode`, `calendarVisibleThisFrame`, `progressVisibleThisFrame`, `tickerVisibleThisFrame`, `calendarRegionReserved`, `tickerClipLeftPx`, `frameSlowCount`, `frameSlowMaxUs`, `frameLastSlowCore`, `frameLastSlowStep`, `frameLastSlowRenderMode`, `frameLastSlowAudioActive`.
9. Do not mix this diagnosis with the separate `single_pixel` ghosting line; that remains its own follow-up track.

## Current Verdict

- Main root cause for the big visible freeze line is considered established:
  - stopping shared `AudioCapture/I2S` was the strongest trigger for the old `Voice OFF` artifacts.
- Main practical fix is in place in normal `s3`:
  - `Voice OFF` now means `speech consumer OFF`, not `audio backend OFF`;
  - shared `AudioCapture/I2S` stays alive via keepalive.
- Remaining artifacts are now reduced to rare transition hiccups during aggressive toggling and are no longer treated as the same bug class.
- Important honesty note for this line:
  - the later UI/API `single-flight` hardening introduced a regression where `Voice ON` could bounce back to `OFF`;
  - this was not an original device bug, but a newly introduced control-path regression during the fix attempts;
  - the regression was surfaced and dissected through an external diagnosis loop led by the user with ChatGPT and partially Grok, while the user handled hardware testing, log collection, and validation;
  - this must be remembered as a caution against over-tightening UI gating on an already stabilized path.
- Project status for this line:
  - close as "practically neutralized at current architecture stage";
  - re-validate once the broader architecture cleanup is finished, because some residual behavior may still depend on current architectural debt or hardware-side sensitivity.

## Core 1 Shell Cleanup

- `Core 1` loop shell was intentionally thinned in three safe steps, without moving the actual producer task or changing keepalive policy.
- Step 1:
  - `handleSpeechRecognitionService()` control polling was moved out of the `Core 1` shell into deferred `Core 0` servicing.
- Step 2:
  - `handleAudioCaptureService()` control polling was moved out of the `Core 1` shell into deferred `Core 0` servicing.
  - `Core 1` still performs only lightweight `requestAudioCaptureForClient(...)` intent updates plus display-safe realtime shell work.
- Step 3:
  - `handleVoiceService()` was also moved out of the `Core 1` shell into deferred `Core 0` servicing.
  - Voice toggle apply, voice client intent, and passive voice runtime-state polling are no longer part of the display-core shell.
- Policy unchanged:
  - `AudioCapture` producer task stays pinned to `Core 1`;
  - display/render ownership stays on `Core 1`;
  - shared-audio keepalive remains active in normal `s3`.

## Normal Telemetry Policy

- Heavy display hash diagnostics no longer belong to normal `s3`.
- Normal `s3` should not expose or compute by default:
  - `frameHash`
  - `leftRegionHash`
  - `progressRowHash`
  - repeat/change counters for those hashes
  - `displayHashBaselineEpoch`
  - verbose `[PERF][STATE]`
  - hash-heavy `[PERF][HB]`
- These stay in `s3_voice_debug`.
- Normal `s3` keeps lightweight runtime-safety/perf telemetry:
  - frame/present max values
  - deadline/slow counts
  - write-violation counters
  - core map fields
  - audio capture state/mask/drop/timeout
  - stack high-water fields

## Product Voice Feedback

- Normal product mode now has a tiny matrix voice-feedback overlay.
- Architecture rule:
  - speech/voice tasks only publish compact UI events;
  - only display/render path draws the indicator.
- Product feedback states:
  - wake detected -> short cyan flashes
  - command listening -> short amber indicator
  - command matched -> green flash
  - command failed / timeout -> red flash
- `/state` now also exposes:
  - `voiceWakeDetectedCount`
  - `voiceLastWakeAtMs`
  - `voiceLastUiEvent`
  - `voiceUiEventAgeMs`
- Template-readiness diagnostics were expanded:
  - `templatePath` alone is not treated as proof of a usable command template;
  - `/state.voiceCommands[]` now separates:
    - path configured
    - file exists
    - file size
    - load attempted
    - loaded
    - valid
    - exact load error
  - speech error text now reports the concrete readiness failure instead of the generic `need templates for both commands`.
- Final current verdict for onboard `ESP-SR` on the main `S3`:
  - wake word is confirmed working;
  - command templates can be present, loaded, and valid;
  - post-wake command capture can still fail to match even with valid templates;
  - more importantly, the post-wake capture + template-matching path reintroduces real runtime pressure on the main board (`frameSlowCount` growth, `frameSlowMaxUs` / `matrixPresentTimeMaxUs` spikes, large `speechMaxStepUs`);
  - therefore the current onboard `ESP-SR` branch is considered to have reached the practical runtime/core limit of the main controller at this architecture stage.
- Operational decision for now:
  - do not continue broad tuning of onboard `ESP-SR` on the main `S3` as the primary path;
  - keep the findings and diagnostics, but treat the branch as paused/frozen after reaching the runtime/core ceiling;
  - future voice work should prefer either a separate voice MCU/node or a simpler trigger path (for example clap/simple detector) rather than pushing more speech workload into the main display controller.
# Note

- For fastest continuation, prefer [CODEX_OPERATING_CONTEXT_RU.md](/d:/MatrixClockS3/Premium%20Clock%20v1/docs/project/CODEX_OPERATING_CONTEXT_RU.md) first.
