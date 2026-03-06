# Runterra

Платформа для локальных беговых сообществ с картой, событиями, пробежками, клубами и тренерскими сценариями.

## Beta Scope

Ближайшая закрытая бета проекта = `mobile + backend`.

- `mobile/` и `backend/` считаются обязательной beta-поверхностью.
- `admin/` отложен и не входит в ближайший release gate.
- `wear/` остаётся активным вторичным направлением, но не входит в обязательный beta gate.

## Current State

Сейчас в рабочем контуре есть:

- Firebase Authentication на клиенте и Firebase Admin SDK на backend для production-проверки токенов.
- Flutter mobile-приложение на Yandex MapKit.
- Node.js + TypeScript backend с PostgreSQL, миграциями и WebSocket для чатов.
- Клубы, события, тренировки, история пробежек, GPS check-in, чат и профиль.

Отдельный инфраструктурный переход на `домен + HTTPS + reverse proxy` осознанно отложен. Текущее удалённое подключение к backend использует IP-конфигурацию; детали и follow-up см. в [infra/README.md](infra/README.md).

## Repo Layout

- `backend/` - API, миграции PostgreSQL, WebSocket, серверная логика.
- `mobile/` - Flutter-приложение.
- `wear/` - companion-направление для часов.
- `admin/` - отложенная админка.
- `infra/` - operational-документация по серверу, deploy и CI/CD.
- `docs/` - продуктовые и инженерные документы, история изменений.
- `scripts/` - deploy и вспомогательные скрипты.

## Quick Start

Backend:

```bash
cd backend
npm install
npm run migrate
npm run dev
```

Mobile:

```bash
cd mobile
flutter pub get
flutter run
```

## CI And Release Gate

Обязательный CI сейчас покрывает только:

- `backend`
- `mobile`

`admin` и `wear` пока не входят в обязательный release gate. Точный operational status см. в [infra/README.md](infra/README.md).

## Canonical Docs

- [infra/README.md](infra/README.md) - сервер, deploy, CI/CD, smoke-checks, infra TODO.
- [backend/README.md](backend/README.md) - backend runtime, env, auth, миграции, локальный запуск.
- [docs/build-and-share.md](docs/build-and-share.md) - mobile build, distribution и release checklist.
- [docs/progress.md](docs/progress.md) - хронология изменений.
- `docs/changes/` - тематические change logs по модулям.
- `docs/adr/` - архитектурные решения.

## Secrets

- Репо-локальные переменные для deploy-скриптов можно держать в `.env.local` по шаблону `.env.local.example`.
- Service-account JSON и другие чувствительные ключи не хранить в корне репозитория; использовать локальную защищённую директорию, например `.secrets/`.
