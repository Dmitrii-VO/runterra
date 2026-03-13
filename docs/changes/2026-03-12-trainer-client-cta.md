# CTA «Стать учеником» — рукопожатие тренер→клиент

**Дата:** 2026-03-12
**Версии:** backend commit `144d5a2`, mobile `v1.0.13+309`

## Цель

Замкнуть цикл тренер→клиент: клиент может подать заявку на обучение к тренеру, тренер принимает или отклоняет. Минимальный viable loop — без чата и расписания.

## Backend

### Миграция `043_trainer_clients.sql`

Таблица `trainer_clients` уже существовала с migration 030 (id, trainer_id, client_id, created_at). Миграция 043 добавляет колонку `status`:

```sql
ALTER TABLE trainer_clients
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'rejected'));
ALTER TABLE trainer_clients
  ALTER COLUMN status SET DEFAULT 'pending';
```

Backfill: существующие строки (сформированные через клубный flow) получают `status='active'`.

### Новый репозиторий `trainer_clients.repository.ts`

Методы:
- `findByTrainerAndClient(trainerId, clientId)` — поиск по паре
- `findById(id)` — поиск по id
- `updateStatus(id, status)` — обновление статуса
- `updateStatusIfPending(id, status)` — compare-and-swap (WHERE status='pending')
- `upsertPending(trainerId, clientId)` — INSERT ON CONFLICT DO UPDATE SET status='pending'
- `delete(trainerId, clientId)` — DELETE WHERE status='pending'
- `findPendingByTrainer(trainerId)` — входящие заявки
- `findActiveClientsByTrainer(trainerId)` — активные клиенты + last_run_at (correlated subquery)
- `findActiveTrainersByClient(clientId)` — активные тренеры клиента
- `countActiveClientsByTrainer(trainerId)` — счётчик

### Новые endpoints

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/api/trainer/:userId/request` | Подать заявку (guard: acceptsPrivateClients, trainer≠client) |
| DELETE | `/api/trainer/:userId/request` | Отозвать pending-заявку |
| GET | `/api/trainer/:userId/request-status` | Статус отношений: none\|pending\|active\|rejected |
| GET | `/api/trainer/requests` | Входящие pending-заявки (для тренера) |
| PATCH | `/api/trainer/requests/:id` | Принять/отклонить (compare-and-swap) |
| GET | `/api/trainer/clients` | Активные клиенты тренера |
| GET | `/api/trainer/my-trainers` | Мои активные тренеры |

`GET /api/trainer` (`findPublicTrainers`) дополнен двумя correlated subqueries:
- `activeClientsCount` — COUNT активных клиентов
- `myStatus` — статус текущего пользователя относительно тренера

### Исправления legacy-кода

- `clubs.routes.ts:983` — INSERT в `trainer_clients` без status → добавлен `status='active'`
- `messages.repository.ts:addTrainerClient` — то же
- `messages.repository.ts:removeTrainerClient` — DELETE без guard → добавлен `AND status != 'active'`

### Тесты

16 новых Jest-тестов в `trainer-clients.routes.test.ts`. 31/31 в suite, 189 total. Полное покрытие всех новых endpoints.

## Mobile

### Новые модели (`trainer_profile.dart`)

- `TrainerClientRequest` — заявка: id, trainerId, clientId, clientName, clientAvatarUrl, status, createdAt
- `MyTrainerEntry` — запись тренера: id, trainerId, trainerName, trainerAvatarUrl, createdAt
- `PublicTrainerEntry` — добавлены поля `activeClientsCount: int`, `myStatus: String`

### TrainerService — новые методы

- `requestToJoin(trainerId)` — POST /request
- `cancelRequest(trainerId)` — DELETE /request
- `getRequestStatus(trainerId)` — GET /request-status
- `getTrainerRequests()` — GET /requests
- `respondToRequest(id, action)` — PATCH /requests/:id
- `getTrainerClients()` — GET /clients
- `getMyTrainers()` — GET /my-trainers

### TrainerProfileScreen — CTA

Кнопка показывается только при `acceptsPrivateClients=true` и `userId != me`:

| Статус | UI |
|--------|-----|
| none | ElevatedButton «Стать учеником» |
| pending | Chip «Заявка отправлена» + OutlinedButton «Отменить» |
| active | Chip «Вы ученик» (зелёный) |
| rejected | ElevatedButton «Подать снова» |

AppBar тренера: IconButton `supervisor_account` → `/trainer/requests`.

`_handleRequest` — try/catch с SnackBar при ошибке, mounted-guard перед setState.

### Новые экраны

**`TrainerRequestsScreen` (`/trainer/requests`):**
- Две секции: входящие pending-заявки (кнопки accept ✓ / reject ✗) + активные клиенты
- `_respond(id, action)` — catch + mounted guard + SnackBar

**`MyTrainersScreen` (`/my-trainers`):**
- Список активных тренеров, тап → `/trainer/:trainerId`

### TrainersListScreen

- Badge статуса (`active` = зелёный, `pending` = серый)
- Счётчик `activeClientsCount` в subtitle

### L10n

20 новых ключей в EN и RU:
`trainerBecomeStudent`, `trainerRequestSent`, `trainerCancelRequest`, `trainerYouAreStudent`, `trainerReapply`, `trainerRequestsScreen`, `trainerIncomingRequests`, `trainerActiveClients`, `trainerAccept`, `trainerReject`, `trainerClientsCount`, `trainerNoRequests`, `trainerNoClientsYet`, `myTrainersScreen`, `myTrainersEmpty`, `trainerRequestAccepted`, `trainerRequestRejectedMsg`, `trainerRequestsCancelledMsg`, `errorLoadTitle`, `retry`

## Архитектурные решения

- `trainer_clients` — отдельная таблица, не смешивается с `trainer_groups`
- Повторная заявка после rejected: `upsertPending` — UPDATE status → pending (история сохраняется)
- `trainer_id == client_id`: 400 `bad_request` на backend, кнопка скрыта на frontend
- FCM push: следующая итерация; текущая — только in-app badge
- `myStatus` вычисляется correlated subquery в `findPublicTrainers` (по authUser)
- compare-and-swap на PATCH /requests/:id через `updateStatusIfPending` — защита от race condition

## CI

CI упал из-за стороннего бага: секрет `GOOGLE_SERVICES_JSON` в GitHub Actions невалиден (base64 decode fail). Flutter analyze и тесты прошли чисто. Backend задеплоен с `--SkipCI`, mobile — через `deploy:mobile`.
