<!-- Compact operator context for fast continuation. Keep short, factual, and current. -->

Start here for code work: `CODEX_PROJECT_MAP_RU.md`.
Use this file as volatile operating memory only; the map is the stable owner/module entrypoint.

Current override, 2026-05-15:
- Target now: stable clock-only normal `s3`.
- Onboard `ESP-SR` and onboard voice frontend are cut out of normal `s3`.
- Voice research survives only in `s3_voice_base` / `s3_voice_debug`.
- Do not reopen onboard voice as a default explanation for current clock freezes.

# CODEX_OPERATING_CONTEXT_RU

## Purpose

Этот файл не для красивой документации.
Это короткая операционная память по проекту, чтобы быстрее входить в работу без повторного раскопа.

## Current Truth

- Главный тяжёлый визуальный баг установлен:
  - старый `Voice OFF -> aud=0 -> постоянные фризы/искры`
  - strongest trigger: остановка shared `AudioCapture/I2S`
- Основной production fix уже внедрён:
  - normal `s3` держит shared `AudioCapture/I2S` живым через `KEEPALIVE`
  - `Voice OFF` = speech consumer OFF, а не audio backend OFF
- Это подтверждено на железе:
  - `aud=1`, `mask=0x04`, `aDrop=0`, `aTout=0`
  - постоянные `Voice OFF` фризы практически исчезли
- Рабочий build-контур теперь должен читаться просто:
  - `s3` = обычный baseline
  - `s3_voice_debug` = основной debug contour
  - `s3ota` = OTA-helper для того же normal baseline
  - остальные env в `platformio.ini` считать архивными диагностическими split-build'ами, а не повседневным маршрутом
- UI/LittleFS теперь должен читаться так же:
  - `s3` / `s3ota` => normal UI
  - `s3_voice_debug` и архивные debug env => diagnostic UI
  - `runtime log`, perf/CPU monitor, online matrix preview и voice-lab/debug blocks не должны жить в обычном UI

## Serial Contour Policy

- `s3` = operationally quiet baseline
- `s3_voice_debug` = noisy `PERF` / verbose `SPEECH_SR` contour
- `s3_voice_base` / `s3_voice_debug` = onboard voice research contours; normal `s3` should not compile or carry onboard `ESP-SR`.
- If normal `s3` still prints heavy `PERF][HB/STATE/FRAME/WIFI/WEB` spam, treat it as stale firmware or an unfinished split.

## Residual State

- Остаток проблемы сейчас уже другой:
  - редкие hiccups при агрессивных `Voice ON/OFF` toggle
- Это не старый `aud=0` bug-class
- Уже сделано:
  - deferred/coalesced apply
  - stricter debounce/cooldown
  - UI/API single-flight
- Важно:
  - один из поздних UI hardening pass внёс регресс `Voice ON -> OFF`
  - регресс раскопан через внешний консилиум (`ChatGPT`, частично `Grok`) при координации пользователя
  - пользователь делал тесты на железе, логи и валидацию

## Separate Known Line

- Жёсткий фриз при refresh страницы виден в логах как:
  - `[PERF][WEB] slow handleClient` примерно `250-337 ms`
- Это уже отдельная web/UI line
- Не смешивать её с закрываемой `Voice OFF / aud=0` freeze line

## Web Refresh Line

- UI lightening and serial quieting do not close the page-refresh freeze by themselves.
- Visible pixel freeze during browser refresh belongs to the separate `WEB refresh / handleClient` track.

## Stable Invariants

- `Core 1` = display owner
- Не тащить speech/audio broad-migration на `Core 1`
- Не ломать keepalive policy без очень сильного основания
- Не считать `voiceEnabled` главным виновником старого freeze-path
- Shared `AudioCapture/I2S` = service
- `Voice`, `Spectrum`, `ReactiveSound` = consumers
- `core_affinity.h` = единственный канонический owner core-pinning policy
- `CORE_MAP` startup log = короткая живая проверка policy без тяжёлой debug-телеметрии

## Current Voice Verdict

- Onboard `ESP-SR` on the main `S3` is currently considered paused.
- Why:
  - wake word was brought to a working state;
  - template files/readiness diagnostics were brought to a working state;
  - but post-wake command/template matching still creates visible runtime/core pressure on the main display controller.
- Practical meaning:
  - this line is no longer treated as "just needs more tuning";
  - at the current architecture stage it is treated as having reached the practical runtime/core ceiling of the main controller.
- Default bias from now on:
  - do not reopen broad onboard `ESP-SR` tuning on the main board by default;
  - prefer future voice exploration as either a separate voice MCU/node or a simpler local trigger path.

## Core 1 Audit

- `Core 1` сейчас несёт:
  - `DisplayTask`
  - `handleDisplayRuntime()`
  - render path / `matrixShow()`
  - `loop()` как тонкий realtime shell
  - `AudioCapture` producer task
- В `loop()` на `Core 1` сейчас вызывается только `handleRealtimeServices()`:
  - `handleVoiceService()` = realtime-safe shell, но позже желательно ещё худеть
  - `handleSpeechRecognitionService()` = questionable shell: сам heavy speech runtime pinned на `Core 0`, но старт/guard logic всё ещё дёргается из `Core 1`
  - `requestAudioCaptureForClient()` = realtime-safe mask update
  - `handleAudioCaptureService()` = допустимо сейчас, но это control-path around hot audio owner, не финальная идеальная граница
- На `Core 1` по текущему аудиту не должно быть:
  - Web / JSON / FS / NVS
  - Wi-Fi service work
  - weather/sensors tasks
  - speech model execution
  - allocation-heavy background logic

## Fix Discipline

- Не лечить симптом локальной затычкой, если есть признаки системной цепочки.
- Сначала определить класс проблемы:
  - локальный изолированный дефект;
  - или симптом более общей архитектурной/ownership/lifecycle проблемы.
- Локальный дефект можно чинить точечно.
- Системный дефект:
  - либо лечить на уровне правильного владельца логики;
  - либо явно фиксировать как составной пункт будущей архитектурной перестройки.
- Временные меры допустимы только если они:
  - явно помечены как временные;
  - узки по scope;
  - не маскируют реальную причину;
  - не искажают архитектурную картину проекта.

## Do Not Re-open Blindly

- `calendar/progress/ticker render` как первопричину старого большого бага
- `WakeNet overload`
- `I2S read timeout` как текущую главную линию
- `Wi-Fi sleep` как уже достаточное объяснение старого дефекта

## Known Good Interpretation

- Если `aud=0` и есть визуальная деградация:
  - это всё ещё подозрение на lower system/output/peripheral state
- Если `aud=1`, `aDrop=0`, `aTout=0`, а есть краткие артефакты:
  - это уже не старый bug-class
  - смотреть transition path или web/UI bursts

## Current Bias

1. Держать проект дешёвым по контексту:
   - короткие доки
   - только подтверждённые выводы
   - без длинных пересказов
2. Не плодить новые telemetry-ветки без явной пользы
3. Любой новый fix-pass сначала проверять на риск регресса control-path
4. Следующие работы вести отдельными линиями:
   - architecture debt
   - web refresh freezes
   - residual toggle hiccups

## Verification Rules

- Менял `data/index.html`:
  - `platformio run -e s3 -t buildfs`
  - заливать `LittleFS`
- Менял `webui/index.template.html` или env-aware UI-variant логику:
  - normal UI: `platformio run -e s3 -t buildfs`
  - debug UI: `platformio run -e s3_voice_debug -t buildfs`
- Менял C++:
  - `platformio run -e s3`
- Менял debug-only voice/ESP-SR behavior:
  - `platformio run -e s3_voice_debug`
- Всегда:
  - `powershell -ExecutionPolicy Bypass -File scripts\\check_literal_newlines.ps1`

## Working Principle

- Краткость важнее литературности
- Дешёвый контекст важнее красивой документации
- Док должен помогать продолжать работу, а не объяснять историю проекта с нуля
