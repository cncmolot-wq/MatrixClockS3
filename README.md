# MatrixClockS3

MatrixClockS3 — прошивка LED-часов на ESP32-S3 для матрицы WS2812 32x8.

## Status

Проект находится в активной разработке.  
Сейчас приоритет — стабильность и поэтапная инженерная доводка, а не расширение функционала.

## Current Scope

- Clock + Fire
- Web UI
- LittleFS
- OTA
- NTP

## Project Docs

Основные документы проекта:

- Technical source of truth: `docs/project/REFACTOR_PLAN_RU.md`
- Project rules and editing contract: `docs/project/PROJECT_EDIT_RULES.md`
- Descriptive overview: `docs/project/README_RU.md`
- Board/profile reference: `docs/project/N16R8_PROFILE_BIBLE_RU.md`

## Architecture

Кратко по слоям:

- `display_runtime` — диспетчер экранного runtime
- `effects` — эффекты и визуальные блоки
- `ui` — Web UI и state/update API
- `hardware` — работа с железом
- `system_services` — Wi-Fi / OTA / FS / startup services

## Constraints

- WS2812 ограничивает допустимый FPS
- Wi-Fi влияет на runtime stability
- проект не считается финальным публичным продуктом

## Build

Смотри `platformio.ini`.

Основные окружения:
- `s3` — USB
- `s3ota` — OTA

## Notes

README не заменяет технический план.  
Если есть конфликт трактовки, ориентироваться нужно на:

1. локальные инструкции
2. `docs/project/PROJECT_EDIT_RULES.md`
3. `docs/project/REFACTOR_PLAN_RU.md`
