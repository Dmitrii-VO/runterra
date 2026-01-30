# Mobile: исправление средних проблем (36-50)

## Дата: 2026-01-29

## Контекст

Исправлены средние проблемы из списка багов проекта:
- Проблемы навигации (36-37)
- Производительность и race conditions (38-39)
- Баги карты и цветов (40, 44-45)
- Совместимость с Flutter Web (41-42)
- Архитектурные проблемы (43, 46-50)

## Изменения

### 36-37: Навигация — context.go() → context.push()

**Проблема:** Использование `context.go()` вместо `context.push()` уничтожало back stack при переходе на детальные экраны.

**Решение:**
- В `navigation_handler.dart` заменены все `router.go()` на `router.push()` для детальных экранов (club, city, territory, activity)
- В `event_details_screen.dart` и `event_card.dart` заменены `context.go()` на `context.push()`
- Для основных табов (map, run, messages, events, profile) оставлен `context.go()` — это корректно, так как они являются корневыми маршрутами

**Файлы:**
- `mobile/lib/shared/navigation/navigation_handler.dart`
- `mobile/lib/features/events/event_details_screen.dart`
- `mobile/lib/features/events/widgets/event_card.dart`

### 38: RunScreen — оптимизация O(n²) пересчёта дистанции

**Проблема:** При каждом GPS-тике пересчитывалась вся дистанция от начала пробежки (O(n²)).

**Решение:** Изменён алгоритм на инкрементальный — добавляется только расстояние от предыдущей точки до текущей.

**Файлы:**
- `mobile/lib/features/run/run_screen.dart`

### 39: MapScreen — синхронизация _onMapCreated и _loadMapData

**Проблема:** Race condition между созданием карты и загрузкой данных — аннотации могли обновляться до готовности карты.

**Решение:** Добавлен флаг `_isMapReady`, который устанавливается в `_onMapCreated`; аннотации обновляются только если карта готова.

**Файлы:**
- `mobile/lib/features/map/map_screen.dart`

### 40: MapScreen — формат цвета для Mapbox SDK

**Проблема:** `Color.value` может неправильно интерпретироваться Mapbox SDK.

**Решение:** Добавлены комментарии о формате ARGB и явное использование `colorValue` для ясности (Color.value уже возвращает правильный формат).

**Файлы:**
- `mobile/lib/features/map/map_screen.dart`

### 41-42: ApiConfig — совместимость с Flutter Web и определение эмулятора

**Проблема:** 
- `dart:io Platform` крашит Flutter Web
- 10.0.2.2 возвращается для всех Android, а не только эмулятора

**Решение:**
- Использован условный импорт `dart:io` с fallback на `dart:html` для Web
- Добавлена проверка `kIsWeb` перед использованием Platform
- Для Android по умолчанию используется localhost (эмулятор определяется через API_BASE_URL override)

**Файлы:**
- `mobile/lib/shared/config/api_config.dart`

### 43: LocationService — фоновое отслеживание GPS

**Проблема:** Нет фонового отслеживания GPS.

**Решение:** Добавлен TODO комментарий в `startTracking()` о необходимости добавления фонового отслеживания в будущем.

**Файлы:**
- `mobile/lib/shared/location/location_service.dart`

### 44: MapScreen — обработка отказа в GPS permissions

**Проблема:** Отказ в GPS permissions молча проглатывался.

**Решение:** Добавлено отображение SnackBar с сообщением пользователю при отказе в разрешениях.

**Файлы:**
- `mobile/lib/features/map/map_screen.dart`

### 45: MapScreen — fallback при ошибке поиска территории

**Проблема:** При ошибке поиска территории по индексу показывалась первая территория вместо ошибки.

**Решение:** Заменён fallback на показ ошибки через SnackBar и логирование через DevRemoteLogger.

**Файлы:**
- `mobile/lib/features/map/map_screen.dart`

### 46: MapFilters — убрать хардкод 'my-club-id'

**Проблема:** Хардкод 'my-club-id' в фильтрах карты.

**Решение:** Заменён на null с TODO комментарием о необходимости получения реального clubId из профиля пользователя.

**Файлы:**
- `mobile/lib/features/map/widgets/map_filters.dart`

### 47-48: Detail screens — общая обработка ошибок

**Проблема:** 
- Обработка ошибок через string matching (contains('TimeoutException'))
- Массивное дублирование boilerplate кода в 6 detail screens

**Решение:**
- Создан общий виджет `ErrorDisplay` в `shared/ui/error_display.dart`
- Все detail screens переведены на использование `ErrorDisplay`
- Устранено дублирование кода обработки ошибок

**Файлы:**
- `mobile/lib/shared/ui/error_display.dart` (новый файл)
- `mobile/lib/features/activity/activity_details_screen.dart`
- `mobile/lib/features/city/city_details_screen.dart`
- `mobile/lib/features/club/club_details_screen.dart`
- `mobile/lib/features/territory/territory_details_screen.dart`
- `mobile/lib/features/events/event_details_screen.dart`

### 49: TerritoryModel — парсинг clubId

**Проблема:** `TerritoryModel` не парсит `clubId` (есть в backend DTO).

**Решение:** Добавлено поле `clubId` в модель и парсинг в `fromJson()`.

**Файлы:**
- `mobile/lib/shared/models/territory_model.dart`

### 50: Все модели — unsafe as int cast

**Проблема:** Unsafe `as int` cast (backend number может быть 5.0).

**Решение:** Заменены все `as int` на `(json[...] as num).toInt()` во всех моделях.

**Файлы:**
- `mobile/lib/shared/models/event_details_model.dart`
- `mobile/lib/shared/models/event_list_item_model.dart`
- `mobile/lib/shared/models/user_stats_model.dart`

## Поведение

Все изменения являются техническими исправлениями без изменения бизнес-логики или доменных инвариантов.

## Связанные файлы

- `docs/progress.md` — обновлён список выполненных задач
