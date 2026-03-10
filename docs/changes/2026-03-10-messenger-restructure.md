# Реструктуризация мессенджера + схема `chat`

**Дата:** 2026-03-10
**Версия:** 1.0.8+296

## Что изменилось

### DB: схема `chat`
- Таблицы `messages` и `direct_messages` перенесены в PostgreSQL-схему `chat` (миграция `039_chat_schema.sql`).
- `trainer_clients` остаётся в `public`.
- Все индексы и FK перенесены автоматически через `ALTER TABLE SET SCHEMA`.
- Cross-schema FK `chat.direct_messages → public.users` работает нативно.

### Backend
- Все SQL-запросы в `messages.repository.ts` обновлены: `messages` → `chat.messages`, `direct_messages` → `chat.direct_messages`.
- Новый endpoint `GET /api/messages/direct/conversations`:
  - Возвращает все DM-диалоги текущего пользователя, сгруппированные по собеседнику.
  - Поля: `userId`, `userName`, `userAvatar`, `lastMessageText`, `lastMessageAt`, `isTrainerRelation`.
  - `isTrainerRelation: true` если собеседник является тренером пользователя (или пользователь — его клиент) через `trainer_clients`.
- ACL упрощён: DM разрешён между любыми пользователями (убрана проверка trainer-client).

### Mobile
- **`MessagesScreen`**: 3 вкладки (Личные / Клуб / Тренер) → 2 вкладки (Личные + Клубы). `CoachTab` удалён.
- **`PersonalChatsTab`**: реализован с нуля:
  - Список всех DM-диалогов из `/api/messages/direct/conversations`.
  - Тренеры закреплены вверху, красная метка «Тренер» справа от имени.
  - Pull-to-refresh.
  - Пустое состояние + кнопка «Новый диалог» → `/people`.
  - FAB «+» → `/people` для начала нового диалога.
- **`ClubMessagesTab`**: убрано авто-открытие первого клуба из `initState`. Всегда показывается список клубов. Кнопка «Назад» в чате возвращает к списку клубов.
- **`DirectChatModel`**: добавлено поле `isTrainerRelation: bool`.
- **`MessagesService`**: добавлен метод `getConversations()`.
- **L10n**: добавлены ключи `tabClubs`, `personalChatsNewChat` в оба ARB. Удалён `tabCoach`.

## Архитектурные решения
- Явные имена схем (`chat.messages`) вместо `search_path` — безопаснее и прозрачнее.
- Тренерский DM не выделяется в отдельную вкладку — достаточно закрепления + метки в общем списке.
- `conversation_model.dart` не создавался отдельно — `DirectChatModel` расширен флагом `isTrainerRelation`.
