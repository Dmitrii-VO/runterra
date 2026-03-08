# ACL Security Fixes — 2026-03-09

Закрыты критичные и средние ACL-уязвимости, выявленные adversarial review (3 Codex-рецензента) коммитов `0c041c4–ee3ce48`.

## Исправления

### F1 — `isTrainerInAnyClub` в ветке тренера-организатора (КРИТИЧНО)

**Файл:** `backend/src/api/events.routes.ts`

**Проблема:** При проверке доступа к приватному событию (`canAccessPrivateEvent`) и при вычислении флага `isOrganizer` в `GET /api/events/:id` тренер-организатор идентифицировался только по `event.organizerId === resolvedUser.id` — без проверки активности в клубе. Приостановленный тренер сохранял доступ к своим приватным событиям.

**Исправление:**
- `canAccessPrivateEvent`: ветка `organizerType === 'trainer'` теперь дополнительно проверяет `isTrainerInAnyClub(resolvedUser.id)`.
- `GET /api/events/:id` inline-проверка `isOrganizer`: аналогично.

### F2 — Отзыв `trainer_clients` при приостановке тренера (КРИТИЧНО)

**Статус: уже было исправлено.**

`getActiveTrainerClientExistsSql()` в `messages.repository.ts` выполняет JOIN к `club_members` и требует `status = 'active'` + `role IN ('trainer', 'leader')`. Все запросы `isTrainerClient`, `hasTrainerClientRelationship`, `getTrainerClients`, `getMyTrainer` автоматически исключают приостановленных тренеров — без физического удаления записей из `trainer_clients`.

### F3 — `DELETE /api/trainer/clients/:userId` без ACL (СРЕДНЕ)

**Файл:** `backend/src/api/trainer.routes.ts`

**Проблема:** Эндпоинт удалял запись из `trainer_clients` для любого аутентифицированного пользователя, не проверяя, является ли он активным тренером в клубе.

**Исправление:** Добавлен вызов `ensureApprovedTrainer(trainerId, res)` перед операцией удаления. Только активный тренер/лидер в клубе может управлять своим списком клиентов.

### F7 — Кнопка «Write as trainer» в ClubDetailsScreen (СРЕДНЕ)

**Файл:** `mobile/lib/features/club/club_details_screen.dart`

**Проблема:** Кнопка «Написать как тренер» в списке участников клуба вызывала `POST /api/trainer/clients/:userId` (прямое создание связи), который был отключён (возвращает 403). UX был сломан, а прямая привязка клиентов без club leader flow является нарушением политики.

**Исправление:**
- Удалена кнопка `ListTile` «Write as trainer» из bottom sheet участника.
- Удалён метод `_writeAsTrainer(ClubMemberModel)`.
- Удалены неиспользуемые импорты `direct_chat_model.dart`, `direct_chat_screen.dart`.
- Удалена неиспользуемая переменная `isTrainerOrLeader`.

Тренер видит своих клиентов в Messages → Coach Tab — только тех, кого назначил club leader через официальный flow.

## Отложено (следующий PR)

- **F4:** Идемпотентность `POST /api/users` — `INSERT ... ON CONFLICT (firebase_uid) DO NOTHING RETURNING *`
- **F5:** CI mobile job для fork PRs — debug на PR, release только на push в main
- **F6:** `trainerGroupsRepo.findById` не должен фильтровать по статусу тренера — разделить data retrieval от ACL

## Верификация

- `npm test` (backend): 40/40 тестов зелёные
- `flutter analyze lib/features/club/club_details_screen.dart`: 0 issues
