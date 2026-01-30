# Изменения: Пользователи / профиль

## История изменений

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
