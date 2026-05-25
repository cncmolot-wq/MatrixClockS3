<!-- Important: keep this file as a running debug log for layer-isolation tests. -->

# DISPLAY_LAYER_ISOLATION_DEBUG_RU

Дата старта серии: 2026-05-13
Проект: MatrixClockS3 / Premium Clock v1
Цель серии: локализовать остаточный визуальный дефект после стабилизации `DisplayTask`.

## Рамки серии

Не трогать в рамках этой серии:
- scheduler
- DisplayTask
- Wi-Fi
- audio
- speech
- OTA
- sensors

Рабочая гипотеза серии:
- остаточный дефект сидит в render/layer/coordinate/stale-pixel логике;
- серия идёт через отключение отдельных визуальных слоёв и тестовые паттерны.

## Базовые наблюдения перед серией

Что уже было установлено до layer-isolation:
- `DisplayTask` стабилизировал cadence display path;
- `frameMiss=0` больше не исключает локальный визуальный дефект;
- `matrixShow()` по времени выглядит нормальным;
- `audio` ранее давал отдельную runtime-проблему, но `audio-off` не убрал локальный дефект;
- остаточный симптом глазами пользователя:
  - сильнее всего заметен в левом блоке примерно `9x8`;
  - тот же район проявляется на бегущей строке;
  - крайний пиксель progress bar мерцает;
  - `Fire` визуально выглядит чисто.

## Тестовые env

Подготовлены env:
- `s3_dbg_no_calendar`
- `s3_dbg_no_progress`
- `s3_dbg_no_calendar_progress`
- `s3_dbg_no_ticker_date`
- `s3_dbg_solid`
- `s3_dbg_single_pixel`

Ниже фиксируются только результаты уже реально прогнанных тестов.

---

## Тест 1: `s3_dbg_no_calendar`

Смысл теста:
- отключён calendar block;
- остальная прошивка оставлена в обычном debug-runtime состоянии.

Факт по визуальному результату:
- пользователь сообщил: `визуально, фризы не наблюдаются`.

Ключевые признаки из лога:
- `frameMiss=0`
- `missMaxUs=0`
- `frameMaxUs=3747`
- `presentMaxUs=7908`

Дополнительные наблюдения из лога:
- `AUDIO_CAPTURE_BACKEND` активен на `Core 1`;
- `audioDrop/audioTimeout` растут;
- периодически есть `PERF][SPEECH] slow step` для `wakenet_detect`.

Статус интерпретации:
- тест завершён;
- факт зафиксирован;
- финальный общий вывод по серии отложен до завершения следующих тестов.

---

## Тест 2: `s3_dbg_no_progress`

Смысл теста:
- отключён progress bar;
- остальная прошивка оставлена в обычном debug-runtime состоянии.

Факт по визуальному результату:
- пользователь сообщил: `фризов не наблюдается`.

Ключевые признаки из лога:
- `frameMiss=0`
- `missMaxUs=0`
- `frameMaxUs=4034`
- `presentMaxUs=7912`

Дополнительные наблюдения из лога:
- `AUDIO_CAPTURE_BACKEND` активен на `Core 1`;
- `audioDrop/audioTimeout` растут;
- периодически есть `PERF][SPEECH] slow step` для `wakenet_detect`.

Статус интерпретации:
- тест завершён;
- факт зафиксирован;
- финальный общий вывод по серии отложен до завершения следующих тестов.

---

## Тест 3: `s3_dbg_no_calendar_progress`

Смысл теста:
- отключены и calendar block, и progress bar;
- остальная прошивка оставлена в обычном debug-runtime состоянии.

Факт по визуальному результату:
- пользователь сообщил: `визуально, фризов нет, всё работает гладко`.

Ключевые признаки из лога:
- `frameMiss=0`
- `missMaxUs=0`
- `frameMaxUs=2912` на стабильном участке;
- `presentMaxUs=7923`

Дополнительные наблюдения из лога:
- `AUDIO_CAPTURE_BACKEND` активен на `Core 1`;
- `audioDrop/audioTimeout` растут;
- периодически есть `PERF][SPEECH] slow step` для `wakenet_detect`;
- присутствует отдельный runtime-эпизод:
  - `PERF][FRAME] slow frame: 255583 us core=1`
  - `PERF][WEB] slow handleClient ...`

Важно:
- несмотря на этот отдельный runtime-шум, пользователь всё равно не наблюдал локального визуального дефекта в рамках данного теста.

Статус интерпретации:
- тест завершён;
- факт зафиксирован;
- финальный общий вывод по серии отложен до завершения следующих тестов.

---

## Тест 4: `s3_dbg_no_ticker_date`

Смысл теста:
- отключены ticker/date overlay;
- остальная прошивка оставлена в обычном debug-runtime состоянии.

Факт по визуальному результату:
- пользователь сообщил: `фризы отсутствуют`.

Ключевые признаки из лога:
- `frameMiss=0`
- `missMaxUs=0`
- `frameMaxUs=4033`
- `presentMaxUs=7907`

Дополнительные наблюдения из лога:
- `AUDIO_CAPTURE_BACKEND` активен на `Core 1`;
- `audioDrop/audioTimeout` продолжают расти;
- много `PERF][SPEECH] slow step` для `wakenet_detect`;
- много `PERF][WEB] slow handleClient`;
- при этом локальный визуальный дефект пользователем не наблюдается.

Статус интерпретации:
- тест завершён;
- факт зафиксирован;
- финальный общий вывод по серии отложен до завершения следующих тестов.

---

## Тест 5: `s3_dbg_solid`

Смысл теста:
- вместо обычной clock/render логики принудительно рисуется сплошной одноцветный экран;
- используется как грубая проверка отсутствия локального layer-конфликта в обычных визуальных слоях.

Факт по визуальному результату:
- пользователь сообщил: `после демонстрации IP - синий экран, BSOD, и всё`.

Ключевые признаки из лога:
- `frameMiss=0`
- `missMaxUs=0`
- `frameMaxUs=3166`
- `presentMaxUs=7904`

Дополнительные наблюдения из лога:
- `AUDIO_CAPTURE_BACKEND` активен на `Core 1`, затем останавливается и позже снова стартует;
- `audioDrop/audioTimeout` растут;
- есть `PERF][SPEECH] slow step` для `wakenet_detect`;
- есть `PERF][WEB] slow handleClient`;
- в показанном фрагменте нет display deadline miss.

Важно:
- визуальный результат здесь качественно отличается от обычного симптома;
- этот тест не описывается пользователем как "локальные фризы", а как переход в сплошной синий экран после показа IP.

Статус интерпретации:
- тест завершён;
- факт зафиксирован;
- финальный общий вывод по серии отложен до завершения следующих тестов.

---

## Тест 6: `s3_dbg_single_pixel`

Смысл теста:
- вместо обычной clock/render логики рисуется один движущийся белый пиксель;
- используется как грубая проверка аппаратной/координатной чистоты вывода без обычных визуальных слоёв.

Факт по визуальному результату:
- в начале пользователь наблюдал чистую картину;
- при включённом голосовом помощнике картинка в целом была чистой на всех уровнях яркости, кроме двух редких глюков за весь тест;
- после выключения голосового помощника за белым пикселем начали появляться фантомные вспышки соседних пикселей:
  - зелёные вспышки;
  - местами фиолетовые;
  - визуально как редкие "искры";
- по яркости:
  - ниже `60` эффект заметно слабее;
  - ниже `50` практически не наблюдался.

Ключевые признаки из лога:
- `frameMiss=0`
- `missMaxUs=0`
- `frameMaxUs=2234`
- `presentMaxUs=7907`

Дополнительные наблюдения из лога:
- `AUDIO_CAPTURE_BACKEND` многократно стартует и останавливается на `Core 1`;
- `audioDrop/audioTimeout` растут;
- есть `PERF][SPEECH] slow step` для `wakenet_detect`;
- есть `PERF][WEB] slow handleClient`;
- в показанном фрагменте нет display deadline miss.

Важно:
- пользователь описывает эффект как аппаратно/визуально отличный от исходного локального `9x8`-фриза;
- поведение зависит от состояния голосового помощника и от уровня яркости;
- сам одиночный белый пиксель при этом остаётся основным визуальным объектом, а фантомные цветные вспышки появляются рядом/следом.

Статус интерпретации:
- тест завершён;
- факт зафиксирован;
- финальный общий вывод по серии отложен до завершения следующих тестов.

---

## Правило ведения этого файла

Для каждого следующего теста фиксировать:
- имя env;
- краткий смысл отключения/паттерна;
- визуальный итог словами пользователя;
- 3-6 ключевых метрик из лога;
- отдельные побочные runtime-наблюдения, если они были;
- без преждевременной финальной сводки до команды пользователя.
# Промежуточный синтез после 6 тестов и post-fix проверки

## Что уже подтверждено

- Исходный локальный дефект обычных часов действительно связан с взаимодействием `calendar + progress + ticker/date`.
- Изолирующие A/B-сборки это подтвердили:
  - `s3_dbg_no_calendar`
  - `s3_dbg_no_progress`
  - `s3_dbg_no_calendar_progress`
  - `s3_dbg_no_ticker_date`
- Узкий layer-fix убрал старые фризы календаря и мерцание последнего пикселя progress bar в обычной `s3` сборке при `voice ON`.

## Что не подтверждено

- Пока не доказано, что `WakeNet` сам по себе "просто слишком тяжёлый" и честно требует второго ядра.
- Пока не доказано, что остаточные подрагивания и искры вызываются тем же самым layer bug.
- Пока не доказано, что нужен перенос speech на `Core 1`. Наоборот, это сейчас считается опасным шагом.

## Новые наблюдения после post-fix прошивки

- При `voice OFF` часть визуальных симптомов возвращается в изменённой форме:
  - подрагивания,
  - цветные искры / ghost-like артефакты,
  - деградация не только часов, но и некоторых визуальных эффектов.
- В режиме `5x3` появился отдельный регресс:
  - ticker/date больше не рисуется в левом/calendar блоке там, где раньше это ожидалось.
- Это означает, что текущий left-clip для overlay оказался слишком грубым и должен стать условным.

## Текущее инженерное разделение

1. Линия A — normal clock layer bug:
   `calendar + progress + ticker/date`.
2. Линия B — voice/audio/runtime instability:
   возможное влияние `AudioCapture` / lifecycle / shared memory pressure / interrupts / render-state coupling.
3. Линия C — single-pixel dynamic ghosting:
   отдельный follow-up, не смешивать с текущей задачей.

## Следующий правильный шаг

- Сначала починить условный `5x3` clipping regression.
- Затем добавить расширенную telemetry для сравнения `voice ON` vs `voice OFF`.
- Отдельно проверить, остаётся ли `AudioCapture` активным или меняет ли `render-state` поведение при `voice OFF`.
- Только после этого решать, нужен ли speech throttling или более глубокая балансировка ресурсов.

---

## Обновление после hash/baseline-диагностики

### Что добавленная telemetry теперь реально показала

- В серию диагностики были добавлены:
  - `frameHash`, `leftRegionHash`, `progressRowHash`;
  - накопительные `fRep/lRep/pRep`;
  - per-heartbeat дельты `fRepD/lRepD/pRepD`;
  - change counters `fChg/lChg/pChg`;
  - явные логи `[VOICE_STATE] ... resetHashBaseline=1 ...`;
  - state transition logs `[PERF][STATE] ... frameHash=... leftHash=... progHash=...`.
- После этого стало видно важное расхождение с прежней гипотезой:
  - при `Voice OFF` визуальный дефект остаётся;
  - но hash-метрики не показывают простого "застывания" логического render-buffer.

### Самое важное новое наблюдение

- Для одинаковых фаз кадра при `Voice ON` и `Voice OFF` final framebuffer перед `matrixShow()` может быть одинаковым.
- Ключевой пример из логов:
  - `dyn=0x07`
  - `frameHash=1616847924`
  - `leftHash=2187437701`
  - `progHash=987181381`
  - эти значения совпали до и после `Voice OFF`.
- Аналогично, после `Voice OFF` продолжают расти и `fChg/lChg/pChg`, то есть логический буфер до `matrixShow()` остаётся живым и меняющимся.

### Что это теперь означает

- Текущие данные уже плохо согласуются с простой версией:
  - "при `Voice OFF` обычный clock-render залипает ещё до `matrixShow()`".
- Более сильная рабочая интерпретация теперь такая:
  - normal clock render path может быть уже корректен для наблюдаемых фаз;
  - оставшийся визуальный дефект сидит ниже pre-present render-buffer;
  - разница между `Voice ON` и `Voice OFF` может определяться не содержимым буфера, а состоянием системы во время scanout/output.

### Какие классы причин теперь стали приоритетнее

При одинаковом framebuffer, но разной визуальной картинке главный подозреваемый смещается ниже render-domain:

- brightness/gamma/output scaling path;
- `matrixShow()` / NeoPixelBus / RMT side effects;
- timing texture physical LED-output path;
- signal / power / ground / matrix behavior;
- или побочный эффект того, что при `Voice ON` активен `AudioCapture/I2S`, а при `Voice OFF` он остановлен.

### Что этим логом теперь ослаблено

Этим этапом больше не выглядит главным объяснением:

- обычный `calendar/progress/ticker` render-order bug;
- simple stale-buffer hypothesis;
- `WakeNet` как прямая причина именно `Voice OFF` симптома;
- `i2s_read timeout` / `audioDrop` / `audioTimeout`;
- классический frame-deadline miss как основное объяснение текущего симптома.

### Новый инженерный verdict по bug-треку

Сейчас правильнее считать так:

1. Исходный normal-clock layer bug действительно существовал и уже был локально подтверждён/частично исправлен.
2. Остаточный дефект "хуже при `Voice OFF`" по новым hash-логам уже не выглядит как простой pre-`matrixShow()` render freeze.
3. Главная открытая линия теперь:
   - влияние состояния `aud=1/mask=0x02` против `aud=0/mask=0x00`,
   - и поиск отличий в output path, а не только в содержимом логического буфера.

### Что делать дальше по этой линии

Следующий диагностический шаг должен проверять уже не `voiceEnabled` сам по себе, а именно роль активного `AudioCapture/I2S`:

1. `Voice OFF` + принудительно активный `AudioCapture`, но без speech activity.
2. `Voice ON` + принудительно неактивный `AudioCapture`, если это можно сделать безопасным debug-способом.
3. Дополнительно полезна output-side telemetry:
   - `brightness`;
   - `bgBrightness`;
   - `effectiveBrightness`;
   - hash/метка post-brightness или post-scanout staging buffer, если такой debug seam появится.

### Подготовленные debug env для следующего A/B

- `s3_voice_off_audio_forced_on`
  - `voiceEnabled=false` по boot-default;
  - `AudioCapture/I2S` принудительно активен через shared audio owner path;
  - цель: проверить, исчезает ли визуальный дефект при `aud=1`, даже когда voice/speech path не должен работать.
- `s3_voice_on_audio_forced_off`
  - `voiceEnabled=true` по boot-default;
  - `AudioCapture/I2S` принудительно отключён;
  - цель: проверить, появляется ли дефект при `aud=0`, даже когда `voiceEnabled` остаётся включённым;
  - это чисто diagnostic build, не production-режим.

### Чего не делать по этому verdict'у

- Не продолжать вслепую "чинить clock render" только по симптому `Voice OFF`.
- Не объявлять `WakeNet` корнем проблемы без новой A/B-проверки.
- Не смешивать этот трек с отдельным `single_pixel` ghosting investigation.

---

## Обновление после A/B по `audioCaptureActive`

### Что теперь уже подтверждено на железе

Проведены два перекрёстных теста:

1. `s3_voice_off_audio_forced_on`
   - `voiceEnabled=0`
   - `speech/WakeNet` не активен
   - `aud=1`
   - `mask=0x01`
   - визуально фризы не наблюдаются

2. `s3_voice_on_audio_forced_off`
   - `voiceEnabled=1`
   - `AudioCapture/I2S` принудительно выключен
   - `aud=0`
   - `mask=0x00`
   - визуально вернулись фризы, цветные искры, дёргание календаря и последнего пикселя progress bar

### Жёсткий вывод этой серии

- Остаточный визуальный дефект следует не за `voiceEnabled`, а за состоянием:
  - `audioCaptureActive / I2S active`
- То есть:
  - `Voice OFF + AudioCapture ON` -> чисто
  - `Voice ON + AudioCapture OFF` -> дефект возвращается

### Что этим теперь резко ослаблено

После этой A/B-пары уже не выглядит главным корнем:

- `clock render` как первопричина текущего остаточного симптома;
- `calendar/progress/ticker` как главный bug path этой конкретной деградации;
- `speech/WakeNet` как первопричина;
- простой stale-framebuffer сценарий;
- обычный frame timing / `frameMiss` / `audioDrop` / `audioTimeout`.

### Новый архитектурный verdict

`AudioCapture/I2S` надо считать общей сервисной инфраструктурой, а не частью самой voice-функции.

Правильная модель:

- `AudioCaptureService`
  - владеет `I2S`
  - публикует shared PCM/audio stream
  - живёт как инфраструктурный backend
- клиенты потока:
  - `Voice/WakeNet`
  - `Spectrum/ReactiveSound`
  - debug/lab path
  - при необходимости отдельный keepalive/stability client

### Что в текущей lifecycle-policy было слишком грубым

Сейчас фактически происходило:

- `Voice OFF`
  - voice client снимается
  - `clientMask` падает в `0`
  - shared `AudioCapture` останавливается
  - `I2S` выключается

Но по результатам теста это слишком жёсткая policy.

Правильнее:

- `Voice OFF`
  - выключает `speech/WakeNet`
  - отключает именно voice-consumer
  - но не обязан останавливать общий `AudioCapture/I2S` backend

### Практический временный fix, который теперь выглядит обоснованным

Для production-stability следующий безопасный workaround выглядит уже не как догадка, а как подтверждённый шаг:

- держать `AudioCapture/I2S` активным даже при `Voice OFF`;
- при этом `speech/WakeNet` оставлять выключенным;
- если нет активного полезного consumer-а, shared audio backend может просто читать frame-ы и discard-ить их.

Коротко:

- `Voice OFF` != `AudioCapture OFF`
- `Voice OFF` = `Voice consumer OFF`

### Следующий правильный шаг после этого verdict'а

1. Сначала внедрить production-safe lifecycle fix:
   - keepalive/shared-audio policy при `Voice OFF`
2. Затем отдельным узким треком искать настоящий низкоуровневый корень:
   - PM / Wi-Fi sleep / DFS / clocking
   - output-side behavior после stop `I2S`
   - peripheral-state side effect при `AudioCapture inactive`

### Следующий approved diagnostic env

- `s3_pm_stability_test`
  - `voiceEnabled=false`
  - `AudioCapture/I2S` forced OFF
  - `Wi-Fi sleep` forced OFF
  - код включает:
    - `WiFi.setSleep(false)`
    - `esp_wifi_set_ps(WIFI_PS_NONE)`
  - цель:
    - проверить, исчезает ли `aud=0`-дефект без keepalive I2S, если удержать Wi-Fi/PM state в более стабильном режиме

### Production-fix status

- Production lifecycle fix по этой линии уже внедрён в `env:s3`:
  - shared `AudioCapture` теперь держится живым через keepalive client;
  - `Voice OFF` выключает `speech/WakeNet` как consumer, но не обязан останавливать `I2S` backend;
  - debug env с forced audio OFF по-прежнему сохраняются как отдельные diagnostic split builds.
### Toggle-transition follow-up

- После production keepalive fix старый постоянный `Voice OFF -> aud=0` freeze-path больше не считается активным.
- Остался только более узкий residual bug: occasional visual hiccups during rapid `Voice ON/OFF` toggling.
- Следующий fix-path для этой линии: transition smoothing (`coalesced/deferred` apply) и вынос подробной toggle-диагностики из обычного production `s3`.
### Current closure status

- Main freeze source for this line is considered established: stopping shared `AudioCapture/I2S` was the strongest trigger for the old `Voice OFF` artifacts.
- Production keepalive policy in normal `s3` has practically neutralized the main defect.
- Additional transition smoothing, stricter debounce/cooldown, and UI/API single-flight reduced the remaining residual toggle hiccups, but did not eliminate every rare artifact under aggressive spam-clicking.
- At the same time, one of the late hardening passes introduced a fresh regression in the UI toggle path:
  - `Voice ON` could bounce back to `OFF` because the first single-flight guard was too aggressive;
  - this regression was created during the fix work itself, not inherited from the original freeze bug;
  - it was later corrected only after an external diagnosis round (`ChatGPT`, partially `Grok`) coordinated by the user, with the user doing the hardware testing and validation.
- This line is therefore closed for now as "practically neutralized at current architecture stage", with explicit re-test required after final architecture cleanup / end-state validation.
