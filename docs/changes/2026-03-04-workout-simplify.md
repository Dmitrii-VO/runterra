# Упрощение формы тренировки (2026-03-04)

## Контекст

Старая форма создания тренировки использовала блочно-сегментный редактор (разминки, отрезки, зоны пульса, видео-инструкции) — слишком сложная модель для MVP. Заменена на упрощённую форму с полями, зависящими от типа тренировки.

## Изменения типов тренировок

**Было:** RECOVERY, TEMPO, INTERVAL, FARTLEK, LONG_RUN
**Стало:** FUNCTIONAL, TEMPO, RECOVERY, ACCELERATIONS

Миграция данных:
- INTERVAL → ACCELERATIONS
- FARTLEK → TEMPO
- LONG_RUN → RECOVERY

## Новая модель полей по типу

| Тип           | Поля                                                       |
|---------------|------------------------------------------------------------|
| TEMPO         | distance_m, heart_rate_target, pace_target                 |
| RECOVERY      | distance_m, heart_rate_target, pace_target                 |
| ACCELERATIONS | rep_distance_m, rep_count, pace_target                     |
| FUNCTIONAL    | exercise_name, exercise_instructions, rep_count            |

Поля `name` и `description` (опционально) — общие для всех типов.
Темп (`pace_target`) хранится как `INTEGER` (секунды/км), вводится в формате `M:SS`.

## Затронутые файлы

### Backend
- `backend/src/db/migrations/035_workout_simplify.sql` — обновлён CHECK-констрейнт типов, добавлены 7 новых колонок, выполнена миграция данных
- `backend/src/modules/workout/workout.type.ts` — 4 новых enum-значения
- `backend/src/modules/workout/workout.entity.ts` — 7 новых опциональных полей в интерфейсе
- `backend/src/modules/workout/workout.dto.ts` — обновлена Zod-схема (difficulty/targetMetric стали опциональными с дефолтами)
- `backend/src/db/repositories/workouts.repository.ts` — обновлены INSERT/UPDATE/SELECT под новые колонки
- `backend/src/api/workouts.routes.ts` — передача новых полей в POST; фикс DELETE (обработка FK violation)

### Mobile
- `mobile/lib/shared/models/workout.dart` — упрощена модель: убраны блоки/сегменты, добавлены 7 новых полей
- `mobile/lib/shared/api/workouts_service.dart` — обновлены параметры `createWorkout`/`updateWorkout`
- `mobile/lib/features/trainer/workout_form_screen.dart` — полная замена блочного редактора: `_buildTypeSpecificFields()` возвращает разные поля по типу
- `mobile/lib/features/trainer/workouts_list_screen.dart` — обновлён `_localizeType()`, убраны чипы difficulty/targetMetric
- `mobile/lib/features/events/event_details_screen.dart` — обновлён `_getWorkoutTypeText()` для новых типов
- `mobile/lib/features/run/run_tracking_screen.dart` — убрана секция блок/сегмент, показывается только имя тренировки
- `mobile/lib/shared/api/run_service.dart` — `_checkSegmentCompletion()` и `nextSegment()` заменены на no-op

### L10n
- Удалены: `typeInterval`, `typeFartlek`, `typeLongRun`
- Добавлены: `typeFunctional`, `typeAccelerations`, `workoutDistanceM`, `workoutHeartRate`, `workoutPaceTarget`, `workoutRepCount`, `workoutRepDistance`, `workoutExercise`, `workoutInstructions`

## Обратная совместимость

Старые поля (`difficulty`, `surface`, `blocks`, `target_metric`, `target_value`, `target_zone`) оставлены в БД и backend-модели, но не отображаются в новом UI. `difficulty` сохраняет дефолт `'BEGINNER'`.

## Фикс: удаление тренировки → Internal server error

**Проблема:** При нажатии «Удалить» на тренировке, связанной с прошедшими событиями, возвращался 500.

**Причина:** Метод `hasUpcomingEvents` проверяет только будущие события. FK-констрейнт `events_workout_id_fkey` блокирует удаление при наличии **любых** событий (включая прошедшие/завершённые). Ошибка PostgreSQL `23503` (foreign_key_violation) не обрабатывалась.

**Решение:** В catch-блоке DELETE-handler добавлена проверка `error.code === '23503'` → возвращает 409 `workout_in_use` вместо 500.

## Верификация

- `npm run build` — 0 ошибок
- 155 backend-тестов — зелёные
- `flutter analyze` — 0 errors
- Миграция `035_workout_simplify.sql` применена на prod-сервере
