> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

# <span style="color:#4EA1FF;">MatrixClock Project Plan</span>

<p>
  <strong><span style="color:#4EA1FF;">Working Project Backbone</span></strong>
  <span style="color:#8AA4C8;">·</span>
  <strong><span style="color:#67C587;">Refactor</span></strong>
  <span style="color:#8AA4C8;">·</span>
  <strong><span style="color:#FF9B5E;">Cleanup</span></strong>
  <span style="color:#8AA4C8;">·</span>
  <strong><span style="color:#D98BFF;">Event Log</span></strong>
</p>

> <span style="color:#AEBFD7;">This file is the working backbone of the project. It tracks the current state, the refactor plan, completed stages, removed legacy leftovers, and meaningful project events over time.</span>

---

## <span style="color:#4EA1FF;">Rules of Use</span>

- This file is the working roadmap of the project.
- After major changes, short notes can be added here.
- Removed legacy branches and junk should also be logged here.
- If the project direction changes, update this file first, then the code.

---

## <span style="color:#4EA1FF;">Documentation Model</span>

- `README_EN.md` is the descriptive layer: what the project is, how it feels, what it can do, and where it is going.
- `REFACTOR_PLAN_EN.md` is the technical layer: stages, change history, decision log, stage alignment, and task relevance.
- `README` must not contradict the plan.
- The plan must not silently overwrite history; it should extend it.
- If a feature, direction, or assumption loses value, that should be recorded explicitly rather than silently replaced.
- Any document containing Russian text must be created and saved only as UTF-8, without mixing in Windows-1251.
- Visible literal backtick-r-backtick-n fragments must never remain in project text files after edits; multiline content must use real line breaks.
- After any multiline scripted edit or bulk replacement, `scripts/check_literal_newlines.ps1` must be run before the change is considered complete.
- Important policies and mechanisms added to `PLAN` or `RULES` must also be checked for a short parallel reflection in `README`.

---

## <span style="color:#4EA1FF;">Current State</span>

- Platform: `ESP32-S3`
- Target module: `N16R8`
- Matrix: `WS2812 32x8`
- Board profile aligned to `N16R8`
- `LittleFS` is working
- Web UI is working
- OTA is working
- Only one fire mode remains: `Fire`
- `Fire` uses a file animation from `LittleFS`
- Old procedural fire branches were removed

---

## <span style="color:#FF9B5E;">Project Direction</span>

Current project direction:
- keep the clock firmware stable
- avoid code bloat from old junk and abandoned experiments
- keep the visual side clean and manageable
- improve architecture without losing working behavior

---

## <span style="color:#D98BFF;">Master Plan</span>

### <span style="color:#4EA1FF;">Stage 1 — Stabilize the Base</span>

- Add one validation layer for persisted state and settings
- Remove hard startup dependency on Wi-Fi
- Make `LittleFS` recovery safe and predictable
- Remove small runtime risks and leftover hacks

**Status:** <span style="color:#FFB347;">Pending</span>

---

### <span style="color:#4EA1FF;">Stage 2 — Reduce Architectural Load</span>

- Split `main.cpp` by responsibility
- Move scattered globals into structured state
- Separate scene decision logic from rendering
- Normalize async task lifecycle

**Status:** <span style="color:#FFB347;">Pending</span>

---

### <span style="color:#4EA1FF;">Stage 3 — Improve Maintainability</span>

- Make project config portable
- Separate debug and release environments
- Clean the project tree further
- Add lightweight diagnostics

**Status:** <span style="color:#FFB347;">Pending</span>

---

## <span style="color:#67C587;">Overlay on Top of the Static Plan</span>

> <span style="color:#AEBFD7;">This block does not rewrite the original Master Plan. It adds a live operational layer on top of it as the project evolves.</span>

### <span style="color:#4EA1FF;">Current Progress by Stage</span>

- `Stage 1` — <span style="color:#FFB347;">actively being driven toward completion</span>
  - runtime and persisted state validation was tightened in `state.cpp` and `webserver.cpp`
  - runtime state normalization now lives in one `state.*` layer instead of being duplicated between `loadState()` and `/update`
  - Wi-Fi startup no longer blocks the firmware forever
  - Wi-Fi credentials were moved into persisted state, and the development bootstrap path is now separated from the product scenario
  - backend groundwork for the product Wi-Fi contour has begun: AP fallback and scan/status/config endpoints
  - the browser-side Wi-Fi onboarding panel is now integrated into the Web UI, and credential saves are immediate for reboot-safe setup
  - the Web UI now uses tabbed navigation so the growing settings surface is no longer one long vertical page
  - `LittleFS` now has an explicit runtime state and an outward-facing status endpoint instead of remaining an implicit service with guessed state
  - `sensor async` now has an explicit runtime state, a safer stop path, and observable status through the web layer instead of relying on an implicit task lifecycle
  - `LittleFS` no longer auto-formats silently on first mount failure
  - sensor initialization now retries safely instead of falsely succeeding
- `Stage 2` — <span style="color:#67C587;">partially completed</span>
  - startup/network services moved into `system_services.*`
  - sensor bootstrap moved into `sensor_bootstrap.*`
  - `main.cpp` is already lighter, and display/runtime orchestration has been moved into `display_runtime.*`; the file is still large, but it no longer owns the full screen flow alone
- `Stage 3` — <span style="color:#FFB347;">partially touched</span>
  - temporary files and dead code paths were removed
  - `platformio.ini` was cleaned up structurally
  - machine-specific OTA settings still remain, but a documented local path already exists via `platformio.local.ini.example`

### <span style="color:#4EA1FF;">Conclusions After External Review</span>

- The external review of the plan is considered useful, but it is not applied mechanically: only conclusions that match the actual code state and real project risks are adopted.
- Main accepted conclusion: `Stage 1` must not remain permanently "partially completed". Each stage needs explicit completion criteria.
- Main conclusion rejected in strict form: artificial targets such as "`main.cpp` < 300 lines" are not treated as mandatory by themselves. Separation of responsibility matters more than raw line count.
- Main practical conclusion: new user-facing features are not the current priority. The priority is closing the remaining foundational risks that still keep `Stage 1` open.
- It is also explicitly fixed that `async lifecycle` is a serious risk area, but that does not automatically imply a mandatory single global state machine. The first priority is to formalize subsystem lifecycles one by one.

### <span style="color:#4EA1FF;">Definition of Done</span>

#### <span style="color:#67C587;">Stage 1 is done when:</span>
- clock startup is stable and predictable even without available Wi-Fi
- the filesystem does not auto-format or silently lose data during normal mount-failure scenarios
- all incoming and persisted settings are validated through one coherent rule set
- hardcoded Wi-Fi credentials are no longer a mandatory condition for device viability in the product logic
- Wi-Fi credentials are loaded from persisted state, while the current hardcoded bootstrap remains valid only as a development mode
- the final product Wi-Fi target is AP onboarding, available-network scan, browser-based SSID/password input, and reboot into the user network
- core runtime risks (`seed`, init order, sensor retry path) are removed or clearly localized
- high-risk async zones are at least described per subsystem so future decisions can be evaluated against a recorded lifecycle model instead of intuition

#### <span style="color:#67C587;">Stage 2 is done when:</span>
- `main.cpp` remains a coordinator entrypoint instead of holding rendering and service business logic
- scene selection, display runtime, startup services, and sensor bootstrap live in separate responsibility zones
- global project state is significantly reduced or meaningfully structured
- async lifecycle becomes deterministic and understandable in terms of ownership

### <span style="color:#4EA1FF;">Async Lifecycle Policy</span>

- `async lifecycle` is treated in this project as a real risk area, not as a vague future architecture topic.
- The current subsystem scope includes:
  - `Wi-Fi / OTA`
  - `audio async / spectrum`
  - `sensor async`
  - `display runtime`
- For each such subsystem, the project should eventually make clear:
  - how it is initialized
  - when it is considered running
  - how it behaves under failure
  - whether retry / restart is required
  - how it affects the rest of the firmware
- The project does not accept “one large `SystemState` for everything” as a mandatory default.
- If a global state machine becomes justified later, that must be:
  - justified first by real subsystem interactions
  - recorded in the plan
  - only then implemented in code
- Until then, the priority is local lifecycle clarity for each async subsystem.

#### <span style="color:#67C587;">Stage 3 is done when:</span>
- machine-specific settings are extracted from shared config or have a proper local override path
- debug and release modes are separated without manual ambiguity
- the project tree is cleaned from temporary and historically dead leftovers
- the project has compact runtime diagnostics useful for real maintenance
### <span style="color:#4EA1FF;">Long-Term Architectural Guidance</span>

- The external README-level review provided useful direction: the project will eventually benefit from a clearer frame pipeline, but this is not treated as work that should happen before `Stage 1` is closed.
- The idea of a unified `renderFrame()` path is accepted as a strong direction for late `Stage 2` / early `Stage 3`, not as an immediate task.
- The idea of an `EffectManager` and a shared effect interface is accepted as a possible future unification layer, but only after the foundational risks are closed.
- The idea of preloading `.anim` assets into RAM / PSRAM is considered useful and realistic for a future `Fire` optimization, especially if real runtime cost from `LittleFS` is confirmed.
- The idea of FPS / frame-budget control is accepted as useful, but it belongs to a later engineering-tuning layer rather than the urgent work of the current stage.
- The idea of hard LUT mapping and broad micro-optimization is not considered mandatory without proven runtime pain.

### <span style="color:#4EA1FF;">How These Suggestions Map Across the Stages</span>

#### <span style="color:#67C587;">Stage 1</span>
- do not introduce a large effect framework yet
- do not rebuild the whole render loop for architectural beauty alone
- only address runtime pain that directly threatens stability

#### <span style="color:#67C587;">Stage 2</span>
- continue extracting orchestration out of `main.cpp`
- move the project toward a more explicit frame-control center
- evaluate whether a clean `EffectManager` should become the next unification layer

#### <span style="color:#67C587;">Stage 3</span>
- introduce a frame pipeline if it proves useful as a distinct engineering layer
- consider preloading `Fire` animation data into RAM / PSRAM
- add frame budget / FPS / heap metrics as control tools, not as a goal by themselves
### <span style="color:#4EA1FF;">What Lost Value Over Time</span>

- Returning to procedural fire no longer has value: file-based `Fire` proved better and became the canonical path.
- Keeping multiple fire presets no longer has value: the project moved toward one strong final mode instead of a mode zoo.
- The old Python animation-generation pipeline lost value and is already gone.
- Backend IP timezone detection experiments did not prove their value yet: the working frontend path was kept and the dead backend tail was removed.

---

## <span style="color:#67C587;">Completed Work</span>

- Real hardware profile `N16R8` confirmed
- Board config and partition table fixed
- `LittleFS` recovered and verified
- OTA enabled and verified
- Fire mode simplified and unified
- Old `Flame Real / Reactive / Smooth` modes removed
- One final `Fire` mode kept
- Old fire junk and temporary leftovers removed
- Project documentation updated

---

## <span style="color:#FF9B5E;">Removed Legacy / Deleted Junk</span>

- Old procedural fire branches
- Old fire modes except `Fire`
- Old animation-header leftovers
- Obsolete notes and temporary junk files
- Old Python fire/animation generation pipeline

---

## <span style="color:#4EA1FF;">Open Issues / Risks</span>

- `main.cpp` is still large, but the key display/runtime orchestration has already been moved into a dedicated module
- The final product Wi-Fi contour is still incomplete: development bootstrap is separated, but the AP onboarding path is not implemented yet
- The Wi-Fi AP onboarding path now has backend foundations, but the browser-side product setup UI is not built yet
- The Wi-Fi product contour now has backend+frontend foundations, but still needs UX polish and real product verification
- Async task lifecycle is still not fully cleaned up
- `platformio.ini` still contains machine-specific OTA leftovers, although a safe extraction path already exists in `platformio.local.ini.example`
- The project still has broken comments and encoding scars

---

## <span style="color:#4EA1FF;">README Synchronization</span>

- The `Overview` block in `README_EN.md` should match `Current State` and `Project Direction` here.
- The `Current Features` block in `README_EN.md` must reflect only what still exists after the entries in `Event Log`.
- The `Roadmap` block in `README_EN.md` should point here as the technical source of truth.
- If the plan gains a major architectural milestone, the README gets a short synchronized reflection of it without duplicating the whole technical story.

---

## <span style="color:#D98BFF;">Event Log</span>

> <span style="color:#AEBFD7;">Use this section to log meaningful project events in short form.</span>

### <span style="color:#67C587;">Format</span>
- Date
- What changed
- Why it was done
- What was removed or replaced
- How it relates to Stage 1 / 2 / 3

### <span style="color:#67C587;">Entries</span>
- 2026-04-16 — Fire system reduced to one final file-based `Fire` mode; legacy fire branches removed.
- 2026-04-16 — `LittleFS` and OTA path stabilized on the current board profile.
- 2026-04-16 — Documentation split into Russian and English README files.
- 2026-04-17 — State validation tightened in `state.cpp` and `webserver.cpp`; this directly moves `Stage 1` forward.
- 2026-04-17 — Wi-Fi startup blocking removed; filesystem mount made non-destructive; sensor init switched to retries. This is core `Stage 1` progress.
- 2026-04-17 — Startup/network services and sensor bootstrap moved out of `main.cpp` into dedicated modules. This is the first real `Stage 2` structural split.
- 2026-04-17 — Temporary files and dead timezone backend path removed; this partially supports `Stage 3` cleanup goals.
- 2026-04-17 — Added N16R8_PROFILE_BIBLE_EN.md as the English technical reference for the custom board profile, the 16MB flash issue, and the partition/LittleFS pitfalls. This supports Stage 3 documentation maturity.
- 2026-04-17 — Display/runtime orchestration was moved out of `main.cpp` into `display_runtime.*`, including IP overlay, reconnect flow, fade-in, and render dispatch. This is the second concrete Stage 2 split.
- 2026-04-17 — External review of the refactor plan was evaluated and partially adopted: the plan now has explicit Definition of Done criteria and the short-term focus is shifted back to finishing `Stage 1` before widening the refactor scope.
- 2026-04-17 — External README-level architecture suggestions were reviewed and distributed across the roadmap instead of being promoted to immediate work: frame pipeline, effect abstraction, RAM preload for `Fire`, and runtime metrics are now tracked as staged future directions rather than urgent tasks.
- 2026-04-17 — Wi-Fi credentials were moved into persisted state, and startup was reworked into an explicit contour: stored product credentials first, development bootstrap as a separate fallback path. This is direct Stage 1 progress.
- 2026-04-17 — Wi-Fi project intent was clarified in documentation: hardcoded credentials are allowed only for development, while the final product path must be AP onboarding with browser-based network selection and reboot into the user network.
- 2026-04-17 — Added a mandatory post-edit newline integrity check via `scripts/check_literal_newlines.ps1` and aligned `.editorconfig` with the project text-file discipline. This reduces recurrence of visible backtick newline artifacts across docs and code.
- 2026-04-17 — Added backend groundwork for the future product Wi-Fi path: AP fallback, explicit Wi-Fi runtime mode, and `/wifi-status` / `/wifi-scan` / `/wifi-config` endpoints. This advances Stage 1 without breaking the current development bootstrap flow.
- 2026-04-17 — Added the browser-side Wi-Fi onboarding panel to the Web UI and made Wi-Fi credential saves immediate for reboot-safe product setup. This continues Stage 1 without breaking the current development bootstrap flow.
- 2026-04-17 — Rebuilt the Web UI around tabs so the growing settings surface no longer lives in one long vertical page. This keeps the current UX manageable while Stage 1 features continue to accumulate.
- 2026-04-17 — Consolidated runtime state validation into `state.*`: persisted load, web updates, and forced saves now pass through one normalization layer instead of duplicating validation logic. This is direct Stage 1 progress.
- 2026-04-17 — Added explicit filesystem runtime-state tracking (`mounted` / `missing_content` / `unmounted`) plus `/fs-status` and state exposure through the web layer. This continues Stage 1 by replacing implicit FS assumptions with observable behavior.
- 2026-04-17 — The project policy for async lifecycle was clarified and fixed in the plan/rules: this risk is recognized as important, but the chosen direction is subsystem-by-subsystem lifecycle formalization first, not an automatic global state-machine rewrite.
- 2026-04-17 — `sensor async` received an explicit runtime lifecycle (`idle` / `starting` / `running` / `stopping` / `error`), a safer stop path, restart-aware bootstrap logic, and outward-facing status via `/state`. This is the first concrete async-lifecycle hardening pass under the Stage 1 policy.

---

## <span style="color:#67C587;">Next Action</span>

Next working step:
- shift short-term focus back to finishing `Stage 1`
- close the criteria for stable startup without Wi-Fi, safe FS behavior, and complete state validation
- then continue `Stage 2` without widening scope with new features

---

## <span style="color:#4EA1FF;">Status Summary</span>

<span style="color:#67C587;"><strong>Project condition:</strong></span>
- Working
- Cleaned up
- Documented
- Evolving with recorded history
- Ready for staged refactor


