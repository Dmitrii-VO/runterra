# Security hardening — повторный adversarial review

**Дата:** 2026-03-11

## Закрытые findings

### #2 [Высокий] — Email утечка через UserViewDto
**Файлы:** `backend/src/modules/users/user.dto.ts`

Удалено поле `email` из интерфейса `UserViewDto` и маппера `userToViewDto`. Публичные endpoints
`GET /api/users` и `GET /api/users/:id` больше не возвращают email, что устраняет возможность
пагинировать список пользователей и собирать PII одним аккаунтом.

### #3 [Высокий] — Секреты в worktree
**Статус:** уже закрыто конфигурацией `.gitignore`.

`.env.*` покрывает `.env.local`; `firebase-service-account.json` явно прописан.
`git ls-files` подтвердил — ни один из файлов не трекается.

### #4 [Средний] — profileVisible bypass через /events/:id/participants
**Файлы:** `backend/src/api/events.routes.ts`

В `GET /api/events/:id/participants` добавлена проверка `profileVisible`. Если у участника
`profileVisible === false`, поля `name` и `avatarUrl` возвращаются как `null`/`undefined`
вместо реальных данных — деанонимизация через публичное событие устранена.

### #5 [Средний] — avatarUrl принимает любой внешний URL
**Файлы:** `backend/src/modules/users/user.dto.ts`

Zod-схема `UpdateProfileSchema.avatarUrl` дополнена `.refine()`:
принимаются только URL с хоста `firebasestorage.googleapis.com` или пустая строка `''`.
Внешние домены (трекеры, медленные серверы) отклоняются на уровне валидации — HTTP 400.

### #6 [Средний] — WS sticky ACL (исключённый пользователь продолжает читать)
**Файлы:** `backend/src/ws/chatWs.ts`, `backend/src/api/clubs.routes.ts`

В `chatWs.ts` добавлен обратный индекс `clientsByUid: Map<string, Set<WebSocket>>`.
Экспортирована функция `evictUserFromChannel(firebaseUid, channelKey)` — удаляет канал
из всех активных соединений пользователя.

В `/api/clubs/:id/leave` после `clubMembersRepo.deactivate()` вызывается
`evictUserFromChannel(req.authUser.uid, 'club:<clubId>')` — ушедший пользователь немедленно
прекращает получать новые сообщения без ожидания переподключения.

### #7 [Средний] — Аккаунт-воскрешение после DELETE /api/users/me
**Файлы:** `backend/src/modules/auth/auth.provider.ts`, `backend/src/modules/auth/firebase.provider.ts`, `backend/src/api/users.routes.ts`

Добавлен метод `revokeTokens(uid: string): Promise<void>` в интерфейс `AuthProvider`
и реализован через `admin.auth().revokeRefreshTokens(uid)` в `FirebaseAuthProvider`.

`DELETE /api/users/me` теперь вызывает `revokeTokens(firebaseUid)` после удаления записи из БД
(с catch + warn, чтобы сбой отзыва не блокировал ответ клиенту).

`verifyIdToken` переведён в режим `checkRevoked: true` — каждый токен проверяется на
предмет отзыва. Существующий ID-токен истекает в течение часа; после истечения пере-создание
аккаунта с тем же Firebase UID невозможно.

## Не закрыто

### #1 [Критично] — cleartext HTTP/WS в release
Отложено до получения домена и TLS-сертификата на сервере. Файлы:
`api_config.dart`, `network_security_config.xml`, `chat_websocket_service.dart`.

## Тесты

`npm test` — **173/173** тестов прошли. Моки `getAuthProvider` обновлены:
добавлен `revokeTokens: jest.fn().mockResolvedValue(undefined)`.
