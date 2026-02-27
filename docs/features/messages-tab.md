# Вкладка «Сообщения»

Функционал вкладки «Сообщения» мобильного приложения Runterra.

## Назначение

Коммуникация пользователя: клубные чаты и тренер↔клиент 1:1 (реализованы), личные чаты (заглушка). Точка входа для обсуждений в рамках беговых клубов и общения с тренером.

## Подвкладки

Экран содержит три таба: **Личные** | **Клуб** | **Тренер**.

---

## Подвкладка «Личные» (Personal)

**Статус:** заглушка (post-MVP)

**Содержимое:** текст «Личные чаты — в разработке» (l10n: `personalChatsEmpty`)

**Примечание:** личные переписки между пользователями не входят в MVP (product_spec §8).

---

## Подвкладка «Клуб» (Club)

**Статус:** полностью реализована

### Поток навигации

1. **Список клубов** — клубы, в которых пользователь состоит (GET /api/messages/clubs)
2. **Выбор канала** — при наличии подчатов у клуба (GET /api/clubs/:id/channels)
3. **Чат канала** — история сообщений + поле ввода

Кнопка «Назад» в чате возвращает к списку каналов или к списку клубов.

### Чат клуба

**Загрузка истории:** GET /api/messages/clubs/:clubId (limit, offset)

**Отправка:** POST /api/messages/clubs/:clubId, тело `{ text }`

**Real-time:**
- WebSocket (`ChatWebSocketService`) — основной источник новых сообщений
- Канал подписки: `club:clubId` или `club:clubId:channelId`
- При сбое WebSocket — fallback на polling (каждые 10 сек)
- Автопереподключение при восстановлении соединения

**Поведение ввода:**
- После отправки клавиатура остаётся открытой (FocusNode.requestFocus)
- Автоскролл к последнему сообщению только при near-bottom
- Подгрузка старой истории при скролле вверх (pagination)

### Подчаты (каналы клуба)

- Таблица `club_channels` (id, club_id, type, name, is_default)
- При `channels.length == 0` — открывается общий чат без выбора канала
- При наличии каналов — сначала выбор канала, затем чат выбранного канала

### Deep-link

Маршрут `/messages?tab=club&clubId=...` открывает вкладку «Клуб» сразу с чатом указанного клуба (если пользователь в нём состоит).

**Источник:** кнопка «Чат клуба» на `ClubDetailsScreen` → `context.go('/messages?tab=club&clubId=${club.id}')`

### Состояния

- Загрузка списка клубов
- Пустой список (`noClubChats`)
- Ошибка загрузки (retry)
- Загрузка чата / сообщений
- Ошибка отправки (SnackBar)

---

## Подвкладка «Тренер» (Coach)

**Статус:** полностью реализована

Внутри вкладки «Тренер» — два подтаба: **Группы** | **Личные**.

### Группы

- Отображается клубный чат (`ClubMessagesTab`) с параметром `highlightTrainer` — у сообщений тренеров/лидеров показывается бейдж «Тренер».

### Личные

- **Для тренера/лидера:** список клиентов (GET /api/messages/trainer/clients) с последним сообщением; тап → 1:1 чат с клиентом.
- **Для атлета:** тренер текущего пользователя (GET /api/messages/trainer/my-trainer); при наличии — чат с тренером.
- Инициатор переписки — только тренер (клиент не может написать первым); связь через таблицу `trainer_clients`.

### 1:1 чат (DirectChatScreen)

- Маршрут: `/messages/direct/:userId`
- История: GET /api/messages/direct/:otherUserId (limit, offset)
- Отправка: POST /api/messages/direct/:otherUserId
- Real-time: WebSocket канал `direct:{minUserId}:{maxUserId}`
- У клиента поле ввода заблокировано до первого сообщения тренера

### Инициация из клуба

- На `ClubDetailsScreen` при тапе на участника (для leader/trainer): action sheet «Написать как тренер» / «Изменить роль» / «Личные сообщения (в разработке)». «Написать как тренер» создаёт связь (POST /api/trainer/clients/:userId) и открывает 1:1 чат.

---

## API

| Метод | Назначение |
|-------|------------|
| GET /api/messages/clubs | Список клубов пользователя с чатами |
| GET /api/messages/clubs/:clubId | История сообщений клуба (limit, offset); в ответе поле `senderRole` |
| POST /api/messages/clubs/:clubId | Отправка сообщения |
| GET /api/clubs/:id/channels | Список каналов (подчатов) клуба |
| POST /api/trainer/clients/:userId | Добавить клиента (тренер/лидер) |
| DELETE /api/trainer/clients/:userId | Удалить клиента |
| GET /api/messages/trainer/clients | Список клиентов тренера с lastMessage |
| GET /api/messages/trainer/my-trainer | Тренер текущего пользователя (404 если нет) |
| GET /api/messages/direct/:otherUserId | История 1:1 сообщений (limit, offset) |
| POST /api/messages/direct/:otherUserId | Отправить 1:1 сообщение |

## WebSocket

- Путь: `/ws`, авторизация по query `?token=...`
- Подписка: `{ type: 'subscribe', channel: 'club:clubId' }` или `club:clubId:channelId`; для 1:1 — `direct:{minUserId}:{maxUserId}`
- Входящие: `{ type: 'message', payload: MessageViewDto }`
- Проверка: клуб — только активные участники; direct — участники пары тренер↔клиент

## Навигация

- `/messages` — вкладка
- Query: `tab` (personal|club|coach), `clubId` (для deep-link)

## Связанные файлы

- `mobile/lib/features/messages/messages_screen.dart`
- `mobile/lib/features/messages/tabs/club_messages_tab.dart`
- `mobile/lib/features/messages/tabs/personal_chats_tab.dart`
- `mobile/lib/features/messages/tabs/coach_tab.dart`
- `mobile/lib/features/messages/direct_chat_screen.dart`
- `mobile/lib/shared/services/chat_websocket_service.dart`
- `mobile/lib/shared/api/messages_service.dart`
- `mobile/lib/shared/api/trainer_service.dart`
- `backend/src/api/messages.routes.ts`
- `backend/src/api/trainer.routes.ts`
- `backend/src/ws/chatWs.ts`
