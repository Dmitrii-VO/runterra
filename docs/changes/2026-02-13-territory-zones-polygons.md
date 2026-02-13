# Территории: полигоны вместо кругов (Quick Win)

**Дата:** 2026-02-13  
**Источник:** docs/tasks/gemini-map-zones-analysis-report.md

## Контекст

Территории отображались как круги (CircleMapObject) с фиксированным радиусом 500 м. Круги создают наложения и пустые зоны на границах, что делает логику «захвата территории» неоднозначной. Анализ рекомендовал адаптивную квадратную сетку для MVP.

## Реализовано (Quick Win)

### Backend

- **TerritoryViewDto:** добавлено опциональное поле `geometry?: GeoCoordinates[]` — массив точек полигона границ.
- **territories.config.ts:** функция `generateSquareGeometry(lat, lon, sizeInMeters)` генерирует квадрат из 4 точек вокруг центра. Используется приближение 1° ≈ 111320 м (для масштаба города искажениями пренебрегаем).
- **materialize():** при формировании TerritoryViewDto добавляется `geometry` — квадрат 1000×1000 м вокруг центра каждой территории.
- **Константа:** `TERRITORY_SQUARE_SIZE_M = 1000`.

### Mobile

- **TerritoryMapModel:** добавлено поле `geometry: List<TerritoryCoordinates>?`. Парсинг из JSON в `fromJson`, сериализация в `toJson`.
- **MapScreen:** логика отрисовки:
  - если `territory.geometry != null && geometry.length >= 3` → `PolygonMapObject` (Yandex MapKit Polygon + LinearRing);
  - иначе → `CircleMapObject` (fallback, радиус 500 м).
- **LinearRing:** кольцо закрывается добавлением первой точки в конец (требование Yandex MapKit).

### Тесты

- Backend: добавлен тест «returns territories with geometry (square polygon)» в api.test.ts.
- Mobile: создан `territory_map_model_test.dart` — парсинг с geometry и без.

## Файлы

**Backend:** territory.dto.ts, territories.config.ts, api.test.ts  
**Mobile:** territory_map_model.dart, map_screen.dart, territory_map_model_test.dart

## Дальнейшие шаги (из отчёта)

- Фаза 2: скрипт `scripts/generate-territories.ts` для нарезки города по зонам плотности (400/700/1200 м).
- Фаза 3: при наличии geometry — полная замена кругов на полигоны (уже реализовано fallback).
