> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

# Project Edit Rules

This document defines the project-wide editing contract.

## Rule Core

- Before editing any project file, review the documentation in `docs/project/` first.
- Code changes, documentation changes, and project-structure changes should be treated as one connected system.
- The expected loop is:
  - documentation -> code -> documentation
- README is the descriptive layer.
- REFACTOR_PLAN is the technical and historical layer.
- board-profile and platform-specific reference docs are supporting technical layers.

## What This Rule Is Good For

- Keeping AI-assisted edits aligned with the actual project direction.
- Reducing accidental contradictions between code and docs.
- Preserving project history instead of silently overwriting intent.
- Making the repo easier to re-enter after breaks.

## What This Rule Does Not Replace

- It does not replace compilation.
- It does not replace runtime verification.
- It does not replace code review.
- It does not replace good architecture.

## Async Lifecycle Policy

- Async lifecycle is treated as a high-risk engineering area in this project.
- Wi-Fi/OTA, audio async, sensor async, and display runtime must be evaluated as separate subsystems with their own lifecycle.
- The preferred order is:
  1. describe the lifecycle of one subsystem
  2. stabilize its init/start/run/retry/failure behavior
  3. document the result in the plan
- A single global state machine is not a mandatory solution by default.
- If a global state model is proposed later, it must be justified by real subsystem interactions and documented in the plan first.

## Injection Policy

The rule is injected directly into safe editable text files where comments are valid:

- `.cpp`
- `.h`
- `.md`
- `.html`
- `.ini`

## Strict-Format Exceptions

Some files must not receive inline rule text because that can break parsing or external tools.
Those files follow this document indirectly.

Typical exceptions:

- `.json`
- `.csv`
- binary assets
- generated build artifacts
- package lockfiles and tool-managed files

## Practical Meaning

This is not decorative text.
It is a coordination protocol for the project.

If an edit changes behavior, structure, or assumptions, the expected follow-up is:

1. update code or config
2. verify the project still works
3. update the relevant doc layer if the meaning of the project changed

## Language Discipline

- Programming language constructs are not translated.
- This includes:
  - code identifiers
  - function names
  - class / struct / enum names
  - API names
  - file and module names
  - protocol and library names
- Russian translation is applied to:
  - comments
  - Russian documentation
  - explanatory text around technical terms
  - the Russian UI
- The only place where full user-facing translation should be treated as mandatory is the Russian UI.
- In Russian docs and comments, technical terms may remain in English when they are part of the actual engineering language of the project, but the surrounding explanatory text should stay clear Russian.

## Resource Discipline

- Resource saving is a project rule, but it must never come at the cost of product reliability.
- The editor must not save resources by skipping:
  - build verification for meaningful code changes
  - critical safety fixes
  - root-cause analysis when a bug affects real behavior
  - documentation updates for important project decisions
- Resources should be saved where the impact is low and the repetition is high.

### Prefer Saving Resources In

- duplicated explanation across multiple files
- constant Russian/English mirroring during active development
- cosmetic refactors that do not change quality or maintainability
- extra UI changes when the current UI is already good enough
- over-instrumentation and premature optimization
- repeated shell-command variation that creates extra approval friction

### Preferred Resource Strategy

1. protect reliability first
2. fix the real problem, not only the visible symptom
3. verify the result
4. document only the layers that truly need updating
5. postpone secondary polish until the project is stable

### Practical Meaning

- Russian documentation is the live documentation branch during active development.
- English documentation is deferred and translated in larger batches later.
- README receives short mirrored updates only for important mechanisms, not every implementation detail.
- PLAN keeps the technical history and action logic.
- New features should not be added when an existing stage is still open unless they are required to close that stage.

## README Mirror Check

- If a new project policy, mechanism, constraint, tool, or workflow is added to `REFACTOR_PLAN` or `PROJECT_EDIT_RULES`, the editor must explicitly check whether it needs a short parallel reflection in `README`.
- `README` does not duplicate the full technical record, but it must compactly reflect important project mechanisms that help a human understand how the project works.
- A change is not considered fully documented until this README mirror check has been performed.

## Documentation Update Threshold

- Not every local code edit deserves updates in every document layer.
- The editor must update only the layers whose meaning really changed.

### Update `README_RU.md` When

- user-facing behavior changed
- the human-readable project workflow changed
- a major project mechanism or rule now matters for understanding the project

### Update `REFACTOR_PLAN_RU.md` When

- stage status changed
- a technical decision was made
- a risk changed
- a task lost or gained value
- an event matters for future engineering decisions

### Update `docs/chatgpt_git/*` Only When

- the external ChatGPT workflow changed
- GitHub paths changed
- the external package structure changed
- the cheap draft-worker contract changed

### Do Not Force Updates When

- the change is purely internal and already obvious from code
- the behavior is unchanged
- the meaning of the project did not move
- updating another doc layer would only duplicate noise

## Stage Gate Discipline

- If the current priority stage is still open, unrelated expansion must be treated as suspect by default.
- This applies to:
  - new user-facing features
  - secondary UI polish
  - broad process changes
  - extra documentation layers that do not help close the active stage
- Before widening scope, the editor should check:
  1. does this help close the active stage?
  2. does this reduce a real current risk?
  3. is this required for stability, verification, or user understanding?
- If the answer is no, the work should usually be deferred.

## Git Repo Reference Policy

- GitHub links for project docs and the external ChatGPT package must be checked against the real published repository before being changed locally.
- The repository structure must not be “re-invented” inside local docs without confirmation from the actual GitHub repo.
- The reference file for this policy is:
  - `docs/project/GIT_REPO_REFERENCE_RU.md`
- In practice:
  - first verify the real remote path
  - then update local docs if needed
  - do not silently assume that local `docs/...` paths and remote published paths are identical
  - do not assume local edits are already published; GitHub publication is a separate user-controlled step

## Documentation Folder Roles

- `docs/project` stores only project documentation:
  - README / PLAN
  - editing rules
  - board/profile references
  - Git repo reference
- `docs/chatgpt_git` stores only the external ChatGPT/GitHub package:
  - project settings
  - task capsule
- ChatGPT-oriented files must not be duplicated inside `docs/project`.
- Project-source documentation must not be duplicated inside `docs/chatgpt_git`.
- If a file belongs to the external ChatGPT workflow, its canonical home is `docs/chatgpt_git`.
- If a file belongs to the project truth/model, its canonical home is `docs/project`.

## Canonical Ownership Rule

- Each documentation role should have one canonical file or one canonical folder.
- Competing copies of the same instruction layer are treated as a process bug.
- If duplicate files appear:
  1. decide which copy is canonical
  2. remove or archive the competing copy
  3. fix all references

## External Package Sync Rule

- `docs/chatgpt_git` is not a mirror of every local documentation change.
- It is a minimal publish-ready external package and should be updated only when its own contract changes.
- Normal code work does not automatically require touching `docs/chatgpt_git`.
- This rule exists to save resource and prevent unnecessary drift between the internal project truth and the external cheap-draft package.


## Newline Discipline

- Literal backtick escape artifacts must never be left inside project text files as visible text.
- When editing .md, .cpp, .h, .html, or .ini, real line breaks must be written as real line breaks, not as pasted escape markers.
- After any scripted replacement that touches multiline text, verify that no accidental visible backtick-r-backtick-n fragments were introduced.
- If a multiline edit is risky, prefer replacing a whole block or verifying the exact rendered result immediately after the edit.

## Mandatory Post-Edit Check

- After any multiline scripted edit, block replacement, or document rewrite, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check_literal_newlines.ps1
```

- A clean result is required before considering the edit finished.
- If the script reports a problem, fix the file first and only then continue with further work.

## Command Prefix Discipline

- When sandbox approvals are involved, the editor must prefer a small, stable set of command shapes instead of many slightly different variants.
- The goal is to let saved approval prefixes accumulate and remain useful across sessions.
- This means:
  - prefer the same read/search command patterns each time
  - avoid inventing new command forms when an already-used form can do the job
  - avoid unnecessary command variation caused by cosmetic differences
- In practice:
  - prefer stable `Get-Content` patterns for file reads
  - prefer stable `rg -n` patterns for searches
  - prefer stable `platformio run ...` patterns for build/upload actions
- If a task can be done with an already-approved command shape, do not switch to a new shell pattern without reason.
- This rule exists to reduce repeated approval prompts and keep the development flow consistent.
## Current Documentation Hub

AI CORE:

The external ChatGPT runtime package is intentionally minimal and lives in:

- `docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`
- `docs/chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`

These two files are the only canonical external ChatGPT runtime layer.

Main project docs live in:

- `docs/project/README_RU.md`
- `docs/project/README_EN.md`
- `docs/project/REFACTOR_PLAN_RU.md`
- `docs/project/REFACTOR_PLAN_EN.md`
- `docs/project/N16R8_PROFILE_BIBLE_RU.md`
- `docs/project/N16R8_PROFILE_BIBLE_EN.md`
- `docs/project/GIT_REPO_REFERENCE_RU.md`

External ChatGPT package lives in:

- `docs/chatgpt_git/CHATGPT_PROJECT_SETTINGS_RU.md`
- `docs/chatgpt_git/CHATGPT_TASK_CAPSULE_RU.md`
