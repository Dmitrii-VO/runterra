# Обновление документации по последним коммитам (2026-03-05)

## Контекст

Ниже зафиксированы изменения из последних коммитов за 2026-03-05:
`98e92eb`, `55e29c5`, `4b39a2e`, `ea8457f`, `c206943`, `9838681`, `b895340`, `0227d69`, `e90f814`, `4972be7`, `8e82398`, `10c0aa4`.

## 1) Backend: валидации и устойчивость

- `98e92eb` (`backend/src/api/events.routes.ts`): в `GET /api/events/:id` добавлена проверка формата `organizerId` (UUID) перед вызовом `isTrainerOrLeaderInClub`, чтобы не падать с 500 на legacy-данных (`organizer_id = '1'`).
- `e90f814` (`backend/src/api/clubs.routes.ts`): операции назначений ограничены целевой ролью `member`:
  - `POST /api/clubs/:id/members/:userId/assign-trainer`
  - `DELETE /api/clubs/:id/members/:userId/assign-trainer`
  - `POST /api/clubs/:id/members/:userId/assign-group`
  - `DELETE /api/clubs/:id/members/:userId/assign-group/:groupId`
  При неверной роли возвращается `400 invalid_target_role`.
- `4972be7` + `8e82398` (`backend/src/api/trainer.routes.ts`, `backend/src/modules/trainer/trainer_group.dto.ts`):
  - в `POST /api/trainer/groups` лидер может создать группу за выбранного тренера через опциональный `trainerId`;
  - `memberIds` в создании группы стал опциональным (можно создать пустую группу и наполнять позже).

## 2) Mobile: управление тренерскими группами из состава клуба

- `4972be7` (`mobile/lib/features/club/club_roster_screen.dart`):
  - создание группы перенесено в экран состава клуба;
  - для лидера добавлена кнопка `group_add` в AppBar;
  - перед созданием показывается выбор тренера, затем открывается `/trainer/groups/create` с `trainerId` и `trainerName`;
  - список на экране состава отсортирован по имени (тренеры, группы, участники), добавлены счётчики в заголовках секций.
- `4972be7` (`mobile/lib/app.dart`, `mobile/lib/shared/api/trainer_service.dart`):
  - роут создания группы принимает `trainerId` / `trainerName`;
  - `TrainerService.createGroup()` поддерживает опциональный `trainerId`.
- `8e82398` (`mobile/lib/features/trainer/create_trainer_group_screen.dart`):
  - режим создания больше не требует выбора участников;
  - выбор участников показывается только в режиме редактирования группы.
- `10c0aa4` (`mobile/lib/features/trainer/create_trainer_group_screen.dart`):
  - в режиме редактирования добавлена кнопка удаления группы;
  - удаление подтверждается диалогом, после успешного удаления экран закрывается с `result=true`.

## 3) Профиль и статистика

- `b895340` (`backend/src/api/users.routes.ts`, `backend/src/modules/users/user-stats.entity.ts`, mobile-модели/UI):
  - метрика `territoriesParticipated` заменена на `totalDistanceKm` (дистанция в км, 1 знак после запятой);
  - обновлены `UserStatsModel` и `ProfileStatsSection`;
  - вызов `_ensureCityAndLoad()` в `MapScreen` перенесён в `addPostFrameCallback` (устранение крэша в `initState`).
- `0227d69` (l10n): восстановлен ключ `statsTerritories` в ARB и сгенерированных локализациях для совместимости CI, несмотря на переход UI на `statsKm`.

## 4) Версионирование, сборка и деплой

- `55e29c5` + `4b39a2e` (`mobile/pubspec.yaml`, `mobile/lib/app.dart`):
  - версия mobile обновлена до `1.0.1+2`;
  - в приложении добавлен и центрирован бейдж версии в зоне статус-бара (`vX.Y.Z`).
- `c206943` (`scripts/deploy-mobile.ps1`):
  - `deploy:mobile` автоматически повышает patch-версию и пытается создать git-тег `v<major>.<minor>.<patch>`.
- `ea8457f` (`scripts/deploy-mobile.ps1`):
  - после Firebase deploy скрипт пытается синхронизировать `APP_VERSION` на сервере и перезапустить backend.
- `9838681` (`mobile/android/app/build.gradle`):
  - `ndkVersion` повышен до `27.0.12077973`.

## Итог

Зафиксированы изменения последнего блока коммитов: backend-валидации, перенос управления тренерскими группами в roster, обновление метрик профиля, а также автоматизация версионирования и post-deploy синхронизации версии.
