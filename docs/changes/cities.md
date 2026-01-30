# Изменения: Города

## История изменений

### 2026-01-29

- **Mobile API error handling (CitiesService):** в `getCities` и `getCityById` добавлена проверка `response.statusCode` и обработка не-JSON ответов по образцу `EventsService.getEvents()`: при статусе != 200 — `Exception`, при ответе не application/json или HTML — `FormatException`, парсинг JSON в try/catch. Устранена возможность FormatException при 404/500.
- **Runtime-валидация входных данных (backend):** Для эндпоинта `POST /api/cities` добавлена техническая runtime-валидация тела запроса через Zod-схему `CreateCitySchema` (на основе `CreateCityDto`). Валидация проверяет только форму и типы полей запроса (name и coordinates) без добавления бизнес-логики; при некорректном теле запроса backend возвращает `400 Bad Request` с описанием ошибок.
 - **Mobile: City details FutureBuilder:** `CityDetailsScreen` переведён на `StatefulWidget` с кэшированием `Future` загрузки деталей города в `initState`, чтобы избежать повторных HTTP-запросов при каждом `rebuild`; отображаемые поля и доменная модель не изменены.

