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
- [ ] Вылет при «Начать пробежку» в Nox — краш на эмуляторе при старте foreground service (GPS). Нужно определить стратегию поддержки/ограничений для Nox и добавить guard-ы/обработку ошибок вокруг старта сервиса.
- [ ] Firebase App Distribution 403 — тестер не может скачать APK; проверить роли/группы тестировщиков и настройки дистрибуции в Firebase Console.
- [x] Profile: "type 'Null' is not a subtype of type 'bool'" — исправлено (isMercenary null-safe)
- [x] Run submit: validation error — исправлено (activityId не отправляется если null, datetime в UTC)
- [x] Карта не загружается — logcat: "You need to set the API key before using MapKit!" — исправлено (setApiKey в MainActivity до super.onCreate)
- [x] launch_background — Resources$NotFoundException на эмуляторе (bitmap @mipmap/ic_launcher) — исправлено (только цвет)

### Открытые фичи (по docs/progress.md)

- [x] Участие в активностях (events/clubs) — реализовано 2026-02-04:
  - **События (join/check-in):** Backend: `userId` из auth (Firebase UID → users.id), ошибки в формате ADR-0002. Mobile: `EventsService.joinEvent`/`checkInEvent`, кнопка «Присоединиться» на EventDetailsScreen, SnackBar успеха/ошибки, i18n. Подробности — [docs/changes/events.md](../docs/changes/events.md).
  - **Клубы (присоединение к клубу):** Backend: миграция `006_club_members`, `POST /api/clubs/:id/join`, `GET /api/clubs/:id` с isMember/membershipStatus. Mobile: `ClubsService.joinClub`, кнопка «Присоединиться» и состояние «Вы в клубе» на ClubDetailsScreen. Подробности — [docs/changes/clubs.md](../docs/changes/clubs.md).
  - **Фильтр «Мой клуб»:** Backend: в профиле добавлено `user.primaryClubId` (из club_members). Mobile: CurrentClubService, чип «Мой клуб» на EventsScreen (подставляет clubId и перезапрашивает список); на карте фильтр по clubId отложен до системы слоёв. Подробности — [docs/changes/users.md](../docs/changes/users.md), [docs/changes/maps.md](../docs/changes/maps.md).

### Аудит (2026-02-04)
- [ ] Исправить bulk-insert GPS точек (плейсхолдеры) и добавить тест на 2+ точки
- [ ] Привести clubId к единому формату (UUID или строка) во всех слоях: DB, API, WS, mobile
- [ ] Внедрить Firebase Admin SDK и убрать заглушки авторизации
- [ ] Обеспечить авто-создание пользователя по валидному токену (или явный onboarding)
- [ ] Добавить проверку членства для клубных чатов (HTTP + WS)
- [ ] Унифицировать формат ошибок API (code/message/details) во всех эндпоинтах
- [ ] Зафиксировать production baseUrl для mobile (без localhost по умолчанию)
- [ ] Убрать моки и подключить реальные данные для территорий/клубов/активностей
- [ ] Доделать флоу событий в mobile (создание, join, check-in, фильтры)
- [ ] Реализовать mobile chat API (messages_service) для клубных/личных чатов
- [ ] Добавить транзакционную защиту от оверсабскрайба на события (participant_limit)
- [ ] Исправить 500 на /api/messages при отсутствии auth (возвращать 401/403)

#### Feedback (2026-02-04)

##### Backend
- [x] Общий профиль: в non-prod `FirebaseAuthProvider` возвращает фиксированный uid `mock-uid-123`, поэтому все пользователи мапятся в одну запись `users`
  - Где: `backend/src/modules/auth/firebase.provider.ts`, `backend/src/auth/authMiddleware.ts`
  - Решение: в non-prod uid теперь берётся из JWT-пэйлоада или хэша токена, чтобы разные токены давали разных пользователей
- [x] Участники события: нет endpoint для списка участников с именами
  - Где: отсутствует `GET /api/events/:id/participants`
  - Решение: добавлен endpoint с join на `users` и отдачей имён/аватаров
- [x] Профиль: `club` в `/api/users/me/profile` всегда `undefined`, несмотря на `primaryClubId`
  - Где: `backend/src/api/users.routes.ts`
  - Решение: `club` теперь заполняется по `primaryClubId` (fallback name `Club <id>`)
- [x] Клубные чаты: нет endpoint для списка клубных чатов пользователя
  - Где: отсутствует `GET /api/messages/clubs` или `GET /api/clubs/my`
  - Решение: добавлен `GET /api/messages/clubs` с фильтром по членству

##### Mobile
- [x] Участники события: `ParticipantsList` генерирует `Participant N` (mock), имена не подтягиваются
  - Где: `mobile/lib/features/events/widgets/participants_list.dart`
  - Решение: подключен API `/api/events/:id/participants` и отображение реальных имён
- [x] Профиль: UI определяет наличие клуба только по `profile.club`, игнорируя `primaryClubId`
  - Где: `mobile/lib/features/profile/profile_screen.dart`, `mobile/lib/shared/models/profile_model.dart`
  - Решение: добавлен fallback по `primaryClubId` (показ клуба и корректный `hasClub`)
- [x] Сообщения/клубы: `MessagesService.getClubChats()` возвращает пустой список (stub)
  - Где: `mobile/lib/shared/api/messages_service.dart`, `mobile/lib/features/messages/tabs/club_messages_tab.dart`
  - Решение: подключен `GET /api/messages/clubs` и парсинг списка чатов

#### Feedback (2026-02-05)

##### Mobile
- [x] События: после «Присоединиться» кнопка должна стать некликабельной «Вы участвуете», и должна появиться кнопка «Отменить участие»
  - Где: `mobile/lib/features/events/event_details_screen.dart`, `mobile/lib/shared/api/events_service.dart`
  - Решение: добавлен `POST /api/events/:id/leave`, `EventDetails` теперь содержит `isParticipant/participantStatus`; в UI показываются «Вы участвуете» + «Отменить участие», добавлены тексты и обработка ошибок
- [x] События: создание события не реализовано
  - Где: `mobile/lib/shared/api/events_service.dart` (createEvent), UI экран/форма отсутствует
  - Решение: реализован `CreateEventScreen` + навигация с FAB, `createEvent()` подключен к backend
- [x] Профиль: расширить редактирование профиля (Имя, Фамилия, Дата рождения, Страна, Город, Пол)
  - Где: `backend/src/api/users.routes.ts`, `backend/src/modules/users/user.dto.ts`, `mobile/lib/features/profile/edit_profile_screen.dart`, `mobile/lib/shared/models/profile_model.dart`
  - Решение: добавлены поля пользователя + миграция, расширены profile DTO/patch, обновлены формы и отображение в профиле

#### Feedback (2026-02-05, доп.)

##### Mobile
- [x] Профиль: пол должен быть только «мужской» или «женский»
  - Где: `mobile/lib/features/profile/edit_profile_screen.dart`, `mobile/l10n/*.arb`, `backend/src/modules/users/user.dto.ts`
  - Решение: enum и валидация ограничены `male|female`, UI показывает только эти варианты, миграция очищает некорректные значения
- [x] Профиль: дата рождения сохраняется на день раньше (пример: 03.02.1994 → 02.02.1994)
  - Где: `mobile/lib/shared/api/users_service.dart` (формат `YYYY-MM-DD`), `backend/src/db/repositories/users.repository.ts` (parse Date), `backend/src/api/users.routes.ts` (toISOString().slice(0,10))
  - Решение: backend возвращает дату как `YYYY-MM-DD` без UTC сдвига, на стороне repo нормализация даты без `toISOString`
- [x] События: после нажатия «Присоединиться» сначала показывается «Запись на событие - TODO»
  - Где: `mobile/lib/features/events/event_details_screen.dart`, `mobile/l10n/*.arb`
  - Решение: добавлен `eventJoinInProgress` и обновлены тексты без TODO
- [x] Клубы: нет кнопки «Выйти из клуба»
  - Где: `mobile/lib/features/club/club_details_screen.dart`, `mobile/lib/shared/api/clubs_service.dart`, backend clubs API
  - Решение: добавлен `POST /api/clubs/:id/leave`, `ClubsService.leaveClub()`, UI кнопка «Выйти из клуба» и очистка currentClubId
