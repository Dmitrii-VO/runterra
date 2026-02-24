# Поддержка Wear OS: запуск пробежки с часов

## Что изменилось

Добавлена поддержка умных часов (Wear OS) для управления пробежкой: запуск/пауза/стоп с часов, отображение статистики на дисплее часов в реальном времени, передача ЧСС с датчика часов на телефон.

## Архитектура

```
Часы (wear/)                   Телефон (mobile/)
┌─────────────────────┐        ┌──────────────────────────┐
│ WatchIdleScreen     │        │ WatchService             │
│  [▶ Старт]          │──────▶ │  messageStream → cmd     │
│                     │  cmd   │  → RunService.*Run()     │
├─────────────────────┤        │                          │
│ WatchRunningScreen  │        │ RunService               │
│  05:24  1.3 km      │◀────── │  every 5s broadcast      │
│  5:12/km  143 ♥     │ update │  → WatchService.send()   │
│  [⏸]  [⏹]          │        │                          │
└─────────────────────┘        │ RunSession               │
                               │  + heartRate: int?       │
      ↑ ЧСС читает             └──────────────────────────┘
        HeartRatePlugin.kt
        → через watch_connectivity
        → updateHeartRate() на телефоне
```

## Новые файлы

| Файл | Описание |
|------|----------|
| `wear/pubspec.yaml` | Wear OS Flutter проект |
| `wear/lib/main.dart` | Точка входа + WatchHome (маршрутизация экранов) |
| `wear/lib/screens/watch_idle_screen.dart` | Экран ожидания (кнопка Старт) |
| `wear/lib/screens/watch_running_screen.dart` | Экран пробежки (время, дистанция, темп, ЧСС) |
| `wear/lib/services/watch_connectivity_service.dart` | Связь с телефоном через watch_connectivity |
| `wear/lib/services/heart_rate_service.dart` | Чтение ЧСС через platform channel |
| `wear/android/app/src/main/AndroidManifest.xml` | Wear OS manifest с uses-feature |
| `wear/android/app/src/main/kotlin/com/runterra/wear/HeartRatePlugin.kt` | Kotlin plugin для SensorManager |
| `mobile/lib/shared/services/watch_service.dart` | Мост RunService ↔ часы (телефон) |

## Изменённые файлы

| Файл | Изменение |
|------|-----------|
| `mobile/pubspec.yaml` | + `watch_connectivity: ^0.2.8` |
| `mobile/lib/shared/models/run_session.dart` | + поле `heartRate: int?` |
| `mobile/lib/shared/api/run_service.dart` | + метод `updateHeartRate(int bpm)` |
| `mobile/lib/shared/di/service_locator.dart` | + регистрация `WatchService` |
| `mobile/lib/features/run/run_tracking_screen.dart` | ЧСС в UI (во время и после пробежки) |
| `mobile/l10n/app_en.arb`, `app_ru.arb` | + ключ `watchNotPaired` |

## Протокол сообщений

### Часы → Телефон
```json
{"cmd": "start"}
{"cmd": "pause"}
{"cmd": "resume"}
{"cmd": "stop"}
{"cmd": "hr", "bpm": 145}
```

### Телефон → Часы (каждые 5 сек)
```json
{
  "type": "update",
  "state": "running",
  "durationSec": 324,
  "distanceM": 1340,
  "paceSecPerKm": 312,
  "bpm": 145
}
```

## Как собрать и установить на часы

### Требования
- Wear OS часы с Android API 30+ (Wear OS 3)
- ADB подключение (USB или Wi-Fi)

### Сборка
```bash
cd wear
flutter pub get
flutter build apk --debug
```

### Установка через ADB
```bash
# Подключить часы через ADB (Bluetooth bridge через телефон или Wi-Fi ADB)
adb -s <watch_serial> install build/app/outputs/flutter-apk/app-debug.apk
```

### Важно
- `applicationId` в `wear/android/app/build.gradle` должен совпадать с `mobile/android/app/build.gradle` для работы Wearable Data Layer.

## Как тестировать в эмуляторе

1. Создать AVD: Wear OS Small Round (API 30+) в Android Studio → AVD Manager
2. Запустить эмулятор телефона (Pixel 5, API 33) и эмулятор часов
3. В Android Studio: Device Manager → виртуальные часы → «Pair with phone» → выбрать эмулятор телефона
4. Запустить телефонное приложение: `cd mobile && flutter run`
5. Запустить приложение часов: `cd wear && flutter run -d <wear_emulator_id>`
6. На эмуляторе часов нажать кнопку «Старт» → проверить, что пробежка началась на телефоне
7. Через 5 сек обновление должно появиться на часах (время, дистанция)
8. Нажать «Стоп» → пробежка завершается на телефоне

## Ограничения MVP

- GPS-трекинг остаётся на телефоне; часы управляют, но не пишут трек независимо
- Submit run — только с телефона
- Auth — часы используют открытый Data Layer канал без Firebase токенов
- ЧСС доступно только при подключённых часах
