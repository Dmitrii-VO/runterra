# Изменения: Пользователи / профиль

## История изменений

### 2026-02-04

- **Редактирование профиля:** Реализован экран/форма изменения данных пользователя (имя, URL фото). Backend: в `user.dto.ts` расширены `UpdateProfileDto` и `UpdateProfileSchema` полями `name?` (z.string().min(1).max(100).optional()) и `avatarUrl?` (z.union([z.string().url(), z.literal('')]).optional()); в `users.routes.ts` обработчик PATCH `/me/profile` собирает из тела запроса `currentCityId`, `name`, `avatarUrl` и передаёт их в `usersRepo.update(user.id, updates)` (пустая строка `avatarUrl` сохраняется как сброс фото). Mobile: в `users_service.dart` метод `updateProfile` принимает опциональные параметры `name` и `avatarUrl`; добавлен экран `edit_profile_screen.dart` (форма с полями имя и URL фото, валидация имени, вызов `UsersService.updateProfile`, при успехе `context.pop(true)`); в `profile_screen.dart` — AppBar с кнопкой «Редактировать» (при наличии данных профиля), переход `context.push('/profile/edit', extra: profile.user)`, по возврату с `result == true` — `_retry()` для обновления профиля; в `app.dart` добавлен маршрут `/profile/edit` с `state.extra as ProfileUserData`. Локализация: в `app_en.arb` и `app_ru.arb` добавлены ключи `editProfileTitle`, `editProfileName`, `editProfilePhotoUrl`, `editProfileSave`, `editProfileNameRequired`, `editProfileEditAction`.

**Файлы:** `backend/src/modules/users/user.dto.ts`, `backend/src/api/users.routes.ts`, `mobile/lib/shared/api/users_service.dart`, `mobile/lib/features/profile/edit_profile_screen.dart`, `mobile/lib/features/profile/profile_screen.dart`, `mobile/lib/app.dart`, `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb`.

### 2026-02-02

- **Единый формат ошибок API (ADR-0002):** В `users.routes.ts` старые эндпоинты (GET /, GET /:id, POST /, DELETE /me) возвращали ошибки в формате `{ error: '...' }`. Приведены к единому формату `{ code, message }`: `internal_error`, `not_found`, `conflict`. Новые эндпоинты (PATCH /me/profile, GET /me/profile) уже использовали правильный формат.

**Файлы:** `backend/src/api/users.routes.ts`.

- **Единый путь профиля:** Алиас GET `/api/me/profile` в `api/index.ts` заменён с 302-редиректа на прямой forward в `usersRouter` — редирект терял заголовок `Authorization`, что приводило к 401. Теперь оба пути (`/api/me/profile` и `/api/users/me/profile`) обрабатываются одним handler без дублирования логики.
- **Авторизация в users.routes:** Везде заменено чтение `(req as unknown as { user?: { uid: string } }).user?.uid` на `req.authUser?.uid`; при отсутствии — ответ 401 в формате API. Затрагивает GET /me/profile, DELETE /me, новый PATCH /me/profile.
- **PATCH /api/users/me/profile:** Добавлен эндпоинт обновления профиля (тело `{ currentCityId?: string }`, валидация через `UpdateProfileSchema`). По `req.authUser.uid` находится пользователь; при наличии `currentCityId` в теле вызывается `usersRepo.update(user.id, { cityId })`. Ответ 200 с `{ success: true }`.
- **Выбор города в профиле (mobile):** В ProfileScreen добавлен блок «Город» (`_CitySection`): отображение текущего города (из профиля), по нажатию — диалог выбора города (`showCityPickerDialog`); после выбора — `UsersService.updateProfile(currentCityId: cityId)` и `CurrentCityService.setCurrentCityId(cityId)`, затем обновление профиля. Добавлены `UsersService.updateProfile()`, метод `patch()` в ApiClient; l10n ключ `cityNotSelected` (Not selected / Не выбран).

**Файлы:** `backend/src/api/index.ts`, `backend/src/api/users.routes.ts`, `backend/src/modules/users/user.dto.ts` (UpdateProfileDto, UpdateProfileSchema), `mobile/lib/shared/api/users_service.dart`, `mobile/lib/shared/api/api_client.dart`, `mobile/lib/features/profile/profile_screen.dart`, `mobile/lib/shared/services/current_city_service.dart`, `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb`.

### 2026-01-29

- **firebaseUid не утекает в API-ответах (безопасность):** Все user-эндпоинты, возвращающие данные пользователя, теперь отдают UserViewDto вместо полной сущности User. UserViewDto не содержит firebaseUid (внутренний идентификатор Firebase). Добавлены интерфейс UserViewDto и функция userToViewDto в user.dto.ts; GET /api/users, GET /api/users/:id и POST /api/users возвращают результат маппинга. GET /api/users/me/profile не изменён — ProfileDto.user уже не содержал firebaseUid.

- **Runtime-валидация создания пользователя (backend):** Для эндпоинта `POST /api/users` добавлена техническая runtime-валидация тела запроса через Zod-схему `CreateUserSchema` (на основе `CreateUserDto`). Валидация проверяет только форму и типы полей запроса (firebaseUid, email, name и опциональные поля) без добавления бизнес-логики; при некорректном теле запроса backend возвращает `400 Bad Request` с описанием ошибок. Контракты DTO и поведение MOCK-заглушек остаются без изменений.

### 2026-01-29

**Backend API auth middleware (доступ к пользовательским данным)**

- **Авторизация для пользовательских эндпоинтов:** Все роуты `/api/users/**` теперь проходят через общее middleware авторизации backend-а, которое ожидает заголовок `Authorization: Bearer <Firebase ID token>`.
- **Проверка токена:** Middleware не реализует бизнес-логику и не меняет контракты ответов; оно только передаёт токен в `AuthService.verifyToken()` (заглушка FirebaseAuthService) и блокирует доступ с `401 Unauthorized` при отсутствии или невалидности токена.
- **Skeleton-этап:** Логика профиля и остальных пользовательских эндпоинтов по-прежнему работает на заглушках; изменение касается только требования авторизационного заголовка для доступа.

### 2025-01-27

**Личный кабинет (профиль): контракты и документация**

- **Контракт `club === null`:** В `ProfileDto` и `ProfileModel` поле `club` явно nullable. UI обязан обрабатывать: `club == null && isMercantile === true` (меркатель), `club == null && isMercantile === false` (без клуба). В `ProfileHeaderSection` добавлена явная ветка для edge-case «Без клуба». Логика только через `if/else`, без try/catch и проверок length.
- **Mock-режим:** В `GET /api/users/me/profile` зафиксированы пометки MOCK и TODO: replace with real data / ProfileService. Заглушка явно помечена как фейковые данные для skeleton.
- **Правила меркателя:** В `user.entity` у `isMercantile` зафиксированы правила: меркатель не имеет `ClubMembership`; membership не создаётся при участии в тренировке; вклад засчитывается логикой активности; доступ в профиль не зависит от `role === MEMBER`.
- **ProfileScreen = точка входа:** В `app.dart` зафиксировано: Profile — entry point после логина, центр личного кабинета; `initialLocation: '/'`, всегда доступен из TabBar.

**Файлы:** `profile.dto.ts`, `user.entity.ts`, `users.routes.ts`, `profile_model.dart`, `header_section.dart`, `quick_actions_section.dart`, `app.dart`.
