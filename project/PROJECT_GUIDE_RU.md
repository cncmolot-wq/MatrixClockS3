> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

> Важно: перед правкой этого файла сначала ознакомься с файлами в папке `docs/project/`, чтобы сохранить синхронизацию документации.

# <span style="color:#4EA1FF;">MatrixClock</span>

<p>
  <strong><span style="color:#4EA1FF;">ESP32-S3</span></strong>
  <span style="color:#8AA4C8;">+</span>
  <strong><span style="color:#FF9B5E;">WS2812 32x8</span></strong>
  <span style="color:#8AA4C8;">+</span>
  <strong><span style="color:#67C587;">Web UI</span></strong>
  <span style="color:#8AA4C8;">+</span>
  <strong><span style="color:#D98BFF;">OTA</span></strong>
</p>

> <span style="color:#AEBFD7;">MatrixClock — это прошивка часов для `ESP32-S3` и светодиодной матрицы `32x8` на `WS2812` с веб-интерфейсом, NTP-синхронизацией, OTA-обновлением, поддержкой датчиков и единым режимом огня `Fire` на базе файловой анимации из `LittleFS`.</span>

---

## <span style="color:#4EA1FF;">Обзор</span>

**MatrixClock** — это актуальная рабочая прошивка часов для матрицы `32x8`, собранная вокруг `ESP32-S3`.

Текущий фокус проекта:
- аккуратный рендер часов на компактной LED-матрице
- настройка через браузер
- OTA-обновление прошивки
- NTP-синхронизация времени
- дополнительные экраны с датчиками
- спектрум-режимы
- один финальный режим огня: `Fire`, работающий от файловой анимации в `LittleFS`
- проект сознательно не расширяется новыми пользовательскими функциями, пока не будет закрыт `Stage 1`

Этот репозиторий отражает **текущее состояние проекта**, а не архив старых экспериментов. Старые процедурные ветки огня и промежуточный генерационный мусор были убраны в пользу текущей runtime-схемы.

Текущая контрольная точка:
- фундамент `Stage 1` уже в основном собран
- но продуктовый Wi-Fi onboarding, переносимый OTA path и остаточные кодировочные хвосты ещё не считаются окончательно закрытыми, хотя cleanup runtime-entrypoints уже начат

---

## <span style="color:#4EA1FF;">Контур проекта</span>

В проекте теперь есть явный контур согласованности:

- перед правкой файлов сначала читается документация из `docs/project/`
- после значимых изменений при необходимости обновляется документация
- после любых многострочных scripted edits запускается `scripts/check_literal_newlines.ps1`
- общие правила этого контура описаны в [`PROJECT_EDIT_RULES.md`](./PROJECT_EDIT_RULES.md)
- async lifecycle рассматривается как важная зона риска и описывается по подсистемам, а не через автоматическое навязывание одной глобальной state machine
- если важная политика или механизм добавлены в `PLAN` / `RULES`, их короткое пояснение тоже должно появиться в `PROJECT_GUIDE_RU.md`
- рабочий живой контур документации сейчас ведётся в русской ветке; английская ветка отложена до стадии финального перевода и не обновляется на каждом шаге
- shell-команды должны использоваться через стабильные повторяемые шаблоны, чтобы сохранённые разрешения не расползались по множеству почти одинаковых вариантов
- кодовые сущности и технические идентификаторы не переводятся; обязательная полная русификация относится прежде всего к русскому UI и русскоязычному объяснительному слою
- экономия ресурса считается правилом проекта, но только там, где она не ухудшает надёжность, проверку и качество результата
- внешний обычный ChatGPT допускается как дешёвый draft-worker для узких локальных задач, но финальные решения, интеграция, проверка и документальная синхронизация остаются за Codex
- для внешнего GitHub-пакета нужно различать локальные пути `docs/...` и удалённые опубликованные пути `project/...` / `chatgpt_git/...`; эти две схемы не должны смешиваться в одном наборе ссылок
- опорный GitHub-репозиторий и правило сверки удалённых путей зафиксированы в [`GIT_REPO_REFERENCE_RU.md`](./GIT_REPO_REFERENCE_RU.md)
- публикация в GitHub не считается автоматической частью локальной правки: после изменений пользователь сам перезаливает опубликованные папки `chatgpt_git` и `project`
- не каждая локальная правка обязана обновлять все слои документации: `PROJECT_GUIDE_RU.md` обновляется только если меняется человечески важный смысл, `PLAN` — если меняется техническое решение или статус, а `docs/chatgpt_git` — только если меняется внешний ChatGPT/GitHub workflow
- пока `Stage 1` открыт, вторичная полировка и расширение scope не считаются хорошим default-ходом, если они не помогают закрыть текущий этап
- у каждой документной роли должен быть один канонический дом; конкурирующие дубли считаются ошибкой процесса

Это помогает удерживать связность между кодом, конфигом и историей решений.

Текущая инженерная дисциплина:
- сначала закрывается фундамент (`Stage 1`)
- затем добавляются минимальные runtime-метрики
- и только после этого проект идёт в следующую архитектурную волну

Структура папки `docs`:
- `docs/project` — только проектная документация, правила, план, справки по плате и Git reference
- `docs/chatgpt_git` — только внешний ChatGPT/GitHub пакет
- GPT-файлы не должны дублироваться в `docs/project`
- проектные файлы не должны расползаться в `docs/chatgpt_git`
- `docs/chatgpt_git` не обновляется на каждый локальный кодовый шаг; этот пакет меняется только при изменении внешнего workflow, GitHub-ссылок или cheap draft-worker контракта
- текст, который вставляется в `Project Instructions` обычного ChatGPT, должен браться из `docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`, а не правиться как отдельная третья копия
- если настройки внешнего ChatGPT меняются, сначала правится канонический файл, а уже потом пользователь вручную обновляет текст в интерфейсе ChatGPT и опубликованный GitHub-пакет

---
## <span style="color:#4EA1FF;">Роль Project Guide</span>

- `PROJECT_GUIDE_RU.md` — человеческий путеводитель по проекту.
- Это не формальная инструкция и не технический источник истины, а разговорный объяснительный слой для понимания проекта человеческим языком.
- Он объясняет, что есть в проекте сейчас, как этим пользоваться и в каком направлении проект развивается.
- Он не должен хранить полную техническую историю всех внутренних правок.
- Источником истины для технической истории, статусов этапов и фиксации решений считается [`REFACTOR_PLAN_RU.md`](./REFACTOR_PLAN_RU.md).
- Для быстрой ориентации по структуре репозитория используется отдельная карта [`PROJECT_TREE_RU.md`](./PROJECT_TREE_RU.md).
- Пока проект активно меняется, именно русская документация считается живой и обязательной к синхронизации; английская ветка будет переводиться пакетно, когда проект станет стабильнее.

---

## <span style="color:#67C587;">Текущие возможности</span>

### <span style="color:#4EA1FF;">Часы и UI</span>
- шрифты `3x5`, `4x7`, `5x7`
- режимы анимации двоеточия
- режимы progress bar
- web UI из `LittleFS`
- web UI перестроен на вкладки для более короткой и управляемой навигации
- сохранение настроек через `Preferences`
- ручной выбор timezone
- auto-detect timezone через браузер и IP path

### <span style="color:#FF9B5E;">Визуальные режимы</span>
- spectrum bars
- waterfall
- symmetric spectrum
- VU meter
- `Fire` на базе файловой анимации: `data/anim/fire_32x8_v1.anim`
- audio async теперь имеет явный runtime-status (`idle` / `starting` / `running` / `stopping` / `error`) вместо неявного старта FFT-задачи

### <span style="color:#67C587;">Сеть и время</span>
- подключение к Wi-Fi
- backend-основа для AP onboarding: AP fallback, Wi-Fi scan и browser-side config endpoints
- browser-side Wi-Fi onboarding panel в Web UI: status, scan, SSID/password, save, save+reboot
- Wi-Fi onboarding теперь валидирует базовую корректность SSID/password и не уходит в reboot при явно плохой конфигурации
- Wi-Fi onboarding в AP-режиме теперь умеет планировать живую попытку перехода в пользовательскую сеть без обязательного reboot: конфиг сохраняется, после ответа Web UI запускается apply-path, а при неудаче setup AP остаётся активной
- Wi-Fi onboarding теперь отдаёт явный `applyState` (`scheduled` / `connecting` / `succeeded` / `failed`), а Web UI показывает живой статус попытки подключения вместо немого ожидания
- файловая система теперь имеет явный runtime-status (`mounted` / `missing_content` / `unmounted`) вместо неявного поведения
- OTA теперь имеет явный runtime-status и отложенный reboot после успешного обновления, чтобы сетевой обмен успевал завершиться корректно
- Wi-Fi теперь тоже имеет явный status message, а OTA корректно переинициализируется после разрыва и возврата соединения
- dev OTA-кнопка в `platformio.ini` сейчас привязана к стабильному IP часов, а не к `matrixclock.local`, потому что Windows/mDNS в этом workflow резолвится нестабильно
- этот OTA IP path считается dev-стабилизацией, а не финальной продуктовой схемой, и позже должен быть либо вынесен в local override, либо заменён на более переносимый discoverable OTA path
- NTP-синхронизация
- web-интерфейс
- OTA-обновление прошивки
- OTA-обновление файловой системы
- нормализация timezone и её сохранение в `Preferences`
- минимальные runtime-метрики через backend: `frameTimeUs`, `frameTimeAvgUs`, `freeHeapBytes`
- display/runtime contour теперь тоже имеет явный backend-status: `waiting_for_time`, `ip_overlay`, `clock_fade_in`, `running_clock`, `running_spectrum`

### <span style="color:#D98BFF;">Датчики</span>
- поддержка `AHT20`
- поддержка `BMP280`
- асинхронный опрос датчиков
- sensor async теперь имеет явный runtime-status (`idle` / `starting` / `running` / `stopping` / `error`) вместо неявного старта “на доверии”
- экраны температуры / влажности / давления

---

## <span style="color:#FF9B5E;">Железо</span>

### <span style="color:#4EA1FF;">Целевой модуль</span>
- `ESP32-S3`
- ожидаемый класс модуля: `N16R8`
- flash: `16MB`
- PSRAM: `8MB`

### <span style="color:#4EA1FF;">Матрица</span>
- тип: `WS2812`
- размер: `32x8`
- data pin: `GPIO12`
- модель рендера: буферизованный вывод через `NeoPixelBus`

### <span style="color:#4EA1FF;">Аудиовход</span>
- микрофон подключается по I2S
- текущие I2S-пины заданы в `src/audio/spectrum_async.cpp`

### <span style="color:#4EA1FF;">Датчики</span>
- сенсорный блок работает через I2C
- текущая реализация поддерживает `AHT20` и `BMP280`

---

## <span style="color:#67C587;">Структура проекта</span>

```text
src/
  audio/              Спектр и асинхронный FFT task
  effects/            Цифры, двоеточие, progress bar, инфо-экраны
  hardware/           Матрица и NTP-логика
  sensors/            Датчики и асинхронный sensor task
  ui/                 Web server и сохранение состояния
  system_services.*   Стартовые сервисы, Wi-Fi, OTA, FS
  sensor_bootstrap.*  Безопасный bootstrap датчиков
  display_runtime.*   IP overlay, fade-in и диспетчер экранного runtime
  main.cpp            Главный runtime приложения

data/
  index.html          Web UI
  anim/               Runtime-анимации для LittleFS

boards/
  matrixclock_esp32s3_n16r8.json
```

---

## <span style="color:#D98BFF;">Build Environments</span>

Определены в [`platformio.ini`](./platformio.ini):

- `s3` — сборка и прошивка по USB
- `s3ota` — прошивка по OTA

Текущий board profile:
- `matrixclock_esp32s3_n16r8`

Текущая partition table:
- `partitions_ota_16mb.csv`

Текущая файловая система:
- `LittleFS`

Локальный путь для будущего выноса machine-specific OTA-настроек:
- `platformio.local.ini.example`

---

## <span style="color:#4EA1FF;">Build и Upload</span>

### <span style="color:#67C587;">Прошивка по USB</span>

```powershell
pio run -e s3 -t upload
```

### <span style="color:#67C587;">Файловая система по USB</span>

```powershell
pio run -e s3 -t uploadfs
```

### <span style="color:#D98BFF;">Прошивка по OTA</span>

```powershell
pio run -e s3ota -t upload --upload-port 192.168.x.x
```

Если OTA дошивает устройство, но PlatformIO/VS Code показывает ложный `FAILED` уже после `100% Done`, причина может быть в host-side баге `espota.py`, а не в самой прошивке часов. Для текущей рабочей машины этот баг уже локально обойдён.

### <span style="color:#D98BFF;">Файловая система по OTA</span>

Используй отдельный OTA-сценарий обновления FS, который уже настроен в проекте.

---

## <span style="color:#FF9B5E;">Web Interface</span>

После подключения часов к Wi-Fi открой устройство по его локальному IP, например:

```text
http://192.168.x.x
```

Через web UI можно менять:
- яркость
- шрифт
- режим двоеточия
- режим progress bar
- интервал глаз
- интервал датчиков
- спектр / огонь
- gain
- overlay interval
- timezone
- цвета

Дополнительно в backend уже подготовлены Wi-Fi endpoints для следующего продуктового шага:
- `/wifi-status`
- `/wifi-scan`
- `/wifi-config`

---

## <span style="color:#FF9B5E;">Режим огня</span>

В проекте теперь остался **один финальный режим огня**:

- имя режима: `Fire`
- источник: файловая анимация в `LittleFS`
- runtime-ассет: `data/anim/fire_32x8_v1.anim`
- визуальный source reference: `png/fire_32x8_v1.gif`

Почему победил именно этот вариант:
- он выглядит лучше старого процедурного огня
- у него предсказуемое runtime-поведение
- он не раздувает код гигантскими animation header'ами
- он лучше ложится на текущую архитектуру проекта

Это и есть канонический путь огня в текущем MatrixClock.

---

## <span style="color:#4EA1FF;">N16R8 Board Profile</span>

Для отдельного технического разбора по нашей плате смотри:

- [`N16R8_PROFILE_BIBLE_RU.md`](./N16R8_PROFILE_BIBLE_RU.md)

В этом документе зафиксировано:
- почему стандартный профиль вёл себя как `8MB`
- как был создан рабочий custom board profile
- почему важна своя partition table
- почему `LittleFS` требовал раздел с именем `spiffs`

---

## <span style="color:#67C587;">Синхронизация с планом</span>

Этот путеводитель синхронизирован с [`REFACTOR_PLAN_RU.md`](./REFACTOR_PLAN_RU.md) по следующим точкам:

- единый режим `Fire`
- работающий `LittleFS`
- работающий OTA path
- timezone support в UI и backend
- начало разгрузки `main.cpp` через отдельные service-модули
- вынос display/runtime orchestration в `display_runtime.*`
- отдельная техпамятка по `N16R8` board profile

Если эти пункты меняются, сначала фиксируется техническая запись в плане, затем кратко отражается здесь.

---

## <span style="color:#67C587;">Примечания</span>

### <span style="color:#4EA1FF;">Wi-Fi</span>
Текущий режим разработки допускает жёсткий dev bootstrap SSID/password, чтобы часы сразу поднимались в рабочей сети разработчика.
При этом продуктовая логика уже отделяется от dev-режима: сохранённые credentials хранятся в persisted state и будут использоваться как основной путь для пользовательской сети.
Финальная цель для этого контура: часы поднимают AP, сканируют доступные Wi-Fi сети, позволяют через браузер выбрать сеть, ввести пароль и после reboot подключаются уже к сети пользователя.

---

## <span style="color:#D98BFF;">Дорожная карта</span>

Текущий план стабилизации и рефакторинга проекта лежит в:

- [`REFACTOR_PLAN_RU.md`](./REFACTOR_PLAN_RU.md)

Там описаны исходные стадии, их живой статус, журнал изменений и изменения ценности задач по мере развития проекта.
Дополнительно в плане уже зафиксированы долгосрочные архитектурные направления:
- более явный frame pipeline
- возможная унификация эффектов
- будущий preload `Fire` анимации в RAM / PSRAM
- будущие runtime-метрики для контроля кадра

Эти идеи не считаются срочными до закрытия `Stage 1`, но уже встроены в roadmap как будущие инженерные слои.

---

## <span style="color:#4EA1FF;">Внешний ChatGPT</span>

Если нужно экономить ресурс, внешний обычный ChatGPT используется не как второй архитектор, а как дешёвый генератор локальных patch-заготовок.

Для этого в проекте подготовлены:
- [`docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`](../chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md) — готовая короткая инструкция для настроек проекта в обычном ChatGPT
- [`docs/chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`](../chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md) — шаблон точной задачи
- GitHub-ссылки на проектные документы уже встроены в эти два файла, чтобы внешний ChatGPT мог опираться на удалённые правила, если умеет читать ссылки

Внешний publish/runtime-пакет теперь сознательно ужат до двух файлов:
- [`docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`](../chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md)
- [`docs/chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`](../chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md)

Рабочая схема:
- сначала формируется узкая локальная задача
- затем внешний ChatGPT даёт минимальный patch-кандидат
- потом Codex проверяет, встраивает, собирает и синхронизирует документацию

---

## <span style="color:#4EA1FF;">Статус</span>

<span style="color:#67C587;"><strong>Текущее состояние:</strong></span>
- board profile выровнен под `N16R8`
- web UI работает из `LittleFS`
- OTA работает
- timezone path работает
- единый режим `Fire` финализирован
- старые fire-ветки убраны
- проект уже не просто готов к рефакторингу, а находится в процессе поэтапного рефакторинга

