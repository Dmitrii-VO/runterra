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

**Клубы (экран деталей клуба, по docs/product_spec.md §5.3)**
- [x] Расширить экран клуба (ClubDetailsScreen): город клуба; метрики MVP (количество участников, удерживаемые территории, рейтинг в городе — при необходимости заглушки); переход в чат клуба (кнопка «Чат клуба» → Сообщения / вкладка «Клуб» или экран чата клуба). Опционально позже: зоны активности, расписание, основатель/лидер.

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
- [x] Profile: "type 'Null' is not a subtype of type 'bool'" — исправлено (isMercenary null-safe)
- [x] Run submit: validation error — исправлено (activityId не отправляется если null, datetime в UTC)
- [x] Карта не загружается — logcat: "You need to set the API key before using MapKit!" — исправлено (setApiKey в MainActivity до super.onCreate)
- [x] launch_background — Resources$NotFoundException на эмуляторе (bitmap @mipmap/ic_launcher) — исправлено (только цвет)

#### Клубы (выявлено 2026-02-08)
- [x] **[КРИТИЧНО]** Отсутствует Foreign Key между `clubs` и `club_members` — исправлено 2026-02-08: создана миграция `012_clubs_fk.sql`, конвертирует `club_members.club_id` из VARCHAR в UUID, удаляет orphaned records, добавляет FK с CASCADE; убран костыль `id::text` из репозитория.
- [x] **[КРИТИЧНО]** Противоречие slug-based ID vs UUID — исправлено 2026-02-08: валидация `isValidClubId()` изменена на строгий UUID-формат; обновлены комментарии; тесты используют валидные UUID вместо slug-based ID.
- [x] Нет валидации существования клуба при join/leave — исправлено 2026-02-08: добавлена проверка `clubsRepo.findById()` в `POST /api/clubs/:id/join` и `POST /api/clubs/:id/leave`, возвращается 404 если клуб не найден; обновлены тесты с моками.
- [x] Ошибка 22P02 при невалидном clubId — исправлено 2026-02-08 коммитом 097ce82: добавлена валидация `isValidClubId()` во все роуты клубов, теперь возвращается 400 с кодом `club_id_invalid` вместо 500.

### Открытые фичи (по docs/progress.md)

- [x] Участие в активностях (events/clubs) — реализовано 2026-02-04:
  - **События (join/check-in):** Backend: `userId` из auth (Firebase UID → users.id), ошибки в формате ADR-0002. Mobile: `EventsService.joinEvent`/`checkInEvent`, кнопка «Присоединиться» на EventDetailsScreen, SnackBar успеха/ошибки, i18n. Подробности — [docs/changes/events.md](../docs/changes/events.md).
  - **Клубы (присоединение к клубу):** Backend: миграция `006_club_members`, `POST /api/clubs/:id/join`, `GET /api/clubs/:id` с isMember/membershipStatus. Mobile: `ClubsService.joinClub`, кнопка «Присоединиться» и состояние «Вы в клубе» на ClubDetailsScreen. Подробности — [docs/changes/clubs.md](../docs/changes/clubs.md).
  - **Фильтр «Мой клуб»:** Backend: в профиле добавлено `user.primaryClubId` (из club_members). Mobile: CurrentClubService, чип «Мой клуб» на EventsScreen (подставляет clubId и перезапрашивает список); на карте фильтр по clubId отложен до системы слоёв. Подробности — [docs/changes/users.md](../docs/changes/users.md), [docs/changes/maps.md](../docs/changes/maps.md).

### Аудит (2026-02-04)
- [x] Исправить bulk-insert GPS точек (плейсхолдеры) и добавить тест на 2+ точки
- [x] Привести clubId к единому формату (UUID или строка) во всех слоях: DB, API, WS, mobile
- [x] Внедрить Firebase Admin SDK и убрать заглушки авторизации
- [x] Обеспечить авто-создание пользователя по валидному токену (или явный onboarding)
- [x] Добавить проверку членства для клубных чатов (HTTP + WS)
- [x] Унифицировать формат ошибок API (code/message/details) во всех эндпоинтах
- [x] Доделать флоу событий в mobile (создание, join, check-in, фильтры)
- [x] Зафиксировать production baseUrl для mobile (без localhost по умолчанию)
- [x] Убрать моки и подключить реальные данные для территорий/клубов/активностей
- [x] Реализовать mobile chat API (messages_service) для клубных/личных чатов
- [x] Добавить транзакционную защиту от оверсабскрайба на события (participant_limit)
- [x] Исправить 500 на /api/messages при отсутствии auth (возвращать 401/403)

Примечание (2026-02-06): для `participant_limit` реализован транзакционный `joinEvent` с `SELECT ... FOR UPDATE` в `backend/src/db/repositories/events.repository.ts`.

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

#### Feedback (2026-02-06)

##### Mobile
- [x] Во вкладке «Сообщения → Клуб» нет чата и нет поля ввода сообщения; надпись с названием клуба в этом месте не нужна.
- [x] Во вкладке «Пробежка» при старте не отображается позиция и нет кнопки «Найти себя» (как в навигаторах); после пробежки темп считается некорректно/непрозрачно.
  - Решение (2026-02-08): Добавлен CircleMapObject для отображения текущей позиции при 1+ GPS-точках; добавлена FAB кнопка «Найти себя» для центрирования карты; увеличен порог отображения темпа с 10м до 50м для стабилизации GPS; добавлено отображение текущего темпа во время пробежки.
- [x] После создания клуба «Пупкины» отображается наименование Club new-club-id, описание не соответствует введенному при создании, и создатель не является участником клуба.
  - Решение (2026-02-08): Создана миграция 010_clubs.sql с таблицей clubs; реализован ClubsRepository; обновлены POST /api/clubs и GET /api/clubs/:id для работы с БД; при создании клуба создатель автоматически добавляется в club_members со статусом active.
- [x] События, которые уже прошли, отображаются со статусом «Открыто».
  - Решение (2026-02-08): Добавлена миграция 011_events_end_date_time.sql с полем end_date_time; обновлены Event entity, DTO и EventsRepository; реализована функция computeEventStatus для time-based перехода в COMPLETED если endDateTime прошло.

#### Feedback (2026-02-08)

##### Клубы
- [x] Создатель клуба — Администратор (исправлено 2026-02-08): добавлено поле role в club_members (миграция 013), создатель получает роль leader; добавлен метод countActiveMembers(); GET /api/clubs/:id возвращает реальное количество участников.

##### События
- [x] Вкладка «События»: фильтр «Только открытые» показывал прошедшие события (исправлено 2026-02-08): добавлено условие (end_date_time IS NULL OR end_date_time > NOW()) в фильтр EventsRepository.findAll().

#### Feedback (2026-02-08, UX и данные)

Проверено по коду проекта. Ниже — уточнённые формулировки и места в коде.

##### Сообщения (вкладка «Сообщения»)
- [x] **Клубы отображаются не названием, а плейсхолдером «Club &lt;uuid&gt;»**
  - **Где:** В списке клубов (`ClubMessagesTab`) и в заголовке открытого чата показывается `chat.clubName`; при его отсутствии — `clubId`. Источник данных: `GET /api/messages/clubs`.
  - **Причина:** В `backend/src/api/messages.routes.ts` (GET /clubs) используется `clubMembersRepo.findActiveByUser(user.id)`, который возвращает только `ClubMembershipRow` (id, clubId, userId, status, role) — без названия клуба. В ответ клиенту подставляется `clubName: \`Club ${membership.clubId}\`` (строка 65), т.е. буквально «Club» + UUID.
  - **Что нужно:** Возвращать реальное название клуба в ответе GET /api/messages/clubs. В репозитории уже есть `findActiveClubsByUser(userId)` (`club_members.repository.ts`), возвращающий `ActiveUserClubMembershipRow` с полем `clubName` (JOIN с `clubs`). В `messages.routes.ts` заменить вызов `findActiveByUser` на `findActiveClubsByUser` и в маппинге в `ClubChatViewDto` использовать `membership.clubName`. На mobile парсер `ClubChatModel.fromJson` уже ожидает `clubName` — менять не требуется.

##### Клуб (экран деталей клуба)
- [x] **Нет просмотра списка участников и редактирования ролей**
  - **Где:** `mobile/lib/features/club/club_details_screen.dart`. На экране есть: название, город, метрики (участники/территории/рейтинг), кнопка «Чат клуба», описание, для лидера — «Редактировать», для участника — «Вы в клубе» / «Выйти из клуба». Блока «Участники» (список членов клуба с ролями) нет.
  - **Backend:** Нет эндпоинта вида `GET /api/clubs/:id/members`. Есть только `countActiveMembers` для отображения числа в метриках. Для списка участников с ролями нужен новый endpoint (например GET /api/clubs/:id/members с полями userId, displayName, role) и проверка прав (просмотр — участникам, смена ролей — только лидеру).
  - **Что нужно:** Backend: добавить GET /api/clubs/:id/members (и при необходимости PATCH для роли). Mobile: на `ClubDetailsScreen` добавить секцию «Участники» (список с именами и ролями); для лидера — возможность менять роль участника (member/trainer/leader).

##### Профиль (вкладка «Профиль»)
- [x] **Клуб отображается под ФИО, хотя есть отдельный блок «Клубы»**
  - **Где:** `mobile/lib/features/profile/profile_screen.dart` передаёт в `ProfileHeaderSection` `resolvedClub` (profile.club). В `mobile/lib/shared/ui/profile/header_section.dart` под отображаемым именем (ФИО) выводится: при наличии клуба — название клуба (кликабельно) и роль; иначе статус «Меркатель» или «Без клуба». Ниже по экрану есть отдельная карточка «Клубы» (`profileMyClubsButton`) с переходом на `/profile/clubs` (список всех клубов пользователя).
  - **Что нужно:** Убрать из шапки профиля (header) отображение одного клуба и роли под ФИО, чтобы не дублировать информацию. Идентификация «в клубе / не в клубе» и переход к клубам оставить через блок «Клубы».

- [x] **Личные данные всегда раскрыты, нет сворачивания**
  - **Где:** `ProfilePersonalInfoSection` (`mobile/lib/shared/ui/profile/personal_info_section.dart`) — карточка с заголовком «Личные данные» и полями: имя, фамилия, дата рождения, страна, пол, город. Нет кнопки «Показать/Скрыть» и состояния свёрнуто/развёрнуто.
  - **Что нужно:** Добавить возможность сворачивать/разворачивать блок личных данных по кнопке (например «Личные данные» с иконкой expand/collapse), по умолчанию можно оставить свёрнутым или развёрнутым по продуктовому решению.

##### События (вкладка «События», экран деталей события)
- [x] **Под «Точка старта» — плейсхолдер вместо карты**
  - **Где:** `mobile/lib/features/events/event_details_screen.dart`: секция «Точка старта» (eventStartPoint) — серый контейнер высотой 200 px с иконкой карты, текстом `eventMapTodo` и координатами `event.startLocation.latitude/longitude`. Реальной карты (Yandex MapKit) нет.
  - **Модель:** `EventDetailsModel` содержит `startLocation: EventStartLocation` (lat/lon) — данных достаточно для отображения точки на карте.
  - **Что нужно:** Заменить плейсхолдер на небольшую статичную карту (мини-карту) с одним маркером в точке старта. Ограничить размер «примерно один квартал» (масштаб/zoom подобрать по UX). Использовать тот же MapKit, что и на вкладке «Карта», в урезанном виде (без лишних слоёв).

- [x] **Тап по мини-карте — переход на вкладку «Карта» с точкой старта**
  - **Где:** Сейчас мини-карты нет, перехода по тапу тоже.
  - **Что нужно:** По нажатию на мини-карту точки старта переходить на вкладку «Карта» (главный экран карты), передавая параметры: центр = точка старта события, маркер/выделение точки старта, чтобы пользователь мог рассмотреть место в полном масштабе. Реализация: роут или query-параметры (например `/map?lat=...&lon=...&eventId=...`) и обработка на экране карты для центрирования и отображения маркера.

#### Feedback (2026-02-09, UX: события, карта, клубы)

##### События: переход с мини-карты на вкладку «Карта»
- [x] **Масштаб карты после перехода с события** (реализовано в коде)
  - `EventMiniMap` передаёт `lat`/`lon` через `context.go('/map?lat=$latitude&lon=$longitude')`. `MapScreen._onMapCreated` центрирует камеру на переданных координатах с zoom 15.0. Если в конкретной сборке масштаб не применяется — проверить, что используется актуальный билд.

##### Создание события (экран «Создать событие»)
- [ ] **Название города: показывается технический ID `spb` вместо «Санкт‑Петербург»** [Сложность: S]
  - **Где:** `mobile/lib/features/events/create_event_screen.dart`
    - Строки 51–77: `_loadDefaults()` — загрузка города через `ServiceLocator.currentCityService.getCurrentCity()`; строка 54: `_cityId = currentCityId`; строки 63–76: попытка получить `CityModel` и извлечь `city.name` в `_cityName`; строки 64–68: `catch (_) { city = null; }` — ошибки глотаются молча.
    - Строки 182–184: отображение — `cityDisplay = _cityName ?? _cityId ?? profileNotSpecified`. Если `_cityName == null`, пользователь видит технический `_cityId` (например, `spb`).
  - **Что нужно:**
    - Убрать `_cityId` из цепочки отображения (строки 182–184): показывать либо `_cityName`, либо явный текст «Выберите город».
    - В `_loadDefaults()` (строки 64–68): логировать ошибку загрузки города, показать пользователю уведомление.
  - **Backend:** Изменения не нужны.
  - **Зависимости:** Нет.

- [ ] **Поле «ID организатора» и «Тип организатора» выглядят техническими** [Сложность: M]
  - **Где:** `mobile/lib/features/events/create_event_screen.dart`
    - Строка 20: `_organizerIdController` — TextEditingController для ручного ввода UUID.
    - Строка 26: `_organizerType` — состояние, default `'club'`.
    - Строки 57–61: автозаполнение `organizerId` из `currentClubId` (если есть).
    - Строки 258–271: `TextFormField` для `organizerId` — видимое обязательное поле.
    - Строки 272–284: `DropdownButtonFormField` для `organizerType` (`club`/`trainer`).
    - Строки 138–165 (`events_service.dart`): `createEvent()` отправляет оба поля на backend.
  - **Что нужно:**
    - Убрать `TextFormField` для `organizerId` (строки 258–271) из UI. Оставить `_organizerIdController` для программного заполнения.
    - Автоопределение `organizerType` (строки 272–284): если есть `currentClubId` → `type='club'`, `organizerId=clubId`; если нет клуба → `type='trainer'`, `organizerId=userId`.
    - Опционально: заменить dropdown на переключатель «Событие клуба» / «Личное событие» с понятными подписями.
    - Обновить валидацию (строки 112–118): проверять наличие контекста (клуб/профиль) вместо ручного ввода.
  - **Backend:** Изменения не нужны.
  - **Зависимости:** Нет.

- [ ] **Задание точки старта: ручной ввод широты/долготы вместо выбора на карте** [Сложность: L]
  - **Где:** `mobile/lib/features/events/create_event_screen.dart`
    - Строки 21–22: два `TextEditingController` для latitude/longitude.
    - Строки 74–76: предзаполнение координатами центра города.
    - Строки 294–333: `Row` с двумя `TextFormField` для ручного ввода десятичных координат. Валидация — `double.tryParse()`.
  - **Что нужно:**
    - Заменить `Row` с lat/lon полями (строки 294–333) на кнопку «Выбрать точку на карте».
    - Реализовать «picker mode» для `MapScreen`: новый роут-параметр (например `mode=pick`); по тапу на карту — выбор координаты; подтверждение → `Navigator.pop(Point(lat, lon))`.
    - В `CreateEventScreen` заменить `TextEditingController` на state-переменные `double? _selectedLatitude / _selectedLongitude`. Отображать выбранные координаты как read-only текст.
    - Обновить валидацию: проверять, что координаты выбраны (not null).
    - Добавить роут в GoRouter для picker mode.
    - Опционально: обратное геокодирование для автозаполнения `locationName`.
  - **Backend:** Изменения не нужны.
  - **Зависимости:** MapScreen — добавить режим выбора точки; GoRouter — новый роут.

##### Карта (вкладка «Карта»)
- [ ] **На карте не отображаются события, хотя они приходят из API** [Сложность: M]
  - **Где:**
    - `mobile/lib/shared/models/map_data_model.dart` строка 19: поле `events: List<EventListItemModel>` — данные уже парсятся из `/api/map/data` (строки 42–44).
    - `mobile/lib/features/map/map_screen.dart`:
      - Строки 223–236: `_updateMapObjects()` — вызывает только `_updateTerritoryCircles()` (строка 228). Маркеров событий нет.
      - Строки 238–269: `_updateTerritoryCircles()` — создаёт `CircleMapObject` для территорий. Аналогичный паттерн можно использовать для событий.
      - Строка 623: `mapObjects: _territoryCircles` — только круги территорий.
  - **Что нужно:**
    - Добавить state: `List<PlacemarkMapObject> _eventMarkers = []` (после строки 63).
    - Создать метод `_updateEventMarkers()` (по аналогии со строками 238–269):
      - Итерация по `_mapData!.events`.
      - Для каждого события — `PlacemarkMapObject(mapId: MapObjectId('event_${event.id}'), point: Point(lat, lon), icon: PlacemarkIcon.single(...), onTap: () => _showEventBottomSheet(event))`.
    - Вызвать `_updateEventMarkers()` из `_updateMapObjects()` (строка 228).
    - Обновить `mapObjects` (строка 623): `[..._territoryCircles, ..._eventMarkers]`.
    - Добавить bottom sheet по тапу на маркер: краткая карточка события + кнопка перехода на `/event/{eventId}`.
    - Подготовить иконку маркера для событий (asset или programmatic).
  - **Backend:** Изменения не нужны — данные уже приходят.
  - **Зависимости:** Нет.

##### Клубы: выход лидера из клуба
- [ ] **Выход лидера не учитывает роль и количество участников** [Сложность: L]
  - **Где (backend):** `backend/src/api/clubs.routes.ts`
    - Строки 431–507: `POST /api/clubs/:id/leave`.
    - Строка 449: проверка существования клуба.
    - Строка 460: поиск пользователя по Firebase UID.
    - Строки 472–489: проверка активного membership.
    - Строка 491: `clubMembersRepo.deactivate(clubId, user.id)` — **без проверки роли**.
    - Доступные методы в `backend/src/db/repositories/club_members.repository.ts`: `findByClubAndUser()` (строки 97–103, возвращает membership с role), `countActiveMembers()` (строки 214–221), `findMembersByClub()` (строки 182–196, список всех участников с ролями).
  - **Где (mobile):**
    - `mobile/lib/shared/api/clubs_service.dart` строки 225–240: `leaveClub()` — без проверки роли.
    - `mobile/lib/features/club/club_details_screen.dart` строки 186–208: `_onLeaveClub()` — вызывает `leaveClub()` без учёта роли; строки 397–407: кнопка «Выйти из клуба» показана всем участникам.
  - **Проблема:** Лидер выходит как обычный участник → клуб остаётся без лидера или существует с 0 активных участников.
  - **Что нужно (backend):**
    - В `POST /api/clubs/:id/leave` (после строки 473): получить membership с ролью через `findByClubAndUser()`, если `role === 'leader'` → получить `countActiveMembers()`:
      - Если `memberCount > 1` → вернуть `400` с `code: 'leader_cannot_leave'`, `message: 'Leader must transfer leadership or disband club'`, `details: { memberCount }`.
      - Если `memberCount === 1` → разрешить выход или требовать явного удаления.
    - Новый endpoint `POST /api/clubs/:id/transfer-leadership` — передача роли `leader` другому участнику (проверка: вызывающий — leader, целевой — active member).
    - Новый endpoint `DELETE /api/clubs/:id` — удаление/деактивация клуба (только leader, деактивирует все memberships и сам клуб).
  - **Что нужно (mobile):**
    - В `_onLeaveClub()` (строки 186–208): проверять `club.userRole == 'leader'` до вызова API.
    - Если лидер и есть другие участники → показать диалог: «Передайте лидерство или распустите клуб» с кнопками «Передать» / «Распустить» / «Отмена».
    - Если лидер один → диалог подтверждения: «Вы единственный участник. Распустить клуб?».
    - Экран/диалог выбора нового лидера (список участников из `GET /api/clubs/:id/members`).
    - Обработка ошибки `leader_cannot_leave` (строки 200–204).
  - **Backend:** 2 новых endpoint'а + валидация роли в leave.
  - **Зависимости:** Экран участников клуба (уже реализован частично); `GET /api/clubs/:id/members` (уже есть).

#### Feedback (2026-02-09, баги после реализации)

##### Карта: переход с мини-карты события не приближает к нужной точке
- [x] **При нажатии на точку старта в событии карта переключается, но не приближается** [Сложность: S] ✅ Исправлено (v2): добавлен флаг `_isAnimatingToFocus` для блокировки bounds-clamping во время анимации; `_flyToFocusPoint` переведён на `async` с `await moveCamera` + задержка 100ms для native view
  - **Где:** `mobile/lib/features/events/event_details_screen.dart` — мини-карта события; `mobile/lib/app.dart` — роут `/map`; `mobile/lib/features/map/map_screen.dart` — обработка `focusLatitude`/`focusLongitude`.
  - **Симптом:** Пользователь нажимает на мини-карту события, экран переключается на вкладку «Карта», но карта не приближается к координатам события — остаётся на дефолтном zoom/позиции.
  - **Вероятная причина:** `context.go('/map?lat=$lat&lon=$lon')` переключает на вкладку карты через ShellRoute, но MapScreen может не получать новые параметры при переиспользовании виджета (GoRouter ShellRoute кэширует дочерний виджет).
  - **Что нужно:** Проверить, что `MapScreen` реагирует на изменение query-параметров (например через `didUpdateWidget` или `didChangeDependencies`), а не только в `_onMapCreated`. Если виджет уже создан, нужно повторно вызвать `moveCamera` при получении новых координат.

##### Создание события: организатор показывается как UUID вместо имени
- [x] **Созданное событие показывает UUID организатора вместо имени** [Сложность: S] ✅ Исправлено: приоритет firstName+lastName над name в organizer-display.ts
  - **Где:** `mobile/lib/features/events/create_event_screen.dart` — автозаполнение `_organizerIdController`; `backend/src/api/events.routes.ts` — `POST /api/events` и `GET /api/events/:id`; `backend/src/api/events.routes.ts` — resolve `organizerDisplayName`.
  - **Симптом:** При создании тренировки организатор отображается как `aa9cf865...` (UUID пользователя) вместо имени.
  - **Вероятная причина:** `organizerType = 'trainer'` + `organizerId = userId` — на backend resolve `organizerDisplayName` работает для `club` (ищет клуб по ID), но для `trainer` может не находить пользователя или возвращать пустое имя (fallback на UUID).
  - **Что нужно:**
    - Проверить backend resolve `getOrganizerDisplayName` для `organizerType = 'trainer'`: убедиться, что ищется пользователь по `organizerId` через `usersRepo.findById()` и возвращается `firstName + lastName`.
    - Проверить, что на mobile при `organizerType = 'trainer'` `organizerId` заполняется корректным user ID из профиля.

### Клубы MVP — чего не хватает для уверенного релиза

По спеке (product_spec §5.3, 16.5) и текущему состоянию кода. Роли в клубе уже приведены к **Лидер / Тренер / Участник** (миграция 014, ClubRole.TRAINER, профиль возвращает реальную роль).

#### Точка входа и список клубов
- [x] **Отдельная точка входа «Клубы»** — реализовано: кнопка «Мои клубы» в `ProfileScreen` → экран `MyClubsScreen` (`/profile/clubs`). Для полноценного «раздела Клубы» (список всех клубов города, не только своих) — отдельная задача.
- [ ] **Экран списка клубов по городу** [Сложность: S]
  - **Где (backend):** `backend/src/api/clubs.routes.ts` строки 55–115: `GET /api/clubs?cityId=` — **уже реализован**, возвращает список активных клубов по городу.
  - **Где (mobile service):** `mobile/lib/shared/api/clubs_service.dart` строки 23–52: `getClubs({required String cityId})` — **уже реализован**.
  - **Где (mobile UI):** Единственное место отображения — bottom sheet на карте (`mobile/lib/features/map/map_screen.dart` строки 400–502, `showClubs=true`). Отдельного экрана `ClubsListScreen` нет. Есть `MyClubsScreen` (`mobile/lib/features/profile/my_clubs_screen.dart`), но он показывает только «мои клубы», а не все по городу.
  - **Что нужно:**
    - Создать `mobile/lib/features/club/clubs_list_screen.dart`: принимает `cityId` через роут; вызывает `ClubsService.getClubs(cityId: cityId)`; отображает список с названием, городом, кол-вом участников; тап → `ClubDetailsScreen`.
    - Добавить GoRouter роут (например `/clubs?cityId=...`).
    - Добавить навигацию: кнопка «Все клубы города» в профиле или на экране клубов.
    - Опционально: вынести `ClubListItem` виджет из bottom sheet (строки 480–491) в shared-виджет для переиспользования.
  - **Backend:** Изменения не нужны.
  - **Зависимости:** Нет.

#### Профиль клуба (экран деталей)
- [ ] **Основатель/лидер в API и UI** [Сложность: S]
  - **Где (DB):** `backend/src/db/migrations/010_clubs.sql` строка 14: колонка `creator_id UUID NOT NULL REFERENCES users(id)` — **уже существует**.
  - **Где (entity):** `backend/src/modules/clubs/club.entity.ts` строка 42: поле `creatorId: string` — **уже маппится** в `clubs.repository.ts` строка 26.
  - **Где (API):** `backend/src/api/clubs.routes.ts` строки 174–249: `GET /api/clubs/:id` — строки 207–220: формирует DTO ответа, но **`creatorId` и `creatorName` не включены** в ответ.
  - **Где (mobile model):** `mobile/lib/shared/models/club_model.dart` (или `club_details_model.dart`) — **нет полей** `creatorId` / `creatorName`.
  - **Где (mobile UI):** `mobile/lib/features/club/club_details_screen.dart` строки 265–428 — **нет секции** «Основатель».
  - **Что нужно (backend):** В `clubs.routes.ts` (строки 207–220):
    - Добавить `creatorId: club.creatorId` в DTO.
    - Опционально: запросить имя создателя через `usersRepo.findById(club.creatorId)` → `creatorName: creator?.name ?? null`.
  - **Что нужно (mobile):**
    - Добавить поля `String? creatorId` и `String? creatorName` в модель клуба + `fromJson`.
    - На `ClubDetailsScreen` (после описания, около строки 342): добавить `ListTile` с иконкой, именем основателя и подписью «Основатель клуба».
    - i18n: ключи `clubFounder` / `clubFounderLabel` в оба ARB-файла.
  - **Backend:** Минимальные изменения (1–2 строки в DTO).
  - **Зависимости:** Нет.
- [x] **Роль текущего пользователя (myRole)** — реализовано: GET /api/clubs/:id возвращает userRole при isMember; ClubDetailsScreen использует userRole для разграничения действий.
- [ ] **Блок «События клуба»** [Сложность: M]
  - **Где (backend):** `backend/src/api/events.routes.ts` строки 48–111: `GET /api/events?clubId=` — строка 50: принимает `clubId`; строка 74: передаёт в `repo.findAll()`. **Уже работает.**
  - **Где (mobile service):** `mobile/lib/shared/api/events_service.dart` строки 25–95: `getEvents({ clubId, ... })` — строка 38: отправляет `clubId` в query params. **Уже работает.**
  - **Где (mobile UI):** `mobile/lib/features/club/club_details_screen.dart` строки 265–438 — секции: название, город, метрики, кнопка чата, описание, участники, редактирование, join/leave. **Блока «События» нет.**
  - **Что нужно (mobile):**
    - Добавить state: `Future<List<EventListItemModel>>? _eventsFuture` (после строки 41).
    - В `initState()` (строка 224): `_eventsFuture = ServiceLocator.eventsService.getEvents(cityId: widget.club.cityId, clubId: widget.clubId, onlyOpen: true)`.
    - Перед секцией участников (около строки 342): добавить `FutureBuilder` с заголовком «Ближайшие события», показывающий до 3 событий + кнопку «Все события клуба» → `/events?clubId=${club.id}`.
    - Empty state: «Нет предстоящих событий».
    - Error state: «Не удалось загрузить события».
    - Переиспользовать существующий виджет карточки события (если есть) или создать inline.
    - i18n: ключи `clubEventsTitle`, `clubEventsEmpty`, `clubEventsError`, `clubEventsViewAll` в оба ARB-файла.
  - **Backend:** Изменения не нужны.
  - **Зависимости:** Виджет карточки события (можно переиспользовать или создать).

#### Управление клубом (для лидера)
- [x] **Редактирование профиля клуба** — реализовано: PATCH /api/clubs/:id (только лидер), EditClubScreen, валидация UpdateClubSchema.

#### Уже сделано (для контекста)
- Роли: Лидер, Тренер, Участник (enum, БД, профиль возвращает реальную роль).
- Создатель клуба автоматически добавляется в club_members с ролью leader; membersCount считается по активным участникам.
- Join/leave, детали клуба (название, город, метрики, чат, описание), создание клуба, переход в чат клуба.

#### Детализация запроса пользователя (2026-02-08, клубы в профиле и сообщениях)

Контекст запроса:
- Пользователь сообщил: его профиль состоит в нескольких клубах, но это не отображается в UI.
- Требование 1: во вкладке «Профиль» нужна отдельная кнопка «Клубы» с показом всех клубов, где состоит пользователь.
- Требование 2: во вкладке «Сообщения → Клуб» сначала должен быть выбор клуба, и только после клика должен открываться чат выбранного клуба.

##### 1) Профиль: список всех клубов пользователя
- [x] **Отдельная точка входа «Клубы» в профиле** (реализовано 2026-02-08):
  - Где сейчас: в `ProfileScreen` нет отдельного экрана/кнопки «Мои клубы», отображается только агрегированный `club` + `primaryClubId`.
  - Нужно: добавить явную кнопку/плитку «Клубы» в профиле, ведущую на экран списка клубов пользователя.
- [x] **API для списка всех членств пользователя** (реализовано 2026-02-08):
  - Где сейчас: профиль (`GET /api/users/me/profile`) возвращает только один клуб (primary), этого недостаточно.
  - Нужно: вернуть все активные членства пользователя с базовой информацией по клубу (id, name, cityId/cityName, role, joinedAt).
  - Вариант MVP: добавить `GET /api/clubs/my` (предпочтительно для доменной логики клубов), не перегружать профиль лишними полями.
  - Контракт `GET /api/clubs/my`:
    - Auth: Bearer token (обязателен)
    - 200: `[{ id, name, description?, cityId, cityName?, status, role, joinedAt }]`
    - role: `member | trainer | leader`
    - Сортировка: по `joinedAt` по убыванию (сначала последний вступивший клуб)
    - 401: `{ code: "unauthorized", message: "Authorization required" | "User not found" }`
    - 500: `{ code: "internal_error", message: "Internal server error" }`
- [x] **Экран «Мои клубы» (mobile)** (реализовано 2026-02-08):
  - Список карточек клубов: название, город, роль пользователя (leader/trainer/member).
  - Клик по карточке: переход на `ClubDetailsScreen`.
  - Empty state: пользователь не состоит ни в одном клубе.
  - Error/retry state: по стандартному паттерну экранов mobile.

##### 2) Сообщения: выбор клуба перед открытием чата
- [x] **Разделить «выбор клуба» и «чат клуба»** (реализовано 2026-02-08):
  - `ClubMessagesTab` сначала показывает список клубов (`_buildClubList()`), чат открывается только после явного выбора (`_openClubChat(clubId)`).
- [x] **Список клубов в табе «Клуб»** (реализовано 2026-02-08):
  - Отображается список клубов пользователя с названиями; empty state при отсутствии клубов.
- [x] **Экран/состояние чата выбранного клуба** (реализовано 2026-02-08):
  - После выбора клуба показывается чат с историей + отправкой сообщений, есть кнопка возврата к списку клубов.
  - Переход из `ClubDetailsScreen` предвыбирает нужный клуб через `clubId` в роуте.

##### 3) Технические ограничения и согласованность MVP
- [x] Не ломать текущий контракт авторизации и проверки членства в backend chat API.
- [x] Для mobile не делать API-вызовы напрямую в `FutureBuilder.future`; кэшировать `Future` в `initState`.
- [x] Все новые пользовательские строки добавить в `mobile/l10n/app_ru.arb` и `mobile/l10n/app_en.arb`.
- [x] Приоритет MVP: сначала корректный выбор клуба и отображение членств, затем UX-улучшения (поиск, сортировка, бейджи непрочитанных).

##### 4) Критерии приёмки (DoD)
- [x] В профиле есть кнопка «Клубы», открывающая список всех клубов пользователя.
- [x] Пользователь, состоящий в нескольких клубах, видит все свои клубы в одном экране.
- [x] Во вкладке «Сообщения → Клуб» первым шагом отображается список клубов, а не чат.
- [x] Чат клуба открывается только после выбора клуба пользователем.
- [x] Переход из карточки клуба в сообщения открывает чат именно этого клуба.

##### 5) План параллельной реализации (независимые подзадачи)

1. **API-контракт (фиксируется один раз)** ✅
   - Выход: короткая спека `GET /api/clubs/my` (поля, сортировка, ошибки, примеры).

2. **Backend: endpoint списка клубов пользователя** ✅
   - Выход: `GET /api/clubs/my`, репозиторный метод, unit/integration тесты.

3. **Mobile data layer: модель + сервис «мои клубы»** ✅
   - Выход: модель `MyClubModel` и метод `ClubsService.getMyClubs()`.

4. **Mobile Profile: CTA «Клубы»** ✅
   - Выход: отдельная кнопка/плитка «Клубы» в `ProfileScreen` с навигацией.

5. **Mobile Profile: экран «Мои клубы»** ✅
   - Выход: список клубов пользователя, empty/error/retry, переход в `ClubDetailsScreen`.

6. **Mobile Messages: экран выбора клуба** ✅
   - Выход: в табе «Клуб» первым шагом отображается список клубов, без авто-открытия чата.
   - Зависимости: п.3.
   - Параллельность: можно делать отдельно от чата выбранного клуба.

7. **Mobile Messages: чат выбранного клуба** ✅
   - Выход: состояние «клуб выбран», история + отправка сообщений, возврат к выбору клуба.
   - Зависимости: п.6.
   - Параллельность: независим от профиля.

8. **Навигация и deep-link клуба в сообщения** ✅
   - Выход: поддержка `clubId` в маршруте (`/messages?tab=club&clubId=...`) и переход из `ClubDetailsScreen`.
   - Зависимости: нет, интеграция с п.6/п.7 на финале.
   - Параллельность: может идти отдельным потоком.

9. **i18n + документация + приёмка** ✅
   - Выход: новые ключи в `mobile/l10n/app_ru.arb` и `mobile/l10n/app_en.arb`, обновления `docs/progress.md`, `docs/changes/*`, финальный прогон DoD.
   - Зависимости: после слияния п.2–п.8.
   - Параллельность: финальный этап, выполняется последним.
