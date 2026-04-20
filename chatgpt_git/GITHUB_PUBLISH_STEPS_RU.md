> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

# GitHub Publish Steps RU

Ниже — пошаговая инструкция, что именно тебе нужно сделать.

## Цель

Сделать так, чтобы внешний обычный ChatGPT мог:
- получить project instructions
- увидеть ссылки на правила проекта
- при возможности открыть их в GitHub
- и работать как дешёвый локальный draft-worker

## Что публиковать

Нужно загрузить в GitHub как минимум:

### Папка внешнего пакета

Из этой папки:
- `docs/chatgpt_git/README_RU.md`
- `docs/chatgpt_git/mc_core.v4.ini`
- `docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`
- `docs/chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`
- `docs/chatgpt_git/GITHUB_PUBLISH_STEPS_RU.md`

### Папка проектных правил

Из живой русской документации:
- `docs/project/README_RU.md`
- `docs/project/REFACTOR_PLAN_RU.md`
- `docs/project/PROJECT_EDIT_RULES.md`

## Куда загружать

Рекомендуемая структура в репозитории:

```text
docs/
  chatgpt_git/
    README_RU.md
    mc_core.v4.ini
    CHATGPT_PROJECT_SETTINGS_RU.md
    CHATGPT_TASK_CAPSULE_RU.md
    GITHUB_PUBLISH_STEPS_RU.md
  project/
    README_RU.md
    REFACTOR_PLAN_RU.md
    PROJECT_EDIT_RULES.md
```

## Что заменить после загрузки

После публикации открой файлы:
- `docs/chatgpt_git/mc_core.v4.ini`
- `docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`
- `docs/chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`

И замени:
- `<OWNER>` → владелец GitHub
- `<REPO>` → имя репозитория
- `<BRANCH>` → обычно `main`

Пример:

```text
<OWNER>  -> cncmolot-wq
<REPO>   -> MatrixClockS3
<BRANCH> -> main
```

## Как проверить

1. Открой в браузере одну из ссылок из `CHATGPT_PROJECT_SETTINGS_RU.md`
2. Убедись, что страница открывается
3. Убедись, что в ссылке уже нет `<OWNER>`, `<REPO>`, `<BRANCH>`
4. Убедись, что документ читается и это именно актуальная версия

## Что потом вставлять в ChatGPT

### В настройки проекта

Скопируй текст из:
- `docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`

### В каждую конкретную задачу

Скопируй шаблон из:
- `docs/chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`

И дополни:
- `Task`
- `Target files`
- при необходимости короткий `Docs summary`

## Если ссылки всё равно не читаются

Это не ломает схему полностью.

Тогда делай так:
- оставляй ссылки в инструкции
- но в саму задачу всегда добавляй короткий `Docs summary`

То есть у тебя будет:
- `project settings`
- `task capsule`
- `docs summary`

Даже без чтения ссылок это уже лучше, чем просто свободный запрос в ChatGPT.

## Главное правило

Внешний ChatGPT не становится источником истины.

Он только:
- даёт локальный draft

А финально:
- проверяешь ты
- интегрирует и верифицирует Codex
