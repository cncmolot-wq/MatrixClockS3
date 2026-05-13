> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

# ChatGPT Task Capsule RU

Используй этот шаблон для каждой узкой задачи, которую отдаёшь внешнему обычному ChatGPT.
Он не должен превращаться в отдельный устав проекта: общие правила уже живут в `CHATGPT_PROJECT_SETTINGS_RU.md`.

---

```text
Project: MatrixClock
Stage: S1
Role: cheap draft worker, not final authority

Remote docs:
- project PROJECT_GUIDE_RU: https://github.com/cncmolot-wq/MatrixClockS3/blob/main/project/PROJECT_GUIDE_RU.md
- REFACTOR_PLAN_RU: https://github.com/cncmolot-wq/MatrixClockS3/blob/main/project/REFACTOR_PLAN_RU.md
- PROJECT_EDIT_RULES: https://github.com/cncmolot-wq/MatrixClockS3/blob/main/project/PROJECT_EDIT_RULES.md

Docs summary:
- PROJECT_GUIDE_RU = human guide
- REFACTOR_PLAN_RU = technical truth
- PROJECT_EDIT_RULES = hard contract
- Current priority = stability, validation, lifecycle, safe init

Task:
[вставь одну конкретную локальную задачу]

Target files:
- [точный список файлов]

Do:
- produce a minimal local patch
- keep state/UI consistency
- preserve existing behavior outside the target bug

Do not:
- refactor unrelated code
- rewrite whole files unless unavoidable
- edit documentation
- invent new features

Output:
- short explanation
- exact patch or exact code block
- assumptions
- possible risks
```

---

## Важно

Если внешний ChatGPT не может открыть ссылки:
- это должно быть сказано прямо;
- после этого он должен опираться только на `Docs summary`;
- нельзя делать вид, что документы были прочитаны.
- этот файл должен оставаться шаблоном конкретной задачи, а не копией общих project settings.

## Когда это выгодно

- локальный UI-bug;
- маленькая backend-правка;
- восстановление state/UI consistency;
- локальная валидация;
- короткий helper/function rewrite.

## Когда это невыгодно

- lifecycle fixes across several subsystems;
- OTA / Wi-Fi / FS behavior;
- архитектурные решения;
- изменения, которые требуют проверки на устройстве;
- всё, что затрагивает проектные правила или модель документации.
