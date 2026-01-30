# Локальное логирование и dev-отправка логов на удалённый сервер

**Дата:** 2026-01-29

## Цель

- Структурированный логгер на backend; в DEV — дополнительная отправка error/warn на удалённый dev-лог-сервер.
- Единый dev-лог-сервер для приёма логов по HTTP POST `/log` (backend, mobile, admin).
- Логи отправляются **только в dev-окружении**; в PROD на этот сервер ничего не отправляется.

## Инфраструктура dev-лог-сервера

- **URL:** `http://176.108.255.4:4000/log` (POST).
- **Формат:** JSON, `Content-Type: application/json`.
- **Ответ:** `204 No Content`.
- **Файл на сервере:** `/home/user1/Runterra/logs/errors.log`.

## Что сделано

### Backend (Node.js)

- **Структурированный логгер** (`backend/src/shared/logger.ts`)
  - Методы: `logger.debug`, `logger.info`, `logger.warn`, `logger.error`.
  - Каждый лог — одна JSON-строка: `level`, `message`, `timestamp`, `context`.

- **Dev-only отправка на удалённый лог-сервер**
  - Модуль `backend/src/shared/devLogClient.ts`:
    - `sendDevLog(level: 'error' | 'warn', message, context)` — только при `NODE_ENV !== 'production'` и заданном URL.
    - URL задаётся через `DEV_LOG_SERVER_URL`; по умолчанию в dev: `http://176.108.255.4:4000`.
    - Fire-and-forget POST на `${url}/log`, без чувствительных данных (токены, пароли, GPS-треки отфильтровываются).
  - В `logger.ts` при вызове `error`/`warn` дополнительно вызывается `sendDevLog` (не блокирует вывод в консоль).

- **Удалён эндпоинт `POST /dev/log`**
  - Логи с mobile/admin отправляются напрямую на внешний лог-сервер, а не на наш backend.

- **Глобальная обработка ошибок**
  - Fallback-middleware в `app.ts` логирует необработанные ошибки через `logger.error` (в т.ч. уходит на dev-лог-сервер в dev).
  - Ошибки пула PostgreSQL в `db/client` логируются через `logger.error`.

### Mobile (Flutter)

- **DevRemoteLogger** (`mobile/lib/main.dart`)
  - Отправка **только в dev**: когда задан `--dart-define=DEV_LOG_SERVER=...` (например `http://176.108.255.4:4000`).
  - В PROD (release-сборка без define) `DEV_LOG_SERVER` пустой — запросы не выполняются.
  - POST на `${baseUrl}/log`, тело: `{ level: "error", message, context }`, `Content-Type: application/json`.
  - Используется в: `FlutterError.onError`, `runZonedGuarded`, MapScreen (GPS, аннотации, территория по тапу), MyLocationButton, EventsScreen (ошибка загрузки списка событий).

### Admin (Next.js)

- **Утилита** `admin/src/shared/devLogClient.ts`
  - `sendDevLog(message, context)` — отправка только когда задан `NEXT_PUBLIC_DEV_LOG_SERVER` (dev-сборки).
  - В PROD переменная не задаётся — запросы не выполняются.
  - Предназначена для будущей обработки ошибок API/UI; при появлении вызовов API — вызывать при ошибках.

## Как использовать

### Backend

1. Запуск в dev: `NODE_ENV=development` (или не `production`). По умолчанию error/warn уходят на `http://176.108.255.4:4000/log`.
2. Переопределить URL: `DEV_LOG_SERVER_URL=http://other:4000`.
3. В production (`NODE_ENV=production`) на лог-сервер ничего не отправляется.

### Mobile

1. **Dev:** при запуске передать URL лог-сервера:
   ```bash
   flutter run --dart-define=DEV_LOG_SERVER=http://176.108.255.4:4000
   ```
2. **Prod:** не передавать `DEV_LOG_SERVER` (release-сборка) — отправка отключена.

### Admin

1. **Dev:** в `.env.local` задать `NEXT_PUBLIC_DEV_LOG_SERVER=http://176.108.255.4:4000`.
2. При появлении вызовов API вызывать `sendDevLog(message, { error, stackTrace, ... })` в catch.
3. **Prod:** переменную не задавать — отправка отключена.

## Что логируется

- **Backend:** все вызовы `logger.error` и `logger.warn` (в т.ч. необработанные ошибки Express, ошибки пула БД).
- **Mobile:** ошибки Flutter, асинхронные ошибки, GPS, карта, территории, загрузка событий.
- **Admin:** по мере появления — ошибки API и ключевые сбои UI (через `sendDevLog`).

## Что НЕ логируется

- Чувствительные данные: токены, пароли, полные GPS-треки (координаты в контексте отфильтровываются в devLogClient).
- В PROD на удалённый лог-сервер ничего не отправляется.

## Конфиденциальность

- В payload не передаются PII, токены, пароли, координаты (в backend/mobile/admin контекст санитизируется).
- Отправка включена только в dev-окружении; код изолирован и может быть удалён после dev-этапа.
