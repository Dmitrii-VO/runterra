# Backend: общий тип координат (latitude, longitude)

**Дата:** 2026-01-29

## Проблема

В пяти модулях дублировались определения типа «широта/долгота»:

- cities: `CityCoordinates`
- territories: `TerritoryCoordinates`
- events: `EventStartLocation`
- runs: `GpsPoint` (latitude, longitude + timestamp)
- map: `MapCoordinates`

Идентичная структура `{ longitude: number; latitude: number }` в каждом модуле усложняла изменения и согласованность.

## Решение

Введён **единый тип** в **shared/types/coordinates.ts**:

- **GeoCoordinates** — интерфейс `{ longitude: number; latitude: number }`.
- **GeoCoordinatesSchema** — Zod-схема для валидации в DTO.

Модули переведены на использование общего типа:

- **map/map.types.ts:** `MapCoordinates` — алиас `GeoCoordinates`.
- **cities/city.entity.ts:** `CityCoordinates` — алиас `GeoCoordinates`; city.dto использует `GeoCoordinatesSchema`.
- **territories/territory.entity.ts:** `TerritoryCoordinates` — алиас `GeoCoordinates`; territory.dto использует `GeoCoordinatesSchema`.
- **events/event.entity.ts:** `EventStartLocation` — алиас `GeoCoordinates`; event.dto использует `GeoCoordinatesSchema`.
- **runs/run.entity.ts:** `GpsPoint` — интерфейс, расширяющий `GeoCoordinates` с полем `timestamp?`; run.dto использует `GeoCoordinatesSchema.extend({ timestamp: ... })`.

Структура данных и контракты API не изменились; устранено только дублирование определений.
