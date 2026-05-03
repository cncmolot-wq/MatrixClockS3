> Important: this note is a dedicated continuity document for the `ESP-SR` transition. It complements the main project docs and is meant to survive chat/session loss.

# ESP-SR Transition RU

## Purpose

Этот документ отдельно фиксирует переход продукта на голосовой контур `ESP-SR`:

- зачем мы это начали
- что именно было встроено в основной `s3` build
- с какими проблемами столкнулись
- что уже исправлено
- что остаётся текущим runtime-risk на железе

Это не общий проектный план и не полный changelog. Это целевая инженерная памятка по voice/`ESP-SR`.

## Product Decision

Главное архитектурное решение:

- `ESP-SR` не должен жить как отдельный кастрированный пользовательский продукт
- основной путь голоса должен идти в обычный `s3`
- `s3sr` допустим только как исследовательский / diagnostic scaffold, но не как финальная пользовательская ветка

Итог: реальная интеграция `WakeNet + MultiNet` была перенесена в продуктовый `s3`, а не оставлена в side-build.

## What We Wanted

Цель была не “сделать тестовый стенд”, а довести часы до живого голосового управления:

- общий микрофонный тракт без второго владельца `I2S`
- wake word
- распознавание command phrase
- маршрутизация в существующие `voice command slots`
- выполнение HTTP-команд без вмешательства display-hot-path

То есть wanted flow:

`microphone -> shared audio capture -> ESP-SR -> matched phrase -> voice_command_service -> queued HTTP action`

## Base Before ESP-SR

До подключения `ESP-SR` уже был подготовлен правильный фундамент:

- `audio_capture_service.*` стал единственным владельцем микрофона / `I2S`
- `voice_service.*` уже умел always-on listening, RMS/VAD и runtime telemetry
- `voice_command_service.*` уже умел хранить command slots и выполнять queued HTTP actions
- `/voice-phrase-test` уже проверял цепочку `recognized text -> command slot -> action`

Это было важно: мы не встраивали `ESP-SR` в хаотичный код, а подключали его в уже разделённую архитектуру.

## What Was Added

### Product path

В основной `s3` build были добавлены:

- product voice partition table с отдельным `model` partition
- product compile flag для включения `ESP-SR`
- vendored runtime parts `esp-sr` и `dl_fft`
- selected official models:
  - `wn9_hiesp`
  - `mn6_en`
- pack path для моделей и готовый `artifacts/srmodels.bin`

### Runtime layer

Добавлен отдельный `speech_recognition_service.*`, который:

- поднимает `ESP-SR` runtime
- загружает wake model и multinet model из `model` partition
- нормализует phrase slots в English uppercase form
- конфигурирует `MultiNet` командами из `voice command slots`
- читает shared PCM frames из `audio_capture_service`
- после распознавания очередит action через `voice_command_service`

То есть `speech_recognition_service` стал каноническим ASR-layer, а не временным обходом.

### Audio bridge

Для этого shared audio path был расширен:

- `audio_capture_service` теперь отдаёт не только `RMS`, но и последний `PCM frame`
- product voice path работает на `16 kHz`
- повторное владение `I2S` не вводилось

## Flashing Reality

Здесь была важная практическая проблема: voice build нельзя шить как обычный firmware-only update.

Нужны все артефакты:

- `bootloader`
- `partitions`
- `firmware`
- `artifacts/srmodels.bin`
- `LittleFS`

Кроме того, выяснилось, что при OTA-style partition layout устройство может продолжать грузить старый `app1`, даже если новый voice firmware записан в `app0`.

Поэтому в `scripts/flash_all_voice.ps1` был добавлен reset `otadata`.

Это сняло ложную проблему вида:

- прошивка заливается
- а в `/state` всё ещё видно `speechRecognitionBackend = "stub"`

После сброса `otadata` стало ясно, что новый product build реально запускается.

## Problems We Hit

### 1. Not a flashing myth, but a real firmware issue

На одном этапе можно было подумать, что всё упирается в кривой PowerShell, `Upload` vs full flash, или старый OTA slot.

Но это было не всё.

После корректной полной заливки выяснилось:

- `esp_sr` backend реально компилируется
- `speechRecognitionBackendCompiled = true`
- устройство начинает грузить именно новый voice build
- но затем может уходить в reboot-loop уже на runtime

То есть это был уже не user error, а настоящий firmware/runtime defect.

### 2. Early boot instability

Сначала reboot-loop выглядел как проблема около `Wi-Fi` / `OTA`:

- падения случались рядом с `STA_CONNECTED`
- потом рядом с `STA_GOT_IP`

Что было сделано:

- readiness сети переведена с “формально connected” на реальный usable `localIP()`
- `OTA` стала подниматься только после настоящего network-ready state

Это улучшило ситуацию: boot стал проходить дальше.

### 3. ESP-SR start window instability

После этого устройство уже могло:

- поднять `Wi-Fi`
- получить IP
- поднять `OTA`
- отдать `/state`
- сходить за погодой по HTTPS
- стартовать sensor async path

И только потом падать.

Это сузило проблему: уже не “всё ломается на старте”, а именно поздний runtime around `ESP-SR` startup / task interaction.

### 4. Core/task contention suspicion

Дальше стало видно, что одновременно работают несколько тяжёлых и фоновых контуров:

- `spectrum_async`
- `speech_recognition_service`
- `weather_service`
- `sensors_async`
- `voice_command_service`

Подозрение сместилось на конфликт ownership/нагрузки по ядрам и таскам, а не только на сеть.

## Fixes Already Applied

На этом треке уже были сделаны такие стабилизационные шаги:

### Voice boot grace

`speech_recognition_service` теперь не стартует мгновенно на boot:

- добавлен boot grace window
- добавлена проверка минимального free heap

### Stronger speech task config

Для speech runtime были усилены параметры:

- увеличен stack
- добавлены более явные status messages
- добавлены более явные serial logs по этапам старта

### Lazy command-model loading

По живому поведению стало видно, что полный eager startup `WakeNet + MultiNet` слишком тяжёл для холодного boot-path.

Поэтому speech runtime был переведён на двухступенчатую схему:

- на boot поднимается только wake-word runtime
- command model (`MultiNet`) теперь может грузиться лениво, уже после wake word

Это не идеальный финальный UX-path, но это сильный stabilizing step: если проблема сидит именно в раннем полном ASR startup, устройство хотя бы перестаёт падать ещё до первого real interaction.

Следующий practical-pass после этого:

- `command model unavailable` больше не должен считаться фатальным тупиком
- если `MultiNet` не удалось поднять на текущем wake из-за памяти/момента runtime, система должна вернуться к ожиданию следующего wake и попробовать снова

Это превращает voice contour из хрупкого one-shot path в повторяемый runtime.

На практике следующий тест показал ещё более точную картину:

- `WakeNet` product path стабилен и переживает холодный boot
- часы могут долго жить как обычный продукт: дисплей, Wi-Fi, OTA, weather, sensors, web UI работают одновременно
- reboot больше не связан с общим startup voice-path
- crash воспроизводится именно после wake word, в момент `Loading command model`

То есть на текущем этапе зафиксировано не "voice broken in general", а более узкое состояние:

- `WakeNet stable`
- `MultiNet load after wake unstable`

Это очень важная граница для дальнейших решений: основной продуктовый runtime уже доказан как жизнеспособный, а open issue остался именно в integrated command-model load path.

### Voice diagnostics and terminal hygiene

После первых живых тестов стало ясно, что сырой `/state` и общий verbose-terminal слишком шумные для нормальной voice-debug работы.

Поэтому были добавлены/изменены:

- отдельный лёгкий `voice-state` polling path для voice UI
- расширенный voice diagnostics block прямо во вкладке `Voice`
- более явные serial logs по стадиям:
  - wake detected
  - command-model load attempt
  - command-model ready/unavailable
  - command recognized
  - command queued / HTTP result
- общий `CORE_DEBUG_LEVEL` снижен, чтобы в терминале доминировали voice-события, а не фоновые verbose-логи web/HTTP

### Background task separation

Фоновые задачи были разведены по ядрам жёстче:

- `weather_service` закреплён на `Core 0`
- `sensors_async` закреплён на `Core 0`
- `voice_command_service` worker закреплён на `Core 0`
- текущий debug-pass `speech_recognition_service` тоже уведён с hot audio core

Логика этого шага:

- `Core 1` не должен без нужды зарастать non-realtime фоном
- `shared audio` / `spectrum_async` должны иметь более чистый realtime contour

### Sensor startup barrier

По живому логу выяснилось, что один из самых опасных моментов — это наложение:

- `speechRecognitionState = loading ESP-SR models`
- резкое падение `freeHeap`
- параллельная попытка `sensor_bootstrap` поднять `sensors_async`

Поэтому был введён жёсткий barrier:

- пока startup `ESP-SR` ещё критичен
- и пока heap остаётся ниже защитного порога
- `sensor_bootstrap` не стартует вообще

Это временно делает voice startup важнее локальных датчиков, но для текущего этапа это правильный product-priority tradeoff.

## Current State

На текущем шаге уже правда:

- `ESP-SR` встроен в основной `s3`
- product build собирается
- `LittleFS` и `model partition` path готовы
- backend в `/state` виден как `esp_sr`, а не `stub`
- boot проходит значительно дальше, чем в начале

То есть интеграция уже не в теоретическом состоянии.

## Current Open Risk

Главный незакрытый риск сейчас такой:

- на железе ещё возможен runtime crash после старта voice build
- проблема уже сужена до позднего startup/runtime interaction, а не до flashing path
- самый вероятный текущий фронт — это либо внутренний runtime-конфликт вокруг `ESP-SR`, либо повреждение памяти/stack в момент позднего запуска speech path

Иначе говоря:

- проблема уже не “как прошить”
- проблема уже не “включился ли backend”
- проблема сейчас “добить стабильный живой runtime без reboot-loop”

## Important Practical Notes

### Command phrases

Текущий product path рассчитан на English command phrases.

Практически безопаснее использовать:

- `one`
- `two`
- `turn on movie`
- `turn off movie`

Цифры как символы (`1`, `2`) хуже подходят для текущего `ESP-SR` command path.

### Normal flash path

Для voice build нельзя полагаться только на обычный PlatformIO `Upload`.

Нужен полный flash sequence:

1. `platformio run -e s3`
2. `platformio run -e s3 -t buildfs`
3. `scripts/flash_all_voice.ps1`

### Research vs product

Если позже снова возникнет соблазн “временно всё увести в `s3sr`”, это против текущего product-решения.

Правильный курс уже зафиксирован:

- голосовая продуктовая логика живёт в `s3`
- `s3sr` допустим только как лабораторный побочный scaffold

## If Session Is Lost

Если переписка снова пропадёт, восстановление надо начинать отсюда:

1. Проверить, что в `/state` видно:
   - `speechRecognitionBackend = "esp_sr"`
   - `speechRecognitionBackendCompiled = true`
2. Если этого нет, проблема снова во flash path / OTA slot / не той прошивке.
3. Если это есть, но устройство падает, проблема уже в runtime stability voice build.
4. В первую очередь смотреть serial log вокруг:
   - `OTA ready`
   - weather HTTPS start/finish
   - sensor async start
   - `SPEECH_SR` task start / model ready
5. Если boot доходит до этих точек и потом падает, продолжать дебаг как `ESP-SR runtime stabilization`, а не как flashing-problem.

## Short Summary

Переход на `ESP-SR` уже сделал главное:

- голос ушёл в основной продуктовый `s3`
- built-in backend стал реальным
- shared audio architecture сохранена
- command/action pipeline уже подключён

Текущая незакрытая часть только одна:

- добить стабильность живого runtime на железе, чтобы `ESP-SR` не только запускался, но и жил без reboot-loop.
