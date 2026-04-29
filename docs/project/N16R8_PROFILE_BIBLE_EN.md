> Important: before editing this file, review the files in `docs/project/` first so the documentation stays synchronized.

# <span style="color:#4EA1FF;">N16R8 Board Profile Bible</span>

> <span style="color:#AEBFD7;">A technical reference for how to bring up an `ESP32-S3 N16R8` module correctly in PlatformIO, why a standard board profile may falsely behave like `8MB`, and which settings are required for full `16MB flash + 8MB PSRAM` support.</span>

---

## <span style="color:#4EA1FF;">What This Module Is</span>

The `N16R8` marking on an `ESP32-S3` module usually means:

- `N16` = `16MB Flash`
- `R8` = `8MB PSRAM`

In this project, that was confirmed not only by the printed marking on the module, but also by direct low-level reads from the chip.

---

## <span style="color:#FF9B5E;">Symptoms We Hit</span>

In practice, the problem looked like this:

- the module was marked as `N16R8`
- the project built
- normal firmware could be uploaded
- but `PlatformIO` / `uploadfs` behaved as if the board only had `8MB flash`
- filesystem and partition logic kept hitting `8388608 bytes`
- the standard `esp32-s3-devkitc-1` profile did not reflect the real flash layout correctly

That made it look like:

- either the hardware was cut down
- or the marking was fake
- or VS Code / PlatformIO could only “see” half of the flash

---

## <span style="color:#4EA1FF;">What the Real Cause Was</span>

The root cause was not the hardware. It was the board profile.

The stock `esp32-s3-devkitc-1` profile in our setup effectively behaved like an `N8`-class board:

- some memory-related assumptions stayed in the `8MB` world
- `uploadfs` and related tooling followed the board profile rather than the real module
- because of that, `LittleFS` and partition handling did not use the full flash correctly

In other words:

- the chip really had `16MB`
- but the project described it as a narrower board
- PlatformIO honestly followed the project description, not the sticker on the module

---

## <span style="color:#67C587;">What Confirmed That Flash Really Was 16MB</span>

The key proof did not come from the IDE. It came from low-level chip inspection.

When we read the chip directly, we confirmed:

- `ESP32-S3`
- `16MB flash`
- `8MB embedded PSRAM`

So the hardware was fine. The problem was that the project described the board incorrectly.

---

## <span style="color:#4EA1FF;">What Actually Fixed It</span>

Three things were required.

### <span style="color:#67C587;">1. A Custom Board Profile</span>

We created a local board definition:

- [boards/matrixclock_esp32s3_n16r8.json](./boards/matrixclock_esp32s3_n16r8.json)

That file defines the important board traits:

- `flash_size = 16MB`
- `maximum_size = 16777216`
- `PSRAM`
- proper build flags for an `ESP32-S3 N16R8`
- the correct board identity for this project

### <span style="color:#67C587;">2. Explicit Use of That Profile in PlatformIO</span>

In [platformio.ini](./platformio.ini), the project is switched to:

- `board = matrixclock_esp32s3_n16r8`
- `boards_dir = boards`

That means PlatformIO no longer uses the generic upstream profile. It uses our local board description.

### <span style="color:#67C587;">3. A Dedicated 16MB Partition Table</span>

The project uses:

- [partitions_ota_16mb.csv](./partitions_ota_16mb.csv)

That matters because setting `flash_size = 16MB` alone is not enough.
You also need a real partition layout that matches the available flash.

---

## <span style="color:#FF9B5E;">A Critical Trap We Hit</span>

For `LittleFS` under Arduino-ESP32, the filesystem partition still has to be named:

```csv
spiffs, data, spiffs, ...
```

not something like:

```csv
littlefs, data, spiffs, ...
```

That was a separate critical bug:

- the filesystem image could be uploaded
- but `LittleFS.begin()` could not find the partition
- the web UI would not come up
- the device reported that `index.html` was missing

So with `LittleFS`, the first column in the CSV still needs to be `spiffs`.
That is an Arduino-ESP32 compatibility detail, not a pretty naming choice.

---

## <span style="color:#4EA1FF;">Why VS Code / PlatformIO Showed the Wrong Size</span>

An important point:

- VS Code itself does not know the hardware
- it only shows what PlatformIO tells it
- PlatformIO follows the board profile and project configuration

If the board profile effectively describes an `N8`-style board, the IDE will behave like that is reality.

So when the IDE acted as if the board only had `8MB`, that was a consequence of the wrong profile, not proof that the module was fake.

---

## <span style="color:#67C587;">How to Build a Correct Profile for a Board Like This</span>

If you need to bring up a similar module with non-default memory, the safe workflow is:

1. Confirm the chip parameters with a real tool, not only with the label.
2. Do not blindly trust the stock board profile.
3. Create a local JSON board profile in `boards/`.
4. Explicitly define:
   - `flash_size`
   - `maximum_size`
   - `PSRAM`
   - build flags for the correct module class
5. Point the project to it using `boards_dir` and `board = ...`.
6. Create a matching partition table for the real flash size.
7. Make sure the `LittleFS` partition is named `spiffs`.
8. After changing the partition table, do at least one USB flash pass, because OTA cannot magically migrate the flash layout for you.

---

## <span style="color:#D98BFF;">Files That Form the Core of the Fix</span>

- [boards/matrixclock_esp32s3_n16r8.json](./boards/matrixclock_esp32s3_n16r8.json)
- [platformio.ini](./platformio.ini)
- [partitions_ota_16mb.csv](./partitions_ota_16mb.csv)

That is the minimum set that makes the project honestly compatible with our `N16R8`.

---

## <span style="color:#4EA1FF;">Practical Outcome</span>

After fixing the board profile, the project gained:

- correct `16MB flash` handling
- correct `8MB PSRAM` handling
- working `LittleFS`
- working OTA partitioning
- alignment between the real hardware, PlatformIO, and the filesystem layout

Main conclusion:

> The problem was not the module and not “broken memory”. The project had been described with the wrong board profile.

---

## <span style="color:#67C587;">Document Status</span>

This file should be treated as the technical reference for the `N16R8` board profile used by this project.
If the memory layout, OTA scheme, or build config changes in the future, those changes should be reflected here too.
