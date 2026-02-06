# Code Review — незакоммиченные изменения (2026-02-06)

## Status (после исправлений)

- [x] Critical: синхронизирован `backend/package-lock.json` после добавления `firebase-admin`.
- [x] Critical: устранены ошибки `body_might_complete_normally` в mobile API-сервисах (`Never _throwApiException`).
- [x] High: исправлен production default URL для Flutter Web (`ApiConfig` больше не указывает на localhost в release).
- [x] Medium: добавлена валидация `cityId` в `GET /api/clubs` (`city_not_found` для неизвестного города).
- [x] Medium: унифицирован формат `clubId` между WS и HTTP chat API (shared validator + 400 на invalid format).
- [x] Medium: устранён race при `joinEvent` (транзакция + `SELECT ... FOR UPDATE` + атомарное обновление счётчика/статуса).
- [x] Medium: исправлен label кнопки check-in (действие вместо текста успеха).
- [x] Medium: добавлены тесты на новые валидации (`GET /api/clubs` unknown city, messages invalid clubId).
- [x] Low: расхождение документации по race condition снято фактическим внедрением транзакционной логики.

## Findings

### Critical

1. **Lockfile не синхронизирован с `package.json`**
- **Файл:** `backend/package.json` (+ `backend/package-lock.json`)
- **Проблема:** Добавлен `firebase-admin`, но lockfile не обновлён.
- **Как проявляется:** `npm ci` падает (`EUSAGE`, missing packages from lock file).
- **Как исправить:** Выполнить `npm install` в `backend/` и закоммитить обновлённый `backend/package-lock.json`.

2. **Ошибки `flutter analyze` из-за non-nullable return paths**
- **Файлы:**
  - `mobile/lib/shared/api/events_service.dart:103`
  - `mobile/lib/shared/api/events_service.dart:115`
  - `mobile/lib/shared/api/messages_service.dart:28`
  - `mobile/lib/shared/api/messages_service.dart:51`
  - `mobile/lib/shared/api/messages_service.dart:80`
- **Проблема:** Методы могут «завершиться нормально» в ветках после `_throwApiException(...)`, т.к. `_throwApiException` объявлен как `void`.
- **Как проявляется:** `flutter analyze` возвращает `body_might_complete_normally`.
- **Как исправить:** Изменить сигнатуру `_throwApiException` на `Never` (в обоих сервисах) или явно `throw`/`return Future.error(...)` в call-sites.

### High

1. **Web release по умолчанию ходит в localhost**
- **Файл:** `mobile/lib/shared/config/api_config.dart:51`
- **Проблема:** Для `kIsWeb` в release остаётся `https://localhost:3000`.
- **Как проявляется:** В production web без `API_BASE_URL` запросы идут в localhost.
- **Как исправить:** Возвращать `_prodBaseUrl` для web release или использовать `Uri.base.origin` по принятой схеме деплоя.

### Medium

1. **Race condition при `joinEvent` (participant_limit)**
- **Файл:** `backend/src/db/repositories/events.repository.ts:238`
- **Проблема:** Нет транзакции/row lock, возможен oversubscribe.
- **Как проявляется:** Параллельные `POST /api/events/:id/join` могут превысить лимит.
- **Как исправить:** Транзакция + `SELECT ... FOR UPDATE` или атомарный SQL с условием лимита.

2. **Потенциальный mismatch формата `clubId` между REST/DB и WS regex**
- **Файл:** `backend/src/ws/chatWs.ts:29`
- **Проблема:** WS допускает только `[A-Za-z0-9_-]{1,128}`, в БД `club_id` хранится как `VARCHAR(128)`.
- **Как проявляется:** REST может работать для `clubId`, а WS подписка для того же ID — отклоняться.
- **Как исправить:** Унифицировать формат ID (единая валидация в API/WS/DB).

3. **`GET /api/clubs` не валидирует `cityId`**
- **Файл:** `backend/src/api/clubs.routes.ts:48`
- **Проблема:** Возвращаются SPB-моки для любого `cityId`.
- **Как проявляется:** `cityId=unknown` всё равно возвращает клубы.
- **Как исправить:** Проверка `findCityById(cityId)` и `400 city_not_found` (или пустой список по согласованному контракту).

4. **Некорректный label кнопки check-in**
- **Файл:** `mobile/lib/features/events/event_details_screen.dart:452`
- **Проблема:** На кнопке текст успеха, а не действия (`eventCheckInSuccess`).
- **Как проявляется:** До нажатия пользователь видит «Check-in successful».
- **Как исправить:** Добавить отдельный i18n ключ для CTA (`eventCheckIn`) и использовать его в кнопке.

5. **Пробелы в тестах для новых рисковых зон**
- **Файлы:** auth/messages/ws/migrations изменения в backend
- **Проблема:** Нет тестов на fallback/prod auth, membership guard в HTTP+WS, миграцию `009`.
- **Как проявляется:** Регрессии могут попасть в релиз.
- **Как исправить:** Добавить unit/integration тесты по указанным сценариям.

### Low

1. **Документация расходится с реализацией (`participant_limit` race)**
- **Файл:** `infra/README.md` (audit checklist)
- **Проблема:** Пункт отмечен как выполненный, но в коде только TODO.
- **Как исправить:** Вернуть пункт в TODO или реализовать транзакционную защиту.

## Open Questions / Assumptions

1. Является ли Flutter Web целевой production-платформой?
2. Какой официальный формат `clubId` (slug/uuid/произвольная строка)?
3. Допустим ли fallback-auth в non-production для публичных/staging окружений?

## Minimal Test Plan

1. **Backend:** `npm ci`, `npx tsc --noEmit`, `npm test`.
2. **Mobile:** `flutter analyze`, `flutter test`.
3. **Auth/Messages:** 401 без токена, 403 не-члену, 200/201 active member; WS subscribe allow/deny по членству.
4. **Events concurrency:** параллельные `join` при `participant_limit=1`.
5. **DB migration:** прогон до `009`, проверка insert/select сообщений с `channel_id='club-1'`.
