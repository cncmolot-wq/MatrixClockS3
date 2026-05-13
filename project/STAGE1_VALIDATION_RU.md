> Stage 1 gate checklist. Use this file for real device validation before adding new feature scope.

# Stage 1 Validation RU

Цель: закрыть фундамент проекта не словами, а проверенными сценариями на реальных часах.

Правило: если пункт не проверен на устройстве, он не считается закрытым.

## Must Pass

- `cold_no_wifi`: холодный старт с сохранённой, но временно недоступной сетью не переводит часы в setup AP; часы продолжают показывать время, мигают синим статус-пикселем и периодически пробуют восстановить STA-соединение.
- `wifi_no_internet`: Wi-Fi подключён, но интернет/NTP/weather недоступны; часы остаются в STA/LAN, не переходят в setup AP, время берётся из RTC/системных часов, сетевые сервисы показывают понятный stale/error status.
- `bad_saved_wifi`: неверные сохранённые credentials не приводят к вечной потере доступа.
- `gpio21_recovery`: удержание кнопки `GPIO21` при старте очищает Wi-Fi credentials и поднимает setup AP.
- `ap_wrong_password`: в setup AP неверный пароль пользовательской сети не выключает AP и не оставляет часы без входа.
- `ap_success_apply`: после правильных SSID/password часы переходят в пользовательскую сеть и переживают повторный старт.
- `ota_reconnect`: OTA работает после disconnect/reconnect Wi-Fi или хотя бы имеет понятный stable recovery path.
- `rtc_offline_start`: с DS3231 часы стартуют с валидным временем без NTP.
- `littlefs_missing`: при missing/битом LittleFS backend отдаёт понятный status, часы не уходят в немую поломку.
- `ui_basic`: вкладки `Настройки`, `Интерфейс`, `Погода`, `Инфо` открываются после LittleFS upload.
- `state_basic`: `/state` отдаёт Wi-Fi, FS, OTA, RTC, weather, async, frame/heap status без зависания.

## Gate Decision

- `PASS`: все Must Pass проверены или для редкого пункта есть осознанный documented exception.
- `HOLD`: есть повторяемая потеря доступа, OTA/recovery неясен, LittleFS ломает UI без статуса, RTC/weather/task state нестабилен.

## Current Decision

- `Stage 1`: `PASS with hardware note`
- Firmware / product logic считаются закрытыми для Stage 1:
  - часы, Wi-Fi onboarding/recovery, AP flow, RTC, weather, `/state`, UI и offline-safe сценарии подтверждены на железе;
  - переходы `STA <-> AP`, recovery-кнопка и product Wi-Fi flow больше не считаются открытым блокером Stage 1.
- Hardware note по текущей dev board `ESP32-S3 N16R8`:
  - нестабильный cold start воспроизводится даже на голой плате без матрицы;
  - offline Wi-Fi rendering glitches на этой плате считаются board-specific поведением стенда, а не firmware-blocker;
  - эти два пункта не закрываются кодом в рамках Stage 1 и выносятся в аппаратный риск текущего стенда.

## After Pass

После PASS можно выбирать один следующий feature-track:
- weather on matrix;
- radio preparation;
- notification bridge research.

Текущий выбранный следующий track:
- radio preparation on dual MCU (`ESP32-S3` как main clock/display controller, `ESP32-WROOM32` как radio/network coprocessor).

Не начинать несколько feature-track одновременно.
