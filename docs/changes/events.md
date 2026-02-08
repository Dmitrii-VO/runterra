# Изменения: События (Events)

## История изменений

### 2026-02-08 — Организатор события: отображаемое имя вместо ID

- **Проблема:** Во вкладке «Событие» в поле «Организатор» выводился сырой идентификатор (много символов), а не имя того, кто создал событие (клуб или тренер).
- **Backend:**
  - В `EventDetailsDto` и `EventListItemDto` добавлено опциональное поле `organizerDisplayName?: string`.
  - Добавлен хелпер `getOrganizerDisplayName(organizerId, organizerType)` в `api/helpers/organizer-display.ts`: для типа `club` — запрос к `ClubsRepository.findById`, для `trainer` — к `UsersRepository.findById`; при ошибке резолва возвращается `undefined`, в лог пишется предупреждение.
  - В `GET /api/events` при маппинге списка событий для каждого события вызывается `getOrganizerDisplayName`, результат попадает в `organizerDisplayName` в DTO.
  - В `GET /api/events/:id` перед формированием `EventDetailsDto` вызывается `getOrganizerDisplayName`, значение передаётся в DTO.
  - В `GET /api/map/data` при формировании списка событий для карты аналогично добавляется `organizerDisplayName` для каждого события.
- **Mobile:**
  - В `EventDetailsModel` и `EventListItemModel` добавлено опциональное поле `organizerDisplayName`; парсинг в `fromJson` и сериализация в `toJson` обновлены.
  - На экране деталей события (`EventDetailsScreen`) в строке «Организатор» выводится `event.organizerDisplayName ?? event.organizerId`.
  - В карточке события в списке (`events/widgets/event_card.dart`) выводится `organizerDisplayName` при наличии, иначе — `eventOrganizerLabel(organizerId)`.
  - В карточке события на карте (`map/widgets/event_card.dart`) выводится `organizerDisplayName` при наличии, иначе — `clubLabel`/`trainerLabel` по ID.
- **Итог:** Пользователь видит читаемое имя организатора (название клуба или имя тренера) вместо технического ID.

### 2026-02-08 — Укрепление: батч-резолв, пустая строка, тесты

- **Backend — батч-резолв имён организаторов (устранение N+1):**
  - Добавлена функция `getOrganizerDisplayNamesBatch(pairs)` в `api/helpers/organizer-display.ts`: собирает уникальные `organizerId` по типам `club` и `trainer`, выполняет два запроса к БД (`ClubsRepository.findByIds`, `UsersRepository.findByIds`) и возвращает `Map<key, name>`.
  - В `GET /api/events` и `GET /api/map/data` вместо N вызовов `getOrganizerDisplayName` используется один вызов `getOrganizerDisplayNamesBatch`; формирование DTO стало синхронным маппингом по готовой карте. Для `GET /api/events/:id` по-прежнему используется одиночный `getOrganizerDisplayName`.
  - В `ClubsRepository` добавлен метод `findByIds(ids: string[])` по аналогии с `UsersRepository.findByIds`.
- **Mobile — пустая строка как отсутствие имени:**
  - На экране деталей события и в карточках событий (список, карта) для отображения организатора используется проверка `organizerDisplayName?.trim().isNotEmpty == true`; при пустой или состоящей из пробелов строке показывается fallback (ID или лейбл).
- **Тесты:**
  - В `api.test.ts` добавлены проверки: GET /api/events — у первого события в ответе есть `organizerDisplayName`, для мока с клубом ожидается `'Test Club'`; GET /api/events/:id — в ответе есть `organizerDisplayName`, для клуба — `'Test Club'`.
  - В моках репозиториев добавлены `findByIds` для `mockClubsRepository` и `mockUsersRepository`.
- **Защита от пустых/невалидных ID:**
  - В `getOrganizerDisplayName`: при пустом или состоящем только из пробелов `organizerId` возвращается `undefined` без запроса к БД.
  - В `getOrganizerDisplayNamesBatch`: в списки `clubIds` и `trainerIds` попадают только пары с непустым (после trim) `organizerId`, чтобы не передавать пустые строки в `findByIds` (важно для колонок типа UUID).

#### Риски (organizerDisplayName) — проверка и митигации

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| **PostgreSQL: `id = ANY($1)` при невалидном UUID** — колонки `clubs.id` и `users.id` имеют тип UUID; при наличии в событиях legacy-значений `organizer_id` (например `club-1`) запрос может выбросить ошибку приведения типа. | Средняя (если в БД есть старые данные) | Ошибка ловится в try/catch; возвращается пустая карта / undefined; в ответе API поле `organizerDisplayName` отсутствует; на mobile показывается fallback по ID. Падения нет. | Try/catch в `getOrganizerDisplayName` и `getOrganizerDisplayNamesBatch`; фильтрация пустых `organizerId` перед вызовом `findByIds`. |
| **Удалённый клуб/пользователь** — событие ссылается на удалённого организатора. | Низкая | `findById`/`findByIds` возвращают пустой результат; имя не подставляется; в UI показывается ID. | Ожидаемое поведение; fallback на ID на mobile. |
| **`user.name` или `club.name` в БД = NULL** — теоретически при изменении схемы. | Низкая | В карту попадает `undefined`; в JSON поле может отсутствовать; mobile обрабатывает null/отсутствие. | Схема: `name` NOT NULL; при появлении nullable — mobile уже использует `?.trim().isNotEmpty`. |
| **Пустая строка `organizerDisplayName` с backend** — backend мог бы отдать `""`. | Низкая | Mobile проверяет `organizerDisplayName?.trim().isNotEmpty == true`; пустая строка не показывается, используется fallback. | Реализовано на mobile. |
| **Порядок событий** — батч резолвит по уникальным ID; маппинг DTO идёт по исходному порядку `events`. | Нет | Порядок сохраняется; карта только подставляет имена. | — |
| **Дубликаты организаторов** — несколько событий с одним и тем же клубом/тренером. | Нет | Уникальные ID собираются в Set; два запроса к БД независимо от числа событий. | Реализовано. |
| **Один запрос падает в Promise.all (batch)** — падение `findByIds` для клубов или пользователей. | Низкая | Весь batch ловит ошибку; возвращается пустая карта; все события в ответе без `organizerDisplayName`. | Try/catch в `getOrganizerDisplayNamesBatch`; логирование предупреждения. |
| **Mobile: null/undefined в `fromJson`** — поле `organizerDisplayName` отсутствует или null. | Нет | `json['organizerDisplayName'] as String?` даёт null; проверка `?.trim().isNotEmpty` даёт false; показывается fallback. | Реализовано. |
| **Контракт API: ключ в ответе** — при `undefined` поле может не сериализоваться в JSON. | Нет | Клиент получает отсутствующее поле как null при парсинге; поведение единообразно. | Ожидаемо. |

**Рекомендуемые проверки после деплоя:** (1) События с организатором-клубом (UUID) — отображается название клуба. (2) События с организатором-тренером — отображается имя пользователя. (3) Событие с несуществующим/удалённым организатором — отображается ID, без падения. (4) Список из 20+ событий — время ответа GET /api/events в норме (два доп. запроса к БД).

### 2026-02-06 — Доделан флоу событий на mobile (создание, join, check-in, фильтры)

- **Mobile — EventsService:** Методы `getEventById` и `getEventParticipants` теперь обрабатывают HTTP‑ошибки в едином стиле через `ApiException`: при не‑2xx ответах парсятся `code`/`message` из ADR‑ответа backend (или используется fallback‑код) и выбрасывается `ApiException`, как и для `createEvent`/`joinEvent`/`checkInEvent`/`leaveEvent`. Это устраняет "тихие" падения при 404/500 и унифицирует обработку ошибок во всех вызовах Events API на клиенте.
- **Mobile — EventDetailsScreen:** Детальный экран события завершён с точки зрения участия и check‑in: помимо кнопок «Присоединиться» / «Вы участвуете» / «Отменить участие» добавлена check‑in кнопка для участников, которая использует `LocationService` через `ServiceLocator.locationService.getCurrentPosition()` и вызывает `EventsService.checkInEvent(eventId, longitude, latitude)`. Успех/ошибка отображаются через Snackbar с использованием `eventCheckInSuccess`/`eventCheckInError`.
- **Mobile — EventsScreen:** Фильтры даты, «Только открытые» и «Мой клуб» проксируются в `EventsService.getEvents` (cityId, dateFilter, clubId, onlyOpen), таким образом минимальный флоу фильтрации реализован. Флоу «создание события» завершён: FAB ведёт на `CreateEventScreen`, который вызывает `EventsService.createEvent()` и после успешного ответа переходит на `EventDetailsScreen` по `event.id`.
- **Итог:** На мобильном клиенте закрыт минимальный флоу событий: список с фильтрами (дата, только открытые, мой клуб), создание события, запись/отмена участия и check‑in через EventsService и экран деталей события, с унифицированной обработкой ошибок.

### 2026-02-06 — Ограничение participant_limit и статус FULL (без полноценной транзакционной блокировки)

- **Backend:** Логика `joinEvent(eventId, userId)` в `EventsRepository` по‑прежнему выполняет проверку лимита участия и статуса события (`OPEN`/`FULL`) и после каждой операции регистрации пересчитывает `participant_count` и статус события через `updateParticipantCount()` (при `participant_count >= participant_limit` статус становится `FULL`, при снижении — возвращается в `OPEN`). Явных транзакций или row‑level locking пока нет, что зафиксировано в комментариях как TODO для будущего этапа, когда будет подключена реальная БД и появится нагрузка; текущая реализация сохраняет инварианты статуса FULL в типовом случае без экстремальной конкуренции.

### 2026-02-06 — Унификация формата ошибок Events API (ADR-0002)

- **Backend:** Эндпоинты `GET /api/events`, `GET /api/events/:id`, `GET /api/events/:id/participants` и `POST /api/events` приведены к единому формату ошибок ADR-0002:
  - Все ответы 500 теперь возвращают `{ code: "internal_error", message: "Internal server error" }` вместо `{ error: "Internal server error" }`.
  - Случаи отсутствия события (`Event not found`) в `GET /api/events/:id` и `GET /api/events/:id/participants` теперь возвращают `404` с телом `{ code: "not_found", message: "Event not found", details: { eventId } }` вместо `{ error: "Event not found" }`.
- **Итог:** Все errors в Events API (включая join/leave/check-in, описанные ранее) используют единый конверт `{ code, message, details? }` в соответствии с `docs/api-errors-and-validation.md`.

### 2026-02-05

- **Tests:** Added API tests for participant flags in `GET /api/events/:id` and `POST /api/events/:id/leave`, repository tests for leaveEvent, and Flutter model tests for EventDetails.

- **Отмена участия + состояние участия в деталях события:**
  - **Backend:** Добавлен `POST /api/events/:id/leave` для отмены участия; в `GET /api/events/:id` добавлены поля `isParticipant` и `participantStatus` для текущего пользователя. В репозитории реализовано `leaveEvent()` и обновление `participantCount` с возвратом статуса OPEN при освобождении мест.
  - **Mobile:** В `EventDetailsScreen` кнопка «Присоединиться» меняется на disabled «Вы участвуете», появляется кнопка «Отменить участие». Добавлены `EventsService.leaveEvent()` и обработка ошибок/успехов.

- **Создание события (mobile):**
  - **Mobile:** Реализован экран `CreateEventScreen` и навигация с FAB на экране событий. `EventsService.createEvent()` подключён к `POST /api/events`; форма собирает основные поля (тип, дата/время, координаты, организатор, лимит).

- **Fix: текст состояния «Запись на событие»:**
  - **Mobile:** При нажатии «Присоединиться» показан нормальный текст «Записываем…/Joining…» вместо TODO-строки.

**Файлы:** `backend/src/api/events.routes.ts`, `backend/src/db/repositories/events.repository.ts`, `backend/src/modules/events/event.dto.ts`, `mobile/lib/shared/api/events_service.dart`, `mobile/lib/shared/models/event_details_model.dart`, `mobile/lib/features/events/event_details_screen.dart`, `mobile/lib/features/events/create_event_screen.dart`, `mobile/lib/features/events/events_screen.dart`, `mobile/lib/app.dart`, `mobile/l10n/*.arb`.

### 2026-02-04

- **Список участников события (имена вместо mock):**
  - **Backend:** Добавлен `GET /api/events/:id/participants` — возвращает список участников с `userId`, `name`, `avatarUrl`, `status`, `checkedInAt` (ISO). Данные пользователей подмешиваются через `UsersRepository.findByIds`, чтобы отображать реальные имена вместо `Participant N`.
  - **Mobile:** `ParticipantsList` переведён на загрузку данных через `EventsService.getEventParticipants(eventId)` и отображение имён; при отсутствии имён используется fallback `Participant N`. Поддержан empty/error state и кнопка retry.

**Файлы:** `backend/src/api/events.routes.ts`, `backend/src/modules/events/event.dto.ts`, `backend/src/db/repositories/users.repository.ts`, `mobile/lib/shared/api/events_service.dart`, `mobile/lib/features/events/widgets/participants_list.dart`, `mobile/lib/shared/models/event_participant_model.dart`, `mobile/lib/features/events/event_details_screen.dart`.

- **События для примера (seed-данные):** Добавлена миграция `005_seed_example_events.sql`: вставка 5 демо-событий для города `spb` (status `open`, типы `group_run`, `training`, `club_event`), даты старта в будущем (NOW() + 1–7 дней), координаты в границах Санкт-Петербурга, организатор `demo-club-1` (club). Используются фиксированные UUID и `ON CONFLICT (id) DO NOTHING` для идемпотентности. После применения миграции список событий и карта показывают примеры без изменений в коде приложения.

**Файлы:** `backend/src/db/migrations/005_seed_example_events.sql`.

### 2026-02-04 — Участие в событиях (join/check-in) — реализовано

- **Backend:**
  - `POST /api/events/:id/join` и `POST /api/events/:id/check-in` берут userId из auth (Firebase UID → users.id через `getUsersRepository().findByFirebaseUid(uid)`). При отсутствии пользователя в БД возвращается 400 с `validation_error` и полем `userId`. Ошибки бизнес-логики (event full, already registered, not registered, check-in too far и т.д.) возвращаются в формате ADR-0002: HTTP 400 с телом `{ code, message, details? }` (коды: event_full, already_registered, event_not_found, event_not_open, join_failed; check_in: not_registered, already_checked_in, check_in_too_far и др.). Успешные ответы по-прежнему в формате `{ success: true, eventId, participant }`.
  - Таблица `event_participants` и обновление `participantCount`/статуса `FULL` в репозитории без изменений.
- **Mobile:**
  - Реализованы `EventsService.joinEvent(eventId)` и `checkInEvent(eventId, longitude, latitude)`: POST на backend, при не-2xx парсится ответ и выбрасывается `ApiException(code, message)`.
  - На `EventDetailsScreen` кнопка «Присоединиться» вызывает `joinEvent`, при успехе — SnackBar «Вы записаны» и перезагрузка события; при ошибке — SnackBar с сообщением из ApiException. Состояние загрузки (_isJoining) отображается на кнопке. Добавлены i18n: eventJoinSuccess, eventJoinError(message), eventCheckInSuccess, eventCheckInError(message).

### 2026-01-29

- **Фильтры перезапрашивают данные (mobile):** В `EventsScreen` при смене фильтра по дате (`_buildDateFilterChip`) или переключателя «Только открытые» вызывается `_eventsFuture = _fetchEvents()` и выполняется `setState`, благодаря чему список событий перезагружается с учётом выбранных фильтров. Раньше фильтры только меняли локальное состояние без повторного запроса.
- **RefreshIndicator не ждал завершения загрузки (mobile):** В `events_screen.dart` метод `_refreshEvents()` вызывал `setState` с новым `_eventsFuture`, но не возвращал Future загрузки; `RefreshIndicator.onRefresh` получал callback без ожидания, и спиннер pull-to-refresh исчезал сразу. Исправлено: `_refreshEvents()` стал `async`, создаёт future через `_fetchEvents()`, обновляет state и `await future`; `onRefresh` передаётся `_refreshEvents`, чтобы виджет дожидался завершения загрузки.
- **Runtime-валидация создания события (backend):** Для эндпоинта `POST /api/events` добавлена техническая runtime-валидация тела запроса через Zod-схему `CreateEventSchema` (на основе `CreateEventDto`). Валидация проверяет только форму и типы полей запроса; поле `startDateTime` на этапе валидации приводится к `Date` через `z.coerce.date()`, остальные правила бизнес-логики (статусы, фильтры, инварианты FULL) не изменены. При некорректном теле запроса backend возвращает `400 Bad Request` с описанием ошибок.
 - **Mobile: Event details FutureBuilder:** `EventDetailsScreen` переведён на `StatefulWidget` с кэшированием `Future` загрузки деталей события в `initState`, чтобы избежать повторных HTTP-запросов при каждом `rebuild`; отображаемые поля и доменная модель не изменены.

### 2026-02-02

- **Поле cityId у событий и миграция:** сущность `Event` и DTO (`CreateEventDto`, `EventListItemDto`, `EventDetailsDto`) дополнены обязательным полем `cityId: string`. Добавлена миграция `003_events_city_id` — в таблицу `events` добавлен столбец `city_id VARCHAR(64) NOT NULL DEFAULT 'spb'` и индекс `idx_events_city_id`. Репозиторий `EventsRepository` мапит `city_id` ↔ `cityId`.
- **Фильтрация событий по городу и клубу:** метод `EventsRepository.findAll` принимает новый параметр `cityId?: string` и добавляет условие `city_id = :cityId` к SQL-запросу. Эндпоинт `GET /api/events` теперь требует query‑параметр `cityId` (при его отсутствии возвращается `400 validation_error`), пробрасывает `cityId` в репозиторий и возвращает DTO с полем `cityId`. Дополнительно при запросе карты `/api/map/data` события фильтруются по тому же `cityId`.
- **Валидация координат старта по границам города:** для `POST /api/events` после Zod‑валидации добавлена техническая проверка `isPointWithinCityBounds(dto.startLocation, dto.cityId)`; при выходе точки старта за границы города возвращается `400 validation_error` с полем `startLocation` и кодом `coordinates_out_of_city`.
- **Mobile Events: cityId в моделях и запросах:** `EventListItemModel` и `EventDetailsModel` расширены полем `cityId` (JSON‑поле `cityId` с дефолтом `''` при отсутствии), сервис `EventsService.getEvents` требует параметр `cityId` и добавляет его в query‑параметры. `EventsScreen` при загрузке событий читает текущий город из `CurrentCityService` и при отсутствии города выбрасывает понятную ошибку вместо «тихого» запроса без `cityId`.

### 2025-01-27

**Events MVP — Архитектурная основа (Skeleton)**

- **Модуль Events в backend:** Создан модуль `backend/src/modules/events/` с типами, статусами, entity и DTO:
  - `event.type.ts`: enum `EventType` (TRAINING, GROUP_RUN, CLUB_EVENT, OPEN_EVENT)
  - `event.status.ts`: enum `EventStatus` (DRAFT, OPEN, FULL, CANCELLED, COMPLETED)
  - `event.entity.ts`: интерфейс `Event` с полями для события (название, тип, статус, дата/время, локация, организатор, участники, территория)
  - `event.dto.ts`: DTO для создания (`CreateEventDto`), списка (`EventListItemDto`) и деталей (`EventDetailsDto`)
  - Инвариант статуса FULL: `status === FULL ⇔ participantLimit != null && participantCount >= participantLimit`

- **API роутер Events:** Создан `backend/src/api/events.routes.ts` с эндпоинтами:
  - `GET /api/events` — список событий (возвращает `EventListItemDto[]`)
  - `GET /api/events/:id` — событие по ID (возвращает `EventDetailsDto`)
  - `POST /api/events` — создание события
  - `POST /api/events/:id/join` — запись на событие
  - `POST /api/events/:id/check-in` — check-in на событие
  - Правило фильтрации: список возвращает только OPEN или FULL, DRAFT исключается (зафиксировано в комментариях)

- **Связь Events → Activities:** Добавлено поле `eventId?: string` в `Activity` entity для будущей связи активностей с событиями.

- **Модели Events в mobile:** Созданы модели для парсинга JSON:
  - `event_list_item_model.dart`: `EventListItemModel` для списка событий
  - `event_details_model.dart`: `EventDetailsModel` для детального экрана
  - Инвариант статуса FULL зафиксирован в комментариях

- **EventsService:** Создан `mobile/lib/shared/api/events_service.dart` с методами:
  - `getEvents()` — получение списка событий
  - `getEventById()` — получение события по ID
  - `createEvent()`, `joinEvent()`, `checkInEvent()` — заглушки с TODO
  - Улучшенная обработка ошибок: проверка Content-Type, определение HTML-ответа, понятные сообщения

- **UI компоненты Events:**
  - `events_screen.dart`: экран списка событий с фильтрами (UI-only), состояниями loading/error/empty
  - `event_card.dart`: карточка события для списка
  - `event_details_screen.dart`: детальный экран события с полной информацией
  - `participants_list.dart`: виджет списка участников (mock-данные)

- **Навигация:** Добавлен маршрут `/event/:id` в `app.dart` для перехода на детальный экран события.

**Архитектурные решения:**
- Разделение DTO: `EventListItemDto` для списка, `EventDetailsDto` для деталей
- Разделение моделей: `EventListItemModel` для списка, `EventDetailsModel` для деталей
- Loose coupling: детальный экран загружает данные по `eventId` через service, а не получает объект из списка
- Инварианты: статус FULL явно зафиксирован через математический инвариант в комментариях
- Capacity/participantsCount: поля `participantLimit` (capacity) и `participantCount` (participantsCount) документированы для определения статуса FULL

**Файлы:**

**Backend (созданы):**
- `backend/src/modules/events/event.type.ts`
- `backend/src/modules/events/event.status.ts`
- `backend/src/modules/events/event.entity.ts`
- `backend/src/modules/events/event.dto.ts`
- `backend/src/modules/events/index.ts`
- `backend/src/api/events.routes.ts`

**Backend (изменены):**
- `backend/src/api/index.ts` — добавлен роутер events
- `backend/src/modules/activities/activity.entity.ts` — добавлено поле `eventId`

**Mobile (созданы):**
- `mobile/lib/shared/models/event_list_item_model.dart`
- `mobile/lib/shared/models/event_details_model.dart`
- `mobile/lib/shared/api/events_service.dart`
- `mobile/lib/features/events/events_screen.dart`
- `mobile/lib/features/events/event_details_screen.dart`
- `mobile/lib/features/events/widgets/event_card.dart`
- `mobile/lib/features/events/widgets/participants_list.dart`

**Mobile (изменены):**
- `mobile/lib/app.dart` — добавлен маршрут `/event/:id`
