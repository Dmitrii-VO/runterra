# Изменения: Клубы

## История изменений

### 2026-01-29

- **Mobile API error handling (ClubsService):** в `getClubs` и `getClubById` добавлена проверка `response.statusCode` и обработка не-JSON ответов по образцу `EventsService.getEvents()`: при статусе != 200 — `Exception`, при ответе не application/json или HTML — `FormatException`, парсинг JSON в try/catch. Устранена возможность FormatException при 404/500.
- **Runtime-валидация входных данных (backend):** Для эндпоинта `POST /api/clubs` добавлена техническая runtime-валидация тела запроса через Zod-схему `CreateClubSchema` (на основе `CreateClubDto`). Валидация проверяет только форму и типы полей запроса без добавления бизнес-логики; при некорректном теле запроса backend возвращает `400 Bad Request` с описанием ошибок.
 - **Mobile: Club details FutureBuilder:** `ClubDetailsScreen` переведён на `StatefulWidget` с кэшированием `Future` загрузки деталей клуба в `initState`, чтобы избежать повторных HTTP-запросов при каждом `rebuild`; отображаемые поля и доменная модель не изменены.
