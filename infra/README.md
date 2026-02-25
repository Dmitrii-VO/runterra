# Infrastructure

Инфраструктура проекта Runterra.

## Сервер backend (Cloud.ru)

- **SSH алиас:** `runterra` (настроен в `~/.ssh/config`)
- **IP:** `<SERVER_IP>`
- **Порт backend:** `3000`
- **Путь к репо:** `/home/<SSH_USER>/runterra`
- **Путь к backend:** `/home/<SSH_USER>/runterra/backend`

### SSH подключение к backend

Рекомендуемый способ (без зависимости от `~/.ssh/config`):

```powershell
ssh -i <PATH_TO_SSH_KEY> <SSH_USER>@<SERVER_IP>
```

Проверка подключения:

```powershell
ssh -i <PATH_TO_SSH_KEY> <SSH_USER>@<SERVER_IP> "echo ok"
```

Если настроен алиас `runterra` в `~/.ssh/config`, можно так:

```bash
ssh runterra
```

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

### Verification (2026-02-12)

- Выполнен полный `npm run deploy` (backend + mobile): CI passed, backend обновлён по SSH, mobile debug APK собран и опубликован в Firebase App Distribution (0.1.0+97).
- CI run (GitHub Actions): `21961188876` (success).
- Примечание: CI валит `flutter analyze` на warnings. После изменения ARB нужно прогонять `flutter gen-l10n`, а также не оставлять предупреждения уровня warning.

### Verification (2026-02-13)

- Messages: removed legacy mixing, added DB backfill + constraint + index. Details: `docs/changes/2026-02-13-messages-channels-optimization.md`.

## TODO

> Выполненные задачи и закрытые баги теперь фиксируются в `docs/progress.md` и `docs/changes/*`. Ниже остаются только актуальные открытые пункты.

### Инфраструктура
- [ ] Docker для backend
- [ ] Автодеплой после merge в main
- [ ] Staging окружение
- [ ] HTTPS / домен

### Backend (критично для MVP)
- [ ] Firebase Auth — сейчас mock, нужна реальная проверка токенов

### Backend (важно)
Открытых задач нет; все реализованные пункты задокументированы в `docs/progress.md` и соответствующих файлах `docs/changes/*`.

### Mobile
Открытых задач нет; статус и детали см. в `docs/progress.md` (блоки про Run, Events, Messages, Map).

### Продукт (фичи)

Все перечисленные продуктовые фичи (тренировки, профиль, чаты, карта, клубы) реализованы и подробно описаны в `docs/progress.md` и тематических файлах `docs/changes/*`.

**Слои карты (по аналогии с Яндекс: пробки/транспорт — включаемые слои)**
- [ ] **A) Базовый слой:** на главном экране карты всегда — захваченные территории и владельцы
- [ ] **B) Слой «Клубы»** — настройка отображения: один из слоёв — клубы
- [ ] **C) Слой «Стадионы/манежи»** — описание, дистанции, рекорды («попробуй обогнать болта»), ачивки, закрытый/открытый, цена и т.д.
- [ ] **D) Слой «Популярные маршруты»** — маршруты с рекордами
- [ ] **E) Слой «Пробежки»** — пробежки сегодня/завтра/на дату; заявка на присоединение или создание пробежки (функция присоединения/создания должна быть доступна и без этого слоя)

### Ошибки (требуют исправления)

#### Общие
- [ ] Вылет при «Начать пробежку» в Nox — краш на эмуляторе при старте foreground service (GPS). Нужно определить стратегию поддержки/ограничений для Nox и добавить guard-ы/обработку ошибок вокруг старта сервиса.
- [ ] Firebase App Distribution 403 — тестер не может скачать APK; проверить роли/группы тестировщиков и настройки дистрибуции в Firebase Console.

### Real Territory Capture & Private Events (2026-02-17)
- [x] Backend: Real GPS scoring (Ray Casting)
- [x] Backend: Transactional run creation
- [x] Backend: Private events visibility
- [x] Mobile: Club selection for scoring
- [x] Mobile: Private event toggle
