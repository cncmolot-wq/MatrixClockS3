> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

# GitHub Publish Steps RU

Ниже — точная схема, как публиковать внешний набор для обычного ChatGPT без путаницы между локальными и удалёнными путями.

## Цель

Сделать так, чтобы внешний ChatGPT мог:
- получить project instructions;
- увидеть ссылки на правила проекта;
- при возможности открыть их по GitHub;
- и работать как дешёвый локальный draft-worker.

## Важное различие

Локально в проекте файлы лежат так:

```text
docs/
  chatgpt_git/
  project/
```

Но удалённые ссылки для внешнего ChatGPT в опубликованном наборе сейчас считаются такими:

```text
chatgpt_git/
project/
```

То есть:
- `docs/...` — это локальная структура в рабочем проекте;
- `chatgpt_git/...` и `project/...` — это удалённые GitHub-пути, на которые ссылается внешний пакет.

## Что публиковать

### 1. Внешний пакет

Нужно опубликовать файлы:
- `docs/chatgpt_git/README_RU.md`
- `docs/chatgpt_git/mc_core.v4.ini`
- `docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`
- `docs/chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`
- `docs/chatgpt_git/GITHUB_PUBLISH_STEPS_RU.md`

После публикации они должны быть доступны по путям:
- `chatgpt_git/README_RU.md`
- `chatgpt_git/mc_core.v4.ini`
- `chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`
- `chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`
- `chatgpt_git/GITHUB_PUBLISH_STEPS_RU.md`

### 2. Русская проектная документация

Нужно опубликовать файлы:
- `docs/project/README_RU.md`
- `docs/project/REFACTOR_PLAN_RU.md`
- `docs/project/PROJECT_EDIT_RULES.md`

После публикации они должны быть доступны по путям:
- `project/README_RU.md`
- `project/REFACTOR_PLAN_RU.md`
- `project/PROJECT_EDIT_RULES.md`

## Что проверять после публикации

1. Открой в браузере:
   - `https://github.com/cncmolot-wq/MatrixClockS3/blob/main/chatgpt_git/README_RU.md`
   - `https://github.com/cncmolot-wq/MatrixClockS3/blob/main/chatgpt_git/mc_core.v4.ini`
   - `https://github.com/cncmolot-wq/MatrixClockS3/blob/main/project/README_RU.md`
2. Убедись, что все страницы реально открываются.
3. Убедись, что кодировка читается нормально, без “кракозябр”.
4. Убедись, что package-файлы не содержат плейсхолдеров `<OWNER>`, `<REPO>`, `<BRANCH>`.
5. Убедись, что package-файлы не ссылаются на локальные `docs/...` URL там, где должны использоваться удалённые `project/...` и `chatgpt_git/...`.

## Что вставлять в ChatGPT

### В настройки проекта

Скопируй текст из:
- `chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`

### В каждую конкретную задачу

Скопируй шаблон из:
- `chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`

И дополни:
- `Task`
- `Target files`
- при необходимости короткий `Docs summary`

## Если ссылки всё равно не читаются

Это не ломает схему полностью.

Тогда делай так:
- оставляй ссылки в project settings;
- но в саму задачу всегда добавляй короткий `Docs summary`.

Итоговый набор:
- `project settings`
- `task capsule`
- `docs summary`

## Главное правило

Внешний ChatGPT не становится источником истины.

Он только:
- даёт локальный draft.

А финально:
- проверяешь ты;
- интегрирует и верифицирует Codex.
