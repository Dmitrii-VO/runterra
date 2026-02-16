# Аудит Trainer 2.0 по спецификации

**Дата:** 2026-02-16  
**Спецификация:** `docs/trainer-implementation-spec.md`  
**Область:** изменения в рабочем дереве (`git diff`) по backend/mobile для Trainer 2.0

## Вердикт

`PASS WITH ISSUES`

## План исправлений

- [x] Шаг 1 (Critical): привести права доступа workouts к Spec 4.2 (строго: `member` не может personal read/create/update/delete), добавить backend-тесты.
- [x] Шаг 2 (High): вернуть поля интеграции тренировки/тренера в `GET /api/events` и `GET /api/events/:id`, добавить backend-тесты.
- [x] Шаг 3 (High): реализовать mobile Stage 3 event integration (выбор workout/trainer, PATCH, отображение в карточке, переход в профиль тренера).
- [x] Шаг 4 (High): добавить выбор `clubId` (personal/club) в mobile форме workout create/edit.
- [x] Шаг 5 (Medium): привести контракт удаления workout к spec (`409 workout_in_use`), синхронизировать backend-тесты и mobile обработку.
- [x] Шаг 6 (Medium): убрать заглушку вкладки клубных тренировок, загрузить club workouts.
- [x] Шаг 7 (Low): убрать хардкод-строки и завершить i18n соответствие EN/RU.

## Ход выполнения

- Шаг 1
- Статус: done
- Что сделано: Реализована строгая трактовка Spec 4.2 для workouts. Для personal списка (`GET /api/workouts` без `clubId`) и personal workout (`GET /api/workouts/:id` при `clubId=null`) добавлена обязательная проверка роли trainer/leader. Для `PATCH` и `DELETE` добавлена обязательная проверка trainer/leader даже для автора workout. Добавлены тесты downgrade-сценариев автора до `member` для `GET personal`, `GET by id personal`, `PATCH`, `DELETE` с ожидаемым `403`.
- Измененные файлы: `backend/src/api/workouts.routes.ts`, `backend/src/api/workouts.routes.test.ts`, `docs/changes/2026-02-16-trainer-implementation-audit.md`
- Проверки (команды + результат):
  - `cd backend && npx jest --runInBand` -> passed (10 test suites, 135 tests).
  - `cd backend && npx tsc --noEmit` -> passed.
  - `cd mobile && flutter analyze` -> blocked: `command timed out after 180163 milliseconds`.
  - `cd mobile && flutter test` -> blocked: `command timed out after 180112 milliseconds`.
- Остаточные риски/что дальше: mobile-проверки не подтверждены из-за таймаутов окружения; перейти к Шагу 2 (добавить поля workout/trainer в чтение событий и тесты на возврат полей).

- Шаг 2
- Статус: done
- Что сделано: Для чтения событий реализовано обогащение integration-полями тренировки/тренера. `GET /api/events` теперь возвращает `workoutId`, `trainerId`, `workoutName`, `workoutType`, `workoutDifficulty`, `trainerName`. `GET /api/events/:id` дополнительно возвращает `workoutDescription`. Добавлен resolver, который подтягивает связанные workout/trainer данные из репозиториев. Обновлены DTO и backend-тесты на возврат integration-полей для списка и деталей.
- Измененные файлы: `backend/src/api/events.routes.ts`, `backend/src/modules/events/event.dto.ts`, `backend/src/api/api.test.ts`, `docs/changes/2026-02-16-trainer-implementation-audit.md`
- Проверки (команды + результат):
  - `cd backend && npx jest --runInBand` -> passed (10 test suites, 137 tests).
  - `cd backend && npx tsc --noEmit` -> passed.
  - `cd mobile && flutter analyze` -> blocked: `command timed out after 180111 milliseconds`.
  - `cd mobile && flutter test` -> blocked: `command timed out after 180108 milliseconds`.
- Остаточные риски/что дальше: mobile-проверки по-прежнему заблокированы таймаутами окружения; перейти к Шагу 3 (mobile event integration + PATCH синхронизация с backend).

- Шаг 3
- Статус: done
- Что сделано: Реализована mobile integration с событиями для MVP Stage 3. Добавлен клиентский `PATCH /api/events/:id` (`EventsService.updateEventTrainerFields`) и вызов после создания события для назначения workout/trainer. В create event flow добавлен выбор тренировки (для club events) и выбор тренера (для лидера клуба). В `EventDetailsScreen` добавлено отображение связанных workout-полей (name/description/type/difficulty) и trainer, плюс переход на `/trainer/:userId`. Модель `EventDetailsModel` расширена integration-полями; добавлен unit-тест на парсинг этих полей.
- Измененные файлы: `mobile/lib/shared/api/events_service.dart`, `mobile/lib/features/events/create_event_screen.dart`, `mobile/lib/features/events/event_details_screen.dart`, `mobile/lib/shared/models/event_details_model.dart`, `mobile/test/models/event_details_model_test.dart`, `docs/changes/2026-02-16-trainer-implementation-audit.md`
- Проверки (команды + результат):
  - `cd backend && npx jest --runInBand` -> passed (10 test suites, 137 tests).
  - `cd backend && npx tsc --noEmit` -> passed.
  - `cd mobile && flutter analyze` -> blocked: `command timed out after 180108 milliseconds`.
  - `cd mobile && flutter test` -> blocked: `command timed out after 180121 milliseconds`.
- Остаточные риски/что дальше: мобильные проверки не завершены из-за таймаутов окружения; перейти к Шагу 4 (добавить выбор personal/club в форме workout и синхронизацию `clubId` в create).

- Шаг 4
- Статус: done
- Что сделано: В `WorkoutFormScreen` добавлен явный выбор области тренировки (personal/club) для create с передачей `clubId` в `createWorkout`. Для edit сохранен текущий API-контракт (изменение `clubId` не поддерживается backend), поэтому поле отображается в read-only режиме как текущая область (personal/club).
- Измененные файлы: `mobile/lib/features/trainer/workout_form_screen.dart`, `docs/changes/2026-02-16-trainer-implementation-audit.md`
- Проверки (команды + результат):
  - `cd backend && npx jest --runInBand` -> passed (10 test suites, 137 tests).
  - `cd backend && npx tsc --noEmit` -> passed.
  - `cd mobile && flutter analyze` -> blocked: `command timed out after 180104 milliseconds`.
  - `cd mobile && flutter test` -> blocked: `command timed out after 180106 milliseconds`.
- Остаточные риски/что дальше: mobile-проверки по-прежнему блокируются таймаутом окружения; перейти к Шагу 5 (контракт `workout_in_use` и обработка ошибки на mobile).

- Шаг 5
- Статус: done
- Что сделано: Контракт удаления workout при связанности с будущими событиями приведен к Spec 3.2. Backend теперь возвращает `409 { code: "workout_in_use", message: "Workout is linked to upcoming events" }`. Обновлены backend-тесты на точный `code/message`. В mobile обновлена обработка ошибки удаления (`workout_in_use` -> локализованное сообщение `workoutInUse`).
- Измененные файлы: `backend/src/api/workouts.routes.ts`, `backend/src/api/workouts.routes.test.ts`, `mobile/lib/features/trainer/workouts_list_screen.dart`, `docs/changes/2026-02-16-trainer-implementation-audit.md`
- Проверки (команды + результат):
  - `cd backend && npx jest --runInBand` -> passed (10 test suites, 137 tests).
  - `cd backend && npx tsc --noEmit` -> passed.
  - `cd mobile && flutter analyze` -> blocked: `command timed out after 180106 milliseconds`.
  - `cd mobile && flutter test` -> blocked: `command timed out after 180114 milliseconds`.
- Остаточные риски/что дальше: мобильные проверки не завершаются из-за ограничений окружения; перейти к Шагу 6 (убрать заглушку club workouts tab и загрузить данные).

- Шаг 6
- Статус: done
- Что сделано: Во вкладке club workouts убрана заглушка. Реализована загрузка `getWorkouts(clubId: currentClubId)` для активного текущего клуба, синхронизирован refresh для обеих вкладок (personal и club), добавлено состояние отсутствия текущего клуба.
- Измененные файлы: `mobile/lib/features/trainer/workouts_list_screen.dart`, `docs/changes/2026-02-16-trainer-implementation-audit.md`
- Проверки (команды + результат):
  - `cd backend && npx jest --runInBand` -> passed (10 test suites, 137 tests).
  - `cd backend && npx tsc --noEmit` -> passed.
  - `cd mobile && flutter analyze` -> blocked: `command timed out after 180118 milliseconds`.
  - `cd mobile && flutter test` -> blocked: `command timed out after 180106 milliseconds`.
- Остаточные риски/что дальше: mobile-проверки остаются заблокированными таймаутом окружения; перейти к Шагу 7 (устранение hardcoded-строк и завершение i18n EN/RU).

- Шаг 7
- Статус: done
- Что сделано: Убраны hardcoded-строки в `TrainerEditProfileScreen` (валидация специализации и диапазона опыта), добавлены i18n-ключи EN/RU и синхронизированы `app_localizations*.dart` для новых сообщений.
- Измененные файлы: `mobile/lib/features/trainer/trainer_edit_profile_screen.dart`, `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb`, `mobile/lib/l10n/app_localizations.dart`, `mobile/lib/l10n/app_localizations_en.dart`, `mobile/lib/l10n/app_localizations_ru.dart`, `docs/changes/2026-02-16-trainer-implementation-audit.md`
- Проверки (команды + результат):
  - `cd backend && npx jest --runInBand` -> passed (10 test suites, 137 tests).
  - `cd backend && npx tsc --noEmit` -> passed.
  - `cd mobile && flutter analyze` -> blocked: `command timed out after 180108 milliseconds`.
  - `cd mobile && flutter test` -> blocked: `command timed out after 180101 milliseconds`.
- Остаточные риски/что дальше: все замечания аудита закрыты по коду; подтверждение mobile quality gate блокируется таймаутами окружения.

## Итоговое резюме

### Что исправлено полностью

- Закрыт Critical по матрице прав workouts (строгая трактовка Spec 4.2 для `member`).
- Закрыт High по Event extension read-path (`GET /api/events`, `GET /api/events/:id` с integration-полями тренировки/тренера).
- Закрыт High по mobile Stage 3 (выбор workout/trainer в event flow, PATCH sync, отображение в деталях, переход в профиль тренера).
- Закрыт High по форме workout (выбор `personal/club` с передачей `clubId` в create, read-only в edit согласно текущему API).
- Закрыт Medium по контракту удаления workout (`workout_in_use` + точный message) и mobile обработке.
- Закрыт Medium по club workouts tab (реальная загрузка вместо заглушки).
- Закрыт Low по i18n (убраны hardcoded-строки в trainer edit profile).

### Что заблокировано окружением

- `cd mobile && flutter analyze` -> `command timed out after 180108 milliseconds`.
- `cd mobile && flutter test` -> `command timed out after 180101 milliseconds`.

### Какие тесты добавлены/обновлены

- `backend/src/api/workouts.routes.test.ts`: добавлены downgrade-кейсы для `member` (`GET personal`, `GET by id personal`, `PATCH`, `DELETE`) и точный контракт `workout_in_use`.
- `backend/src/api/api.test.ts`: добавлены проверки integration-полей workout/trainer для `GET /api/events` и `GET /api/events/:id`.
- `mobile/test/models/event_details_model_test.dart`: добавлен тест парсинга integration-полей (`workoutId/trainerId/workoutName/workoutDescription/workoutType/workoutDifficulty/trainerName`).

### Ключевые дифф-решения и измененные файлы

- `backend/src/api/workouts.routes.ts`: role guards для personal/read-update-delete + контракт `409 workout_in_use`.
- `backend/src/api/events.routes.ts`: resolver integration-полей для событий на read-path.
- `backend/src/modules/events/event.dto.ts`: расширены DTO полями workout/trainer для чтения.
- `backend/src/api/api.test.ts`: тесты на возврат integration-полей.
- `backend/src/api/workouts.routes.test.ts`: тесты прав и контракта удаления.
- `mobile/lib/shared/api/events_service.dart`: добавлен клиентский PATCH для trainer/workout полей события.
- `mobile/lib/features/events/create_event_screen.dart`: UI выбора workout/trainer + PATCH после create.
- `mobile/lib/features/events/event_details_screen.dart`: отображение workout/trainer и переход на `/trainer/:id`.
- `mobile/lib/shared/models/event_details_model.dart`: новые поля интеграции.
- `mobile/lib/features/trainer/workout_form_screen.dart`: выбор `personal/club` для формы тренировки.
- `mobile/lib/features/trainer/workouts_list_screen.dart`: реальная загрузка club workouts + обработка `workout_in_use`.
- `mobile/lib/features/trainer/trainer_edit_profile_screen.dart`: удалены hardcoded-строки валидации.
- `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb`, `mobile/lib/l10n/app_localizations*.dart`: ключи и реализации i18n для новых сообщений.

## Выполненные проверки

1. `backend`: `npx jest --runInBand` — **137/137 passed**.
2. `backend`: `npx tsc --noEmit` — **passed**.
3. `mobile`: `flutter analyze` — **не удалось завершить** (таймаут: `command timed out after 180108 milliseconds`).
4. `mobile`: `flutter test` — **не удалось завершить** (таймаут: `command timed out after 180101 milliseconds`).

## Исходные проблемы по приоритету (закрыты)

Все перечисленные ниже замечания закрыты в шагах 1-7.

### Critical

1. Нарушение матрицы прав для workout: автор может `PATCH/DELETE` даже будучи `member`, при том что в Spec 4.2 для `member` это запрещено.
   - Где: `backend/src/api/workouts.routes.ts:134`, `backend/src/api/workouts.routes.ts:157`, `backend/src/api/workouts.routes.ts:58`
   - Нарушение: Spec 4.2
   - Исправление: добавить роль-проверку (`trainer/leader`) для personal read/update/delete, либо зафиксировать исключение в спецификации.

### High

1. Event extension не доведена до чтения события: `GET /api/events` и `GET /api/events/:id` не возвращают trainer/workout поля, поэтому клиент не может отобразить интеграцию.
   - Где: `backend/src/api/events.routes.ts:113`, `backend/src/api/events.routes.ts:181`
   - Нарушение: Spec 2.3, Spec 3.3, Spec 6.4
   - Исправление: добавить `workoutId/trainerId` в DTO ответа чтения (и при необходимости `workoutName/trainerName`).

2. Mobile event integration из MVP-роадмапа не реализована: нет назначения `workoutId/trainerId` при создании/редактировании события и нет отображения привязки в карточке события.
   - Где: `mobile/lib/shared/api/events_service.dart:148`, `mobile/lib/features/events/create_event_screen.dart:167`, `mobile/lib/features/events/event_details_screen.dart:245`
   - Нарушение: Spec 6.3, Spec 6.4, Spec 7 (Stage 3)
   - Исправление: добавить клиентский `PATCH /api/events/:id`, UI выбора workout/trainer и отображение в `EventDetailsScreen`.

3. В mobile-форме создания тренировки отсутствует выбор `clubId`, хотя по сценарию тренер должен иметь возможность опционально привязать тренировку к клубу.
   - Где: `mobile/lib/features/trainer/workout_form_screen.dart:24`, `mobile/lib/features/trainer/workout_form_screen.dart:77`
   - Нарушение: Spec 6.2 (шаг 3), Spec 5.1
   - Исправление: добавить selector клуба или explicit toggle personal/club с передачей `clubId` в `createWorkout`.

### Medium

1. Контракт `DELETE /api/workouts/:id` при связанности с будущими событиями не совпадает со спецификацией.
   - Где: `backend/src/api/workouts.routes.ts:173`, `backend/src/api/workouts.routes.test.ts:297`, `mobile/lib/features/trainer/workouts_list_screen.dart:71`
   - Текущее: `409 { code: "conflict", message: "Cannot delete workout linked to upcoming events" }`
   - Ожидаемое: `409 { code: "workout_in_use", message: "Workout is linked to upcoming events" }`
   - Нарушение: Spec 3.2
   - Исправление: вернуть точный `code/message` по spec и синхронизировать mobile обработку.

2. Вкладка клубных тренировок в mobile — заглушка, данные не загружаются.
   - Где: `mobile/lib/features/trainer/workouts_list_screen.dart:99`
   - Нарушение: Spec 5.1 (MVP mobile workouts)
   - Исправление: загрузка `getWorkouts(clubId: ...)` и состояние “нет клуба/нет данных”.

### Low

1. Нелокализованные строки в экране редактирования профиля тренера.
   - Где: `mobile/lib/features/trainer/trainer_edit_profile_screen.dart:69`, `mobile/lib/features/trainer/trainer_edit_profile_screen.dart:182`
   - Нарушение: Spec 5.1 / i18n completeness
   - Исправление: вынести в ARB и использовать `AppLocalizations`.

## Покрытие спецификации

1. Spec 2.1 / 3.1 (TrainerProfile API): **реализовано**.
2. Spec 2.2 / 3.2 (Workouts API): **реализовано**.
3. Spec 2.3 / 3.3 (Event extension backend PATCH + read integration): **реализовано**.
4. Spec 4.2 (матрица прав): **реализовано**.
5. Spec 5.1 (Mobile profile/workouts): **реализовано в рамках MVP**.
6. Spec 7 Stage 3 (Mobile integration with events): **реализовано**.
7. Spec 9 (i18n ключи EN/RU): **реализовано** (пары ключей есть в обоих ARB).
8. Spec 10 (Zod DTO): **реализовано**.
9. Spec 5.2 (Future вне MVP): **реализовано** (лишних future-фич не обнаружено).

## Тестовые пробелы

1. Закрыты: права `member` для workouts (`GET personal`, `GET by id personal`, `PATCH`, `DELETE`) и контракт `workout_in_use`.
2. Закрыты: тесты чтения integration-полей в `GET /api/events` и `GET /api/events/:id`.
3. Остаётся как улучшение качества (не блокер аудита): расширить негативы `PATCH /api/events/:id` (чужой workout/невалидный trainer) и добавить полноценные widget/integration tests mobile event flow.

## Открытые вопросы

1. Решено: применена строгая трактовка Spec 4.2 (для `member` personal workout-операции запрещены).
2. Решено: Stage 3 включен в текущий инкремент и реализован.
