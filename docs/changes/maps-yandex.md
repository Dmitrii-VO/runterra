# Миграция карт: Mapbox → Yandex MapKit

## Дата
2026-01-31

## Причина изменения
- Лучшая поддержка региона РФ (актуальные данные, POI, маршруты)
- Ценовая политика: бесплатно до 1000 DAU при соблюдении условий
- Официальная поддержка Flutter через пакет `yandex_mapkit`

## Что изменено

### Конфигурация
- `.cursorrules` — стек карт изменён на Yandex MapKit
- `mobile/pubspec.yaml` — `mapbox_maps_flutter: ^2.17.0` → `yandex_mapkit: ^4.0.0`
- `mobile/android/app/src/main/AndroidManifest.xml` — Mapbox token заменён на Yandex API key

### Код
- `mobile/lib/main.dart` — добавлен импорт `yandex_mapkit`
- `mobile/lib/features/map/map_screen.dart` — полностью переписан под Yandex MapKit API:
  - `YandexMap` вместо `MapWidget`
  - `YandexMapController` вместо `MapboxMap`
  - `CircleMapObject` вместо `CircleAnnotation`
  - `CameraUpdate.newCameraPosition()` вместо `flyTo()`
  - `MapAnimation` вместо `MapAnimationOptions`
  - Функционал кнопки "Моё местоположение" встроен в экран
- `mobile/lib/features/map/widgets/my_location_button.dart` — удалён (функционал встроен в map_screen.dart)

### Документация
- `README.md` — стек карт обновлён
- `mobile/README.md` — инструкции по настройке Mapbox заменены на Yandex

## API ключ
- Получен бесплатный ключ Yandex MapKit
- Условия: до 1000 DAU, приложение бесплатное и общедоступное
- Коммерческая лицензия потребуется при превышении лимитов или платном приложении

## Ограничения бесплатной версии
- До 1000 уникальных пользователей в сутки (DAU)
- Только онлайн-режим (без офлайн-карт)
- Приложение должно быть бесплатным и общедоступным
- Нельзя использовать для мониторинга транспорта

## Не изменено
- Backend API для карт (`/api/map/data`)
- Модели данных (`MapDataModel`, `TerritoryMapModel`)
- Логика фильтров
- UI компоненты (bottom sheet территории, панель фильтров)
