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
- [x] i18n — локализация строк (крупная фича)
- [x] Чат — real-time сообщения (крупная фича)
- [x] Background GPS — трекинг пробежки в фоне (крупная фича)

### Продукт (фичи)

**Тренировки и профиль**
- [x] Завершение тренировки — экран результата как в фитнес-приложении (темп, скорость, калории, placeholder пульс)
- [x] Редактирование профиля — экран/форма изменения данных пользователя (проверить)
- [x] Выбор города — настройка города пользователя
- [x] События для примера — добавить примеры событий (данные/демо)

**Чаты**
- [x] Удалить чат города — оставить только чат клуба; вместо города сделать вкладки: **Личные** / **Клуб** / **Тренер**

**Карта и трекинг**
- [x] Трекинг пробежки на карте — отображение маршрута в реальном времени во время бега (локация, интеграция с часами, опционально — показатели в реальном времени)
- [x] Кнопка «Найти клуб» — переход на карту с отображением клубов
- [x] Кнопка «Создать клуб» — сделать функциональной (создание клуба)
- [x] Убрать с карты фильтры «сегодня / неделя / мой клуб» и аналогичные

**Слои карты (по аналогии с Яндекс: пробки/транспорт — включаемые слои)**
- [ ] **A) Базовый слой:** на главном экране карты всегда — захваченные территории и владельцы
- [ ] **B) Слой «Клубы»** — настройка отображения: один из слоёв — клубы
- [ ] **C) Слой «Стадионы/манежи»** — описание, дистанции, рекорды («попробуй обогнать болта»), ачивки, закрытый/открытый, цена и т.д.
- [ ] **D) Слой «Популярные маршруты»** — маршруты с рекордами
- [ ] **E) Слой «Пробежки»** — пробежки сегодня/завтра/на дату; заявка на присоединение или создание пробежки (функция присоединения/создания должна быть доступна и без этого слоя)

### Ошибки (требуют исправления)
- [ ] Firebase App Distribution 403 — тестер не может скачать APK (проверить права в Firebase Console)
- [x] Profile: "type 'Null' is not a subtype of type 'bool'" — исправлено (isMercenary null-safe)
- [x] Run submit: validation error — исправлено (activityId не отправляется если null, datetime в UTC)
- [x] Карта не загружается — logcat: "You need to set the API key before using MapKit!" — исправлено (setApiKey в MainActivity до super.onCreate)
- [x] launch_background — Resources$NotFoundException на эмуляторе (bitmap @mipmap/ic_launcher) — исправлено (только цвет)
