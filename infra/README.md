# Infrastructure

Инфраструктура проекта Runterra.

## Сервер backend (Cloud.ru)

- **SSH алиас:** `runterra` (настроен в `~/.ssh/config`)
- **IP:** `85.208.85.13`
- **Порт backend:** `3000`
- **Путь к репо:** `/home/user1/runterra`
- **Путь к backend:** `/home/user1/runterra/backend`

### Systemd сервис

```
runterra-backend.service
```

Управление:
```bash
ssh runterra "systemctl status runterra-backend"
ssh runterra "systemctl restart runterra-backend"
ssh runterra "journalctl -u runterra-backend -f"  # логи
```

### Обновление backend

На сервере есть скрипт `~/runterra/backend/update.sh`:
```bash
git pull → npm ci → npm run build → npm run migrate:prod → systemctl restart
```

**Локально** (из корня репо):
```bash
npm run deploy:backend   # push + SSH + update.sh
npm run deploy           # backend + mobile
```

## База данных (PostgreSQL)

- **Host:** localhost
- **Port:** 5432
- **Database:** runterra
- **User:** runterra

### Таблицы

| Таблица | Назначение |
|---------|------------|
| `users` | Пользователи (связь с Firebase Auth) |
| `events` | События (тренировки, забеги) |
| `event_participants` | Участники событий (join/check-in) |
| `runs` | Пробежки пользователей |
| `run_gps_points` | GPS точки пробежек |
| `migrations` | Трекинг применённых миграций |

### Миграции

Миграции хранятся в `backend/src/db/migrations/*.sql`

```bash
# Локально (dev)
cd backend && npm run migrate

# На сервере (prod) — запускается автоматически при деплое
npm run migrate:prod
```

### Подключение к БД

```bash
ssh runterra "PGPASSWORD=... psql -h localhost -U runterra -d runterra"
```

## Firebase App Distribution (mobile)

Тестировщики получают email с новой сборкой.

```bash
npm run deploy:mobile    # tests + build APK + upload + notify
```

Конфиг: `scripts/app-distribution.config.json`

## CI/CD

GitHub Actions CI (`ci.yml`) запускается на каждый push/PR в main:
- **Backend:** typecheck, tests, build
- **Mobile:** analyze, tests, build APK

Скрипт `npm run deploy` автоматически ждёт прохождения CI перед деплоем.

## TODO

### Инфраструктура
- [ ] Docker для backend
- [x] CI/CD (GitHub Actions) — проверка перед деплоем
- [x] Миграции БД
- [ ] Автодеплой после merge в main
- [ ] Staging окружение
- [ ] HTTPS / домен

### Backend (критично для MVP)
- [ ] Firebase Auth — сейчас mock, нужна реальная проверка токенов
- [x] События — запись на событие (join) с проверкой лимита
- [x] События — check-in с GPS проверкой (500м радиус)
- [x] Пробежки — валидация (≥100м, ≤30км/ч, ≥30с)
- [x] Пробежки — сохранение GPS точек

### Backend (важно)
- [x] Фильтры событий — dateFilter, clubId, difficultyLevel, eventType
- [x] Фильтры карты — события из БД (территории mock — нет таблицы)
- [x] Профиль — реальные данные из БД + статистика пробежек
- [x] Удаление аккаунта — DELETE /api/users/me

### Mobile
- [x] Backend URL — конфиг через `--dart-define=API_BASE_URL=...` (api_config.dart)
- [ ] i18n — локализация строк (крупная фича)
- [ ] Чат — real-time сообщения (крупная фича)
- [ ] Background GPS — трекинг пробежки в фоне (крупная фича)
