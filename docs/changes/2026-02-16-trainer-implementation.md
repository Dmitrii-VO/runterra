# Trainer 2.0 — полная реализация

**Дата:** 2026-02-16
**Спецификация:** docs/trainer-implementation-spec.md

## Обзор

Реализован полный функционал тренера: профиль тренера, библиотека тренировок (личные и клубные), интеграция с событиями (назначение тренировки и тренера). Роль `trainer` в клубах из номинальной превращена в функциональную.

## Backend

### Миграции (018–020)

| Миграция | Описание |
|----------|----------|
| `018_trainer_profiles.sql` | Таблица `trainer_profiles`: user_id (PK → users), bio, specialization TEXT[], experience_years, certificates JSONB |
| `019_workouts.sql` | Таблица `workouts`: id UUID, author_id, club_id (nullable), name, description, type, difficulty, target_metric + индексы |
| `020_events_trainer_fields.sql` | ALTER TABLE events + workout_id (FK → workouts), trainer_id (FK → users) |

### Модули

- **`src/modules/trainer/`** — `TrainerProfile` entity, `Certificate` interface, Zod-схемы `CreateTrainerProfileSchema` и `UpdateTrainerProfileSchema`. Специализации: MARATHON, SPRINT, TRAIL, RECOVERY, GENERAL.
- **`src/modules/workout/`** — `Workout` entity, enums `WorkoutType` (RECOVERY, TEMPO, INTERVAL, FARTLEK, LONG_RUN), `WorkoutDifficulty` (BEGINNER, INTERMEDIATE, ADVANCED, PRO), `WorkoutTargetMetric` (DISTANCE, TIME, PACE), Zod-схемы.
- **`src/modules/events/`** — расширены `event.entity.ts` (+ workoutId, trainerId) и `event.dto.ts` (+ поля в DTO, + `UpdateEventTrainerFieldsSchema`).

### Репозитории

- **`trainer_profiles.repository.ts`** — findByUserId, create, update (динамический SQL builder).
- **`workouts.repository.ts`** — CRUD, findByAuthor (clubId IS NULL), findByClub, hasUpcomingEvents.
- **`events.repository.ts`** — новый метод `updateTrainerFields(eventId, data)`, обновлён `rowToEvent` и `EventRow`.

### API роуты

**`/api/trainer/profile`:**
- `GET /` — свой профиль (из req.authUser)
- `GET /:userId` — публичный просмотр
- `POST /` — создать (требует trainer/leader в любом клубе)
- `PATCH /` — обновить (требует trainer/leader в любом клубе)

**`/api/workouts`:**
- `GET /` — без clubId → личные автора; с clubId → клубные (проверка членства)
- `GET /:id` — автор или член клуба
- `POST /` — требует trainer/leader; если clubId → проверка роли в клубе
- `PATCH /:id` — только автор
- `DELETE /:id` — только автор + 409 если привязана к будущим событиям

**`PATCH /api/events/:id`:**
- Назначение workoutId и/или trainerId
- trainerId назначает **только leader** (спека 4.2)
- Проверка существования workout и принадлежности клубу
- Проверка что target trainer — trainer/leader в клубе

### Хелпер `trainer-role.ts`

- `isTrainerInAnyClub(userId)` — тренер/лидер хотя бы в одном клубе
- `isTrainerOrLeaderInClub(userId, clubId)` — тренер/лидер в конкретном клубе
- `isLeaderInClub(userId, clubId)` — лидер в конкретном клубе

### Тесты

33 новых тестов:
- `trainer.routes.test.ts` — 11 тестов (CRUD профиля, проверка ролей, 403/404)
- `workouts.routes.test.ts` — 16 тестов (CRUD, visibility, delete 409, клубное членство)
- `events-patch.routes.test.ts` — 6 тестов (назначение тренировки/тренера, права)

Итого: 131 тест (98 existing + 33 new).

## Mobile

### Модели

- **`trainer_profile.dart`** — `TrainerProfile` и `Certificate` с fromJson/toJson
- **`workout.dart`** — `Workout` с fromJson/toJson
- **`event_details_model.dart`** — расширена полями workoutId, trainerId, workoutName, trainerName

### Сервисы

- **`trainer_service.dart`** — getMyProfile, getProfile(userId), createProfile, updateProfile
- **`workouts_service.dart`** — getWorkouts({clubId}), getWorkout(id), createWorkout, updateWorkout, deleteWorkout

Оба сервиса зарегистрированы в `ServiceLocator`.

### UI экраны

| Экран | Файл | Описание |
|-------|------|----------|
| Профиль тренера | `trainer_profile_screen.dart` | StatefulWidget, lazy-load, bio, chips специализаций, опыт, сертификаты |
| Редактирование профиля | `trainer_edit_profile_screen.dart` | Форма: bio, FilterChips для специализаций, experienceYears, динамический список сертификатов |
| Список тренировок | `workouts_list_screen.dart` | TabBarView (Мои/Клубные), swipe-to-delete с подтверждением, FAB создания |
| Форма тренировки | `workout_form_screen.dart` | Create/edit, dropdowns: type, difficulty, targetMetric |

### Навигация (GoRouter)

```
/trainer/:userId    → TrainerProfileScreen
/trainer/edit       → TrainerEditProfileScreen (extra: TrainerProfile?)
/workouts           → WorkoutsListScreen
/workouts/create    → WorkoutFormScreen
/workouts/:id/edit  → WorkoutFormScreen (extra: Workout?)
```

### i18n (~50 ключей)

Добавлены в оба ARB файла (app_en.arb, app_ru.arb):
- Профиль тренера: trainerProfile, trainerEditProfile, trainerBio, trainerSpecialization, trainerExperience, trainerCertificates и др.
- Специализации: specMarathon, specSprint, specTrail, specRecovery, specGeneral
- Тренировки: workouts, myWorkouts, createWorkout, editWorkout, workoutName, workoutDescription и др.
- Типы: typeRecovery, typeTempo, typeInterval, typeFartlek, typeLongRun
- Сложность: diffBeginner, diffIntermediate, diffAdvanced, diffPro
- Метрики: metricDistance, metricTime, metricPace
- Интеграция: eventWorkout, eventTrainer и др.

## Новые файлы (~30)

### Backend
- `backend/src/db/migrations/018_trainer_profiles.sql`
- `backend/src/db/migrations/019_workouts.sql`
- `backend/src/db/migrations/020_events_trainer_fields.sql`
- `backend/src/modules/trainer/trainer.entity.ts`
- `backend/src/modules/trainer/trainer.dto.ts`
- `backend/src/modules/trainer/index.ts`
- `backend/src/modules/workout/workout.entity.ts`
- `backend/src/modules/workout/workout.type.ts`
- `backend/src/modules/workout/workout.difficulty.ts`
- `backend/src/modules/workout/workout.target-metric.ts`
- `backend/src/modules/workout/workout.dto.ts`
- `backend/src/modules/workout/index.ts`
- `backend/src/db/repositories/trainer_profiles.repository.ts`
- `backend/src/db/repositories/workouts.repository.ts`
- `backend/src/api/helpers/trainer-role.ts`
- `backend/src/api/trainer.routes.ts`
- `backend/src/api/workouts.routes.ts`
- `backend/src/__tests__/trainer.routes.test.ts`
- `backend/src/__tests__/workouts.routes.test.ts`
- `backend/src/__tests__/events-patch.routes.test.ts`
- `backend/src/db/repositories/__mocks__/trainer_profiles.repository.ts`
- `backend/src/db/repositories/__mocks__/workouts.repository.ts`

### Mobile
- `mobile/lib/shared/models/trainer_profile.dart`
- `mobile/lib/shared/models/workout.dart`
- `mobile/lib/shared/api/trainer_service.dart`
- `mobile/lib/shared/api/workouts_service.dart`
- `mobile/lib/features/trainer/trainer_profile_screen.dart`
- `mobile/lib/features/trainer/trainer_edit_profile_screen.dart`
- `mobile/lib/features/trainer/workouts_list_screen.dart`
- `mobile/lib/features/trainer/workout_form_screen.dart`

## Изменённые файлы (~10)

- `backend/src/modules/events/event.entity.ts` — + workoutId, trainerId
- `backend/src/modules/events/event.dto.ts` — + поля в DTO, + UpdateEventTrainerFieldsSchema
- `backend/src/db/repositories/events.repository.ts` — + updateTrainerFields, EventRow, rowToEvent
- `backend/src/db/repositories/index.ts` — + экспорт новых репозиториев
- `backend/src/api/events.routes.ts` — + PATCH /:id handler
- `backend/src/api/index.ts` — + регистрация /trainer, /workouts
- `backend/src/db/repositories/__mocks__/index.ts` — + моки новых репозиториев
- `mobile/lib/shared/di/service_locator.dart` — + TrainerService, WorkoutsService
- `mobile/lib/app.dart` — + GoRouter routes, imports
- `mobile/lib/shared/models/event_details_model.dart` — + workoutId, trainerId, workoutName, trainerName
- `mobile/l10n/app_en.arb` — + ~50 i18n ключей
- `mobile/l10n/app_ru.arb` — + ~50 i18n ключей

## Не реализовано (отложено)

- **Stage 8.1–8.2:** UI интеграция с событиями на мобильном (dropdown тренировки/тренера в форме события, отображение в карточке события). Backend PATCH endpoint готов.
- **Конструктор тренировок (structure JSON)** — Future, не MVP.
- **Рейтинг, верификация, соцсети тренера** — Future, не MVP.

## Верификация

- `npx tsc --noEmit` — clean (0 errors)
- `npx jest --runInBand` — 131 tests passed
- `flutter analyze` — 0 errors
- `flutter gen-l10n` — successful
