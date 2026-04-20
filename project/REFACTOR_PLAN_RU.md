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
- Внутри этого правила теперь отдельно зафиксирован `README mirror check`: важные политики и механизмы из `PLAN` / `RULES` должны коротко отражаться и в `README`.

---
## <span style="color:#4EA1FF;">Модель документации</span>

- `README_RU.md` — описательный слой проекта: что это, как устроено, что умеет, куда движется.
- `REFACTOR_PLAN_RU.md` — технический слой: стадии, журнал изменений, фиксация решений, статус по этапам и ценность задач.
- `README` не должен спорить с планом.
- План не должен переписывать уже зафиксированную историю, а только дополнять её.
- Пока проект находится в активной инженерной фазе, живая обязательная синхронизация ведётся только в русской документации.
- Английская ветка документации считается отложенным переводным слоем и не должна обновляться на каждом локальном шаге рефактора.
- Если функция, решение или направление устарели, это отмечается отдельной записью, а не тихой заменой старого смысла.
- Любые документы с русским текстом должны создаваться и сохраняться только в UTF-8 без смешивания с Windows-1251.
- Буквальные backtick-r-backtick-n последовательности не должны оставаться в текстовых файлах проекта как видимый текст после правок; переносы должны быть настоящими переносами строк.
- После любых многострочных scripted edits и массовых замен обязательно запускается `scripts/check_literal_newlines.ps1`.
- Для shell-работы должна соблюдаться дисциплина стабильных command-prefix patterns: чем меньше лишнего разнообразия в формах команд, тем лучше работают сохранённые разрешения и тем меньше лишних запросов в процессе.
- Язык программирования и технические идентификаторы не переводятся; переводится человеческий слой — комментарии, объяснения, русская документация и русский UI.
- Экономия ресурса является частью проектной дисциплины, но не допускается за счёт надёжности, верификации и качества продукта.
- Внешний обычный ChatGPT допускается только как дешёвый draft-worker для локальных задач; финальная интеграция, проверка, архитектурное решение и документальная синхронизация остаются за Codex.

---

## <span style="color:#4EA1FF;">Текущее состояние</span>

- Платформа: `ESP32-S3`
- Целевой модуль: `N16R8`
- Матрица: `WS2812 32x8`
- Board profile выровнен под `N16R8`
- `LittleFS` работает
- Web UI работает
- OTA работает
- Огонь оставлен один: `Fire`
- `Fire` работает через файловую анимацию из `LittleFS`
- Старые процедурные ветки огня удалены

---

## <span style="color:#FF9B5E;">Направление проекта</span>

Текущий курс проекта:
- сохранить рабочую базу часов
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

**Статус:** <span style="color:#FFB347;">Pending</span>

---

### <span style="color:#4EA1FF;">Stage 2 — Разгрузить архитектуру</span>

- Разделить `main.cpp` по зонам ответственности
- Собрать глобальное состояние в понятные структуры
- Разделить выбор сцены и сам рендер
- Привести async-task lifecycle к нормальному виду

**Статус:** <span style="color:#FFB347;">Pending</span>

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

- `Stage 1` — <span style="color:#FFB347;">приоритетно добивается до завершения</span>
  - добавлена валидация runtime/state значений в `state.cpp` и `webserver.cpp`
  - runtime state normalization теперь проходит через единый слой в `state.*`, а не дублируется между `loadState()` и `/update`
  - старт по Wi-Fi больше не блокирует прошивку навсегда
  - Wi-Fi credentials вынесены в persisted state, а dev bootstrap путь отделён от продуктового сценария
  - backend-основа для продуктового Wi-Fi contour уже начата: AP fallback, scan/status/config endpoints
  - browser-side Wi-Fi onboarding panel уже встроена в Web UI, а сохранение credentials для reboot идёт без debounce-рискa
  - Wi-Fi onboarding теперь имеет базовую валидацию конфигурации и не делает `Save & reboot` при заведомо плохом SSID/password
  - Web UI получил tabbed navigation, чтобы длинный single-column layout не мешал дальнейшему росту проекта
  - `LittleFS` теперь имеет явный runtime-state и наружный status endpoint, а не остаётся неявным сервисом с угадываемым состоянием
  - OTA lifecycle теперь имеет явный runtime-state и отложенный reboot после успешного апдейта вместо слишком раннего рестарта сразу после OTA success
  - `Wi-Fi / OTA` lifecycle теперь имеет явные runtime messages и корректный переход через disconnect/reconnect, чтобы OTA не застревала в старом initialized-состоянии после потери сети
  - `sensor async` теперь имеет явный runtime-state, безопасный stop-path и наблюдаемый state через web layer вместо неявной task-схемы “на доверии”
  - `audio async` теперь тоже имеет явный runtime-state, безопасный stop-path и наблюдаемый state через web layer вместо немого старта FFT task
  - `display runtime` теперь тоже имеет явный runtime-state и message через `/state`, так что IP overlay / fade-in / clock / spectrum больше не являются скрытым внутренним поведением без наблюдаемого статуса
  - введён минимальный runtime metrics layer: `frameTimeUs`, `frameTimeAvgUs`, `freeHeapBytes` теперь отдаются через `/state` как базовый инженерный контроль
  - `LittleFS` больше не форматируется молча при первом сбое монтирования
  - инициализация датчиков переведена на безопасные повторные попытки
- `Stage 2` — <span style="color:#67C587;">частично выполнен</span>
  - стартовые сервисы вынесены в `system_services.*`
  - bootstrap датчиков вынесен в `sensor_bootstrap.*`
  - `main.cpp` уже разгружен, а display/runtime orchestration вынесена в `display_runtime.*`; файл всё ещё крупный, но больше не держит на себе весь экранный flow целиком
- `Stage 3` — <span style="color:#FFB347;">частично задет</span>
  - удалены временные файлы и мёртвые code paths
  - `platformio.ini` приведён в чистый вид
  - machine-specific OTA настройки пока ещё остаются, но для них уже подготовлен documented path через `platformio.local.ini.example`

### <span style="color:#4EA1FF;">Выводы после внешнего review</span>

- Внешний review по плану признан полезным, но не принимается механически: в проект вносятся только те выводы, которые подтверждаются текущим состоянием кода и реальными рисками.
- Главный принятый вывод: `Stage 1` нельзя держать вечно "частично выполненным". У каждой стадии должны быть явные критерии завершения.
- Главный отклонённый в жёсткой форме вывод: искусственные метрики вроде "`main.cpp` < 300 строк" не считаются обязательной целью сами по себе. Важнее разделение ответственности, чем число строк.
- Главный практический вывод: новые пользовательские функции сейчас не в приоритете. Приоритет — закрытие фундаментальных рисков, которые всё ещё держат `Stage 1` открытым.
- Отдельно зафиксировано: `async lifecycle` признаётся важной зоной риска, но не тянет за собой автоматическое внедрение одной глобальной state machine. Приоритет — сначала формализовать жизненный цикл подсистем по отдельности.
- Дополнительно подтверждено внешней оценкой: проект уже стал управляемым и продуктово-ориентированным, но `Stage 1` всё ещё остаётся главным рубежом стабильности и не должен маскироваться под “почти готово”.
- Принята ещё одна практическая поправка: сразу после закрытия оставшихся lifecycle-дыр нужно ввести минимальные runtime-метрики (`frame time`, `heap`), но без преждевременного ухода в большой performance-refactor.
- Принята отдельная ресурсная дисциплина: экономить можно на дублировании, зеркалировании, вторичной косметике и преждевременной полировке, но нельзя экономить на root-cause analysis, сборке, safety-правках и фиксации важных решений.
- Отдельно принят двухуровневый workflow по ресурсу: внешний ChatGPT может давать дешёвые локальные patch-заготовки, но не считается источником финальных проектных решений. Для этого в проекте поддерживаются `.mc_core.v4.ini` и `CHATGPT_TASK_CAPSULE_RU.md`.
- Для project settings обычного ChatGPT нужен не “запретительный манифест”, а короткий управляемый режим. Поэтому отдельно поддерживается `CHATGPT_PROJECT_SETTINGS_RU.md` как paste-ready инструкция под внешний ChatGPT.
- Для внешнего ChatGPT отдельно зафиксирован remote-doc path: ключевые русские документы должны быть доступны и по GitHub-ссылкам, а если модель ссылки не читает, это должно быть явно компенсировано коротким `Docs summary` внутри самой задачи.
- Для внешней публикации собран отдельный пакет `docs/chatgpt_git/`, чтобы не смешивать живую внутреннюю документацию проекта и внешний набор для обычного ChatGPT.

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

- Внешний review по README дал полезное направление: проекту со временем нужен более явный frame pipeline, но это не считается задачей до завершения `Stage 1`.
- Идея единого `renderFrame()` принята как сильное направление для позднего `Stage 2` / раннего `Stage 3`, а не как немедленная задача.
- Идея `EffectManager` и общего effect-интерфейса принята как возможная будущая унификация режимов, но только после закрытия фундаментальных рисков.
- Идея preload `.anim` в RAM / PSRAM признана полезной и реалистичной для будущего улучшения `Fire`, особенно если подтвердится реальная runtime-нагрузка от `LittleFS`.
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
- рассмотреть preload `Fire` анимации в RAM / PSRAM
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
- Финальный продуктовый Wi-Fi contour ещё не завершён: dev bootstrap отделён, но AP onboarding path ещё не реализован
- Wi-Fi AP onboarding уже имеет backend foundation, но browser UI для product setup ещё не собран
- Wi-Fi product contour уже имеет backend+frontend foundation, но ещё требует полировки UX и реальной product-проверки
- Lifecycle async-task ещё не доведён до полностью аккуратной схемы
- `sensor async`, `audio async` и `Wi-Fi/OTA` уже переведены на более явный lifecycle, но весь сетевой продуктовый контур всё ещё требует реальной полевой проверки, а не только архитектурной аккуратности
- OTA host-side workaround уже есть, но его нельзя считать доказательством закрытого root cause без повторной проверки реального OTA-потока после device-side lifecycle fix
- Минимальные runtime-метрики уже введены, но это только базовый измерительный слой; более глубокий performance-анализ и frame budget всё ещё остаются следующей инженерной ступенью
- `platformio.ini` всё ещё содержит machine-specific OTA хвосты, хотя для них уже подготовлен безопасный путь выноса в `platformio.local.ini.example`
- dev OTA path сейчас стабилизирован прямым IP в `platformio.ini`, но это не считается финальной продуктовой схемой; позже этот контур должен быть либо вынесен в local override, либо заменён более устойчивым discoverable OTA path без жёсткой привязки к одному IP
- В проекте ещё остаются битые комментарии и следы плохой кодировки

---

## <span style="color:#4EA1FF;">Синхронизация с README</span>

- Блок `Обзор` в `README_RU.md` должен соответствовать разделам `Текущее состояние` и `Направление проекта` здесь.
- Блок `Текущие возможности` в `README_RU.md` должен отражать только то, что реально существует после записей в `Event Log`.
- Блок `Дорожная карта` в `README_RU.md` должен ссылаться на этот файл как на технический источник истины.
- Если в плане появляется новая значимая архитектурная веха, в README добавляется краткое отражение этой вехи, но без дублирования всей технички.
- Техническая история профиля платы `N16R8` вынесена в отдельный справочник [`N16R8_PROFILE_BIBLE_RU.md`](./N16R8_PROFILE_BIBLE_RU.md).

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
- 2026-04-17 — Принята новая документальная дисциплина по ресурсу: живая синхронизация дальше ведётся только в русской ветке (`README_RU.md` / `REFACTOR_PLAN_RU.md`), а английская документация переводится пакетно позже, когда проект стабилизируется.
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
- 2026-04-20 — Пересобран внешний ChatGPT workflow под экономию ресурса: `.mc_core.v4.ini` превращён в профиль дешёвого draft-worker, а `CHATGPT_TASK_CAPSULE_RU.md` добавлен как шаблон узкой задачи. Это должно снизить расход ресурса на мелких локальных правках без потери контроля со стороны Codex.
- 2026-04-20 — Для обычного ChatGPT добавлена отдельная короткая проектная инструкция `CHATGPT_PROJECT_SETTINGS_RU.md`: вместо длинного жёсткого текста проект теперь опирается на более компактный и выполнимый режим `cheap draft worker`, который лучше подходит для экономии ресурса и меньшей самодеятельности внешней модели.
- 2026-04-20 — Внешний ChatGPT workflow стал remote-aware: в `.mc_core.v4.ini`, `CHATGPT_PROJECT_SETTINGS_RU.md` и `CHATGPT_TASK_CAPSULE_RU.md` добавлены прямые GitHub-ссылки на русские документы проекта и явное правило fallback на `Docs summary`, если модель не умеет читать ссылки.
- 2026-04-20 — Для внешней публикации создан отдельный набор `docs/chatgpt_git/`: туда вынесены publish-ready версии `.mc_core.v4.ini`, project settings, task capsule и пошаговая инструкция публикации в GitHub, чтобы внешний контур не путался с живой проектной документацией.

---

## <span style="color:#67C587;">Следующее действие</span>

Следующий рабочий шаг:
- вернуть фокус на завершение `Stage 1`
- добить критерии стабильного старта без Wi-Fi, безопасного FS поведения и полной валидации состояния
- затем уже продолжать `Stage 2`, не раздувая scope новыми функциями
- в финальном контуре поддержки отдельно закрыть dev-only OTA stabilization: убрать жёсткую зависимость общей кнопки `Upload` от одного IP-адреса и перевести её в более переносимую схему

---

## <span style="color:#4EA1FF;">Итоговый статус</span>

<span style="color:#67C587;"><strong>Состояние проекта:</strong></span>
- Working
- Cleaned up
- Documented
- Evolving with recorded history
- Ready for staged refactor


