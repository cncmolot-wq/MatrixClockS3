> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

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

> <span style="color:#AEBFD7;">MatrixClock is a clock firmware project for `ESP32-S3` and a `32x8` `WS2812` LED matrix with a web interface, NTP sync, OTA updates, optional sensors, and one final `Fire` mode based on a file animation stored in `LittleFS`.</span>

---

## <span style="color:#4EA1FF;">Overview</span>

**MatrixClock** is the current working firmware for a compact `32x8` LED matrix clock built around `ESP32-S3`.

Current project focus:
- clean clock rendering on a compact LED matrix
- browser-based configuration
- OTA firmware updates
- NTP time sync
- optional sensor info screens
- spectrum modes
- one final fire mode: `Fire`, powered by a file animation in `LittleFS`

This repository reflects the **current live state** of the project, not an archive of old experiments.
Old procedural fire branches and generation junk were removed in favor of the current runtime approach.

---

## <span style="color:#4EA1FF;">README Role</span>

- `README_EN.md` is the descriptive layer of the project.
- It explains what exists now, how it is used, and what direction the project is taking.
- It should not carry the full technical history of every internal change.
- The source of truth for technical history, stage status, and decision logging is [`REFACTOR_PLAN_EN.md`](./REFACTOR_PLAN_EN.md).

---

## <span style="color:#4EA1FF;">Project Consistency Loop</span>

- before editing files, documentation in `docs/project/` is reviewed first
- after meaningful changes, documentation is updated when needed
- after any multiline scripted edit, `scripts/check_literal_newlines.ps1` is run
- the shared rules for this loop are described in [`PROJECT_EDIT_RULES.md`](./PROJECT_EDIT_RULES.md)
- async lifecycle is treated as a high-risk area and is described per subsystem rather than forced into one global state machine by default
- if an important policy or mechanism is added to `PLAN` / `RULES`, it must also receive a short explanatory reflection in `README`

---

## <span style="color:#67C587;">Current Features</span>

### <span style="color:#4EA1FF;">Clock and UI</span>
- `3x5`, `4x7`, and `5x7` font modes
- animated colon modes
- progress bar modes
- web UI served from `LittleFS`
- web UI rebuilt around tabs for shorter and more manageable navigation
- persistent settings via `Preferences`
- manual timezone selection
- auto-detect timezone through browser and IP path

### <span style="color:#FF9B5E;">Visual Modes</span>
- spectrum bars
- waterfall spectrum
- symmetric spectrum
- VU meter
- `Fire` mode powered by a file animation: `data/anim/fire_32x8_v1.anim`

### <span style="color:#67C587;">Network and Time</span>
- Wi-Fi connection
- backend groundwork for AP onboarding: AP fallback, Wi-Fi scan, and browser-side config endpoints
- browser-side Wi-Fi onboarding panel in the Web UI: status, scan, SSID/password, save, save+reboot
- the filesystem now has an explicit runtime status (`mounted` / `missing_content` / `unmounted`) instead of implicit behavior
- NTP synchronization
- web interface
- OTA firmware update
- OTA filesystem update support
- timezone normalization and persistence in `Preferences`

### <span style="color:#D98BFF;">Sensors</span>
- `AHT20` support
- `BMP280` support
- async sensor polling
- sensor async now has an explicit runtime status (`idle` / `starting` / `running` / `stopping` / `error`) instead of relying on implicit startup behavior
- optional temperature / humidity / pressure info screens

---

## <span style="color:#FF9B5E;">Hardware</span>

### <span style="color:#4EA1FF;">Target Module</span>
- `ESP32-S3`
- expected module class: `N16R8`
- flash: `16MB`
- PSRAM: `8MB`

### <span style="color:#4EA1FF;">Matrix</span>
- type: `WS2812`
- size: `32x8`
- data pin: `GPIO12`
- render model: buffered rendering through `NeoPixelBus`

### <span style="color:#4EA1FF;">Audio Input</span>
- microphone path uses I2S
- current I2S pins are defined in `src/audio/spectrum_async.cpp`

### <span style="color:#4EA1FF;">Sensors</span>
- sensor path uses I2C
- current implementation supports `AHT20` and `BMP280`

---

## <span style="color:#67C587;">Project Layout</span>

```text
src/
  audio/              Spectrum rendering + async FFT task
  effects/            Digits, colon, progress bar, info screens
  hardware/           Matrix output and NTP helpers
  sensors/            Sensor access + async sensor task
  ui/                 Web server and persisted state
  system_services.*   Startup services, Wi-Fi, OTA, FS
  sensor_bootstrap.*  Safe sensor bootstrap logic
  display_runtime.*   IP overlay, fade-in, and screen runtime dispatch
  main.cpp            Main application runtime

data/
  index.html          Web interface
  anim/               Runtime animation assets for LittleFS

boards/
  matrixclock_esp32s3_n16r8.json
```

---

## <span style="color:#D98BFF;">Build Environments</span>

Defined in [`platformio.ini`](./platformio.ini):

- `s3` — USB build/upload environment
- `s3ota` — OTA upload environment

Current board profile:
- `matrixclock_esp32s3_n16r8`

Current partition table:
- `partitions_ota_16mb.csv`

Current filesystem:
- `LittleFS`

Future local path for machine-specific OTA overrides:
- `platformio.local.ini.example`

---

## <span style="color:#4EA1FF;">Build and Upload</span>

### <span style="color:#67C587;">Firmware via USB</span>

```powershell
pio run -e s3 -t upload
```

### <span style="color:#67C587;">Filesystem via USB</span>

```powershell
pio run -e s3 -t uploadfs
```

### <span style="color:#D98BFF;">Firmware via OTA</span>

```powershell
pio run -e s3ota -t upload --upload-port 192.168.x.x
```

### <span style="color:#D98BFF;">Filesystem via OTA</span>

Use the dedicated OTA filesystem flow already configured for the project.

---

## <span style="color:#FF9B5E;">Web Interface</span>

After the clock joins your Wi-Fi network, open it in the browser using its local IP address, for example:

```text
http://192.168.x.x
```

The web UI allows you to control:
- brightness
- font
- colon mode
- progress bar mode
- eyes interval
- sensor interval
- spectrum / fire mode
- gain
- overlay interval
- timezone
- colors

The backend also now exposes Wi-Fi setup endpoints for the next product step:
- `/wifi-status`
- `/wifi-scan`
- `/wifi-config`

---

## <span style="color:#FF9B5E;">Fire Mode</span>

The project now has **one final fire mode**:

- mode name: `Fire`
- source: file-based animation in `LittleFS`
- runtime asset: `data/anim/fire_32x8_v1.anim`
- visual source reference: `png/fire_32x8_v1.gif`

Why this approach won:
- it looks better than the old procedural fire
- it behaves predictably at runtime
- it avoids giant embedded animation headers
- it fits the current project structure much better

This is the canonical fire path in the current MatrixClock.

---

## <span style="color:#67C587;">Synchronization with the Plan</span>

This README is synchronized with [`REFACTOR_PLAN_EN.md`](./REFACTOR_PLAN_EN.md) on these key points:

- one final `Fire` mode
- working `LittleFS`
- working OTA path
- timezone support in UI and backend
- backend groundwork for the future AP onboarding path
- first structural split of `main.cpp` through dedicated service modules
- display/runtime orchestration extracted into `display_runtime.*`

If these points change, the technical entry is added to the plan first, then the README gets the short synchronized reflection.

---

## <span style="color:#67C587;">Notes</span>

### <span style="color:#4EA1FF;">Wi-Fi</span>
The current development mode allows a hardcoded dev bootstrap SSID/password so the clock can immediately join the developer network.
At the same time, the product logic is already being separated from the dev path: persisted credentials are stored in state and are meant to become the primary route for the user network.
The final target for this contour is AP onboarding: the clock starts its own AP, scans available Wi-Fi networks, lets the user choose a network and enter the password in the browser, then reboots into the user network.

---

## <span style="color:#4EA1FF;">N16R8 Board Profile</span>

For the dedicated technical write-up on our board, see:

- [`N16R8_PROFILE_BIBLE_EN.md`](./N16R8_PROFILE_BIBLE_EN.md)

That guide explains:
- why the stock profile behaved like `8MB`
- how the working custom board profile was created
- why a dedicated partition table matters
- why `LittleFS` still needed the partition name `spiffs`

---
## <span style="color:#D98BFF;">Roadmap</span>

The current stabilization and refactor roadmap lives in:

- [`REFACTOR_PLAN_EN.md`](./REFACTOR_PLAN_EN.md)

That file now contains the original stages, their live status, the change log, and notes about how task value has shifted over time.

---

## <span style="color:#4EA1FF;">Status</span>

<span style="color:#67C587;"><strong>Current state:</strong></span>
- board profile aligned with `N16R8`
- web UI working from `LittleFS`
- OTA working
- timezone path working
- single `Fire` mode finalized
- old fire branches removed
- the project is no longer only ready for refactor, it is already inside a staged refactor process

