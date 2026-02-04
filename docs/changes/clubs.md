# Изменения: Клубы

## История изменений

### 2026-02-04 — Кнопка «Создать клуб» (функциональное создание)

- **Контекст:** Пункт раздела «Карта и трекинг» в infra/README.md — сделать кнопку «Создать клуб» функциональной.
- **Mobile:** Добавлен метод `ClubsService.createClub({required String name, String? description, required String cityId})`: POST /api/clubs, тело `{ name, description?, cityId }`, разбор ответа 201 в ClubModel; при не-201 — ApiException с code/message из ответа backend. Экран `CreateClubScreen`: форма (название — обязательно, описание — опционально), город берётся из CurrentCityService; при отсутствии города показывается подсказка и кнопка «Создать» отключена; при успешном создании — переход на экран клуба (`context.go('/club/${club.id}')`). Маршрут `/club/create` добавлен в app.dart; CreateClubAction в NavigationHandler ведёт на `router.push('/club/create')`. i18n: createClubTitle, createClubNameHint, createClubDescriptionHint, createClubSave, createClubNameRequired, createClubCityRequired, createClubError(message).
- **Backend:** без изменений; POST /api/clubs и CreateClubSchema уже реализованы.
- **Файлы:** `mobile/lib/shared/api/clubs_service.dart`, `mobile/lib/features/club/create_club_screen.dart`, `mobile/lib/app.dart`, `mobile/lib/shared/navigation/navigation_handler.dart`, `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb`.

### 2026-01-29

- **Mobile API error handling (ClubsService):** в `getClubs` и `getClubById` добавлена проверка `response.statusCode` и обработка не-JSON ответов по образцу `EventsService.getEvents()`: при статусе != 200 — `Exception`, при ответе не application/json или HTML — `FormatException`, парсинг JSON в try/catch. Устранена возможность FormatException при 404/500.
- **Runtime-валидация входных данных (backend):** Для эндпоинта `POST /api/clubs` добавлена техническая runtime-валидация тела запроса через Zod-схему `CreateClubSchema` (на основе `CreateClubDto`). Валидация проверяет только форму и типы полей запроса без добавления бизнес-логики; при некорректном теле запроса backend возвращает `400 Bad Request` с описанием ошибок.
 - **Mobile: Club details FutureBuilder:** `ClubDetailsScreen` переведён на `StatefulWidget` с кэшированием `Future` загрузки деталей клуба в `initState`, чтобы избежать повторных HTTP-запросов при каждом `rebuild`; отображаемые поля и доменная модель не изменены.

### 2026-02-02

- **Поле cityId у клубов (skeleton):** сущность `Club` и DTO (`CreateClubDto`, `ClubViewDto`) расширены обязательным полем `cityId: string`, чтобы явно фиксировать город клуба в доменной модели. Таблица клубов пока отсутствует (mock‑данные), поэтому изменения не затрагивают БД.
- **Фильтрация клубов по городу в API:** эндпоинт `GET /api/clubs` теперь требует query‑параметр `cityId`; при его отсутствии возвращается `400 validation_error` с полем `cityId`. Заглушка возвращает список клубов с `cityId` из запроса; `GET /api/clubs/:id` возвращает mock‑клуб с `cityId: "spb"` для согласованности контракта.
- **Mobile ClubsService: cityId в запросах:** метод `ClubsService.getClubs` теперь принимает обязательный параметр `cityId` и добавляет его в query‑строку `/api/clubs?cityId=...`. Модель `ClubModel` по‑прежнему использует только id/name/description/status/createdAt/updatedAt; фильтрация по городу реализуется на уровне backend.
