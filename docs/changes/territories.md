# Изменения: Территории

## История изменений

### 2026-02-06 — Реальные популярные беговые локации СПб вместо generic-моков

- **Backend (territories):** Эндпоинт `GET /api/territories` больше не возвращает абстрактную `Test Territory` с координатами вне контекста города. Добавлен конфиг `modules/territories/territories.config.ts` с тремя реальными популярными локациями для бега в Санкт‑Петербурге (`cityId: "spb"`):  
  - `spb-primorsky-park-pobedy` — «Приморский парк Победы (Крестовский остров)», статус `CAPTURED`;  
  - `spb-yalagin-island` — «ЦПКиО им. Кирова (Елагин остров)», статус `FREE`;  
  - `spb-park-300` — «Парк 300-летия Санкт-Петербурга», статус `CONTESTED`.  
  `GET /api/territories` теперь использует `getTerritoriesForCity(cityId, clubId?)` из этого конфига и возвращает только территории выбранного города (с учётом `clubId`).
- **Backend (territory details):** `GET /api/territories/:id` использует `getTerritoryById(id)` из конфига. При отсутствии записи возвращает `404 not_found` с телом `{ code: "not_found", message: "Territory not found", details: { territoryId } }` вместо фиктивной Territory `{ id, name: "Territory {id}", ... }`.
- **Backend (map):** Эндпоинт `GET /api/map/data` больше не содержит локальный массив mock-территорий; он также использует `getTerritoriesForCity(cityId, clubId?)`, а флаги `onlyActive` и `clubId` фильтруют реальные конфиг‑территории (популярные парки для бега). События по‑прежнему берутся из БД через `EventsRepository`.
- **Итог:** Территории на карте и в списке больше не выглядят как искусственные "test" заглушки — они привязаны к трём реальным беговым локациям СПб, при этом архитектура остаётся конфиг‑based (без таблицы территорий), что соответствует skeleton‑этапу.

### 2026-01-29

- **Mobile API error handling (TerritoriesService):** в `getTerritories` и `getTerritoryById` добавлена проверка `response.statusCode` и обработка не-JSON ответов по образцу `EventsService.getEvents()`: при статусе != 200 — `Exception`, при ответе не application/json или HTML — `FormatException`, парсинг JSON в try/catch. Устранена возможность FormatException при 404/500.
- **Runtime-валидация входных данных (backend):** Для эндпоинта `POST /api/territories` добавлена техническая runtime-валидация тела запроса через Zod-схему `CreateTerritorySchema` (на основе `CreateTerritoryDto`). Валидация проверяет только форму и типы полей запроса без добавления бизнес-логики; при некорректном теле запроса backend возвращает `400 Bad Request` с описанием ошибок.
 - **Mobile: Territory details FutureBuilder:** `TerritoryDetailsScreen` переведён на `StatefulWidget` с кэшированием `Future` загрузки деталей территории в `initState`, чтобы избежать повторных HTTP-запросов при каждом `rebuild`; отображаемые поля и доменная модель не изменены.
 - **Mobile: TerritoryCoordinates dedup:** класс координат `TerritoryCoordinates`, ранее определённый отдельно в `territory_model.dart` и `territory_map_model.dart`, вынесен в единую DTO-модель и переиспользуется через импорт; это техническая правка для устранения конфликта компиляции без изменения формата данных API.

### 2026-02-02

- **cityId в территориальных контрактках:** сущность `Territory` и DTO (`CreateTerritoryDto`, `TerritoryViewDto`) уже содержали поле `cityId: string`; оно стало основой для фильтрации карты и списка территорий по городу.
- **Фильтрация территорий по городу и клубу (backend):** эндпоинты `/api/territories` и `/api/map/data` теперь требуют query‑параметр `cityId` (при его отсутствии возвращают `400 validation_error` с полем `cityId`) и принимают опциональный `clubId`. Заглушки в `territories.routes.ts` и `map.routes.ts` отдают mock‑территории только с указанным `cityId`, при наличии `clubId` дополнительно фильтруют по клубу.
- **Валидация координат территории по границам города:** в `POST /api/territories` после Zod‑валидации добавлена проверка `isPointWithinCityBounds(dto.coordinates, dto.cityId)`; при выходе центра территории за границы города API возвращает `400 validation_error` с полем `coordinates` и кодом `coordinates_out_of_city`.
- **Mobile TerritoriesService: cityId/clubId в запросах:** метод `TerritoriesService.getTerritories` расширен параметрами `cityId` (обязательный) и `clubId` (опциональный), которые передаются как query‑параметры. Это гарантирует, что клиент не запрашивает и не отображает территории из других городов.
