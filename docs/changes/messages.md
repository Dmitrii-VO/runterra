# Изменения: Messages

## История изменений

### 2026-02-09 — Исправление названий клубов в списке чатов

- **Проблема:** В `GET /api/messages/clubs` использовался `findActiveByUser()`, возвращавший `ClubMembershipRow` без названия клуба. В ответ подставлялся placeholder `Club <UUID>`.
- **Решение:** Заменён на `findActiveClubsByUser()`, возвращающий `ActiveUserClubMembershipRow` с полями `clubName`, `clubDescription`. Поля `createdAt`/`updatedAt` заменены на `membership.joinedAt`, `id` использует `clubId`.

### 2026-02-08 — Сообщения: выбор клуба перед чатом (задачи 6–9 infra/README)

- **Задача 6–7. Вкладка «Клуб»: сначала список клубов, затем чат выбранного**
  - `ClubMessagesTab` переработан: первым шагом загружается список клубов пользователя через `GET /api/messages/clubs` (`MessagesService.getClubChats()`), отображается список карточек (название клуба, превью последнего сообщения при наличии). Авто-открытие чата убрано.
  - По тапу на карточку открывается чат выбранного клуба (история + composer). Добавлена кнопка «Назад» (иконка arrow_back) в шапке чата — возврат к списку клубов без выхода из вкладки.
  - Состояния: загрузка списка, ошибка загрузки списка (retry), пустой список (`noClubChats`), список клубов, загрузка чата, ошибка загрузки сообщений (retry), экран чата.
- **Задача 8. Навигация и deep-link**
  - Маршрут `/messages` поддерживает query-параметр `clubId`: `/messages?tab=club&clubId=...`. При открытии с `clubId` вкладка «Клуб» открывается сразу с чатом этого клуба (если пользователь в нём состоит).
  - `MessagesScreen` принимает `initialClubId` и передаёт в `ClubMessagesTab(initialClubId: initialClubId)`.
  - Кнопка «Чат клуба» на `ClubDetailsScreen` ведёт на `context.go('/messages?tab=club&clubId=${club.id}')` — открывается чат именно этого клуба.
- **Задача 9. i18n и документация**
  - Добавлены ключи l10n: `messagesBackToClubs` («К списку клубов» / «Back to clubs»), `messagesSelectClub` («Выберите клуб для переписки» / «Select a club to chat») в `app_ru.arb` и `app_en.arb`.
  - Обновлены `docs/progress.md` и `docs/changes/messages.md`.

**Файлы:** `mobile/lib/features/messages/tabs/club_messages_tab.dart`, `mobile/lib/features/messages/messages_screen.dart`, `mobile/lib/app.dart`, `mobile/lib/features/club/club_details_screen.dart`, `mobile/l10n/app_ru.arb`, `mobile/l10n/app_en.arb`, `docs/progress.md`, `docs/changes/messages.md`.

### 2026-02-06  Mobile:       (история + ввод)

- **Mobile (`ClubMessagesTab`)**:
  - Вкладка `Сообщения -> Клуб` переведена с режима списка клубов на режим одного клубного чата пользователя.
  - Источник clubId: сначала `CurrentClubService.currentClubId`; если он пустой, выбирается релевантный доступный клуб из `GET /api/messages/clubs` и сохраняется в `CurrentClubService`.
  - При наличии clubId загружается история через `GET /api/messages/clubs/:clubId` (`MessagesService.getClubChatMessages`), сообщения сортируются по времени (ASC) и отображаются в виде чата.
  - Добавлено поле ввода и отправка сообщений через `POST /api/messages/clubs/:clubId` (`MessagesService.sendClubMessage`).
  - Внутри тела вкладки больше не отображается заголовок/надпись с названием клуба.
  - Состояния: loading, error с retry, empty-state при отсутствии клуба (`noClubChats`), snackbar при ошибке отправки.
- **тог:** закрыт функциональный пробел по вкладке клуба: есть история чата и composer для отправки, без лишней подписи названия клуба в контентной области.

### 2026-02-06 — Mobile: стабилизация ClubMessagesTab после первичного фикса

- **Mobile (`ClubMessagesTab`)**:
  - справлена идентификация собственных сообщений: для `isMine` используется `users.id` из профиля (`/api/users/me/profile`), с fallback на Firebase uid.
  - Добавлена проверка актуальности выбранного `clubId` по списку доступных клубов (`GET /api/messages/clubs`): если сохранённый `currentClubId` больше недоступен, он очищается и переопределяется.
  - Выбор fallback-клуба больше не зависит от «первого в списке»: приоритет — `primaryClubId`, затем наиболее активный клуб (по `lastMessageAt`/`updatedAt`).
  - Добавлена подгрузка старой истории (pagination) при скролле вверх через `limit/offset`.
  - Добавлено периодическое обновление входящих сообщений (polling каждые 10 секунд) с merge по `message.id`.
  - Guarded against stale async responses: polling/history batches are ignored when the active `clubId` changes before the response arrives.
  - справлен текст ошибки загрузки: для истории сообщений используется `messagesLoadError(...)`, а не `clubChatsLoadError(...)`.
  - Улучшен автоскролл: при отправке/новых сообщениях используется плавный `animateTo` и автопрокрутка только когда пользователь находится около нижней границы списка.
- **тог:** закрыты основные риски регрессий в UX и данных для вкладки `Сообщения -> Клуб` (stale club, неверная маркировка «моих» сообщений, отсутствие обновления/доступа к старой истории, дерганый скролл).

### 2026-02-06 — Mobile MessagesService для клубных чатов (HTTP API) и stub личных чатов

- **Mobile вЂ” MessagesService (club chats):**
  - `getClubChats()` теперь полностью реализован против backend API: выполняет `GET /api/messages/clubs`, при 2xx парсит список `ClubChatModel`, при не‑2xx разбирает ADR‑ответ `{ code, message }` и выбрасывает `ApiException` (реиспользуется из `users_service.dart`) с соответствующим кодом/сообщением.
  - `getClubChatMessages(clubId, { limit, offset })` реализован через `GET /api/messages/clubs/:clubId?limit=&offset=`, парсит список `MessageModel`; при ошибках также выбрасывает `ApiException`.
  - `sendClubMessage(clubId, text)` реализован через `POST /api/messages/clubs/:clubId` с телом `{ text }`, успешный ответ 201 парсится в `MessageModel`, ошибки мапятся в `ApiException` c `code`/`message` из ADR‑ответа.
- **Mobile вЂ” MessagesService (personal chats):**
  - Личные чаты формально не входят в MVP и backend‑эндпоинтов для них нет, поэтому:
    - `getPrivateChats()` и `getChatMessages(chatId)` возвращают пустые списки (stub), не выполняя сетевых запросов.
    - `sendChatMessage(chatId, text)` явно маркирован как не реализованный и бросает `UnimplementedError('Personal chats are not implemented in MVP')`, чтобы не создавать ложных ожиданий.
- **тог:** На мобильном клиенте есть полноценный HTTP‑клиент для клубных чатов (список чатов, загрузка сообщений, отправка сообщений) поверх существующих backend‑эндпоинтов, а личные чаты зафиксированы как осознанная заглушка до появления соответствующего API на backend.

### 2026-02-06 — справлен 500 на /api/messages при отсутствии auth (401/403 вместо 500)

- **Backend:** В `messages.routes.ts` вспомогательная функция `getAuthUid` заменена на `getAuthUidOrRespondUnauthorized(req, res)`, которая:
  - При отсутствии `req.authUser.uid` возвращает 401 с ADR‑ответом `{ code: "unauthorized", message: "Authorization required", details: { reason: "missing_header" } }` и прерывает обработку запроса.
  - спользуется во всех маршрутах `/api/messages/clubs*` (список клубных чатов, сообщения клуба, отправка сообщения), чтобы отсутствие auth не приводило к выбросу исключения и последующему 500.
- **тог:** При обращении к эндпоинтам `/api/messages/clubs` / `/api/messages/clubs/:clubId` / `POST /api/messages/clubs/:clubId` без заголовка Authorization сервер теперь корректно возвращает 401/403 (в зависимости от конкретной проверки), а не 500 internal_error.

### 2026-02-06 — Проверка членства для клубных чатов (HTTP + WS) + clubId как строковый идентификатор

- **Backend (DB):** Добавлена миграция `009_messages_channel_id_varchar.sql`, которая меняет тип столбца `messages.channel_id` с `UUID` на `VARCHAR(128)` с `USING channel_id::text`. Это выравнивает схему с тем, что идентификатор клуба (`club_members.club_id`, `clubId` в DTO) трактуется как строка, а не как строгий UUID, и позволяет использовать одинаковый формат идентификаторов для городов/клубов в каналах сообщений.
- **Backend (HTTP — клубные чаты):**
  - Эндпоинт `GET /api/messages/clubs/:clubId` теперь, помимо проверки auth (`Authorization: Bearer <token>`), находит пользователя по `firebaseUid` через `UsersRepository.findByFirebaseUid` и проверяет активное членство в клубе через `ClubMembersRepository.findByClubAndUser(clubId, user.id)`. При отсутствии пользователя возвращается `401 unauthorized` (`code: "unauthorized", message: "User not found"`), при отсутствии активного членства — `403 forbidden` с `code: "forbidden"`, `message: "User is not a member of this club"` и `details: { clubId }`.
  - Эндпоинт `POST /api/messages/clubs/:clubId` использует тот же паттерн: перед созданием сообщения и broadcast-а проверяется, что пользователь существует и является активным участником клуба; иначе возвращается 401/403 по тем же правилам. Только после успешной проверки вызывается `MessagesRepository.create({ channelType: 'club', channelId: clubId, ... })` и выполняется `broadcast("club:{clubId}", dto)`.
- **Backend (WS — подписка на клубные каналы):**
  - В `chatWs.ts` регулярное выражение `VALID_CHANNEL_RE` ослаблено с `^club:[0-9a-f-]{36}$` до `^club:[A-Za-z0-9_-]{1,128}$`, чтобы разрешить каналы вида `club:{clubId}` с любыми строковыми ID (например, `club-1`, `spb-runner-club`), а не только UUID v4.
  - Функция `canSubscribe(uid, channelKey)` теперь, помимо проверки формата канала, находит пользователя по `firebaseUid` (`UsersRepository.findByFirebaseUid`) и проверяет активное членство в клубе (`ClubMembersRepository.findByClubAndUser(clubId, user.id)`, статус `active`). Если пользователь не найден, не состоит в клубе или произошла ошибка БД, подписка запрещается и клиенту отправляется `{ type: 'error', message: 'Subscribe denied' }`.
- **тог:** Для клубных чатов установлен единый строковый формат clubId во всех слоях (БД, REST, WS, mobile) и реализована строгая проверка членства: доступ к истории и отправке сообщений по HTTP, а также подписка на real-time канал `club:{clubId}` по WebSocket разрешены только активным участникам соответствующего клуба.


### 2026-02-04

- **Список клубных чатов (membership-based):**
  - **Backend:** Добавлен `GET /api/messages/clubs` — возвращает список чатов клубов пользователя на основе `club_members` (active). Формат ответа соответствует `ClubChatViewDto` (id, clubId, clubName, createdAt/updatedAt и т.д.).
  - **Mobile:** `MessagesService.getClubChats()` теперь вызывает `GET /api/messages/clubs` и парсит список `ClubChatModel` вместо пустой заглушки. `ClubMessagesTab` начинает показывать клубы после вступления.

**Файлы:** `backend/src/api/messages.routes.ts`, `backend/src/modules/messages/message.dto.ts`, `backend/src/db/repositories/club_members.repository.ts`, `mobile/lib/shared/api/messages_service.dart`.

- **Удаление чата города:**
  - **Backend**
    - `messages.routes.ts`: удалены эндпоинты GET и POST `/api/messages/global`.
    - `chatWs.ts`: удалена поддержка каналов `city:{cityId}`; VALID_CHANNEL_RE и canSubscribe() поддерживают только `club:{clubId}`; удалён импорт getUsersRepository.
  - **Mobile**
    - Удалён `global_chat_tab.dart`.
    - Удалён `notifications_tab.dart` (orphaned — не используется после замены вкладок).
    - Удалён `chat_realtime_service.dart` (orphaned — использовал city-каналы, не нужен без GlobalChatTab; будет переписан для club-каналов при реализации real-time в ClubMessagesTab).
    - `messages_screen.dart`: вкладки заменены с «Город | Клубы | Уведомления» на «Личные | Клуб | Тренер»; добавлены PersonalChatsTab и CoachTab (заглушки), ClubMessagesTab оставлен.
    - `messages_service.dart`: удалены getGlobalChatMessages() и sendGlobalMessage().
    - l10n: добавлены tabPersonal, tabClub, tabCoach, cityLabel, personalChatsEmpty, coachMessagesEmpty; удалены tabCity, tabClubs, tabNotifications, globalChatEmpty. Примечание: ключи noNotifications и notificationsLoadError оставлены — используются в ProfileNotificationsSection.
    - `profile_screen.dart`: блок «Город» использует cityLabel вместо tabCity.
  - **Файлы:** backend/src/api/messages.routes.ts, backend/src/ws/chatWs.ts, mobile/lib/features/messages/*.dart, mobile/lib/shared/api/messages_service.dart, mobile/lib/shared/api/chat_realtime_service.dart (удалён), mobile/l10n/*.arb, mobile/lib/features/profile/profile_screen.dart.

### 2026-02-02

- **GlobalChatTab: убран fallback 'spb', лишний API-запрос при отсутствии города:** В `_fetchData()` cityId имел fallback `'spb'`, из-за которого messages API вызывался даже когда у пользователя не установлен город (noCitySet=true). Убран fallback; теперь при `cityId == null` API не вызывается, сразу возвращается `noCitySet=true` и показывается подсказка «Укажите город в профиле». Упрощена логика: `noCitySet` определяется единообразно через проверку cityId.

**Файлы:** `mobile/lib/features/messages/tabs/global_chat_tab.dart`.

- **GET /api/messages/global — обязательный cityId:** Эндпоинт изменён: город берётся из обязательного query-параметра `cityId`. При отсутствии или пустом `cityId` возвращается 400 с `code: "validation_error"`, `message: "cityId is required"`. Mobile: `getGlobalChatMessages` принимает обязательный параметр `cityId` и передаёт его в query; в GlobalChatTab передаётся `profile?.user.cityId ?? CurrentCityService.currentCityId ?? 'spb'` (дефолт «spb» при первом запуске без выбора города); флаг `noCitySet` выставляется, когда в профиле и CurrentCityService города нет, для отображения подсказки «Укажите город в профиле».

**Файлы:** `backend/src/api/messages.routes.ts`, `mobile/lib/shared/api/messages_service.dart`, `mobile/lib/features/messages/tabs/global_chat_tab.dart`.

- **Чат — real-time сообщения:**
  - **Backend**
    - Миграция `002_messages.sql`: таблица `messages` (id, channel_type 'city'|'club', channel_id, user_id FK, text VARCHAR(500), created_at, updated_at), индекс по (channel_type, channel_id, created_at DESC).
    - Модуль `modules/messages`: entity Message, MessageViewDto и CreateMessageDto, CreateMessageSchema (Zod, text 1–500 символов).
    - Репозиторий MessagesRepository: create(), findByChannel() с JOIN users для userName.
    - REST API: GET /api/messages/global (query limit, offset; cityId из пользователя по authUser.uid), POST /api/messages/global (body { text }, валидация; при отсутствии cityId у пользователя — 400 user_city_required); GET/POST /api/messages/clubs/:clubId (доступ — заглушка «разрешено»). Ответы — MessageViewDto (id, text, userId, userName, createdAt, updatedAt в ISO).
    - WebSocket: пакет `ws`, путь /ws на том же HTTP-сервере (server.ts — http.createServer(app), initChatWs(server)). При подключении: токен из query ?token=..., verifyToken(); подписки по сообщениям { type: 'subscribe', channel: 'city:{cityId}' } или 'club:{clubId}'; broadcast(channelKey, MessageViewDto) после сохранения сообщения в POST-обработчиках; клиентам отправляется { type: 'message', payload: MessageViewDto }.
  - **Mobile**
    - Зависимость web_socket_channel: ^2.4.0.
    - MessagesService: getGlobalChatMessages(limit, offset) — GET /api/messages/global, разбор списка MessageModel; обработка 400 user_city_required, 401, 5xx. sendGlobalMessage(text) — POST /api/messages/global, разбор 201 → MessageModel; обработка 400 validation_error/user_city_required, 401, 5xx.
    - ChatRealtimeService: подключение к ws(s) URL (из ApiConfig.getBaseUrl()), токен в query; после connect отправка { type: 'subscribe', channel: 'city:{cityId}' }; стрим новых сообщений (type: 'message', payload → MessageModel); dispose() для закрытия.
    - GlobalChatTab: загрузка данных через Future (getGlobalChatMessages + getProfile для cityId); при успехе — список в state, при наличии cityId — подписка на real-time (ChatRealtimeService), новые сообщения добавляются в список (дедуп по id); поле ввода и кнопка «Отправить», sendGlobalMessage, при успехе — добавление сообщения в список; обработка ошибок отправки.

- **Чат — исправления после code review:**
  - **Backend**
    - WebSocket (chatWs.ts): uid из verifyToken сохраняется на соединении (структура WsClient { channels, uid }). Добавлена валидация канала при subscribe: regex `^(city|club):[0-9a-f-]{36}$`, для city-каналов — проверка совпадения cityId пользователя из БД. При отказе клиенту отправляется `{ type: 'error', message: 'Subscribe denied' }`. Добавлена функция `closeChatWs()` — закрытие всех WS-соединений с кодом 1001 и очистка; вызывается в gracefulShutdown() (server.ts) перед закрытием DB pool.
    - REST API (messages.routes.ts): GET /clubs/:clubId — добавлен вызов getAuthUid(req) для проверки аутентификации. Добавлена функция parsePagination() — парсинг limit/offset из query с защитой от NaN, отрицательных значений, ограничение MAX_LIMIT=100, DEFAULT_LIMIT=50; применена во всех GET-эндпоинтах.
  - **Mobile**
    - GlobalChatTab (global_chat_tab.dart): начальные сообщения из REST (DESC порядок) переворачиваются через `.reversed` при сохранении в state, чтобы список хранился в ASC порядке (oldest→newest); WS-сообщения корректно добавляются в конец; `reverse: true` ListView c `_messages[length-1-index]` отображает новые внизу.
    - ChatRealtimeService (chat_realtime_service.dart): `_toWsUrl()` больше не приводит весь URL к lowercase — `toLowerCase()` применяется только для определения схемы (http/https), оригинальный URL сохраняется.

- **Чат — fix Unhandled Exception user_city_required (logcat):**
  - **Mobile**
    - GlobalChatTab (global_chat_tab.dart): `_fetchData()` теперь загружает профиль первым для получения cityId. Если город не установлен (`cityId == null`) — messages API не вызывается, возвращается пустой список с флагом `noCitySet=true`. В UI при `_noCitySet` показывается дружелюбный экран с иконкой города, текстом «Укажите город в профиле, чтобы участвовать в чате» и кнопкой «Повторить», вместо красного экрана ошибки. Это устраняет `Unhandled Exception: User must have a city set to use global chat` в logcat, которое возникало при открытии чата без установленного города.

### 2026-01-29
- **Mobile: Messages tabs FutureBuilder:** вкладки `GlobalChatTab`, `ClubMessagesTab` и `NotificationsTab` переведены на `StatefulWidget` с кэшированием `Future` загрузки данных в `initState`, чтобы избежать повторных HTTP-запросов при каждом `rebuild`; контракт заглушек и отображаемые данные не изменены.

### 2025-01-27
- **Табы MVP по 123.md:** заменены «Общий чат | Личные переписки | Сообщения Клуба» на «Город | Клубы | Уведомления».
- Личные переписки убраны из MVP (удалён `PrivateChatsTab`).
- Добавлена вкладка «Уведомления» (системные сообщения, read-only, заглушка).
- Empty state городского чата: «Пока тихо. Напиши первое сообщение и задай ритм городу 🏃‍♂️».
- `MessagesService` не изменён; заглушки для личных чатов сохранены.


