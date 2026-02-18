# Deploy fixes (2026-02-18)

## Контекст

При запуске `npm run deploy` возникали ошибки:
1. Uncommitted changes блокировали деплой
2. CI падал: yandex_mapkit 4.2.1 несовместим с Flutter 3.27.4 (Color.toARGB32 удалён)
3. Flutter 3.24.5: Color.r/g/b и withValues отсутствуют в коде
4. Mobile Build APK: Android "cannot access Point/MapKitFactory" — нативные зависимости

## Выполненные исправления

### 1. Git и .gitignore
- Восстановлены удалённые `mobile/pubspec.yaml` и `mobile/pubspec.lock`
- Добавлены в .gitignore: `_write_test_root.txt`, `mobile_acl.txt`

### 2. CI: Flutter и yandex_mapkit
- **Flutter:** понижен с 3.27.4 до 3.24.5 (yandex_mapkit 4.2.1 не поддерживает 3.27)
- **Патч yandex_mapkit:** добавлен шаг в CI после `flutter pub get` — замена `toARGB32()` на `.value` в Dart-файлах плагина (Flutter 3.24 тоже не имеет toARGB32)

### 3. Mobile: Color API для Flutter 3.24
Заменены вызовы Flutter 3.27+ API на совместимые с 3.24:
- `Color.r/g/b` → `Color.red/green/blue`
- `Color.withValues(alpha: x)` → `Color.withOpacity(x)`

Затронутые файлы:
- `club_details_screen.dart`
- `event_details_screen.dart`
- `events/widgets/event_card.dart`
- `map/widgets/event_card.dart`
- `map/widgets/territory_bottom_sheet.dart`
- `shared/ui/profile/activity_section.dart`

### 4. Android: Yandex MapKit
- Версия maps.mobile: 4.6.1-lite → 4.22.0-lite (по README yandex_mapkit)
- Добавлено `yandexMapkit.variant=lite` в `gradle.properties`

### 5. Backend deploy
Backend успешно задеплоен через `deploy:backend -SkipCI`. Применены миграции 018–022.

## Открытая проблема: Mobile Build в CI

Mobile job в CI продолжает падать на шаге "Build APK (debug)" с ошибками:
```
error: cannot access Point
error: cannot access MapKitFactory
...
```

Причина: Yandex MapKit Android SDK (`com.yandex.android:maps.mobile`) не резолвится в среде GitHub Actions. Dart-компиляция проходит (после патча toARGB32), но Java-компиляция плагина yandex_mapkit не находит классы MapKit.

**Временное решение:** деплой mobile выполнять локально (`npm run deploy:mobile`), backend — через `npm run deploy:backend` или `deploy -SkipCI` (только backend).

**Для полного CI:** требуется разобраться с Maven-репозиторием Yandex MapKit в GitHub Actions (возможно, нужен отдельный repository или кэширование).
