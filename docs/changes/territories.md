# Изменения: Территории

## История изменений

### 2026-01-29

- **Mobile API error handling (TerritoriesService):** в `getTerritories` и `getTerritoryById` добавлена проверка `response.statusCode` и обработка не-JSON ответов по образцу `EventsService.getEvents()`: при статусе != 200 — `Exception`, при ответе не application/json или HTML — `FormatException`, парсинг JSON в try/catch. Устранена возможность FormatException при 404/500.
- **Runtime-валидация входных данных (backend):** Для эндпоинта `POST /api/territories` добавлена техническая runtime-валидация тела запроса через Zod-схему `CreateTerritorySchema` (на основе `CreateTerritoryDto`). Валидация проверяет только форму и типы полей запроса без добавления бизнес-логики; при некорректном теле запроса backend возвращает `400 Bad Request` с описанием ошибок.
 - **Mobile: Territory details FutureBuilder:** `TerritoryDetailsScreen` переведён на `StatefulWidget` с кэшированием `Future` загрузки деталей территории в `initState`, чтобы избежать повторных HTTP-запросов при каждом `rebuild`; отображаемые поля и доменная модель не изменены.
 - **Mobile: TerritoryCoordinates dedup:** класс координат `TerritoryCoordinates`, ранее определённый отдельно в `territory_model.dart` и `territory_map_model.dart`, вынесен в единую DTO-модель и переиспользуется через импорт; это техническая правка для устранения конфликта компиляции без изменения формата данных API.
