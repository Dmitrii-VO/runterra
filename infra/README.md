# Infrastructure

Операционная документация Runterra: сервер, deploy, CI/CD и release-проверки.

## Beta Scope

Ближайшая закрытая бета = `mobile + backend`.

- `admin` не входит в ближайший beta/release gate.
- `wear` остаётся вторичным активным направлением, но не обязателен для текущего release gate.

## Backend Server

- SSH alias: `runterra`
- Public server IP: `85.208.85.13`
- Backend repo path: `/home/<SSH_USER>/runterra/backend`
- systemd service: `runterra-backend`

Подключение:

```powershell
ssh -i <PATH_TO_SSH_KEY> <SSH_USER>@85.208.85.13
```

Если alias настроен:

```bash
ssh runterra
```

Управление сервисом:

```bash
ssh runterra "systemctl status runterra-backend"
ssh runterra "systemctl restart runterra-backend"
ssh runterra "journalctl -u runterra-backend -f"
```

## Current Networking

Текущее удалённое mobile/backend взаимодействие использует IP-конфигурацию вокруг `85.208.85.13:3000`.

Отдельный инфраструктурный переход на:

- домен,
- HTTPS,
- reverse proxy,
- backend за `localhost`

считается `deferred` и пока не реализуется в этом цикле.

## Deploy

Backend обновляется через серверный `update.sh`:

```bash
git pull
npm ci
npm run build
npm run migrate:prod
systemctl restart runterra-backend
```

Локальные entrypoints из корня репозитория:

```bash
npm run deploy:backend
npm run deploy:mobile
npm run deploy
```

## Database

PostgreSQL работает локально на сервере:

- Host: `localhost`
- Port: `5432`
- Database: `runterra`
- User: `runterra`

Подключение:

```bash
ssh runterra "PGPASSWORD=... psql -h localhost -U runterra -d runterra"
```

Миграции:

```bash
cd backend
npm run migrate
npm run migrate:prod
```

## CI/CD

Текущий обязательный GitHub Actions CI покрывает только:

- `backend`: install, lint, typecheck, test, build
- `mobile`: `flutter pub get`, analyze, test, debug APK build

`admin` и `wear` сейчас не входят в обязательный release gate.

`npm run deploy` ожидает успешный CI перед backend deploy, если проверка не отключена флагами.

## Firebase And Distribution

- Для mobile distribution используется Firebase App Distribution.
- Для production backend auth используется Firebase Admin SDK через env-конфигурацию.
- Service-account JSON и другие секреты не хранить в корне репозитория; использовать локальную защищённую директорию, например `.secrets/`.

## Post-Deploy Smoke Checklist

Минимальная обязательная проверка после deploy:

### Backend

- `GET /health`
- `GET /api/version`
- один авторизованный API-запрос

### Mobile

- запуск приложения
- вход в аккаунт
- открытие карты
- открытие профиля

Если есть время на один ключевой сценарий, приоритет:

- вход в событие или
- старт/завершение пробежки

## Active Infra TODO

- [ ] Автодеплой после merge в `main`
- [ ] Staging окружение
- [ ] Docker для backend
- [ ] Завести домен + HTTPS + reverse proxy для backend (`deferred`, не текущий цикл)
- [ ] Разобраться с `Firebase App Distribution 403`, если проблема воспроизводится у тестеров

## Source Of Truth

- repo overview: [README.md](../README.md)
- backend runtime/env: [backend/README.md](../backend/README.md)
- mobile build/distribution: [docs/build-and-share.md](../docs/build-and-share.md)
