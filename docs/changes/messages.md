# Изменения: Messages

## История изменений

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
