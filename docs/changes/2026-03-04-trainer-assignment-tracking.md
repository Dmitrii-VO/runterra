# Тренерская система: отслеживание выполнения заданий и назначение группе

**Дата:** 2026-03-04
**Тип:** Feature (Backend + Mobile)

## Что изменилось

### База данных
- **Миграция 038** (`038_runs_assignment_id.sql`): добавлена колонка `assignment_id UUID` в таблицу `runs` с FK на `workout_assignments(id) ON DELETE SET NULL`. Опциональная — клиент может бегать без назначенного задания. Добавлен индекс `idx_runs_assignment_id`.

### Backend

#### Новые эндпоинты
- `GET /api/trainer/clients/:clientId/runs` — тренер получает список выполненных пробежек своего клиента. Проверяет наличие записи в `trainer_clients`. Возвращает: id, startedAt, endedAt, duration, distance, rpe, notes, assignmentId, workoutTitle. Пагинация через `limit`/`offset`.
- `POST /api/workouts/:id/assign-group` — batch-назначение тренировки всем участникам группы. Требует: `groupId` (UUID). Проверяет: workout.authorId == caller, group.trainerId == caller, группа непустая. Возвращает `{ ok: true, assigned: N }`.

#### Изменения в репозиториях
- `RunsRepository.findByClientForTrainer(trainerId, clientId, limit, offset)` — новый метод, JOIN с workout_assignments и workouts.
- `RunsRepository`: `RunRow` + `rowToRun` + `Run` entity расширены полем `assignmentId`.
- `WorkoutsRepository.findAssignedToUser(clientId)` — расширен: теперь возвращает `assignmentId` и `isCompleted` (EXISTS-подзапрос на runs).
- `WorkoutsRepository.assignToClients(workoutId, trainerId, clientIds, note)` — новый batch-метод.

### Mobile

#### Новые файлы
- `lib/shared/models/client_run_model.dart` — модель пробежки клиента для тренера.
- `lib/features/trainer/client_runs_screen.dart` — экран списка пробежек клиента (карточки с метриками).

#### Изменённые файлы
- `lib/shared/models/assigned_workout.dart` — добавлены поля `assignmentId` (String) и `isCompleted` (bool).
- `lib/shared/api/trainer_service.dart` — добавлен метод `getClientRuns(clientId)`.
- `lib/shared/api/workouts_service.dart` — добавлен метод `assignWorkoutToGroup(workoutId, groupId)`.
- `lib/features/trainer/workouts_list_screen.dart` — assigned-tab: иконка ✓/○ по `isCompleted`; `_showAssignDialog` заменён на two-tab bottom sheet (Клиент / Группа).
- `lib/features/messages/direct_chat_screen.dart` — кнопка 📊 в AppBar (только `isTrainer == true`) → роут результатов.
- `lib/app.dart` — новый роут `/trainer/clients/:clientId/runs`.
- `l10n/app_en.arb`, `l10n/app_ru.arb` — 7 новых ключей (`clientRunsTitle`, `clientRunsEmpty`, `clientRunsViewResults`, `clientRunsDistance`, `clientRunsRpe`, `clientRunsAssignment`, `workoutAssignSelectGroup`, `workoutAssignedToGroup`, `workoutAssignTabClient`, `workoutAssignTabGroup`, `trainerNoGroups`).

## Что НЕ изменилось (оставлено на потом)
- Синхронизация `trainer_clients` и `trainer_group_members` (P0-3 из аудита)
- Batch-добавление клиентов из клуба (P1-4)
- Unified trainer dashboard (P2-9)

## Тесты
- Backend: 156 тестов, все зелёные
- Mobile: `flutter analyze` — 0 issues
