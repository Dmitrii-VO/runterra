# Вкладка «Тренер» в Сообщениях — полная реализация

**Дата:** 2026-02-28

## Описание

Реализовано двустороннее общение тренер↔ученики через вкладку «Тренер» в разделе «Сообщения».

## Пользовательский сценарий

1. Лидер/тренер открывает список участников клуба → тапает на участника
2. Видит action-sheet: «Написать как тренер» / «Изменить роль» / «Личные сообщения (в разработке)»
3. «Написать как тренер» → создаёт связь `trainer_clients` → открывает 1:1 чат
4. Ученик заходит в «Сообщения → Тренер → Личные» и видит чат с тренером

## Правила

- Инициирует переписку **только тренер** (клиент не может написать первым)
- Связь тренер↔клиент явная через `trainer_clients`
- Вкладки неактивны если нет контента

## Backend изменения

### Миграция `030_trainer_direct.sql`
- `trainer_clients` — связь тренер↔клиент (UNIQUE, CASCADE)
- `direct_messages` — 1:1 сообщения (sender_id, receiver_id, text)

### Новые endpoints
- `POST /api/trainer/clients/:userId` — добавить клиента (проверка: trainer/leader в общем клубе)
- `DELETE /api/trainer/clients/:userId` — удалить клиента
- `GET /api/messages/trainer/clients` — список клиентов тренера + lastMessage
- `GET /api/messages/trainer/my-trainer` — тренер текущего пользователя (404 если нет)
- `GET /api/messages/direct/:otherUserId` — история 1:1 сообщений (limit/offset)
- `POST /api/messages/direct/:otherUserId` — отправить 1:1 сообщение

### Изменённые endpoints
- `GET /api/messages/clubs/:clubId` — добавлено поле `senderRole` в ответ (JOIN с club_members)

### WebSocket
- Поддержка канала `direct:{min_id}:{max_id}` для real-time 1:1 сообщений

## Mobile изменения

### Модели
- `MessageModel` — добавлено поле `senderRole` (nullable, backward-совместимо)
- `DirectChatModel` — новая модель для контакта (userId, userName, userAvatar, lastMessage)

### Сервисы
- `MessagesService` — 4 новых метода (getTrainerClients, getMyTrainer, getDirectMessages, sendDirectMessage)
- `TrainerService` — метод `addClient(userId)`

### Экраны
- `DirectChatScreen` — новый экран 1:1 чата (WS + polling fallback, пагинация, блокировка ввода для клиента)
- `ClubMessagesTab` — параметр `highlightTrainer` с бейджем «Тренер» у сообщений тренеров/лидеров
- `ClubDetailsScreen` — action sheet при тапе на участника (для leader/trainer)
- `CoachTab` — полная замена стаба: вложенные вкладки «Группы» и «Личные»

### Локализация
11 новых ключей в обоих ARB файлах (EN + RU).

## Файлы

| Файл | Действие |
|------|---------|
| `backend/src/db/migrations/030_trainer_direct.sql` | Новый |
| `backend/src/db/repositories/messages.repository.ts` | Расширен |
| `backend/src/modules/messages/message.dto.ts` | Расширен (senderRole, DirectChatViewDto) |
| `backend/src/api/messages.routes.ts` | +4 endpoint, senderRole в GET clubs |
| `backend/src/api/trainer.routes.ts` | +POST/DELETE /clients/:userId |
| `backend/src/ws/chatWs.ts` | +direct channel |
| `mobile/lib/shared/models/message_model.dart` | +senderRole |
| `mobile/lib/shared/models/direct_chat_model.dart` | Новый |
| `mobile/lib/shared/api/messages_service.dart` | +4 метода |
| `mobile/lib/shared/api/trainer_service.dart` | +addClient |
| `mobile/lib/features/messages/tabs/club_messages_tab.dart` | +highlightTrainer |
| `mobile/lib/features/messages/tabs/coach_tab.dart` | Полная реализация |
| `mobile/lib/features/messages/direct_chat_screen.dart` | Новый |
| `mobile/lib/features/club/club_details_screen.dart` | Action sheet |
| `mobile/l10n/app_en.arb` + `app_ru.arb` | +11 ключей |
