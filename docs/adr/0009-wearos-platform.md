# ADR-0009: Поддержка Wear OS для управления пробежкой

## Контекст

Пользователи хотят запускать/останавливать пробежку прямо с умных часов, видеть статистику на дисплее часов во время бега и получать ЧСС с датчика часов.

Рассматривались две платформы для смарт-часов:
- **Wear OS** (Google / Samsung / Fossil / TicWatch)
- **Apple Watch** (watchOS, только iOS)

Целевые устройства: Samsung Galaxy Watch 4/5/6/7, Pixel Watch, TicWatch.

Вопросы:
1. Какую платформу выбрать?
2. Как организовать канал связи телефон ↔ часы?
3. Как читать ЧСС с датчика часов?

## Решения

### 1. Платформа: Wear OS

**Решение:** Wear OS как единственная поддерживаемая платформа часов на MVP.

**Обоснование:**
- Официальная поддержка Flutter через пакет `wear`
- Galaxy Watch 4+ работают на Wear OS (не Tizen), охватывая большинство Android-пользователей проекта
- Apple Watch требует отдельного iOS-приложения и macOS для сборки — вне текущего стека
- Pixel Watch, TicWatch, Fossil — все на Wear OS

**Последствия:**
- Отдельный Flutter-проект `wear/` в монорепозитории
- Сборка отдельно для часов, установка через ADB или Google Play (раздельные APK)

### 2. Канал связи: `watch_connectivity` (Wearable Data Layer API)

**Решение:** Пакет `watch_connectivity: ^1.1.0` как двусторонний канал телефон ↔ часы.

**Обоснование:**
- Оборачивает Android Wearable Data Layer API (MessageClient)
- Поддерживает Wear OS 3+
- Простой API: `sendMessage(Map)` и `messageStream`
- Не требует собственного Kotlin-кода для коммуникации

**Протокол (JSON):**
- Часы → Телефон: `{"cmd": "start|pause|resume|stop"}`, `{"cmd": "hr", "bpm": 145}`
- Телефон → Часы: `{"type": "update", "state": "running", "durationSec": 324, "distanceM": 1340, "paceSecPerKm": 312, "bpm": 145}`

**Последствия:**
- Обе стороны (телефон и часы) должны иметь одинаковый `applicationId` для работы Data Layer
- `WatchService` на стороне телефона инициализируется в `ServiceLocator`

### 3. ЧСС: Platform Channel → SensorManager

**Решение:** Kotlin plugin `HeartRatePlugin` на стороне часов читает `Sensor.TYPE_HEART_RATE` через `SensorManager` и передаёт данные в Dart через `EventChannel`.

**Обоснование:**
- Wear OS Health Services API (Jetpack Health) — более мощный, но требует больше setup
- `SensorManager` — стандартный Android API, ~50 строк Kotlin, достаточен для MVP
- Данные ЧСС с часов передаются на телефон через `watch_connectivity` каждые 5 сек

**Последствия:**
- Нужно разрешение `android.permission.BODY_SENSORS` в AndroidManifest часов
- GPS-трекинг остаётся на телефоне; часы управляют пробежкой, но не пишут трек независимо
- `submit run` — только с телефона (финальный экран результатов не нужен на часах)

## Статус

Принято — 2026-02-24
