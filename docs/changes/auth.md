# Единая auth-абстракция (Backend)

**Дата:** 2026-01-29 (обновление 2026-02-06)

## Обновление (2026-02-04)

- **Non-prod auth stub больше не даёт общий UID:** В `FirebaseAuthProvider` для non-production сред теперь вычисляется `uid` из JWT-пэйлоада (user_id/uid/sub) или детерминированного хэша токена. Это исключает ситуацию, когда все пользователи мапятся в одну запись `users` из-за фиксированного `mock-uid-123`. Реальная проверка Firebase Admin SDK по-прежнему требуется для production.

**Файлы:** `backend/src/modules/auth/firebase.provider.ts`.

## Обновление (2026-02-06) — интеграция Firebase Admin SDK

- **Backend — реальная проверка Firebase ID токенов:**
  - В `FirebaseAuthProvider.verifyToken` добавлена интеграция с `firebase-admin`: при наличии конфигурации окружения (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`) модуль инициализирует Admin SDK и использует `admin.auth().verifyIdToken(token)` для проверки токена и маппинга в `AuthUser`.
  - В production окружении при отсутствии корректной конфигурации (`assertFirebaseAuthConfigured`) сервер не стартует; любая ошибка верификации токена приводит к `valid: false` с технической причиной.
  - В non-production окружениях при отсутствии конфигурации Admin SDK сохраняется безопасная заглушка: uid детерминированно derive-ится из токена (`stub-<sha256>`), а остальные поля читаются из JWT payload; это упрощает локальную разработку без Firebase.
- **Новая зависимость:** в `backend/package.json` добавлен пакет `firebase-admin`.

**Файлы:** `backend/src/modules/auth/firebase.provider.ts`, `backend/package.json`.

## Проблема

Существовали две параллельные auth-абстракции с идентичной функциональностью:

- **auth/** — `AuthService`, `FirebaseAuthService`, `createAuthService()`, типы `FirebaseUser`, `TokenVerificationResult`; middleware использовал `createAuthService().verifyToken()`.
- **modules/auth/** — `AuthProvider`, `FirebaseAuthProvider`, типы `AuthUser`, `TokenVerificationResult`; реализация заглушки verifyToken дублировалась.

Дублирование логики и типов усложняло поддержку и рисковало расхождением поведения.

## Решение

Оставлена **одна абстракция** — **modules/auth** (AuthProvider, FirebaseAuthProvider).

- В **modules/auth** добавлена функция `getAuthProvider(): AuthProvider` (синглтон FirebaseAuthProvider).
- **auth/authMiddleware** переведён на использование `getAuthProvider().verifyToken()`; тип `req.authUser` — `AuthUser` (из modules/auth).
- **auth/types.ts** реэкспортирует типы из modules/auth; тип `FirebaseUser` оставлен как алиас `AuthUser` для обратной совместимости.
- **auth/service.ts** удалён; **auth/index** экспортирует только типы и `authMiddleware`.

Поведение (заглушка verifyToken, 401 при невалидном токене) не изменилось. Все защищённые эндпоинты по-прежнему используют общее auth middleware.
