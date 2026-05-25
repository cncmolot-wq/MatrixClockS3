> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

> Важно: перед правкой этого файла сначала ознакомься с файлами в папке `docs/project/`, чтобы сохранить синхронизацию документации.

# <span style="color:#4EA1FF;">MatrixClock Project Plan</span>

<p>
  <strong><span style="color:#4EA1FF;">Рабочая карта проекта</span></strong>
  <span style="color:#8AA4C8;">·</span>
  <strong><span style="color:#67C587;">Refactor</span></strong>
  <span style="color:#8AA4C8;">·</span>
  <strong><span style="color:#FF9B5E;">Cleanup</span></strong>
  <span style="color:#8AA4C8;">·</span>
  <strong><span style="color:#D98BFF;">Event Log</span></strong>
</p>

> <span style="color:#AEBFD7;">Этот файл — основа проекта для дальнейшей работы. Здесь фиксируется текущее состояние, план изменений, выполненные этапы, удалённые хвосты и события по мере развития MatrixClock.</span>

---

## <span style="color:#4EA1FF;">Правила использования</span>

- Этот файл считается рабочей картой проекта.
- После заметных изменений сюда можно добавлять краткие записи о том, что сделано.
- Удалённые хвосты и старые ветки тоже фиксируются здесь, чтобы было понятно, почему они исчезли.
- Если направление проекта меняется, сначала обновляется этот файл, потом код.

---

## <span style="color:#4EA1FF;">Правило редактирования проекта</span>

- Глобальное правило проекта зафиксировано в [`PROJECT_EDIT_RULES.md`](./PROJECT_EDIT_RULES.md).
- Это не декоративная строка, а координационный контракт между кодом, документацией и правками.
- Цель правила — удерживать проект в связном состоянии при ручных правках и AI-assisted разработке.
- Это правило дополняет процесс, но не заменяет сборку, проверку и архитектурное мышление.
- Внутри этого правила теперь отдельно зафиксирован `Project Guide mirror check`: важные политики и механизмы из `PLAN` / `RULES` должны коротко отражаться и в `PROJECT_GUIDE_RU.md`.

---
## <span style="color:#4EA1FF;">Модель документации</span>

- `PROJECT_GUIDE_RU.md` — человеческий путеводитель по проекту: что это, как устроено, что умеет, куда движется.
- `REFACTOR_PLAN_RU.md` — технический слой: стадии, журнал изменений, фиксация решений, статус по этапам и ценность задач.
- `PROJECT_GUIDE_RU.md` не должен спорить с планом.
- План не должен переписывать уже зафиксированную историю, а только дополнять её.
- Пока проект находится в активной инженерной фазе, живая обязательная синхронизация ведётся только в русской документации.
- Английская ветка документации считается отложенным переводным слоем и не должна обновляться на каждом локальном шаге рефактора.
- Если функция, решение или направление устарели, это отмечается отдельной записью, а не тихой заменой старого смысла.
- Любые документы с русским текстом должны создаваться и сохраняться только в UTF-8 без смешивания с Windows-1251.
- Буквальные backtick-r-backtick-n последовательности не должны оставаться в текстовых файлах проекта как видимый текст после правок; переносы должны быть настоящими переносами строк.
- После любых многострочных scripted edits и массовых замен обязательно запускается `scripts/check_literal_newlines.ps1`.
- Для shell-работы должна соблюдаться дисциплина стабильных command-prefix patterns: чем меньше лишнего разнообразия в формах команд, тем лучше работают сохранённые разрешения и тем меньше лишних запросов в процессе.
- Язык программирования и технические идентификаторы не переводятся; переводится человеческий слой — комментарии, объяснения, русская документация и русский UI.
- Для русских комментариев PowerShell и терминал не считаются источником истины: их нельзя массово “чинить” только по консольному mojibake, пока сам файл не подтверждён как реально повреждённый.
- Экономия ресурса является частью проектной дисциплины, но не допускается за счёт надёжности, верификации и качества продукта.
- Внешний обычный ChatGPT допускается только как дешёвый draft-worker для локальных задач; финальная интеграция, проверка, архитектурное решение и документальная синхронизация остаются за Codex.
- Структура `docs` должна оставаться однозначной: `docs/project` — проектный источник истины, `docs/chatgpt_git` — внешний ChatGPT/GitHub пакет, без конкурирующих дублей между этими папками.
- У каждой документной роли должен быть один канонический дом; конкурирующие копии считаются ошибкой процесса, а не нормальным запасным вариантом.
- Не каждая локальная правка обязана обновлять все документные слои: `PROJECT_GUIDE_RU.md` обновляется по смыслу для человека, `PLAN` — по техническому статусу и решениям, `docs/chatgpt_git` — только при изменении внешнего workflow.
- Пока активная стадия не закрыта, вторичная полировка, лишние process-слои и новые пользовательские расширения не должны получать приоритет над задачами, закрывающими текущий stage.

---

## <span style="color:#4EA1FF;">Текущее состояние</span>

- Платформа: `ESP32-S3`
- Целевой модуль: `N16R8`
- Матрица: `WS2812 32x8`
- Board profile выровнен под `N16R8`
- `LittleFS` работает
- Web UI работает
- OTA работает
- Optional `DS3231` RTC layer добавлен и подтверждён на железе
- Огонь оставлен один: `Fire`
- `Fire` работает через файловую анимацию из `LittleFS`
- Старые процедурные ветки огня удалены

---

## <span style="color:#FF9B5E;">Направление проекта</span>

Текущий курс проекта:
- сохранить рабочую базу часов
- сделать часы автономными как часы: корректное время не должно зависеть от интернета
- считать интернет сервисным расширением, а не фундаментом устройства: радио, погода, уведомления, Web UI, OTA и NTP-коррекция
- не раздувать код старым мусором и экспериментальными хвостами
- держать визуальную часть аккуратной и управляемой
- улучшать архитектуру без потери рабочего результата

---

## <span style="color:#D98BFF;">Master Plan</span>

### <span style="color:#4EA1FF;">Stage 1 — Стабилизировать основу</span>

- Ввести единый слой валидации состояния и настроек
- Убрать жёсткую зависимость старта от Wi-Fi
- Сделать recovery `LittleFS` безопасным и предсказуемым
- Убрать мелкие runtime-риски и спорные костыли

**Статус:** <span style="color:#67C587;">PASS with hardware note</span>

---

### <span style="color:#4EA1FF;">Stage 2 — Разгрузить архитектуру</span>

- Разделить `main.cpp` по зонам ответственности
- Собрать глобальное состояние в понятные структуры
- Разделить выбор сцены и сам рендер
- Привести async-task lifecycle к нормальному виду

**Статус:** <span style="color:#FFB347;">In Progress</span>

---

### <span style="color:#4EA1FF;">Stage 3 — Довести поддерживаемость</span>

- Сделать конфиг проекта переносимым
- Разделить debug и release окружения
- Дочистить дерево проекта
- Добавить компактную самодиагностику

**Статус:** <span style="color:#FFB347;">Pending</span>

---

## <span style="color:#67C587;">Поверх статического плана</span>

> <span style="color:#AEBFD7;">Этот блок не переписывает исходный Master Plan, а накладывает поверх него живой статус проекта по мере развития.</span>

### <span style="color:#4EA1FF;">Текущий прогресс по стадиям</span>

- `Stage 1` — <span style="color:#67C587;">закрыт по прошивке, с аппаратной оговоркой по текущей dev board</span>
  - добавлена валидация runtime/state значений в `state.cpp` и `webserver.cpp`
  - runtime state normalization теперь проходит через единый слой в `state.*`, а не дублируется между `loadState()` и `/update`
  - старт по Wi-Fi больше не блокирует прошивку навсегда
  - Wi-Fi credentials вынесены в persisted state, а dev bootstrap путь отделён от продуктового сценария
  - backend-основа для продуктового Wi-Fi contour уже начата: AP fallback, scan/status/config endpoints
  - browser-side Wi-Fi onboarding panel уже встроена в Web UI, а сохранение credentials для reboot идёт без debounce-рискa
  - Wi-Fi onboarding теперь имеет базовую валидацию конфигурации и не делает `Save & reboot` при заведомо плохом SSID/password
  - Wi-Fi onboarding в AP-режиме теперь умеет запускать живой apply-path без обязательного reboot: конфиг сначала сохраняется и подтверждается через Web UI, затем часы сами пытаются перейти в пользовательскую сеть, а при неудаче сохраняют setup AP активной
  - Wi-Fi onboarding теперь отдаёт явный `applyState` и показывает живой статус попытки подключения вместо немого ожидания после `Connect now`
  - Wi-Fi scan теперь работает через async backend и короткий cache, чтобы setup AP не подвисал от тяжёлого синхронного scan и повторных запросов UI
  - Wi-Fi runtime transitions after `disconnect` переведены на отложенное неблокирующее исполнение внутри `wifi_service.*`: setup AP, stored-credentials apply и закрытие setup AP больше не держат hot path на `delay(100)`
  - Wi-Fi credentials теперь явно закреплены как persisted config в `Preferences` / `NVS`, отдельный от `firmware` и `LittleFS` слой, который не должен теряться при обычных апдейтах
  - добавлен физический recovery path: удержание кнопки на `GPIO21` во время старта очищает сохранённые Wi-Fi credentials и принудительно уводит устройство в setup AP
  - Wi-Fi recovery теперь сохраняет forced setup AP state, чтобы после обычного reset устройство не возвращалось в dev bootstrap сеть до ввода новых credentials
  - setup AP режим теперь сам показывает на матрице `AP:` и адрес `192.168.4.1`, чтобы первичная настройка была понятна без внешней инструкции
  - Web UI получил tabbed navigation, чтобы длинный single-column layout не мешал дальнейшему росту проекта
  - `LittleFS` теперь имеет явный runtime-state и наружный status endpoint, а не остаётся неявным сервисом с угадываемым состоянием
  - OTA lifecycle теперь имеет явный runtime-state и отложенный reboot после успешного апдейта вместо слишком раннего рестарта сразу после OTA success
  - `Wi-Fi / OTA` lifecycle теперь имеет явные runtime messages и корректный переход через disconnect/reconnect, чтобы OTA не застревала в старом initialized-состоянии после потери сети
  - `sensor async` теперь имеет явный runtime-state, безопасный stop-path и наблюдаемый state через web layer вместо неявной task-схемы “на доверии”
  - `audio async` теперь тоже имеет явный runtime-state, безопасный stop-path и наблюдаемый state через web layer вместо немого старта FFT task
  - audio start failures теперь не должны вызывать loop-level thrash: retry path для `spectrum_async` проходит через cooldown/backoff, а не через попытку рестарта на каждом кадре при сломанном I2S/микрофоне
  - microphone ownership больше не должен жить как скрытый побочный эффект одного `spectrumMode`: shared audio capture теперь вынесен в отдельный сервисный слой, а `spectrum` и будущий `voice` должны быть его клиентами
  - `display runtime` теперь тоже имеет явный runtime-state и message через `/state`, так что IP overlay / fade-in / clock / spectrum больше не являются скрытым внутренним поведением без наблюдаемого статуса
  - введён минимальный runtime metrics layer: `frameTimeUs`, `frameTimeAvgUs`, `freeHeapBytes` теперь отдаются через `/state` как базовый инженерный контроль
  - `LittleFS` больше не форматируется молча при первом сбое монтирования
  - инициализация датчиков переведена на безопасные повторные попытки
- `Stage 2` — <span style="color:#67C587;">частично выполнен</span>
  - стартовые сервисы вынесены в `system_services.*`
  - bootstrap датчиков вынесен в `sensor_bootstrap.*`
  - `main.cpp` уже разгружен, а display/runtime orchestration вынесена в `display_runtime.*`; файл всё ещё крупный, но больше не держит на себе весь экранный flow целиком
  - calendar/date/sensor visual helpers, обычная clock-face отрисовка и slide clock-face отрисовка вынесены из `main.cpp` в `clock_visuals.*`; это ещё не завершает Stage 2, но делает entry-файл заметно ближе к роли coordinator-only
  - `renderClock()` вынесен из `main.cpp` в `clock_runtime.*`; теперь `main.cpp` держит в основном глобальное состояние, `setup()` и `loop()`, а clock-phase runtime живёт отдельно
  - shared runtime-state и глобальные runtime-объекты вынесены из `main.cpp` в `app_state.*`; `main.cpp` теперь фактически держит только `setup()` и `loop()`
  - `LittleFS` runtime вынесен в `filesystem_service.*`; `system_services.*` больше не хранит внутреннее FS-состояние напрямую
  - OTA lifecycle вынесен в `ota_service.*`; Wi-Fi слой только поднимает/останавливает OTA по сетевым событиям
  - Wi-Fi contour вынесен в `wifi_service.*`, а HTTP endpoints Wi-Fi вынесены в `ui/wifi_routes.*`
  - `Fire` playback вынесен из `spectrum.cpp` в `effects/fire_animation.*`, сохранив preload `.anim` в RAM / PSRAM
  - optional RTC слой вынесен в `rtc_service.*`; одна прошивка должна работать и с модулем `DS3231`, и без него
  - добавлен MVP-вывод погоды на матрицу как отдельный online-блок: `ПОГОДА`-заставка, затем current weather (`8x8` иконка + температура), humidity, pressure, wind и короткое словесное состояние; блок отделён от локальных sensor cards и живёт в отдельные overlay-минуты, использует только cached `WeatherSnapshot`, без новых fetch path и без новых настроек
  - weather snapshot расширен под взрослый runtime: в прошивку добавлены `is_day`, `cloud_cover`, `wind_direction_10m`, `wind_gusts_10m`, `precipitation`, `visibility`; матрица теперь различает day/night, показывает более человеческое состояние погоды и использует отдельные weather-иконки, а не повторяет символы локальных датчиков
  - weather block получил собственные user settings в Web UI: `on/off`, отдельную cadence и режим `compact/full`; weather runtime больше не привязан к `sensorInterval`, а при совпадении одной минуты с локальными датчиками получает приоритет как отдельный online-сценарий
- `Stage 3` — <span style="color:#FFB347;">частично задет</span>
  - удалены временные файлы и мёртвые code paths
  - `platformio.ini` приведён в чистый вид
  - machine-specific OTA настройки больше не живут в основном `platformio.ini`: они вынесены в автоматически подхватываемый `platformio.local.ini`, а шаблон остаётся в `platformio.local.ini.example`

### <span style="color:#4EA1FF;">Checkpoint Stage 1</span>

- <span style="color:#67C587;">Закрыто:</span>
  - единая валидация и нормализация runtime/state значений
  - безопасный offline-safe startup без вечной блокировки на Wi-Fi
  - неразрушающее поведение `LittleFS` без silent format
  - явный lifecycle/status для `sensor async`, `audio async`, `Wi-Fi / OTA`, `display runtime`
  - минимальный измерительный слой (`frame time`, `free heap`)
  - optional RTC contour добавлен как неразрушающий слой: отсутствие `DS3231` не ломает часы, а наличие модуля должно давать backup-время до NTP
- <span style="color:#FFB347;">Аппаратная оговорка:</span>
  - cold-start instability текущей `ESP32-S3 N16R8` dev board воспроизводится даже на голой плате без матрицы;
  - offline Wi-Fi display glitches на этом стенде считаются board-specific поведением;
  - оба пункта выведены из Stage 1 firmware gate и считаются аппаратным риском конкретной платы/стенда, а не незакрытой дырой архитектуры прошивки.
- <span style="color:#4EA1FF;">Следующий выбранный трек:</span>
  - radio preparation on dual MCU: `ESP32-S3` как main clock/display controller, `ESP32-WROOM32` как radio/network coprocessor.

### <span style="color:#4EA1FF;">Выводы после внешнего review</span>

- Внешний review по плану признан полезным, но не принимается механически: в проект вносятся только те выводы, которые подтверждаются текущим состоянием кода и реальными рисками.
- Главный принятый вывод: `Stage 1` нельзя держать вечно "частично выполненным". У каждой стадии должны быть явные критерии завершения.
- Главный отклонённый в жёсткой форме вывод: искусственные метрики вроде "`main.cpp` < 300 строк" не считаются обязательной целью сами по себе. Важнее разделение ответственности, чем число строк.
- Главный практический вывод: новые пользовательские функции сейчас не в приоритете. Приоритет — закрытие фундаментальных рисков, которые всё ещё держат `Stage 1` открытым.
- Отдельно зафиксировано: `async lifecycle` признаётся важной зоной риска, но не тянет за собой автоматическое внедрение одной глобальной state machine. Приоритет — сначала формализовать жизненный цикл подсистем по отдельности.
- Дополнительно подтверждено внешней оценкой: проект уже стал управляемым и продуктово-ориентированным, но `Stage 1` всё ещё остаётся главным рубежом стабильности и не должен маскироваться под “почти готово”.
- Принята ещё одна практическая поправка: сразу после закрытия оставшихся lifecycle-дыр нужно ввести минимальные runtime-метрики (`frame time`, `heap`), но без преждевременного ухода в большой performance-refactor.
- Принята отдельная ресурсная дисциплина: экономить можно на дублировании, зеркалировании, вторичной косметике и преждевременной полировке, но нельзя экономить на root-cause analysis, сборке, safety-правках и фиксации важных решений.
- Отдельно принят двухуровневый workflow по ресурсу: внешний ChatGPT может давать дешёвые локальные patch-заготовки, но не считается источником финальных проектных решений. Для этого в проекте поддерживается отдельный пакет `docs/chatgpt_git/`.
- Для project settings обычного ChatGPT нужен не “запретительный манифест”, а короткий управляемый режим. Поэтому paste-ready инструкция и task capsule теперь считаются каноническими именно в `docs/chatgpt_git/`, а не в `docs/project/`.
- Для внешнего ChatGPT отдельно зафиксирован remote-doc path: ключевые русские документы должны быть доступны и по GitHub-ссылкам, а если модель ссылки не читает, это должно быть явно компенсировано коротким `Docs summary` внутри самой задачи.
- Для внешней публикации собран отдельный пакет `docs/chatgpt_git/`, чтобы не смешивать живую внутреннюю документацию проекта и внешний набор для обычного ChatGPT.
- Отдельно зафиксировано: во внешнем ChatGPT/GitHub-пакете локальные пути `docs/...` и удалённые опубликованные пути `project/...` / `chatgpt_git/...` должны быть разведены явно, иначе пакет начинает противоречить сам себе.
- Отдельно зафиксировано правило репозитория: GitHub-структура не придумывается локально, а сначала сверяется с реальным репозиторием и только потом отражается в документации.
- Дополнительно зафиксировано: публикация в GitHub остаётся отдельным пользовательским шагом после локальных правок; локальная документация не считается автоматически опубликованной.
- Принята дополнительная дисциплина по ресурсу: в обычном активном ритме живые RU-доки можно синхронизировать пакетно примерно раз в два осмысленных шага, но при изменении stage-status, проектных правил, ключевой архитектуры или критичного пользовательского сценария синхронизация должна происходить сразу.

### <span style="color:#4EA1FF;">Definition of Done</span>

#### <span style="color:#67C587;">Stage 1 считается завершённым, когда:</span>
- старт часов стабилен и предсказуем даже без доступного Wi-Fi
- файловая система не форматируется и не теряет данные при обычных сбоях монтирования
- все входящие и сохраняемые настройки проходят валидацию через единые правила
- хардкод Wi-Fi credentials больше не является обязательным условием жизнеспособности устройства в продуктовой логике
- Wi-Fi credentials поднимаются из persisted state, а текущий dev hardcoded bootstrap остаётся допустимым только как режим разработки
- финальная продуктовая цель для Wi-Fi: AP onboarding, scan доступных сетей, ввод SSID/password через браузер и reboot в пользовательскую сеть
- базовые runtime-риски (`seed`, init order, sensor retry path) убраны или явно локализованы
- high-risk async zones хотя бы описаны по подсистемам, чтобы дальнейшие решения можно было оценивать не по ощущениям, а по зафиксированному lifecycle

#### <span style="color:#67C587;">Stage 2 считается завершённым, когда:</span>
- `main.cpp` остаётся coordinator entrypoint, а не хранит business-логику рендера и сервисов
- scene selection, display runtime, startup services и sensor bootstrap живут в отдельных зонах ответственности
- глобальное состояние проекта заметно сокращено или структурировано
- async lifecycle становится детерминированным и понятным по ownership

### <span style="color:#4EA1FF;">Политика по async lifecycle</span>

- `async lifecycle` в этом проекте считается не “архитектурной абстракцией на будущее”, а реальной зоной риска.
- Под подсистемами здесь понимаются:
  - `Wi-Fi / OTA`
  - `audio async / spectrum`
  - `sensor async`
  - `display runtime`
- Для каждой такой зоны в будущем должно быть понятно:
  - как она инициализируется
  - когда считается запущенной
  - как ведёт себя при сбое
  - нужен ли retry / restart
  - как она влияет на остальные части прошивки
- Проект не принимает как обязательную догму идею “одного большого `SystemState` на всё”.
- Если позже появится смысл в общей state machine, это должно быть:
  - сначала обосновано реальными связями между подсистемами
  - потом зафиксировано в плане
  - и только потом реализовано в коде
- До этого приоритет — локальная ясность по lifecycle каждой async-подсистемы.

#### <span style="color:#67C587;">Stage 3 считается завершённым, когда:</span>
- machine-specific настройки вынесены из общего конфига или имеют нормальный local override path
- debug/release режимы разведены без ручной путаницы
- дерево проекта очищено от временных и исторически мёртвых хвостов
- у проекта есть компактная самодиагностика, полезная в реальной эксплуатации

### <span style="color:#4EA1FF;">Минимальные runtime-метрики</span>

- Минимальный следующий диагностический слой после закрытия оставшихся дыр `Stage 1`:
  - `frame time`
  - `free heap`
- Эти метрики не считаются новой пользовательской функцией.
- Они нужны как инженерный контроль перед следующей архитектурной волной, чтобы дальнейшие решения принимались не “на глаз”.
- Полный performance-layer, FPS budget и более глубокие runtime-метрики остаются более поздним шагом и не смешиваются с текущим закрытием фундамента.
### <span style="color:#4EA1FF;">Долгосрочные архитектурные ориентиры</span>

- Внешний review по человеческому guide-слою дал полезное направление: проекту со временем нужен более явный frame pipeline, но это не считается задачей до завершения `Stage 1`.
- Идея единого `renderFrame()` принята как сильное направление для позднего `Stage 2` / раннего `Stage 3`, а не как немедленная задача.
- Идея `EffectManager` и общего effect-интерфейса принята как возможная будущая унификация режимов, но только после закрытия фундаментальных рисков.
- Preload `.anim` в RAM / PSRAM для `Fire` уже реализован: файл читается из `LittleFS` один раз, а кадры дальше проигрываются из памяти.
- Идея FPS / frame budget контроля признана полезной, но относится к более позднему слою инженерной доводки, а не к срочным шагам текущего этапа.
- Идея жёсткого LUT-маппинга и тотальной микрооптимизации пока не считается обязательной без подтверждённой боли в runtime.

### <span style="color:#4EA1FF;">Как эти рекомендации раскладываются по стадиям</span>

#### <span style="color:#67C587;">Stage 1</span>
- не внедрять большой effect-framework
- не перестраивать весь render loop ради архитектурной красоты
- максимум: фиксировать runtime-боли, которые реально мешают стабильности

#### <span style="color:#67C587;">Stage 2</span>
- продолжить вынос orchestration из `main.cpp`
- подвести проект к более явному центру управления кадром
- оценить, нужен ли аккуратный `EffectManager` как следующий слой унификации

#### <span style="color:#67C587;">Stage 3</span>
- при подтверждённой пользе ввести frame pipeline как отдельный инженерный слой
- развивать `Fire` уже поверх существующего RAM / PSRAM preload, без возврата к чтению `LittleFS` на каждый кадр
- добавить frame budget / FPS / heap metrics как инструменты контроля, а не как самоцель
### <span style="color:#4EA1FF;">Что изменилось по ценности плана</span>

- Возврат к procedural fire утратил ценность: файловый `Fire` показал себя лучше и стал каноническим режимом.
- Поддержка множества fire-пресетов утратила ценность: проект ушёл в сторону одного сильного режима вместо зоопарка режимов.
- Старый Python-пайплайн подготовки анимаций утратил ценность и уже удалён.
- Эксперименты с backend-детектом timezone по IP пока не доказали ценность: рабочим оставлен frontend path, а backend-хвост удалён.

---

## <span style="color:#67C587;">Выполнено</span>

- Подтверждён реальный профиль железа `N16R8`
- Исправлена конфигурация платы и partition table
- Поднят и проверен `LittleFS`
- Поднят и проверен OTA
- Восстановлен и упрощён огненный режим
- Старые режимы `Flame Real / Reactive / Smooth` убраны
- Оставлен единый режим `Fire`
- Удалён старый огненный мусор и временные хвосты
- Обновлена документация проекта

---

## <span style="color:#FF9B5E;">Удалённый legacy / мусор</span>

- Старые procedural fire branches
- Старые огненные режимы кроме `Fire`
- Старые animation-header хвосты
- Устаревшие служебные заметки и мусорные временные файлы
- Старый Python-пайплайн генерации огня и анимаций

---

## <span style="color:#4EA1FF;">Открытые риски</span>

- `main.cpp` всё ещё крупный, но ключевая display/runtime orchestration уже вынесена в отдельный модуль
- Финальный продуктовый Wi-Fi contour ещё не завершён: dev bootstrap отделён, AP onboarding уже собран по backend/frontend основам, но ещё не подтверждён как завершённый пользовательский сценарий
- Wi-Fi product contour уже имеет backend+frontend foundation, но ещё требует полировки UX и реальной product-проверки
- Lifecycle async-task ещё не доведён до полностью аккуратной схемы
- `sensor async`, `audio async` и `Wi-Fi/OTA` уже переведены на более явный lifecycle, но весь сетевой продуктовый контур всё ещё требует реальной полевой проверки, а не только архитектурной аккуратности
- OTA host-side workaround уже есть, но его нельзя считать доказательством закрытого root cause без повторной проверки реального OTA-потока после device-side lifecycle fix
- Минимальные runtime-метрики уже введены, но это только базовый измерительный слой; более глубокий performance-анализ и frame budget всё ещё остаются следующей инженерной ступенью
- local override path для OTA уже внедрён через `platformio.local.ini`, но сам OTA dev-flow всё ещё не считается финально переносимым продуктовым решением
- shared OTA fallback по-прежнему опирается на `matrixclock.local`, а значит конечная переносимая схема discovery всё ещё остаётся открытым вопросом
- В проекте ещё остаются битые комментарии и следы плохой кодировки
- Часть документов ChatGPT/GitHub-пакета и Git reference уже переживала кодировочные сбои; это считается не косметикой, а прямым риском для управляемости внешнего workflow

---

## <span style="color:#4EA1FF;">Синхронизация с Project Guide</span>

- Блок `Обзор` в `PROJECT_GUIDE_RU.md` должен соответствовать разделам `Текущее состояние` и `Направление проекта` здесь.
- Блок `Текущие возможности` в `PROJECT_GUIDE_RU.md` должен отражать только то, что реально существует после записей в `Event Log`.
- Блок `Дорожная карта` в `PROJECT_GUIDE_RU.md` должен ссылаться на этот файл как на технический источник истины.
- Если в плане появляется новая значимая архитектурная веха, в `PROJECT_GUIDE_RU.md` добавляется краткое отражение этой вехи, но без дублирования всей технички.
- Техническая история профиля платы `N16R8` вынесена в отдельный справочник [`N16R8_PROFILE_BIBLE_RU.md`](./N16R8_PROFILE_BIBLE_RU.md).
- Для структурной ориентации по репозиторию поддерживается отдельная карта [`PROJECT_TREE_RU.md`](./PROJECT_TREE_RU.md).

---

## <span style="color:#D98BFF;">Event Log</span>

> <span style="color:#AEBFD7;">Используй этот блок для короткой фиксации значимых изменений проекта.</span>

### <span style="color:#67C587;">Формат</span>
- Дата
- Что изменилось
- Зачем это было сделано
- Что было удалено или заменено
- Как это связано со Stage 1 / 2 / 3

### <span style="color:#67C587;">Записи</span>
- 2026-04-16 — Огненная система сведена к одному финальному файловому режиму `Fire`; legacy-ветки огня удалены.
- 2026-04-16 — `LittleFS` и OTA-контур стабилизированы на текущем профиле платы.
- 2026-04-16 — Документация разделена на русскую и английскую ветки README.
- 2026-04-17 — Валидация состояния усилена в `state.cpp` и `webserver.cpp`; это напрямую двигает `Stage 1` вперёд.
- 2026-04-17 — Убрана блокировка старта на Wi-Fi; монтирование файловой системы стало неразрушающим; инициализация датчиков переведена на повторные попытки. Это базовый прогресс `Stage 1`.
- 2026-04-17 — Startup/network services и sensor bootstrap вынесены из `main.cpp` в отдельные модули. Это первое реальное структурное разделение в `Stage 2`.
- 2026-04-17 — Удалены временные файлы и мёртвый backend-путь timezone; это частично поддерживает цели очистки `Stage 3`.
- 2026-04-17 — Добавлен `N16R8_PROFILE_BIBLE_RU.md` как технический справочник по кастомному board profile, проблеме 16MB flash и подводным камням partition/LittleFS. Это усиливает документальную зрелость `Stage 3`.
- 2026-04-17 — Display/runtime orchestration вынесена из `main.cpp` в `display_runtime.*`, включая IP overlay, reconnect flow, fade-in и диспетчер рендера. Это второе конкретное разделение `Stage 2`.
- 2026-04-17 — Внешний review по refactor-плану был оценён и частично принят: у плана появились явные `Definition of Done`, а краткосрочный фокус возвращён к завершению `Stage 1`, а не к расползанию scope.
- 2026-04-17 — Added backend groundwork for the future product Wi-Fi path: AP fallback, explicit Wi-Fi runtime mode, and `/wifi-status` / `/wifi-scan` / `/wifi-config` endpoints. This advances Stage 1 without breaking the current development bootstrap flow.
- 2026-04-17 — Added the browser-side Wi-Fi onboarding panel to the Web UI and made Wi-Fi credential saves immediate for reboot-safe product setup. This continues Stage 1 without breaking the current development bootstrap flow.
- 2026-04-17 — Rebuilt the Web UI around tabs so the growing settings surface no longer lives in one long vertical page. This keeps the current UX manageable while Stage 1 features continue to accumulate.
- 2026-04-17 — Consolidated runtime state validation into `state.*`: persisted load, web updates, and forced saves now pass through one normalization layer instead of duplicating validation logic. This is direct Stage 1 progress.
- 2026-04-17 — Added explicit filesystem runtime-state tracking (`mounted` / `missing_content` / `unmounted`) plus `/fs-status` and state exposure through the web layer. This continues Stage 1 by replacing implicit FS assumptions with observable behavior.
- 2026-04-17 — The project policy for async lifecycle was clarified and fixed in the plan/rules: this risk is recognized as important, but the chosen direction is subsystem-by-subsystem lifecycle formalization first, not an automatic global state-machine rewrite.
- 2026-04-17 — `sensor async` received an explicit runtime lifecycle (`idle` / `starting` / `running` / `stopping` / `error`), a safer stop path, restart-aware bootstrap logic, and outward-facing status via `/state`. This is the first concrete async-lifecycle hardening pass under Stage 1 policy.
- 2026-04-17 — Added a mandatory post-edit newline integrity check via `scripts/check_literal_newlines.ps1` and aligned `.editorconfig` with the project text-file discipline. This reduces recurrence of visible backtick newline artifacts across docs and code.
- 2026-04-17 — External README-level architecture suggestions were reviewed and distributed across the roadmap instead of being promoted to immediate work: frame pipeline, effect abstraction, RAM preload for `Fire`, and runtime metrics are now tracked as staged future directions rather than urgent tasks.
- 2026-04-17 — Wi-Fi credentials were moved into persisted state, and startup was reworked into an explicit contour: stored product credentials first, development bootstrap as a separate fallback path. This is direct Stage 1 progress.
- 2026-04-17 — Wi-Fi project intent was clarified in documentation: hardcoded credentials are allowed only for development, while the final product path must be AP onboarding with browser-based network selection and reboot into the user network.
- 2026-04-17 — Принята новая документальная дисциплина по ресурсу: живая синхронизация дальше ведётся только в русской ветке (`PROJECT_GUIDE_RU.md` / `REFACTOR_PLAN_RU.md`), а английская документация переводится пакетно позже, когда проект стабилизируется.
- 2026-04-21 — Русский описательный слой проекта переименован в `PROJECT_GUIDE_RU.md`, чтобы зафиксировать его реальную роль: это человеческий разговорный путеводитель, а не формальный README или инструкция.
- 2026-04-21 — Добавлен `PROJECT_TREE_RU.md` как компактная карта структуры репозитория для человека и внешнего ChatGPT; это должно уменьшить путаницу, когда модели показывают отдельные файлы без общего контекста.
- 2026-04-17 — `audio async` получил явный runtime lifecycle (`idle` / `starting` / `running` / `stopping` / `error`), безопасный stop-path, явный init-result и внешний status через `/state`. Это второй конкретный async-lifecycle hardening pass под политику `Stage 1`.
- 2026-04-17 — Внешняя оценка текущего прогресса признала архитектурный курс сильным и подтвердила, что главный риск по-прежнему в незакрытом `Stage 1`. Из этой оценки в план принят новый практический слой: после закрытия оставшихся lifecycle-узлов вводятся минимальные runtime-метрики (`frame time`, `free heap`) как инженерный контроль перед следующей волной рефактора.
- 2026-04-17 — Зафиксирован и локально обойдён host-side баг `espota.py`: после успешной OTA-передачи скрипт мог падать по таймауту и ложно помечать загрузку как `FAILED`, хотя устройство уже обновилось. Это не изменение прошивки часов, а workstation workaround для стабильного dev-потока OTA.
- 2026-04-17 — OTA lifecycle на устройстве доработан: automatic reboot after success replaced with a delayed restart window, and OTA state is now exposed through the web layer. This is the first device-side attempt to address the false post-upload failure at the source instead of only masking it on the host.
- 2026-04-17 — `Wi-Fi / OTA` lifecycle дополнительно формализован: Wi-Fi теперь имеет явный status message, а OTA сервис корректно сбрасывается и поднимается заново после disconnect/reconnect вместо зависания в старом initialized-состоянии. Это первый полный lifecycle-pass по сетевому контуру в рамках `Stage 1`.
- 2026-04-17 — Введён минимальный runtime metrics layer: время кадра и свободная куча теперь доступны через `/state`, чтобы следующий этап оптимизации и архитектурных решений опирался на измерения, а не на ощущение.
- 2026-04-17 — Wi-Fi onboarding усилен базовой валидацией: SSID/password нормализуются, слишком короткий непустой пароль помечается как плохая конфигурация, а `Save & reboot` не уводит устройство в заведомо проблемную сеть. Это ещё один шаг к продуктовой надёжности `Stage 1`.
- 2026-04-17 — В проектные правила добавлена дисциплина стабильных command prefixes: shell-команды должны использоваться через минимальный набор повторяемых шаблонов, чтобы сохранённые sandbox-разрешения действительно переиспользовались, а не терялись из-за мелкого разнообразия команд.
- 2026-04-17 — Зафиксирована языковая дисциплина проекта: код, API и технические идентификаторы не переводятся, а полная русификация обязательна прежде всего для русского UI и русскоязычного объяснительного слоя.
- 2026-04-17 — В проектные правила добавлена ресурсная дисциплина: ресурс экономится только там, где это не снижает надёжность и качество продукта; верификация, safety-правки, root-cause analysis и фиксация важных решений не подпадают под режим экономии.
- 2026-04-20 — Стабилизирован `/state` payload для Web UI: увеличен JSON capacity backend-ответа, чтобы диагностические поля больше не вытесняли `digits/bar` color state и цветовой круг после перезагрузки страницы восстанавливал реальный цвет, а не падал в белый центр.
- 2026-04-20 — OTA dev-workflow в `platformio.ini` переведён с `matrixclock.local` на прямой IP часов, потому что Windows/mDNS-резолв `.local` в этом проекте нестабилен и ломает кнопку `Upload`, хотя само устройство продолжает работать нормально.
- 2026-04-20 — Прямой IP в OTA-конфиге отдельно зафиксирован как `valid dev stabilization`, а не как финальная архитектура: это осознанная временная мера для надёжного рабочего процесса, и в финальных аккордах проекта этот путь должен быть либо вынесен в local override, либо заменён на более устойчивый discoverable OTA mechanism.
- 2026-04-20 — `display runtime` формализован как ещё одна lifecycle-зона Stage 1: через `/state` теперь наружу выходят явные состояния `waiting_for_time`, `ip_overlay`, `clock_fade_in`, `running_clock`, `running_spectrum`, чтобы экранный контур тоже оценивался по наблюдаемому статусу, а не по догадкам.
- 2026-04-20 — Пересобран внешний ChatGPT workflow под экономию ресурса: task capsule и project settings вынесены в канонический внешний пакет `docs/chatgpt_git/`. Это должно снизить расход ресурса на мелких локальных правках без потери контроля со стороны Codex.
- 2026-04-20 — Внешний ChatGPT workflow стал remote-aware: в `CHATGPT_PROJECT_SETTINGS_RU.md` и `CHATGPT_TASK_CAPSULE_RU.md` добавлены прямые GitHub-ссылки на русские документы проекта и явное правило fallback на `Docs summary`, если модель не умеет читать ссылки.
- 2026-04-20 — Для внешней публикации собран минимальный набор `docs/chatgpt_git/`: туда входят только project settings и task capsule, без лишних meta-слоёв.
- 2026-04-20 — Из `docs/project/` удалены устаревшие дубли `CHATGPT_PROJECT_SETTINGS_RU.md` и `CHATGPT_TASK_CAPSULE_RU.md`: каноническим слоем для этих файлов теперь считается только внешний пакет `docs/chatgpt_git/`, а внутренний проектный слой больше не хранит конкурирующие копии.
- 2026-04-21 — Из `docs/project/` удалён и дублирующий `mc_core.v4.ini`: после этой чистки все ChatGPT-ориентированные файлы живут только в `docs/chatgpt_git/`, а папка `docs/project/` содержит только проектную документацию.
- 2026-04-20 — Начат аккуратный cleanup битых комментариев в `main.cpp`: runtime-critical entrypoints получили нормальные поясняющие комментарии без изменения поведения. Это не закрывает весь кодировочный хвост файла, но снижает риск чтения ключевых участков.
- 2026-04-21 — Проведён аудит документации: восстановлена нормальная кодировка у Git reference и внешнего ChatGPT/GitHub-пакета, убраны противоречивые формулировки по Wi-Fi onboarding, а в правила добавлены `Documentation Update Threshold`, `Stage Gate Discipline`, `Canonical Ownership Rule` и `External Package Sync Rule`. Это снижает расход ресурса и делает дальнейший прогресс менее шумным.
- 2026-04-21 — Wi-Fi onboarding дополнительно доведён по наблюдаемости: backend теперь отдаёт явный `applyState` (`scheduled` / `connecting` / `succeeded` / `failed`), а Web UI умеет показывать живой статус попытки подключения и сам допрашивает `/wifi-status`, пока apply-path не завершится. Это ещё один шаг к product-grade Wi-Fi contour внутри `Stage 1`.
- 2026-04-21 — Из `main.cpp` вынесены calendar/date/sensor visual helpers в новый модуль `clock_visuals.*`; затем туда же вынесены обычная clock-face отрисовка и slide-переходы часов. `renderClock()` и orchestration-path пока ещё остаются в `main.cpp`, но entry-файл уже стал заметно тоньше без изменения поведения. Это аккуратный структурный шаг по `Stage 2`.
- 2026-04-21 — `renderClock()` вынесен из `main.cpp` в новый модуль `clock_runtime.*`; после этого `main.cpp` стал тонким entrypoint-файлом с глобальным состоянием, `setup()` и `loop()`, а сам clock-phase runtime живёт отдельно. Это крупный, но всё ещё безопасный шаг по `Stage 2`.
- 2026-04-21 — Shared runtime-state вынесен из `main.cpp` в `app_state.*`; глобальные runtime-объекты, цвета, режимы, sensor state и slide tracking больше не определяются в entrypoint. После этого `main.cpp` фактически остался файлом `setup()` / `loop()`. Это прямое продвижение `Stage 2`.
- 2026-04-22 — Файловый runtime вынесен из перегруженного `system_services.cpp` в отдельный `filesystem_service.*`: mount/status/missing-content/unmount-for-OTA теперь принадлежат одному FS-слою, а `system_services` больше не владеет внутренним состоянием LittleFS напрямую. Это снижает связанность FS/OTA/Wi-Fi и продолжает Stage 2 без изменения поведения.
- 2026-04-22 — OTA lifecycle вынесен из `system_services.cpp` в `ota_service.*`: `ArduinoOTA`, runtime-state, status message, delayed reboot и `handleOtaService()` теперь живут в отдельном слое. Wi-Fi contour только поднимает/останавливает OTA по событиям сети, что уменьшает смешение Wi-Fi/OTA ответственности без изменения upload-path.
- 2026-04-21 — Внешний ChatGPT/GitHub-пакет дополнительно ужат до двух рабочих файлов: `CHATGPT_PROJECT_SETTINGS_RU.md` и `CHATGPT_TASK_CAPSULE_RU.md`. `mc_core.v4.ini`, внешний package README и publish steps убраны из runtime-пакета как дублирующие meta-слои.
- 2026-04-21 — Доведена каноничность внешних инструкций: отдельно зафиксировано, что текст для `Project Instructions` обычного ChatGPT должен жить только в `docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`, а `CHATGPT_TASK_CAPSULE_RU.md` остаётся только шаблоном конкретной задачи и не должен разрастаться во второй устав. Это дополнительно уменьшает drift и стоимость синхронизации.
- 2026-04-21 — Принята пакетная дисциплина синхронизации: в нормальном рабочем ритме `PROJECT_GUIDE_RU.md` и `REFACTOR_PLAN_RU.md` можно обновлять примерно раз в два осмысленных шага, чтобы не тратить ресурс на шум, но смысловые повороты проекта по-прежнему должны фиксироваться сразу.
- 2026-04-21 — Wi-Fi contour дополнен product-grade recovery path: сохранённые credentials окончательно закреплены как persisted слой в `Preferences` / `NVS`, независимый от `firmware` и `LittleFS`, а на старте добавлена физическая recovery-кнопка на `GPIO21`, которая очищает Wi-Fi конфиг и сразу поднимает setup AP. Это закрывает важный жизненный сценарий устройства вне знакомой сети.
- 2026-04-21 — OTA dev-config переведён на более взрослую схему: общий `platformio.ini` теперь хранит только shared fallback (`matrixclock.local`), а machine-specific `upload_port` / `host_ip` вынесены в автоматически подхватываемый `platformio.local.ini`, который исключён из git. Кнопка `Upload` на текущей машине остаётся рабочей, а shared конфиг становится чище и переносимее.
- 2026-04-21 — Восстановлена логика calendar maze-runner после выноса визуалов в `clock_visuals.*`: точка снова движется внутри пикселей цифр календаря с направлением и меняет ход только при столкновении с препятствием, а не случайно в пустоте.
- 2026-04-21 — Wi-Fi recovery path усилен persisted-флагом forced setup AP: после очистки credentials кнопкой устройство больше не должно возвращаться в development bootstrap сеть при следующем reset, пока пользователь не задаст новые Wi-Fi credentials.
- 2026-04-21 — Setup AP получил экранную подсказку: display runtime в `WIFI_RUNTIME_AP_CONFIG` циклично показывает `AP:` и IP `192.168.4.1`, чтобы пользователь видел адрес настройки прямо на матрице.
- 2026-04-21 — `/wifi-scan` переведён на async scan + 30-секундный cache результата: endpoint больше не ждёт завершения тяжёлого `WiFi.scanNetworks()` синхронно, а UI допрашивает результат polling-ом. Это снижает лаги setup AP при автоскане, повторных запросах и нескольких клиентах.
- 2026-04-21 — Setup AP UI избавлен от лишней внешней CDN-загрузки color picker: в AP/offline режиме страница показывает локальный fallback вместо попытки тянуть `iro.js` из интернета. Color picker теперь лениво загружается только в нормальном STA-доступе, чтобы onboarding с телефона не зависал на внешней сети.
- 2026-04-22 — Setup AP ограничен одним клиентом (`max_connection = 1`): режим настройки рассматривается как одноразовый onboarding-канал для телефона/ПК, а не как многопользовательская точка доступа. Это уменьшает риск лагов, конкурирующих запросов и непредсказуемого поведения при настройке Wi-Fi.
- 2026-04-22 — Wi-Fi scan UI стабилизирован: browser больше не затирает найденные сети пустым списком при refresh/lang/render, а backend не кэширует нулевой результат scan на 30 секунд. Это устраняет сценарий, когда scan визуально завершился, но выпадающий список снова пустой.
- 2026-04-22 — Wi-Fi scan backend дополнительно защищён от перегруженного окружения: `/wifi-scan` отдаёт максимум 20 непустых SSID и помечает `truncated`, если сетей больше. Это снижает риск переполнения JSON-ответа и странных пустых выпадающих списков в местах с большим количеством Wi-Fi сетей.
- 2026-04-22 — Fire playback вынесен из `spectrum.cpp` в отдельный модуль `effects/fire_animation.*`: уже существующий preload `.anim` в RAM / PSRAM сохранён без изменения поведения, но файловая анимация больше не спрятана внутри spectrum runtime. Это продолжает Stage 2 через разделение ответственности.
- 2026-04-22 — Wi-Fi contour вынесен из `system_services.cpp` в отдельный `wifi_service.*`: recovery-кнопка, AP onboarding, stored credentials apply-path, Wi-Fi status и связь с OTA теперь принадлежат Wi-Fi слою, а `system_services.*` стал тонким coordinator базовых сервисов. Это продолжает Stage 2 и готовит проект к аккуратному добавлению новых I2C-сервисов.
- 2026-04-22 — Wi-Fi HTTP endpoints вынесены из `ui/webserver.cpp` в `ui/wifi_routes.*`: `/wifi-status`, `/wifi-scan` и `/wifi-config` остались теми же API, но Web UI backend больше не хранит всю Wi-Fi scan/config логику в общем server-файле.
- 2026-04-22 — Добавлен optional `DS3231` RTC слой `rtc_service.*`: одна прошивка теперь может работать и с RTC-модулем, и без него. При наличии DS3231 системное время поднимается из RTC до NTP, а после появления валидного system/NTP time RTC синхронизируется обратно. `AT24C32` на модуле только детектируется и не используется как storage, чтобы не плодить лишний источник состояния.
- 2026-04-22 — RTC hardware validation пройдена: подключенный `DS3231` определяется (`rtcPresent=true`), время валидно (`rtcTimeValid=true`), после перезапуска система поднимает время из RTC (`rtcSeededSystemTime=true`), а затем синхронизирует RTC обратно от system/NTP time (`rtcSyncedFromSystemTime=true`). Инженерное решение: DS3231 используется как скрытый backup-источник времени, NTP остаётся главным корректором, AT24C32 не используется без отдельного обоснованного сценария.
- 2026-04-28 — Wi-Fi runtime hot path дочищен от лишних блокировок: переходы после `WiFi.disconnect()` (stored credentials apply, запуск setup AP, закрытие setup AP после grace window) переведены на отложенное исполнение через `handleWifiService()` без `delay(100)` в рабочем цикле. Это снижает оставшийся фундаментальный долг перед дальнейшей работой в `weather`, `voice` и `radio`, не меняя внешний Wi-Fi onboarding flow.
- 2026-04-22 — Уточнена роль интернета в продуктовой концепции: базовая функция часов должна оставаться автономной через RTC, а Wi-Fi/интернет рассматриваются как сервисный слой для радио, погоды, уведомлений, Web UI, OTA и NTP-коррекции. Это защищает проект от неверного вектора, где часы становятся зависимыми от сети ради самой функции времени.
- 2026-04-22 — Зафиксирована инженерная оценка внешних модулей: питание матрицы и level shifter относятся к стабильности, `MAX98357A` — к будущему радио, `PCM5102A` — к качественному аудиовыходу, а `16x2`/`320x240` дисплей пока рассматривается только как возможный диагностический слой, не как второй полноценный UI. Это удерживает бытовые идеи в roadmap без подмены текущих приоритетов.
- 2026-04-22 — Подготовлен инженерный контур для будущей погоды: первым кандидатом выбран `Open-Meteo` как лёгкий JSON API без обязательного API-ключа, а сама логика должна войти отдельным `weather_service.*` с cache последнего успешного ответа, update interval, status/error через `/state` и без блокировки render/network loop при сбоях сети.
- 2026-04-22 — Добавлен первый безопасный кодовый каркас `weather_service.*`: сервис пока не делает HTTP-запросы и не имеет UI, но уже подключён к общему service loop и отдаёт базовый status через `/state`. Это закрепляет ownership будущей погоды до внедрения API/cache/UI.
- 2026-04-22 — `weather_service.*` получил первый реальный backend-pass: Open-Meteo запрос выполняется в отдельной FreeRTOS task, результат кэшируется, а `/state` отдаёт температуру, ощущаемую температуру, влажность, давление, ветер, weather code, координаты, interval и возраст последнего обновления. UI и матричное отображение пока намеренно не тронуты.
- 2026-04-22 — Web UI получил отдельную вкладку `Weather`: погода больше не спрятана в `System`, а показана человеческими строками — город/координаты, статус, событие, температура, влажность, давление, ветер, облачность и возраст обновления. WMO weather code расшифровывается в понятное состояние, а не показывается только числом.
- 2026-04-22 — Исправлена честность weather UI: временные dev-координаты не должны отображаться как автоматически определённый город. До появления настройки локации или reverse geocoding UI показывает `Custom location` / `Пользовательская локация` и сами координаты.
- 2026-04-22 — Добавлена настройка погодной локации: `weather_service.*` хранит имя/широту/долготу в NVS, `/weather-config` принимает новую локацию, `/state` отдаёт `weatherLocationName`, а Web UI позволяет вручную ввести координаты или взять их из геолокации браузера. Это убирает ложное угадывание города и делает источник погоды явным.
- 2026-04-22 — В погодную вкладку добавлена короткая пользовательская инструкция по ручной настройке координат. Решение: не делать отдельную вкладку инструкций, пока достаточно локальной подсказки рядом с полями, чтобы не раздувать UI.
- 2026-04-22 — Погодная локация стала бытовой: Web UI ищет город напрямую через `Open-Meteo Geocoding API`, показывает до 5 вариантов и подставляет имя/широту/долготу из выбранного результата. Ручной ввод координат оставлен как fallback, но основным сценарием стал поиск города. Серверный `/weather-search` убран из прошивки, потому что HTTPS-geocoding внутри web handler оказался тяжёлым и нестабильным для ESP32.
- 2026-04-22 — Исправлено отображение длинных погодных локаций: select показывает короткую метку, полное имя выбранного места выводится отдельной строкой, поле имени стало многострочным, а лимит сохранённого имени в `weather_service.*` увеличен до 95 символов.
- 2026-04-22 — В Web UI добавлена вкладка `Guide` / `Помощь` с короткими пользовательскими сценариями: AP/Wi-Fi onboarding, настройка погоды, DS3231 offline time, firmware/LittleFS updates и `/state` diagnostics. Статус решения: это оформленный MVP-help слой, не архитектурный источник истины; тексты можно редактировать позже без изменения логики.
- 2026-04-22 — Навигация Web UI упрощена до четырёх бытовых вкладок: `Настройки`, `Интерфейс`, `Погода`, `Инфо`. Отдельная вкладка часов убрана, timezone объединён с настройками, яркость перенесена в интерфейс, `Visuals` переименован в `Interface`, а `Guide` переименован в `Info`, чтобы UI отражал пользовательские сценарии, а не внутреннюю архитектуру.
- 2026-04-22 — Добавлен компактный машинный слой `PROJECT_CONTEXT_COMPACT_RU.md`: для обычных правок Codex/AI сначала читает короткий контекст, а большие документы открывает только точечно. Цель — снизить расход токенов на документацию без потери дисциплины, истории и человеческого путеводителя.
- 2026-04-27 — Подтянут фундамент стабильности без смены пользовательской логики: в `hardware/i2c_bus.*` введён общий lock для шины, а `rtc_service.cpp` и `sensors/sensors.cpp` переведены на guarded I2C access вместо конкурентного сырого `Wire`. Это закрывает основной риск race/hang между RTC и сенсорами.
- 2026-04-27 — Async lifecycle подчищен в `sensors_async.cpp`, `audio/spectrum_async.cpp` и `weather_service.cpp`: runtime state/status/running флаги теперь читаются через один lock/snapshot, а у spectrum `rawSamples[512]` вынесен из task stack в static buffer. Это уменьшает вероятность полубитых start/stop состояний и лишнего stack pressure.
- 2026-04-27 — `wifi_service.cpp` перестал молча использовать hardcoded development bootstrap по умолчанию (`DEV_WIFI_BOOTSTRAP_ENABLED=false`). Инженерное правило зафиксировано: dev-only сетевые fallback'и должны жить в локальном окружении/конфиге, а не в продуктовой прошивке как скрытый default.
- 2026-04-27 — Документация Pixel Editor синхронизирована с реальным состоянием инструмента: запуск теперь через `.\run_server.cmd`, сервер умеет fallback по порту `8000..8009`, а web-инструментарий включает не только animation editor, но и `font_editor.html` с импортом `OTF` в `src/text/font5x7_utf8.cpp`.
- 2026-04-27 — Web UI hot path облегчён без потери диагностики: браузерный sync переведён с тяжёлого `/state` на новый компактный `/ui-state`, а `/state` оставлен как ручной debug endpoint. Одновременно `/matrix-frame` переведён с `StaticJsonDocument + String` на прямую сериализацию в статический буфер, а запись browser-preview стала реже (`1000ms` вместо `500ms`), чтобы открытая вкладка меньше дёргала runtime.
- 2026-04-28 — Аудиотракт отвязан от boot по-взрослому: `system_services.cpp` больше не поднимает `spectrum_async` всегда при старте. Вместо этого введена синхронизация владения core services, которая lazy-start/lazy-stop FFT+I2S только для реально аудио-реактивных режимов (`SPEC_BARS`, `SPEC_WATERFALL`, `SPEC_SYMMETRIC`, `SPEC_VU`). `SPEC_FIRE` и `SPEC_OFF` больше не держат микрофон и фоновые FFT-вычисления.
- 2026-04-28 — `audio/spectrum.cpp` получил безопасный fallback при отсутствии FFT-кадра: вместо возврата без очистки теперь кадр очищается и overlay дорисовывается честно. Это убирает stale-frame риск в spectrum mode при ошибке I2S/микрофона или во время ленивого старта async-обработки.
- 2026-04-28 — `system_services.cpp` получил retry cooldown для старта `spectrum_async`: при ошибке I2S/микрофона система больше не пытается поднимать FFT task практически на каждом проходе `loop()`. Это уменьшает thrash и делает текущий аудиоконтур безопаснее как база для будущих `voice`-команд.
- 2026-04-28 — Shared microphone ownership вынесен в новый `audio/audio_capture_service.*`: это теперь отдельный сервисный слой с client mask, retry/backoff и единым runtime-status для общего I2S/capture path. `system_services.*` больше не является фактическим владельцем микрофонной policy, а только координирует потребности subsystem-ов.
- 2026-04-28 — Добавлен `voice_service.*` как отдельный service-slot будущих голосовых команд: даже без готового VAD/распознавания он уже живёт как самостоятельный клиент shared audio capture, а не как скрытый хук внутри spectrum-кода. Это укрепляет иерархию ответственности до реальной voice-логики.
- 2026-04-28 — `spectrum_async` получил неблокирующий stop-request вместо ожидания до `500 ms` в вызывающем потоке, а `/state` теперь показывает не только `spectrumAsync*`, но и общий `audioCapture*` / `voice*` status. Это уменьшает риск конфликтов сервисов за I2S и улучшает наблюдаемость будущего аудиоконтура.
- 2026-04-28 — В `voice_service.*` появился первый реальный voice-listening pipeline поверх shared audio capture: persisted `voiceEnabled` / `voiceSensitivity`, ожидание готовности общего аудиосервиса, получение shared audio snapshot, RMS-based voice activity detection, адаптация noise floor и диагностические поля `voiceSpeechActive`, `voiceLevelRms`, `voiceNoiseFloorRms`, `voiceTriggerThresholdRms`, `voiceSignalAgeMs` через `/state`. Это ещё не speech recognition, но уже правильный продуктовый фундамент для VAD/trigger без обхода общей архитектуры.
- 2026-04-28 — Исправлен важный voice-lifecycle дефект: `initVoiceService()` больше не должен молча сбрасывать persisted `voiceEnabled` в `false` на boot. Для продукта, где голос — фундаментальная always-on функция, сервис обязан уважать сохранённое намерение слушать сразу после старта.
- 2026-04-28 — Поверх voice-listening слоя добавлен `voice_command_service.*`: persisted command slots (`label`, `phrase`, `URL`) теперь хранятся в общем state/NVS, Web UI получил отдельную вкладку `Voice`, а HTTP relay/control действия уходят в отдельный queued worker вместо выполнения в display-critical loop. Это важный продуктовый шаг: транспорт side effects отделены от общего микрофонного/VAD контура, а будущий speech parser сможет подключаться к тем же command slot'ам без нового ownership-конфликта.
- 2026-04-28 — Voice pipeline получил следующий связующий слой перед реальным ASR: `voice_service.*` теперь публикует speech-segment telemetry (количество сегментов, длительность, peak RMS, age), а voice Web/UI contour умеет прогонять phrase-routing до command slot'а через отдельный `/voice-phrase-test`. Это честный инженерный мост: уже можно проверять продуктовую цепочку `recognized text -> command slot -> queued HTTP action`, не pretending, что speech recognition уже реализован в прошивке.
- 2026-04-28 — Display pipeline усилен по-взрослому: `frame[]` переведён в роль логического render-buffer, а brightness scaling и физический вывод на WS2812 вынесены в отдельный scanout/present path внутри `matrixShow()`. Это убирает смешение render-domain и hardware-domain, делает матричный контур более детерминированным и добавляет новые метрики `matrixPresentTimeUs` / `matrixPresentTimeAvgUs` через `/state` для реальной диагностики лагов/фризов.
- 2026-04-28 — Runtime scheduler поднят на более строгую модель приоритетов: `main.cpp` переведён на frame-first loop с фиксированным cadence display-потока, realtime-квантами для `voice`/audio-capture и отдельным deferred round-robin для `Wi-Fi`, `RTC`, `weather`, `webserver`, sensor bootstrap и delayed save только в slack между кадрами. Это явное инженерное решение в пользу display smoothness как высшего приоритета, а не случайного результата общего цикла.
- 2026-04-28 — Зафиксированы два базовых архитектурных закона проекта как обязательный almanac-level контракт. Закон 1: display owns frame timing, а web/UI/OTA/Wi-Fi должны оставаться command/status gateway и переводить тяжёлые действия в deferred/scheduled path. Закон 2: `audio_capture_service` owns microphone/I2S, voice является always-on core service, а spectrum/VU и другие визуальные аудио-потребители считаются только клиентами shared audio features и не имеют права владеть микрофоном напрямую.
- 2026-04-28 — Начат целевой boundary-hardening под эти два закона: `voice_command_service.*` переведён на lock+snapshot модель вместо чтения живых `String` across task boundary, reboot из `ui/wifi_routes.cpp` убран из HTTP handler в scheduled path через `wifi_service.*`, `spectrum_async.cpp` больше не читает runtime-state мимо getter-а, а `/ui-state` и `/state` теперь явно падают с `500`, если JSON переполнен, вместо тихой потери полей.
- 2026-04-28 — В проектную модель явно добавлено правило resource arbitration: устройство рассматривается как единый coordinated runtime, а не как набор независимых фич. Дублирующее владение ресурсом, скрытая конкуренция за время кадра и неуправляемые blocking-path считаются архитектурным дефектом даже до пользовательски заметного сбоя.
- 2026-04-28 — В runtime metrics добавлены `frameDeadlineMissCount` и `frameDeadlineMissMaxUs` через `/state`: теперь display-cadence контролируется не только по среднему времени кадра, но и по факту срывов frame schedule. Это делает smoothness измеряемой инженерной обязанностью, а не субъективным ощущением.
- 2026-04-28 — Weather ticker motion дополнительно согласован с display cadence: `weatherTickerSpeed` теперь нормализуется к кратным `FRAME_INTERVAL`, а смещение тикера считается через целые frame-step вместо произвольного `millis()/speed`. Это убирает микродрожание бегущей строки и подчёркивает правило, что motion на матрице должен жить в той же временной сетке, что и кадры.
- 2026-04-28 — Проведён второй smoothness-pass по animation/motion path: phase transitions в `clock_runtime.cpp`, voice/spectrum clock overlay в `audio/spectrum.cpp`, IP/AP overlay motion в `effects/display_info.cpp`, clock fade в `display_runtime.cpp`, digit slide/eyes animation в `effects/digits.cpp` и file-fire playback в `effects/fire_animation.cpp` дополнительно согласованы с frame cadence через quantized frame-step timing. Это снижает количество участков, где motion жил по “сырому millis” отдельно от display scheduler.
- 2026-04-28 — `display_timing.h` введён как канонический cadence-layer проекта: frame quantization, progress normalization и delay normalization теперь должны браться из общего helper-а, а не из локальных самодельных расчётов по `millis()`. Это превращает smoothness в повторяемое правило архитектуры, а не в набор разрозненных локальных правок.
- 2026-04-28 — Начат честный migration path под распознавание Espressif: введён отдельный `speech_recognition_service.*` как сервисный мост между будущим ASR backend и `voice_command_service.*`, а `/voice-phrase-test` переведён через него, чтобы реальное распознавание подключалось в один канонический вход.
- 2026-04-28 — Для voice-track добавлен отдельный build scaffold `s3sr`: hybrid `Arduino + ESP-IDF`, корневой `CMakeLists.txt`, `src/CMakeLists.txt`, `app_main` bridge, `sdkconfig` defaults и отдельная partition table с `model`-разделом. Статус intentionally промежуточный: обычная `s3` сборка остаётся рабочей, а `s3sr` ещё требует финальной toolchain/backend доводки перед подключением `ESP-SR`.
- 2026-04-29 — Shared audio groundwork продвинут под будущий `ESP-SR`: `audio/audio_capture_service.*` теперь умеет отдавать не только `rms`, но и последний PCM-frame из общего capture path, а `s3sr`-ветка переведена на `16 kHz` sample rate, чтобы следующий backend мог питаться из того же централизованного аудиосервиса без второго владельца I2S.
- 2026-04-29 — Исправлен побочный визуальный дефект после закона `display owns frame timing`: calendar maze pixel в `clock_visuals.cpp` больше не накапливает wall-clock "долг" во время показа погоды/датчиков и не устраивает ускоренный catch-up sprint после возврата циферблата.
- 2026-04-29 — `ESP-SR` переведён из research-идеи в основной `s3` product path без превращения `s3sr` в кастрированный user build. В проект подтянуты минимальные runtime части `esp-sr` и `dl_fft`, основная `s3` сборка получила отдельную product voice partition table с `model`-разделом, а `speech_recognition_service.*` теперь запускает реальный `WakeNet + MultiNet` backend поверх shared PCM frames и очередит совпавшие command slot'ы в `voice_command_service.*`.
- 2026-04-29 — Для product voice-path зафиксирован воспроизводимый комплект артефактов: в репозиторий добавлены selected official models (`wn9_hiesp` + `mn6_en`), pack-скрипт `scripts/build_esp_sr_models.py`, helper `scripts/flash_all_voice.ps1` и готовый `artifacts/srmodels.bin` для model-partition.
- 2026-04-29 — Важное уточнение по voice flashing path: проблема на этом этапе была не только в пользовательских ошибках PowerShell. Даже при корректной полной заливке (`bootloader + partitions + firmware + model + LittleFS`, плюс reset `otadata`) новый voice-build может уходить в reboot-loop уже после старта `ESP-SR`. Это зафиксированный firmware/runtime дефект текущего шага, а не закрытая тема.
- 2026-04-29 — Runtime-debugging voice path сузился от общего reboot-loop к конфликту around `ESP-SR` start window: после переноса сетевой готовности на реальный `STA_GOT_IP` boot начал доходить до OTA/weather/web/sensors, а падение стало воспроизводиться вокруг позднего старта speech-runtime. В ответ background task ownership ужесточён: `weather_service`, `sensors_async` и `voice_command_service` закреплены на `Core 0`, а текущий `speech_recognition_service` debug-pass тоже уведён с hot audio core, чтобы оставить `Core 1` прежде всего под `spectrum_async` / shared audio capture.
- 2026-05-06 — Shared audio ownership был продвинут до следующей реальной границы. `audio_capture_service` разделён на более узкие control/runtime/snapshot модули, введён нейтральный `audio_capture_backend` seam, а сырое чтение микрофона вынесено в `audio_capture_backend_i2s.*`. Самое важное: общий producer больше не считает project-wide FFT. Теперь он публикует только PCM/RMS snapshots, а `audio/spectrum.cpp` считает визуальный FFT локально из shared PCM только тогда, когда режим спектра реально нуждается в этом.
- 2026-05-06 — Weather city search перестал зависеть от прямого browser-side доступа к Open-Meteo: добавлен device-side `/weather-search`, а серверный запрос получил корректный URL-encoding для кириллицы и пробелов. Это убирает срыв поиска в AP/offline-like сценариях браузера и делает weather onboarding ближе к продуктовой модели "часы отвечают за интеграцию, браузер только UI".
- 2026-05-06 — Voice-lab capture path больше не требует заранее существующих `voice_lab_*.wav`: сохранение теперь удаляет старый файл при наличии и создаёт новый заново. Рабочий режим при этом отделён от training-path: template-match больше не пишет новые WAV в `LittleFS`, а использует post-wake буфер только в памяти.
- 2026-05-06 — После clean/erase зафиксирован важный flashing contract voice-build'а: обычный `Upload` поднимает только firmware, но не восстанавливает `model` partition. Для возврата `Hi, ESP` после чистой флешки нужен полный voice-flash (`firmware + LittleFS + srmodels.bin`), иначе runtime честно уходит в `required ESP-SR models are missing`.
- 2026-05-06 — Spectrum/display конфликт в training-пути был ужесточён до явного правила: при `voiceTrainingModeEnabled=true` аудиореактивный visual path должен быть выключен, а renderSpectrum дополнительно облегчён по cadence/FFT update, чтобы матрица не стробила во время voice-focused диагностики.
- 2026-05-07 — Исправлен критичный дефект качества voice-lab записи: wake gain больше не мутирует тот же PCM-буфер, который идёт в WAV/template matching. Для WakeNet/MultiNet теперь используется отдельная усиленная копия, а запись и lightweight template matcher работают на raw PCM без наследования клиппинга.
- 2026-05-07 — Исправлен ещё один критичный дефект temporal integrity voice-lab: `speech_recognition_service` раньше читал только latest shared PCM snapshot и терял промежуточные кадры, из-за чего слово в WAV выглядело ускоренным/сжатым. В `audio_capture_snapshots.*` добавлен небольшой ordered PCM ring, а voice path переведён на последовательное чтение кадров через `getNextAudioCapturePcmFrameAfter(...)`. Это возвращает сохранённым sample'ам естественную длительность и убирает главный артефакт "слово реальное, а в WAV оно как четверть секунды".
- 2026-05-07 — Почищен UX/diagnostics voice lab: post-wake window был слегка увеличен, numbering `voice_lab_0001..0012` теперь живёт по реальным занятым слотам `LittleFS` и переиспользует освобождённые номера после удаления, labels команд больше не режутся по сырым байтам и сохраняются как UTF-8-safe строки до 20 символов, а на время активного sample capture display contour замораживает последний кадр вместо визуального "снега".
- 2026-05-07 — Lightweight template matcher поднят на следующий инженерный уровень: к сравнению огибающих/RMS и ZCR добавлены более явные temporal features (доля активной части слова, положение доминирующего пика, грубая оценка количества выраженных RMS-пиков/слоговой структуры), а их веса в итоговом distance увеличены. Это прямой ответ на наблюдение, что для реальных слов вроде `Проектор` / `Телевизор` чистая нормализованная форма сигнала без temporal акцентов даёт слишком много ложных совпадений.
- 2026-05-07 — Следующий tuning-pass по template matcher сделал command contour менее "слепым" к тихим и длинным словам: выделение активной части стало мягче (`peak RMS` floor снижен, activity threshold ослаблен, контекст вокруг активных кадров расширен), а в runtime log добавлен прямой вывод расстояний по каждому template slot'у. Это переводит tuning из режима "крутим ручки в темноте" в режим наблюдаемого сравнения `slot0 vs slot1` на реальных пользовательских словах.
- 2026-05-07 — Для lightweight command matcher сделан не просто очередной пороговый pass, а смена самой точки наблюдения: кроме coarse summary-признаков он теперь сравнивает активный контур слова как последовательность кадров с time-aligned distance. Это прямой ответ на реальные логи, где `Проектор` / `Телевизор` регулярно давали почти равные `s0/s1` и coarse shape-сводка оказывалась слишком грубой для похожих длинных команд.
- 2026-05-07 — Поверх sequence-aware contour matching добавлен ещё один продуктовый guard: очень сильные совпадения больше не должны отбрасываться только из-за того, что `second-best - best` не дотянул до старого жёсткого gap буквально на несколько тысячных. Теперь matcher принимает и "strong match" путь по комбинации `best score + уменьшенный gap + ratio second/best`, чтобы borderline-but-clean команды не превращались в лишние `matched=false`.
- 2026-05-07 — Для возобновления этой ветки без чатов и длинной раскопки истории добавлен отдельный handoff-док `docs/project/VOICE_COMMAND_MATCHER_ARCHIVE_RU.md`. Он фиксирует именно voice-command matcher track: что уже не надо расследовать заново, какие дефекты уже закрыты, где кодовая точка входа и какой следующий алгоритмический шаг считается правильным.
- 2026-05-07 — Matcher command contour усилен ещё на один шаг в сторону "реального разбора sample": кроме time-aligned sequence comparison он теперь отдельно повышает вес onset-зоны слова и учитывает динамику атаки (`frame-to-frame RMS delta`). Это осознанный ответ на пользовательское наблюдение, что для пары `Проектор` / `Телевизор` именно стартовая согласная (`П` vs `Т`) несёт больше различающей информации, чем хвост слова.
- 2026-05-08 — Проведён отдельный anti-freeze pass по runtime. Найдены и убраны два прямых кандидата на новые лаги матрицы: `display_runtime` больше не делает полный early-return "voice capture hold" без `matrixShow()`, а speech hot path перестал писать подробную wake/template-диагностику в кольцевой runtime log на каждом совпадении. Дополнительно `displayRuntimeStatusMessage` переведён с `String` на `const char*`, чтобы hot render path не дёргал кучу лишний раз.
- 2026-05-08 — Закрыт следующий foundation-pass по verdict'у на voice runtime без преждевременного split больших файлов. `platformio.ini` теперь разводит `env:s3` как product-clean voice build и `env:s3_voice_debug` как лабораторный wake-only/WAV-capture env; template matcher отделён от самого флага voice-lab, так что product path больше не обязан притворяться debug-сборкой. В `audio_capture_control.cpp` client mask защищён критической секцией, а в `audio_capture_snapshots.cpp` полный PCM memcpy вынесен из основной snapshot critical section в staging/swap схему. Дополнительно `speech_recognition_service.cpp` получил heap telemetry вокруг task gate и MultiNet load (`internal free`, `internal largest block`, `SPIRAM free/largest`, `stack high-water`), чтобы дальнейшая стабилизация голоса шла уже не по одному `ESP.getFreeHeap()`.
- 2026-05-08 — Начат следующий runtime-hardening pass уже по живому железному симптому "матрицу трясёт в моменты voice/save/command event". Product path больше не должен бить по display core так резко: частый speech-event serial/runtime-log spam оставлен выключенным по умолчанию, а сохранение `voice_lab` WAV в `speech_recognition_service.cpp` больше не делает один большой blocking `file.write(...)`, а пишет данными по небольшим чанкам с `vTaskDelay(1)` между пачками. Это не считается окончательным root-cause verdict по матричным артефактам, но уже закрывает самые очевидные synchronous side-effect spikes в voice event-path.
- 2026-05-13 — Вместо преждевременного переноса display в отдельный task добавлен явный runtime-audit слой для dual-core карты. `main.cpp`, `display_runtime.cpp`, `system_services.cpp`, `wifi_service.cpp`, `ui/webserver.cpp` и pinned background tasks теперь записывают наблюдаемые `core id` в общий telemetry layer; `/perf-state` и `/state` отдают `loopCore`, `displayCore`, `audioCaptureCore`, `speechRecognitionCore`, `weatherCore`, `sensorsCore`, `voiceCommandCore`, а также `realtime/deferred/Wi-Fi/WebServer` service cores вместе с уже существующими `frame`, `present`, `deadline miss`, `heap`, `largest block`, `audio` и `speech stack` метриками. Это не ещё один refactor-for-refactor, а foundation-шаг: сначала сделать ownership видимым, потом решать, нужен ли отдельный `DisplayTask` и куда именно его пиновать относительно hot audio core.
- 2026-05-13 — Freeze-hunting telemetry усилена без смены архитектуры: `runtime_metrics.*` теперь копит не только last/avg, но и `frameTimeMaxUs`, `matrixPresentTimeMaxUs`, а speech runtime через `speech_recognition_service.cpp` накапливает `speechSlowStepCount`, `speechMaxStepUs` и `speechLastSlowCore`. В serial добавлены one-shot core log для `matrixShow()` и отдельный `[PERF][FRAME] deadline miss ...` путь, чтобы визуальный подфриз можно было связать не только с "медленным кадром", но и с фактическим срывом frame schedule.
- 2026-05-13 — После того как telemetry показала нормальный `matrixShow()`/render cost, но продолжающиеся `frame deadline miss` на `Core 1`, введён минимальный `DisplayTask` foundation вместо полного rewrite. В `main.cpp` cadence display вынесен из прямого владения `Arduino loop()` в pinned task на `Core 1` с фиксированным `vTaskDelayUntil()` шагом, а `loop()` оставлен тонким realtime-shell для текущих non-display service ticks. Это не финальная dual-core архитектура проекта, а контролируемый промежуточный шаг: изолировать сам каденс display от jitter планировщика loop, не перетаскивая пока `Wi-Fi/speech/audio` по новым task ownership границам.
- 2026-05-13 — После успешной стабилизации cadence (`frameMiss=0` в steady state) freeze-hunting переведён с timing на frame ownership. Добавлены display-specific telemetry и ownership guards: `DisplayTask` регистрируется как owner render buffer, `clearBuf()/setBufPixel()` считают off-owner violations, а `/perf-state` теперь показывает `displayScheduled/rendered/presented` seq, текущий render mode, overlay flag, animation phase, render delta, repeated/skipped logic counters и возраст sensor snapshot. Это позволяет отделять "кадр не успел" от "кадр успел, но состояние/буфер дёрнулся".
- 2026-05-13 — Следующий live-log сузил remaining issues ещё точнее: общий scheduler starvation уже не доминирует, но после старта `AudioCap_Task` на `Core 1` появляются настоящие `slow frame` события и непрерывный рост `audioDrop/audioTimeout`. В ответ добавлен диагностический A/B env `s3_audio_off_debug` (`MATRIXCLOCK_AUDIO_CAPTURE_FORCE_DISABLED`) и расширена telemetry: `/perf-state` теперь отдаёт `frameSlowCount`, `frameSlowMaxUs`, `frameLastSlowRenderMode`, `frameLastSlowAudioActive`, `frameLastSlowCore`, а также `audioCaptureClientMask`, `audioCaptureActive` и `audioCaptureLastStartReason`. Цель этого шага не в новой архитектуре, а в честном разделении двух оставшихся классов дефектов: локальный 9x8/render-layer glitch versus глобальный stall после старта audio capture на hot display core.
- 2026-05-14 — Начат отдельный `voice/audio` performance pass уже после закрытия `4x7` ticker regression и containment-починки `bg_infra`. Найден локальный дефект прямо в `audio_capture_backend_i2s.cpp`: `i2s_read()` ждал всего `10` RTOS ticks, хотя один shared PCM frame здесь равен `512` samples, то есть примерно `32 ms` при `16 kHz`. Это означало, что hot audio path мог регулярно объявлять `read timeout/frame drop` раньше, чем успевал набраться полный frame. В ответ timeout чтения привязан к реальной длительности кадра с небольшим запасом, а лишний `vTaskDelay(1)` после успешного чтения убран, чтобы capture loop не добавлял себе искусственную паузу между соседними PCM frames.
- 2026-05-14 — Следующий freeze-hunting pass перевёл diagnosis с общих timing-метрик на содержимое и состояние display buffer. В runtime добавлены `frameHash/leftRegionHash/progressRowHash`, repeat/change counters, baseline reset на `Voice ON/OFF`, heartbeat-поля `fRepD/lRepD/pRepD/fChg/lChg/pChg`, а serial теперь пишет `[VOICE_STATE] ... resetHashBaseline=1 ...` и `[PERF][STATE] ... frameHash=... leftHash=... progHash=...`. Это был не "ещё один лог ради лога", а жёсткая проверка гипотезы "Voice OFF = stale render-buffer".
- 2026-05-14 — Новый hash/baseline verdict изменил направление расследования. Логи показали, что для одинаковых фаз кадра (`dyn=0x07` и др.) pre-`matrixShow()` framebuffer может быть одинаковым при `voice ON` и `voice OFF`, а `fChg/lChg/pChg` продолжают расти и после `Voice OFF`. Значит текущий остаточный симптом больше не выглядит как простой normal-clock render freeze до `matrixShow()`. Главный подозреваемый смещён ниже render-buffer: в output/brightness/gamma/scanout path, signal/power behavior или в side effect того, что `AudioCapture/I2S` активен при `aud=1/mask=0x02` и остановлен при `aud=0/mask=0x00`.
- 2026-05-14 — Под этот новый verdict добавлен следующий диагностический split, не меняющий production-логики: `env:s3_voice_off_audio_forced_on` и `env:s3_voice_on_audio_forced_off`. Первый build принудительно держит shared `AudioCapture` активным при `voiceEnabled=false`, второй — принудительно держит `AudioCapture` выключенным при `voiceEnabled=true`. Реализация проходит через existing audio-capture owner path и compile-time boot defaults для `voiceEnabled`, чтобы A/B на железе был воспроизводимым и не зависел от старого значения в NVS.
- 2026-05-14 — Этот A/B split дал уже не просто намёк, а жёсткий lifecycle verdict. `Voice OFF + AudioCapture ON` оказался визуально чистым, а `Voice ON + AudioCapture OFF` вернул фризы, sparkles, calendar jitter и артефакты progress/ticker path. Значит остаточный visual bug следует за `audioCaptureActive/I2S active`, а не за `voiceEnabled`. Это резко ослабляет render/state как главный remaining root cause и одновременно даёт архитектурную коррекцию: `AudioCapture/I2S` надо трактовать как shared stream service, а `Voice`/`WakeNet` — только как consumer этого потока. Следующий production-safe шаг после этого verdict'а: не останавливать shared audio backend только потому, что `Voice` выключен; сначала внедрить keepalive/lifecycle fix, а уже потом отдельно разбирать PM / Wi-Fi sleep / DFS / output-path первопричину.
- 2026-05-14 — Чтобы связать новый `I2S active/inactive` verdict со старой историей "Wi-Fi connected стабильнее, чем AP/no-Wi-Fi", добавлен отдельный env `s3_pm_stability_test`: `voice OFF`, `AudioCapture OFF`, но Wi-Fi sleep/power-save принудительно отключён через `WiFi.setSleep(false)` и `esp_wifi_set_ps(WIFI_PS_NONE)`. Это не production fix, а чистый split-тест: если `aud=0` в таком режиме визуально очистится, root cause смещается в PM/clock-state/Wi-Fi-sleep область; если нет — keepalive `AudioCapture/I2S` остаётся лучшим практическим stabilizing workaround.
- 2026-05-14 — Production-safe lifecycle fix по этому verdict'у внедрён в основной `env:s3`: shared audio path получил keepalive client (`AUDIO_CAPTURE_CLIENT_KEEPALIVE`), который удерживает `AudioCapture/I2S` активным как инфраструктурный backend даже при `Voice OFF`. Speech/WakeNet остаются только consumer-ами этого потока и должны выключаться отдельно от физического backend. Telemetry теперь также явно отдаёт `audioCaptureKeepaliveWanted`, а `audioCaptureLastStartReason` различает `keepalive`, `voice+keepalive`, `spectrum+keepalive` и комбинированные причины.
- 2026-05-14 — После keepalive-fix основной `Voice OFF -> aud=0 -> постоянные фризы` bug закрыт на железе, но выявился более узкий residual bug: occasional visual hiccups during rapid `Voice ON/OFF` toggling. Новый pass должен уже не трогать keepalive/audio lifecycle policy, а сглаживать сам transition path: coalesced/deferred voice apply, меньше production toggle diagnostics, без немедленного тяжёлого применения в web-handler.
- 2026-05-14 — Toggle-path дополнительно ужесточён: debounce увеличен, добавлен post-apply cooldown, а UI/API получили single-flight policy для `voiceEnabled` toggle. Это не устранило абсолютно все редкие hiccups при агрессивном спам-кликанье, но заметно сузило остаточный дефект. Линия теперь считается практически нейтрализованной и переводится в статус "close for now, re-test after final architecture cleanup".
- 2026-05-14 — Важно: на этом же этапе был внесён отдельный регресс в UI toggle-path. Первая версия `single-flight` блокировки пережала фронт так, что `Voice ON` мог немедленно откатываться в `OFF`. Этот дефект не был исходной проблемой часов и появился в результате неудачной попытки дополнительного сглаживания. Регресс был выявлен и разобран только после внешнего консилиума (`ChatGPT`, частично `Grok`) при координации пользователя, который обеспечивал тесты на железе, сбор логов и сверку выводов. В будущих pass'ах это надо помнить как пример того, что нельзя бездумно усложнять уже стабилизированный control-path.
- 2026-05-14 — После закрытия основной `Voice OFF / aud=0` линии принято ещё одно организационное решение: рабочий build-контур сужается до `env:s3` как normal baseline и `env:s3_voice_debug` как единственного основного debug contour; `env:s3ota` остаётся только OTA-helper для того же baseline. Старые A/B и display-isolation env не удаляются ради дешёвой воспроизводимости истории, но переводятся в архивный статус и больше не должны восприниматься как штатный маршрут разработки.
- 2026-05-14 — Эта же contour-policy распространена и на LittleFS/UI surface. `data/index.html` теперь рендерится из общего `webui/index.template.html` через env-aware pre-script: `s3`/`s3ota` получают облегчённый user UI, а `s3_voice_debug` и прочие diagnostic env — полную diagnostic surface. Runtime terminal (`/runtime-log`), perf/CPU monitor, online matrix preview и voice-lab/debug blocks убраны из normal UI, чтобы сама web-диагностика меньше давила на камень и не выглядела как обязательная часть повседневного интерфейса.
- 2026-05-14 — Contour split распространён и на serial telemetry. `speech_build_config.h` теперь определяет `MATRIXCLOCK_DEBUG_CONTOUR_ENABLED` только для diagnostic env, а `main.cpp`, `hardware/matrix.cpp`, `display_runtime.cpp`, `wifi_service.cpp`, `ui/webserver.cpp` и verbose части `speech_recognition_service.cpp` гейтят шумные `PERF][HB/STATE/FRAME/WIFI/WEB` и boot/info `SPEECH_SR` логи этим флагом. Нормальный `env:s3` должен читаться как operationally quiet baseline; если такая болтовня ещё видна в normal build, это считать stale firmware или недожатым split, а не нормой.
- 2026-05-14 — После облегчения normal UI и quiet-split serial подтверждено, что page-refresh freeze остаётся отдельной линией. Видимый пиксельный фриз при обновлении страницы не объясняется уже закрытой `Voice OFF / aud=0` lifecycle-проблемой и должен дальше расследоваться как `WEB refresh / slow handleClient` track.
- 2026-05-14 — Следующий дешёвый architecture-cleanup step сделан не по симптомам, а по ownership: shared `/update` apply-path вынесен из монолитного `ui/webserver.cpp` в отдельный `ui/update_apply.*`. Это не меняет пользовательское поведение само по себе, но возвращает `webserver` к роли transport/gateway и подготавливает дальнейший cleanup web/write-path без смешивания HTTP-слоя с длинной business-логикой изменения state.
- 2026-05-14 — Ownership-cleanup web write-path продолжен без добавления нового delayed-save механизма: подтверждено, что `ui/state.cpp` уже владеет `markStateDirty()` + debounce-save через `checkAndSave()`, поэтому следующая чистка пошла не в новые слои, а в уменьшение знаний `webserver.cpp` о runtime-мутациях. Voice-config и voice-template apply-path перенесены в `ui/update_apply.*`, а HTTP handlers оставлены в роли parse -> call apply -> send response.
- 2026-05-15 — Web read-path разделён по ownership ещё на один слой: `ui/webserver.cpp` оставлен transport/gateway, а runtime snapshot serialization для `/ui-state`, `/voice-state`, `/weather-state`, `/perf-state` вынесена в `ui/web_state.*`. Это завершает базовое разделение web ownership на `transport / read-state / write-apply`.
- 2026-05-15 — Зафиксирована product policy для onboard `ESP-SR`: он не удаляется из проекта, но normal `s3` не считается его baseline. До завершения архитектурной зачистки `ESP-SR` живёт как `experimental/debug subsystem`; после этого уже принимается решение, можно ли держать его на одном камне с часами или нужен отдельный voice-node MCU.
- 2026-05-15 — Начат каркас будущего 4-channel output boundary без смены поведения single-channel часов: введён `MatrixOutput` abstraction и `SingleChannelMatrixOutput` wrapper, а текущий `matrixShow()` переведён на physical output interface вместо прямой привязки к `strip.Show()`. Four-channel implementation пока не добавляется; задача этого шага — отделить logical render от physical output ownership.
- 2026-05-15 — Перед реальным `FourChannelMatrixOutput` зафиксирован обязательный промежуточный долг: сначала документируется code-backed `GPIO/peripheral map` (LED/I2S/I2C/recovery pin + reserved areas), затем placeholder-таблица будущего 4-channel physical split, и только потом допускается mapping-ready код. Это нужно, чтобы 4-channel не расползся в рендер, эффекты и случайные pin-решения.
- 2026-05-15 — Следующий безопасный слой поверх `MatrixOutput` тоже введён без behavior-change: added mapping-ready contract (`MatrixOutputMode`, `MatrixChannelConfig`, `MatrixPhysicalMapping`). Текущий single-channel output теперь описан как channel `0` на `GPIO12`, covering the full logical matrix, но физически всё ещё работает как прежний один канал. Four-channel implementation по-прежнему не включается.
- 2026-05-15 — Single-channel mapping path дожат до precomputed LUT: `SingleChannelMatrixOutput` теперь валидирует `MatrixPhysicalMapping` и на init/build phase готовит таблицу `physical pixel -> logical frame index`, чтобы hot present path не считал mapping math для каждого пикселя на каждом кадре. Поведение single-channel не меняется; это подготовка к будущим larger/four-channel outputs.
- 2026-05-15 — В дерево добавлен disabled `FourChannelMatrixOutput` skeleton и compile-time output-mode seam. Normal `s3` остаётся жёстко на `single-channel` path; skeleton не владеет реальными GPIO и не меняет runtime behavior. Цель шага — закрыть архитектурный долг "вторая реализация того же MatrixOutput контракта" до реального wiring-pass.
- 2026-05-15 — Channel config layer централизован: current/future channel layout вынесен в `hardware/matrix_channel_config.*`, а shared validation moved to `matrix_output.*`. Теперь `MatrixOutput` строит mapping не из рассыпанных литералов, а из одного compile-time owner. Four-channel placeholders по-прежнему инвалидны по GPIO и обязаны safe-fail validation до реального wiring-pass.
- 2026-05-15 — Добавлена display slack telemetry directly in `DisplayTask` cadence path: `displayFrameBudgetUs`, `displayFrameUsedUs`, `displaySlackLastUs`, `displaySlackMinUs`, `displaySlackAvgUs`, `displayOverBudgetCount`. Это отдельный измерительный слой перед реальным 4-channel wiring: теперь запас display-core оценивается по budget-vs-used, а не только по `frameSlow`/`deadlineMiss`.
- 2026-05-16 — Scheduler/cadence ownership дочищен до явной policy-карты: `system_services.cpp` больше не держит slot enums и интервалы как скрытую локальную мешанину. Новый `system_service_schedule.h` стал каноническим владельцем `DeferredControlServiceSlot`, `DeferredInfraServiceSlot` и cadence policy для `voice/speech/audio lifecycle` и `wifi/rtc/weather/webserver`, а `system_services.cpp` теперь только привязывает эти слоты к runtime handlers и round-robin execution. Это делает scheduler ближе по форме к уже разложенным `web_state / route group / matrix output` ownership boundaries.
- 2026-05-16 — `backgroundInfraTask` получил такой же ownership-pass: slice policy `sensor bootstrap / deferred control / deferred infra / persistence` вынесена из локального enum `main.cpp` в отдельный `background_maintenance_schedule.h`. Это пока ещё не новый scheduler engine, а дисциплина структуры: task-loop остаётся исполнителем, а карта maintenance slices становится отдельным читаемым owner-слоем вместо скрытого знания внутри `main.cpp`.
- 2026-05-16 — Добавлен компактный `service_metadata.h` как сводная карта runtime ownership без изменения поведения. Это не новый registry-framework и не новая истина для cadence/core pinning: файл только индексирует уже существующие owner-слои (`core_affinity.h`, `system_service_schedule.h`, `background_maintenance_schedule.h`) и даёт человеку короткую таблицу `name / group / role / expectedCore / cadenceOwner / telemetryOwner / product/debug` для realtime, deferred control, deferred infra и background maintenance.
- 2026-05-16 — Поверх этого metadata-слоя добавлен дешёвый read-only debug bridge `/service-map`. Endpoint сериализует только статическую ownership-карту из `service_metadata.h`, не вмешивается в scheduler и не смешивается с `/perf-state`. Это не новая система управления сервисами, а runtime-readable индекс для аудита архитектуры без чтения кода.
- 2026-05-16 — Финальный micro-polish по scheduler ownership: `main.cpp` перестал держать даже валидационный хвост policy maintenance slices, а `system_services.cpp` лишился дублирования `intervalMs` внутри локальной deferred schedule table. Source-of-truth по cadence остался только в `system_service_schedule.h`, а source-of-truth по maintenance slice coverage закреплён рядом с `background_maintenance.cpp`.
- 2026-05-16 — После принятого `normal s3 baseline` practical трек 4-channel prep начат с промежуточного `2-channel debug` bring-up. Добавлен env `s3_two_channel_debug`, который не меняет normal `s3`, но переключает `MatrixOutput` в multi-channel mode для split `16x8 + 16x8`: `CH0=GPIO12`, `CH1=GPIO13`. `matrix_channel_config.cpp` теперь умеет отдавать двухканальную mapping-конфигурацию под этим env, а `four_channel_matrix_output.cpp` стал рабочим multi-channel backend для `channelCount=2` без включения полного future 4-channel product path.
- 2026-05-23 — Для того же split-bring-up добавлен отдельный OTA-helper env `s3_2ch_ota`, чтобы случайно не заливать normal `s3ota` на двухканальную разводку. Имя сделано коротким специально под Windows build-path limits. Это не новый product contour и не смена baseline policy, а просто безопасный OTA-маршрут для временного `16x8 + 16x8` debug-подключения.
- 2026-05-23 — Основной `platformio.ini` подчищен от архивного шума: старые A/B и display-isolation env (`s3_audio_off_debug`, `s3_voice_*`, `s3_pm_stability_test`, `s3_dbg_*`) вынесены в отдельный `platformio.archived.ini`, который всё ещё подключается через `extra_configs`, но больше не захламляет ежедневный рабочий контур. Active daily envs остались в главном файле.
- 2026-05-23 — Погодный display-layer собран в один owner: добавлен `weather_display_classifier.*`, который интерпретирует raw `WeatherSnapshot` (`weather_code`, `cloud_cover`, `precipitation_probability`, `precipitation/rain/showers`, `snowfall`, `wind_gusts`, freshness/state`) в осторожные пользовательские формулировки. `weather_service.*` остаётся только fetch/cache/status слоем, `web_state.cpp` начал отдавать classifier labels в `/weather-state`, `clock_visuals.cpp` больше не решает текст погоды напрямую по `weather_code`, а Web UI предпочитает backend display labels вместо собственного raw weather mapping. Это уменьшает риск сценариев вида «по факту ливень/тучи, а устройство уверенно пишет без осадков». Следом classifier-polish сделал `WEATHER_UPDATING` безопасным при наличии cached snapshot, stale-ветка перестала оставлять уверенные `sky/precipitation` labels, диапазон `precipitation_probability 20..29%` теперь формулируется как `Небольшой риск осадков`, а оставшийся мёртвый legacy-path прямого `weather_code -> matrix text` удалён из `clock_visuals.cpp`.
- 2026-05-23 — Поверх unified weather-classifier добавлен ещё и единый phrase-catalog `weather_display_phrases.h`. Это не новый runtime/config слой и не web-редактор фраз, а дешёвый source-of-truth для wording: если пользователя не устраивают формулировки погоды, теперь правится один словарь, а не россыпь строк в classifier и matrix display helper-ах.
- 2026-05-23 — Следующим коротким pass weather ticker тоже перестал жить как ручной `snprintf` внутри `clock_visuals.cpp`: добавлен `weather_ticker_builder.*`, который собирает бегущую строку из секций (`location/date/weather/sky/precip/temp/humidity/wind/pressure`) поверх phrase-конфига из `weather_display_phrases.h`. Это пока firmware-side "конструктор строки", но именно его потом можно будет вынести в weather UI без повторной логики.
- 2026-05-23 — Начат отдельный `weather alerts` слой без подключения реального warning API: добавлены `weather_alerts_service.*` и `weather_alert_display.*`. В первом pass сервис отдаёт отдельный `WeatherAlertSnapshot` из fake/manual compile-time source, `/weather-state` уже экспортирует alert-поля, `weather_ticker_builder.*` умеет префиксовать ticker строкой вида `Внимание: ... до ...`, а матрица получила compact colored alert card со style-level mapping `yellow / orange / red`. При этом current-weather classifier и `weather_service.*` не трогались: alerts идут отдельным параллельным контуром.
- 2026-05-24 — `weather alerts` display layer поднят до системного critical overlay: fullscreen attention/preflash теперь вызывается сверху из `renderClock()` и не зависит от обычного weather-path. Добавлен временный present-brightness override, чтобы alert attention оставался видимым даже при низкой яркости, а one-shot логика заменена на controlled reminder policy: `yellow` повторяется раз в 30 минут, `orange` — раз в 15 минут, `red` — раз в 5 минут (с optional test override macro).
- 2026-05-25 — `danger` visual path переделан под отдельный alert marquee mode: после цветных fullscreen вспышек warning больше не падает обратно в compact card, а продолжает жить как самостоятельная бегущая строка 5x7 на цветном фоне уровня опасности, независимо от обычной погоды. Строб-последовательность теперь дискретная (`yellow=2`, `orange=3`, `red=4` вспышки), а reminder policy продолжает периодически запускать её заново, пока alert остаётся активным.
- 2026-05-25 — `danger` отделён от обычной погоды и по ownership/state surface: weather ticker больше не префиксуется warning-текстом, `/weather-state` снова держит только current-weather snapshot и classifier labels, а предупреждения вынесены в отдельный `danger` API contour с `/danger-state`, отдельным service/display owner-слоем и отдельной service identity в deferred infra.
- 2026-05-25 — Wrapper-этап закрыт: `danger_service.*` и `danger_display.*` перестали быть тонкими прокладками поверх `weather_alerts_*` и стали настоящими owner-слоями fake/manual source, overlay-state, strobe/reminder policy и danger marquee path. `weather_alerts_service.*` и `weather_alert_display.*` оставлены только как compatibility-адаптеры без права владения живым runtime.
- 2026-05-25 — Текущее поведение бегущих строк зафиксировано как эталон проекта: weather ticker и danger marquee выровнены по frame cadence, убраны дёргания, спотыкания, truncation-регрессии и лишние hot-path пересчёты. Для этих часов это считается канонической реализацией marquee/ticker-вывода и должно сохраняться как source-of-truth для будущих правок render path.
- 2026-05-25 — Добавлена provider-граница для future warning sources: `danger_service.*` остался owner-слоем lifecycle/cache/status/cadence, `danger_provider_stub.*` сохранил fake/manual тестовый режим, а поверх него добавлен первый реальный proof-provider `danger_provider_meteoalarm_atom.*` для Украины. Этот provider читает публичный MeteoAlarm Atom feed, фильтрует CAP `polygon/status/expires` по текущим weather-координатам, не лезет в render path и не владеет cadence/cache. `/danger-state` теперь отдаёт `dangerProvider`, `dangerSupported` и `dangerMessage`, а при provider failure сервис сохраняет последний валидный snapshot и переводит его в stale только по TTL вместо немедленного обнуления.
- 2026-05-25 — Перед первым реальным hardware-тестом MeteoAlarm Atom provider дожат ещё на один stabilizing pass: большие polygon buffers вынесены со stack в static namespace storage, добавлен `Content-Length` guard на XML feed (`128 KB`), а `/danger-state` JSON doc увеличен до `2048`, чтобы реальные `headline/region/description` не резались переполнением. Следующий шаг по этой линии теперь уже не новый refactor, а живой `/danger-state` результат на железе в режимах `Wi-Fi off / NTP not ready / weather location not ready / no active alert / active alert`.
- 2026-05-25 — Живой hardware smoke-test MeteoAlarm Atom для Украины подтверждён. Реальный `/danger-state` на часах вышел в состояние: `dangerProvider="meteoalarm_atom"`, `dangerSupported=true`, `dangerDataReady=true`, `dangerStale=false`, `dangerActive=false`, `dangerMessage="no active danger alerts for location"`. Это считается PASS для первого реального provider-proof на железе: HTTPS fetch, Atom XML parsing, CAP `status/expires/polygon` filtering и service-owned precondition recovery отработали корректно. Следующий шаг по этой линии теперь уже не чинить текущий UA path, а после резервного архива идти в MeteoAlarm country-feed map foundation для Европы.
- 2026-05-25 — Для линии `2-channel random sparks` закрыт первый сильный software-кандидат: temporary two-channel contour больше не использует `NeoPixelBus` bitbang-path. `s3_two_channel_debug` и `s3_2ch_ota` переведены обратно на аппаратный RMT через `NeoEsp32RmtNWs2812xMethod` с явным разнесением strip-ов по независимым channel `0/1`. Это должно убрать редкие цветные искры, характерные для bitbang-передачи WS2812 под живыми `Wi‑Fi/audio` interrupt load, не возвращая старый single-channel RMT conflict.
- 2026-05-25 — Прямой hardware A/B тест по `bitbang` закрыл эту линию достаточно жёстко для текущего железа: `bitbang + Wi‑Fi ON` даёт sparkles, `bitbang + Wi‑Fi OFF` убирает их, а при возврате `Wi‑Fi ON` sparkles возвращаются снова. Значит Wi‑Fi/RF activity действительно участвует в срыве запаса устойчивости WS2812-линии. Текущий технический verdict такой: `bitbang` не является `production-safe` на текущем железе при `Wi‑Fi ON`, `RMT` является текущим preferred/default production path, а `bitbang` должен оставаться доступным как diagnostic/fallback contour для повторного сравнения после железной ревизии линии данных. Следующий реальный шаг по стабилизации лежит в signal-integrity hardware (`SN74AHCT125/SN74AHCT245`, 220–470Ω data resistor, рекомендуется 330Ω, общий GND, 1000–2200µF на 5V матрицы, 100nF возле AHCT, короткие DATA-линии рядом с GND), а не в новых попытках спасать bitbang в чистом софте.
- 2026-05-15 — Для линии `browser refresh / web pressure` добавлена endpoint-level web telemetry. `runtime_metrics.*` теперь хранит compact per-route timing для `/`, `/state`, `/ui-state`, `/weather-state`, `/perf-state`, `/runtime-log`, `/voice-state`, `/voice-lab-list`, `/matrix-frame`, `/update`, а `/perf-state` и полный `/state` отдают `webEndpointSlowestName`, `webEndpointSlowestUs`, `webEndpointSlowCount` и небольшой `webEndpointsTop[]`. Следующий шаг по этой линии должен опираться уже на конкретный route-виновник, а не на общий `handleClient()` verdict.
- 2026-05-15 — После измерений normal `s3` линия `web pressure` уточнена: `Core 1` display budget остаётся здоровым, а самым тяжёлым product-route оказался `/perf-state`. Поэтому `perf`-контур разделён на `light product` и `heavy debug`: `/perf-state` теперь держит только краткий product snapshot и web endpoint summary, а подробная diagnostic perf-секция вынесена в `/perf-debug-state`. Это не emergency fix, а подготовка baseline перед реальным 4-channel wiring-pass.
- 2026-05-15 — Root/static serving вынесен в отдельный ownership layer `ui/web_static.*`. `webserver.cpp` снова остался transport/router, а `/` теперь обслуживается через explicit static service с preference `index.html.gz -> index.html -> fallback`. Для этой линии добавлены отдельные метрики `webStaticRootTotalUs`, `webStaticRootOpenUs`, `webStaticRootStreamUs`, `webStaticRootLastBytes`, `webStaticRootUsedGzip`, `webStaticRootFallbackCount`, `webStaticRootOpenFailCount`, `webStaticRootLastPath`, доступные через `/perf-debug-state`. Это нужно, чтобы следующий шаг по линии `slow "/"` шёл уже по факту: тормозит `LittleFS.open`, `streamFile` или сам page weight.
- 2026-05-15 — В UI build pipeline добавлена автоматическая генерация `data/index.html.gz` из `webui/index.template.html` через `scripts/select_ui_variant.py`. `web_static` уже умеет предпочитать gzip-версию, а `buildfs` подтверждает включение `/index.html.gz` в LittleFS image. На текущем normal UI размер root payload сокращён примерно с `151642` до `31827` байт, так что следующий hardware-pass должен уже показать, насколько упадут `webStaticRootLastBytes`, `webStaticRootStreamUs` и общий `"/"` spike.
- 2026-05-16 — Web route ownership продолжен ещё на один слой: voice-specific HTTP endpoints вынесены из общего `ui/webserver.cpp` в отдельный `ui/voice_routes.*`. Теперь `webserver.cpp` удерживает transport/router роль, `web_static.*` владеет root/static serving, `web_state.*` сериализует runtime snapshots, `update_apply.*` владеет write/apply path, а `voice_routes.*` содержит `/voice-state`, `voice-lab`, `voice-config`, `voice-template`, `voice-action` и `voice-phrase-test` route group. Это не меняет product behavior, но уменьшает knowledge-mixing в монолитном web layer и упрощает дальнейшее разделение feature clients/handlers.
- 2026-05-16 — Следующий слой того же cleanup завершён: debug/system HTTP handlers вынесены из `ui/webserver.cpp` в `ui/debug_routes.*`. Туда перешли `/state`, `/perf-state`, `/perf-debug-state`, `/runtime-log`, `/matrix-frame` и `/fs-status`, тогда как `webserver.cpp` остался transport/router с root, light state, update-path и регистрацией route groups. Это ещё сильнее уменьшает knowledge-mixing между transport, debug snapshots и feature clients и подготавливает дальнейшее сжатие `webserver.cpp` до почти чистой registration surface.
- 2026-05-16 — После экспорта и реального аудита state JSON закрыт ещё один ownership-хвост: полный `/state` больше не собирается вручную внутри `ui/debug_routes.cpp`. Полная debug snapshot assembly перенесена обратно в `ui/web_state.*` через `fillFullState(...)`, так что route layer снова отвечает только за HTTP wiring, а не за знание половины runtime-полей проекта.
- 2026-05-16 — Следом вычищена и смешанная ответственность `/voice-state`: endpoint больше не тянет в себя общий `ui-state` config block (`brightness/font/calendar/timezone/colors/...`) через `fillUiStateEssential(...)`. `voice_routes.cpp` теперь отдаёт voice-centric snapshot из `fillVoiceState(...)`, а сами voice-specific settings (`voiceEnabled`, `voiceSensitivity`, `voiceWakeTriggerSlot`, `voiceTrainingModeEnabled`) оставлены внутри voice payload, чтобы вкладка Voice не теряла автономность.
- 2026-05-25 — Для линии `browser refresh / audio-debug seam` обычный `voice` read-path разделён ещё и по весу payload: `/voice-state` оставлен лёгким runtime/UI snapshot без тяжёлых template-debug полей по каждому command slot, а полный диагностический payload вынесен в `/voice-debug-state`. Это нужно, чтобы refresh вкладки `Голос` не тащил лабораторный command/template груз в обычный runtime sync и не смешивал пользовательский polling с отладочным ownership.
- 2026-05-25 — Для линии `refresh -> рассыпание текста на пиксели` добавлен scanout-consistency guard в matrix output path. И single-channel, и multi-channel RMT path теперь проверяют `strip.CanShow()` до перезаписи внутреннего NeoPixelBus буфера; если предыдущая передача ещё не завершена, present пропускается и учитывается отдельным счётчиком `matrixPresentSkippedBusyCount`. Это не про “ускорение веба”, а про защиту целостности кадра: лучше кратко пропустить present, чем перетирать RMT scanout-буфер на полупередаче и получать разваленный текст.
- 2026-05-25 — Для проверки display-isolation seam realtime keepalive shell убран с `Core 1`: `loop()` больше не вызывает `handleRealtimeServices()`, а сам realtime-slice перенесён в `background_maintenance` на `Core 0`. Это не про web payload и не про matrix mapping, а про жёсткую изоляцию display-owner: `Core 1` должен держать только `DisplayTask` и hot audio producer, без дополнительного service-shell рядом с RMT scanout.
- 2026-05-25 — Для линии `browser refresh -> matrix jitter` доведён ещё один cleanup-pass вокруг audio/voice debug tails: `voice-lab` отвязан от обычного auto-refresh, `/voice-state` облегчён до runtime-snapshot без тяжёлых template/debug payload, полный diagnostic слой вынесен в `/voice-debug-state`, а stale `audio capture keepalive` больше не живёт при `voiceEnabled=false`. Все эти шаги признаны правильными и полезными для cleanliness/ownership, но корневой refresh-glitch они не закрыли.
- 2026-05-25 — Дополнительная диагностика показала важный разворот: даже при `audioCaptureActive=false`, чистом `Core 1`, нулевых `displayOverBudget/frameSlow/deadlineMiss/writeViolation` и низком `matrixPresentSkippedBusyCount` матрица всё ещё может визуально дёргаться при browser refresh. Значит обычный scheduler/render telemetry verdict сейчас недостаточен: логический кадр считается здоровым, а physical image на матрице всё равно может ломаться.
- 2026-05-25 — Введён `MATRIXCLOCK_STATIC_SCANOUT_TEST` и отдельный diagnostic env для полностью неподвижного тестового кадра. Он bypass-ит normal clock/weather/danger/ticker rendering и рисует только фиксированный pattern. Живой hardware verdict по этому тесту критичен: если даже статичный кадр дёргается при refresh, обычный renderer уже не считается главным подозреваемым, а корень смещается ниже — в `active WS2812 scanout / RMT transport interaction / electrical margin`.
- 2026-05-25 — Диагностический `web-present suppression` выполнил свою задачу как доказательство, но признан непригодным как product behavior: он превращает рассыпание кадра в заметный стоп-кадр. Поэтому suppression переведён в чисто compile-time diagnostic policy (`MATRIXCLOCK_WEB_PRESENT_SUPPRESSION_DIAG`), а следующий взрослый тест смещён на `physical present cadence` вместо заморозки экрана. Для этого добавлен `MATRIXCLOCK_MATRIX_PRESENT_MIN_INTERVAL_MS`, telemetry `matrixPresentSkippedCadenceCount / matrixPresentMinIntervalMs / matrixPresentLastPhysicalAgeMs` и отдельные 30 FPS diagnostic env-ы, плюс low Wi-Fi TX-power env для проверки гипотезы про `scanout + Wi-Fi burst/electrical margin`.
- 2026-05-25 — Для отдельной проверки гипотезы `bitbang sparkles <- Wi‑Fi radio/activity` добавлен специальный diagnostic contour `s3_2ch_bitbang_wifi_off_diag_ota`. Он намеренно оставляет two-channel `bitbang`, но через non-blocking state machine в `wifi_service.*` после первой минуты работы полностью выключает `WiFi.mode(WIFI_OFF)` на 60 секунд, а затем один раз возвращает штатный reconnect через существующий Wi-Fi service path. Это не product feature и не попытка чинить RMT path; это жёсткий A/B тест: исчезает ли snow/sparkle именно во время полного Wi‑Fi OFF окна.

## <span style="color:#FF4D4F;">Красный статус: открытый matrix refresh incident</span>

<span style="color:#FF4D4F;"><strong>Проблема не закрыта.</strong></span> На текущем этапе остаётся реальный незакрытый дефект: при `browser refresh` матрица может кратко дёргаться или рассыпать картинку, хотя standard telemetry (`displayOverBudgetCount`, `frameSlowCount`, `frameDeadlineMissCount`, `displayWriteViolationCount`) показывает здоровый render/runtime path.

Что уже сделано правильно, но не решило корень:
- переход `2-channel` с `bitbang` на `RMT` закрыл `random sparkles`, но открыл отдельную линию `refresh jitter`
- endpoint/web cleanup (`/voice-state`, `/voice-debug-state`, lazy voice-lab, buffered root path) оказался полезным housekeeping, но не снял визуальный defect
- `CanShow()` guard защитил от явной порчи NeoPixelBus буфера, но не убрал сам глюк
- вынос realtime shell с `Core 1` и отключение stale audio keepalive не дали корневого эффекта
- чистые telemetry-метрики больше не являются достаточным доказательством "display path healthy"

Текущая рабочая граница расследования:
- normal renderer выше `renderClock()` уже практически исключён
- тесты `static scanout` и `static hold` уже показали, что без активной передачи картина не дёргается
- текущий оставшийся software verdict: `active WS2812 scanout + Wi‑Fi burst` остаётся чувствительной зоной даже на `RMT`
- дальнейшие product-глупости вроде web-suppression / stop-frame / 30fps-freeze не считаются решением и должны оставаться только временными diagnostic выводами, а не постоянной policy
- 2026-05-25 — Следом убран и сам старый always-on audio keepalive из обычного idle path: `AUDIO_CAPTURE_CLIENT_KEEPALIVE` больше не держится включённым при `voiceEnabled=false`, даже если build собран с `MATRIXCLOCK_AUDIO_CAPTURE_KEEPALIVE`. Теперь keepalive привязан к реальному voice-enabled состоянию, а не живёт как вечный debug-мотор рядом с display contour.
- 2026-05-14 — Отдельно зафиксирована дисциплина правок: не лечить системные симптомы локальными костылями "лишь бы работало". Перед каждым fix-pass сначала определяется класс дефекта (`локальный` vs `системный`). Локальные UI/CSS/изолированные баги можно чинить точечно; системные ownership/lifecycle/runtime цепочки должны лечиться на уровне правильного владельца логики либо явно откладываться как составная часть будущей архитектурной перестройки.
- 2026-05-14 — Начат отдельный architecture-pass по `Core 0 / Core 1` ownership без преждевременной смены самой runtime-policy. Вместо дальнейшего размножения локальных `static constexpr ... CORE = 0/1` введён канонический `src/core_affinity.h`, а `main.cpp`, `speech_recognition_service.cpp`, `voice_command_service.cpp`, `weather_service.cpp`, `sensors_async.cpp` и `audio/audio_capture_backend_i2s.cpp` переведены на этот общий слой. Это не "перетаскивание задач по ядрам ради эффекта", а подготовка: сначала one-source-of-truth для pinning policy, потом уже любые осмысленные изменения dual-core архитектуры.
- 2026-05-14 — Verification-pass для core-affinity закрыт без смены policy: raw task-pinning literals в активных task-create путях больше не используются, а normal `s3` теперь печатает один компактный startup log `[CORE_MAP] display=... infra=... audio=... speech=... sensors=... weather=... voicecmd=...`. Это даёт дешёвую живую проверку карты ядер без возврата к шумной debug-телеметрии.
- 2026-05-14 — Выполнен первый `Core 1` ownership audit без переносов задач. Вердикт: `Core 1` сейчас допустимо держит `DisplayTask`, render/present path, `matrixShow()`, hot `AudioCapture` producer и тонкий `loop()` shell. При этом `handleSpeechRecognitionService()` и `handleAudioCaptureService()` всё ещё вызываются из shell на `Core 1`; это пока терпимо и без прямого behavior-change не трогается, но отмечено как следующий архитектурный кандидат на дальнейшее истончение `Core 1`. Web/JSON/FS/NVS/Wi-Fi/weather/sensors/heavy speech work на `Core 1` по policy не допускаются.
- 2026-05-08 — Проведён foundation hardening pass #2 без добавления новых фич. `audio_capture_snapshots.cpp` дожат до buffer-index/metadata модели на producer-side: publish critical section больше не копирует PCM sample arrays и занимается только индексами/метаданными. Для `speech_recognition_service.cpp` убрано прямое владение `sensors_async`: подготовка к command-model load теперь идёт через barrier API, owned самим `sensors_async.*`, а не через прямые `stop/init` вызовы из speech-слоя. Web state разделён по весу опроса: `/ui-state` оставлен лёгким, а voice/perf/weather payload вынесены в `/voice-state`, `/perf-state` и `/weather-state`; `/state` сохранён как полный ручной debug endpoint. Одновременно добавлены audio runtime metrics (`audioCapturePublishTimeUs`, `audioCaptureReadTimeoutCount`, `audioCaptureFrameDropCount`, `audioCaptureTaskStackHighWaterBytes`) для живой диагностики hot path.
- 2026-05-08 — Отдельно зафиксирована archive hygiene policy для review/handoff пакетов: `.pio/`, случайные build logs, machine-local `platformio.local.ini` и ненужные копии `managed_components/` не должны попадать в обычные инженерные архивы. Полный local debug snapshot допускается только как явно помеченный special-case архив, а не как default handoff package.

---

## <span style="color:#67C587;">Следующее действие</span>

Следующий рабочий шаг:
- `normal s3` baseline уже принят как продуктовый контур после architecture cleanup:
  - `audioCaptureActive=true`
  - `audioCaptureClientMask=4`
  - `speechRecognitionState=\"disabled\"`
  - `displayOverBudgetCount=0`
  - `frameSlowCount=0`
  - `displayWriteViolationCount=0`
- practical ветка продолжается через промежуточный `2-channel debug` bring-up:
  - проверить split `CH0=GPIO12` + `CH1=GPIO13`
  - подтвердить logical mapping `left 16x8 + right 16x8`
  - после этого собрать GPIO/peripheral conflict table для `CH2..CH3`
  - затем подготовить wiring plan под `74AHCT125/245`
- для `danger` не открывать новый архитектурный pass до живого результата `/danger-state`:
  - живой UA hardware smoke-test уже получен и принят:
    - `dangerProvider="meteoalarm_atom"`
    - `dangerSupported=true`
    - `dangerDataReady=true`
    - `dangerStale=false`
    - `dangerActive=false`
    - `dangerMessage="no active danger alerts for location"`
  - перед следующим шагом сделать резервный архив этого milestone
  - только после архива продолжать через MeteoAlarm country-feed map foundation для Европы
  - provider-select convenience и отдельный `NWS` не открывать раньше country-map foundation без новой причины
- не возвращаться к broad runtime/scheduler refactor без новой причины: текущий ownership cleanup считать завершённым этапом
- не смешивать future `4-channel` preparation с возвратом к onboard `ESP-SR`; voice path остаётся отдельной experimental веткой и не определяет normal `s3` baseline

---

## <span style="color:#4EA1FF;">Итоговый статус</span>

<span style="color:#67C587;"><strong>Состояние проекта:</strong></span>
- Working
- Cleaned up
- Documented
- Evolving with recorded history
- Stage 2 separation сильно продвинут
- One firmware path for with/without optional RTC
- DS3231 hardware validation passed
- Ready for final Stage 1 gate decision


## 2026-05 Display/Voice Diagnostic Synthesis

### Confirmed Split

- There are at least two separate bug classes and they must not be mixed in one fix pass.
- Class A: normal-clock render/layer conflict around `calendar + progress + ticker/date`.
- Class B: dynamic spark/twitch/ghost instability that correlates with voice/audio/runtime state and may also affect non-clock visuals.

### What Recent A/B Tests Proved

- `s3_dbg_no_calendar`, `s3_dbg_no_progress`, `s3_dbg_no_calendar_progress`, and `s3_dbg_no_ticker_date` removed the original local left-side calendar/progress defect.
- A narrow layer-isolation fix then removed the old calendar freeze and the last progress-pixel flicker in the normal `s3` build when voice remained enabled.
- The same pass introduced a `5x3` regression: ticker/date clipping became too global and now incorrectly blocks left-side drawing when the calendar region is not actually reserved.
- When voice is disabled, visual artifacts can return in a changed form: twitching, colored sparks, broader instability, and clock/effect degradation are observed even though the old pure layer bug was already partially fixed.

### Current Interpretation

- The old local calendar/progress symptom was real and software-side. The layer-fix direction was correct but incomplete.
- The remaining instability is not yet proven to be "WakeNet is simply too heavy". That conclusion is still premature.
- The most suspicious bridge from voice to the display core is currently the shared audio path:
  - `speech_recognition_service` runs on `Core 0`,
  - `audio capture backend` runs on `Core 1`,
  - `DisplayTask` / display runtime / present path also live on `Core 1`.
- Therefore voice may affect `Core 1` indirectly through audio-capture lifecycle, shared memory pressure, interrupts, heap/PSRAM pressure, or render-state coupling.

### Architecture Rule Reconfirmed

- `Core 1` remains display-owner and must not receive a broad migration of speech logic.
- Do not move `WakeNet`/speech to `Core 1` as a first response.
- Any future use of spare time on `Core 1` must be explicit, low-priority, short, and preemptible, and only after telemetry-backed proof.

### Next Action Plan

1. Fix the `5x3` clipping regression by making left-side ticker/date clipping conditional on actual calendar ownership instead of a permanent left clip.
2. Extend telemetry for voice/audio/render correlation:
   - `voiceEnabled`
   - `voiceActive`
   - `audioCaptureActive`
   - `audioCaptureClientMask`
   - `audioCaptureLastStartReason`
   - `audioCaptureStartStopSeq`
   - `currentRenderMode`
   - `fontMode`
   - `calendarVisibleThisFrame`
   - `progressVisibleThisFrame`
   - `tickerVisibleThisFrame`
   - `calendarRegionReserved`
   - `tickerClipLeftPx`
   - `frameSlowCount`
   - `frameSlowMaxUs`
   - `frameLastSlowCore`
   - `frameLastSlowStep`
   - `frameLastSlowRenderMode`
   - `frameLastSlowAudioActive`
   - `displayWriteViolationCount`
3. Add slow-frame context so each `[PERF][FRAME] slow frame` event can be correlated with:
   - voice/audio state,
   - current render mode,
   - last display stage,
   - time since last audio start/stop,
   - time since last slow web event.
4. Run a focused matrix after telemetry is in place:
   - voice ON, normal clock
   - voice OFF, normal clock
   - voice OFF with audio capture forced disabled
   - voice ON with audio capture forced disabled
   - `5x3` voice ON
   - `5x3` voice OFF
5. Only after the mechanism is proven, choose the next fix line:
   - audio lifecycle cleanup,
   - speech throttling/yield on `Core 0`,
   - or deeper resource balancing.

### Explicit Non-Goals For The Next Pass

- No scheduler rewrite.
- No `DisplayTask` redesign.
- No `matrixShow()` changes.
- No broad move of speech to `Core 1`.
- No mixing this pass with the separate `single_pixel` ghosting track.

---

## Core 1 Ownership Cleanup Notes

- `core_affinity.h` remains the canonical source of task pinning policy.
- After the audit, `Core 1` loop-shell cleanup was continued without moving realtime producers:
  - `handleVoiceService()` control/state polling was moved from the `Core 1` shell to deferred `Core 0` servicing;
  - `handleSpeechRecognitionService()` control polling was moved from the `Core 1` shell to deferred `Core 0` servicing;
  - `handleAudioCaptureService()` control polling was moved from the `Core 1` shell to deferred `Core 0` servicing.
- This does **not** move:
  - `DisplayTask`
  - `matrixShow()`
  - render path ownership
  - `AudioCapture` producer task
  - shared-audio keepalive policy
- Resulting intent:
  - `Core 1` should carry display/output ownership plus only short realtime shell pieces;
  - backend lifecycle control for speech/audio should increasingly live on `Core 0`.

## Normal vs Debug Display Telemetry

- Heavy display hash diagnostics are now intentionally split out of normal `s3`.
- Normal `s3` no longer computes/returns by default:
  - `frameHash`
  - `leftRegionHash`
  - `progressRowHash`
  - hash repeat/change counters
  - `displayHashBaselineEpoch`
  - verbose `[PERF][STATE]`
  - hash-heavy `[PERF][HB]`
- `s3_voice_debug` keeps that telemetry for investigation.
- Normal `s3` still keeps runtime-safety telemetry needed for product validation:
  - frame/present maxima
  - slow/deadline counters
  - write-violation counters
  - audio state/drop/timeout
  - core ids
  - stack high-water values

## Product Voice Overlay

- Added a small product-mode voice feedback overlay on the matrix.
- Ownership rule is preserved:
  - speech/voice paths only publish UI events;
  - display overlay is drawn only from `display_runtime` / display-owner path.
- Event set:
  - wake detected
  - command listening
  - command matched
  - command failed
  - timeout
- Normal `/state` also exposes compact counters/status for these voice UI events.
- Command-template readiness diagnostics were added for product/debug validation:
  - `/state.voiceCommands[]` now shows whether each template path is configured, whether the file exists, file size, load-attempt status, loaded/valid flags, and an exact load error;
  - speech runtime no longer reports only `need templates for both commands`, but instead surfaces the concrete failing condition or slot.
- Latest hardware verdict for onboard `ESP-SR` on the main `S3`:
  - wake word path works;
  - template files can exist and validate correctly;
  - however the post-wake command/template-matching path still fails in real usage often enough and, more importantly, causes visible runtime pressure on the display controller (`frameSlowCount`, `frameSlowMaxUs`, `matrixPresentTimeMaxUs`, `speechMaxStepUs`);
  - this line is therefore not treated as "just needs more tuning", but as having reached the practical runtime/core ceiling of the current single-controller architecture.
- Planning consequence:
  - pause further broad onboard `ESP-SR` tuning on the main `S3`;
  - preserve diagnostics and conclusions;
  - evaluate future voice work as a separate-MCU voice node or a simpler local trigger instead of continuing to load the main display controller.
- 2026-05-14 — After that verdict, the default build contours were cut apart at build time instead of only by policy wording:
  - `env:s3` now builds as a quiet clock-first baseline without onboard `ESP-SR` and without the voice/model partition baggage;
  - onboard speech research moved behind `env:s3_voice_base` and `env:s3_voice_debug`;
  - archived voice A/B envs now extend the voice base instead of the normal clock baseline.
