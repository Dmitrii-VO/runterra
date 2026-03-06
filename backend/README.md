# Backend

Backend Runterra: Node.js + TypeScript + Express + PostgreSQL + WebSocket.

Этот файл описывает текущий runtime backend. Исторические изменения и длинные подробности вынесены в `docs/progress.md` и `docs/changes/*`.

## Current Scope

Backend обслуживает рабочий beta-контур `mobile + backend`:

- REST API под `/api`
- health-check `GET /health`
- version endpoint `GET /api/version`
- WebSocket чат на `/ws`
- PostgreSQL миграции и репозитории
- production auth через Firebase Admin SDK

## Local Run

```bash
npm install
npm run migrate
npm run dev
```

Полезные команды:

```bash
npm test
npm run lint
npm run build
npm start
```

## Runtime Notes

- Порт приложения берётся из `PORT`, по умолчанию `3000`.
- В production сервер слушает `localhost`.
- В non-production сервер слушает `0.0.0.0`, что удобно для локальной разработки и Android emulator.
- `GET /health` проверяет доступность процесса.
- `GET /api/version` отдаёт `APP_VERSION`, если она задана в окружении.

## Database

Backend использует PostgreSQL через пакет `pg`.

- Конфиг читается из `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`.
- Пул создаётся lazy-образом и открывает соединение при первом реальном запросе.
- Миграции лежат в `src/db/migrations/`.

Локально:

```bash
npm run migrate
```

После production build:

```bash
npm run migrate:prod
```

## Auth

Backend использует единый auth layer поверх Firebase.

- В production обязательны `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`.
- При наличии этих переменных backend валидирует Firebase ID token через Firebase Admin SDK.
- В non-production, если Firebase Admin не сконфигурирован, остаётся технический fallback для локальной разработки.

Это значит:

- production auth не считается mock;
- dev fallback не должен трактоваться как production-модель безопасности.

## Deploy Context

Operational truth по серверу, systemd и CI/CD находится в [infra/README.md](../infra/README.md).

Коротко:

- локальный deploy backend: `npm run deploy:backend`
- полный deploy: `npm run deploy`

## Compatibility Notes

- В домене тренировок часть старых полей (`difficulty`, `surface`, `blocks`, `target_metric`, `target_value`, `target_zone`) оставлена как compatibility layer.
- Эти поля не являются целевой моделью текущего workout UI и не должны использоваться как базовая схема для новых изменений.

## Source Of Truth

- runtime и infra: [infra/README.md](../infra/README.md)
- mobile distribution: [docs/build-and-share.md](../docs/build-and-share.md)
- changelog: `docs/progress.md`, `docs/changes/*`
