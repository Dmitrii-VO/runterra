# Изменения: Клубы

## История изменений

### 2026-02-06 — Статические клубы, привязанные к реальным беговым территориям СПб

- **Backend:** Эндпоинт `GET /api/clubs` больше не возвращает обезличенный `Test Club`. Для указанного `cityId` теперь отдаётся небольшой статический список клубов, согласованный с конфигом территорий:  
  - `club-1` — «Runterra Крестовский», клуб утренних пробежек в Приморском парке Победы / на Крестовском острове;  
  - `club-2` — «Runterra Парк 300-летия», сообщество любителей пробежек по набережной и в парке 300‑летия.  
  Эти ID используются как владельцы соответствующих территорий в конфиге `territories.config.ts`, чтобы карта, клубы и территории были связаны между собой даже без таблицы клубов в БД.
- **Итог:** Модуль клубов по‑прежнему использует in‑memory данные (таблица clubs ещё не создана), но они стали осмысленными и согласованы с реальными территориями для бега в Санкт‑Петербурге.

### 2026-02-06 — Расширение экрана клуба (город, метрики, чат)

- **Контекст:** Задача из infra/README.md — расширить экран клуба по docs/product_spec.md §5.3 (город, метрики MVP, переход в чат клуба).
- **Backend:** GET `/api/clubs/:id` дополнен полями: `cityName` (из `findCityById(cityId)`), `membersCount`, `territoriesCount`, `cityRank` (плейсхолдеры 0). Импорт `findCityById` из `modules/cities/cities.config`.
- **Mobile ClubModel:** Добавлены поля `cityId`, `cityName`, `membersCount`, `territoriesCount`, `cityRank` (все опциональные); парсинг в `fromJson`.
- **Mobile ClubDetailsScreen:** Под названием клуба отображается город (иконка + cityName ?? cityId ?? «—»); блок метрик — три карточки (участники, территории, рейтинг в городе) с значениями из модели или «—»; кнопка «Чат клуба» — `context.go('/messages?tab=club')`. Добавлен helper `_buildMetricChip`.
- **Навигация к чату клуба:** Маршрут `/messages` поддерживает query `tab=club` (и `tab=coach`); `MessagesScreen` принимает `initialTabIndex` и передаёт его в `DefaultTabController(initialIndex: index)`. Кнопка «Чат клуба» открывает Сообщения с вкладкой «Клуб».
- **i18n:** clubChatButton, clubMembersLabel, clubTerritoriesLabel, clubCityRankLabel, clubMetricPlaceholder (EN/RU).
- **Тесты:** В `club_model_test.dart` добавлен тест парсинга city и metrics из JSON.
- **Файлы:** `backend/src/api/clubs.routes.ts`, `mobile/lib/shared/models/club_model.dart`, `mobile/lib/features/club/club_details_screen.dart`, `mobile/lib/features/messages/messages_screen.dart`, `mobile/lib/app.dart`, `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb`, `mobile/test/models/club_model_test.dart`.

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

### 2026-02-04 — Присоединение к клубу (join club) — реализовано

- **Backend:**
  - Добавлена миграция `006_club_members.sql`: таблица `club_members` (id, club_id VARCHAR(128), user_id UUID REFERENCES users(id), status VARCHAR(20) DEFAULT 'active', created_at, updated_at; UNIQUE (club_id, user_id)). Репозиторий `ClubMembersRepository` (findByClubAndUser, create, findPrimaryClubIdByUser).
  - Эндпоинт `POST /api/clubs/:id/join`: auth → userId (findByFirebaseUid), проверка дубликата (findByClubAndUser), вставка в club_members, ответ 201 с телом { id, clubId, userId, status, createdAt } (без firebaseUid). Ошибки: 401 unauthorized, 400 validation_error (user not found), 400 already_member.
  - `GET /api/clubs/:id`: при наличии auth запрашивается membership; в ответ добавляются опциональные поля isMember (boolean) и membershipStatus (string).
- **Mobile:**
  - `ClubsService.joinClub(clubId)`: POST /api/clubs/:id/join, при не-2xx — ApiException(code, message). Модель `ClubModel` расширена полями isMember и membershipStatus (парсятся из GET /api/clubs/:id).
  - На `ClubDetailsScreen`: кнопка «Присоединиться» (при !isMember) вызывает joinClub; при успехе — setCurrentClubId(clubId), SnackBar «Вы вступили в клуб», перезагрузка клуба; при isMember отображается «Вы в клубе» (OutlinedButton disabled). i18n: clubJoin, clubJoinSuccess, clubJoinError(message), clubYouAreMember.

### 2026-02-05 — Выход из клуба (leave club)

- **Tests:** Added API tests for club leave and membership flags, plus model tests for membership fields.

- **Backend:** Добавлен `POST /api/clubs/:id/leave` — переводит membership в `inactive` (если есть активное). `GET /api/clubs/:id` теперь считает `isMember=true` только для `status=active`.
- **Mobile:** Добавлен `ClubsService.leaveClub()` и кнопка «Выйти из клуба» на `ClubDetailsScreen`; при успешном выходе сбрасывается currentClubId.

**Файлы:** `backend/src/api/clubs.routes.ts`, `backend/src/db/repositories/club_members.repository.ts`, `mobile/lib/shared/api/clubs_service.dart`, `mobile/lib/features/club/club_details_screen.dart`, `mobile/l10n/*.arb`.
