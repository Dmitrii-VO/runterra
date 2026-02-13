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

Подробный список исправленных ошибок и контекст их появления/исправления ведётся в:
- `docs/errors-runbook.md` — runbook по ошибкам в проде и dev
- `docs/progress.md` — хронологический прогресс и багфиксы

### История и аудит

Ранее в этом файле хранились большие списки аудитов, фидбека и уже выполненных задач по backend, mobile и продуктовым фичам.
Сейчас фактический статус и история изменений ведутся в:
- `docs/progress.md` — ежедневный прогресс и принятые решения
- `docs/changes/*` — детальные изменения по модулям (events, runs, clubs, messages, map и т.д.)

Для актуального состояния системы и подробностей реализации см. эти файлы документации.

### Новый фидбек (2026-02-12, продукт/UX)

- **Run / вкладка «Пробежка»**
  - Вместо текста кнопки «Начать пробежку» использовать короткий вариант «Старт» в момент фактического запуска пробежки.
  - Добавить возможность ставить пробежку на паузу (сейчас можно только завершить сессию).

- **Клубы**
  - Сделать вход в клуб по запросу: пользователь отправляет заявку, администратор/лидер подтверждает, и только после этого даётся доступ в клуб.
  - Проработать модель нескольких чатов у клуба (подчаты): отдельные каналы для тренировок, болталки, результатов и т.п.

- **Сообщения**
  - Во вкладке «Сообщения» после отправки сообщения текстовое поле и клавиатура должны оставаться в предсказуемом состоянии (не «прыгать» и не закрывать ввод неожиданно; требуется уточнить целевое поведение и доработать UX).

- **События**
  - Во вкладке «События» на экране деталей события кнопка «Отметиться» как отдельное действие не нужна — требуется пересмотреть UX check‑in.

- **Тренеры**
  - Для роли тренера нужен отдельный продуманный функционал (управление тренировками, доступ к клубам, коммуникация с участниками и т.д.); требуется отдельная проработка требований и UX.

#### Анализ и точки изменений в коде (детально)

- **Run / вкладка «Пробежка»**
  - **Где в коде (mobile):**
    - Экран: `RunScreen` / `RunTrackingScreen` (см. `docs/changes/run-history.md`).
    - Логика: `RunService`, модели `RunSession`, `RunSessionStatus`.
    - UI-компоненты: кнопки управления бегом (start/stop) в `run_screen.dart` / связанных виджетах.
    - Тексты: ключи `runStart*`, `runStop*` и др. в `mobile/l10n/app_*.arb`.
  - **Что менять:**
    - **Переименование кнопки:** заменить текст «Начать пробежку» на «Старт»:
      - Обновить ARB-ключи или значения (RU/EN) и места использования в `RunScreen`.
      - Убедиться, что новые тексты не ломают существующие тесты (widget‑тесты, snapshot‑проверки, если есть).
    - **Пауза в пробежке:**
      - Расширить модель `RunSessionStatus` (например, `idle/running/paused/completed`) и саму `RunSession` (флаг или поля для накопления времени в паузе).
      - В `RunService`:
        - Ввести методы `pauseRun()` и `resumeRun()`, определить, как они влияют на таймер и сбор GPS‑точек.
        - При паузе — останавливать обновление таймера/дистанции и/или временно отключать подписку на поток GPS (или игнорировать новые точки).
        - Обновить сериализацию при `submitRun()`, чтобы паузы не ломали расчёт duration/pace (возможно, duration = только активное время).
      - В `RunScreen` / `RunTrackingScreen`:
        - Добавить кнопку «Пауза» в состоянии `running` и «Продолжить» в состоянии `paused`, пересобрать layout (кнопки старт/стоп/пауза).
        - Обновить отображение статуса и логики блокировки других действий (например, нельзя начать новую пробежку, пока текущая на паузе).
      - Проверить влияние на:
        - Экран результата (метрики не должны считаться по времени, проведённому в паузе, если это требуется по продукту).
        - Историю пробежек и карту (как рисовать маршрут с паузами — единая полилиния или несколько сегментов).
  - **Риски/вопросы:** не ломаем существующий контракт backend `CreateRunDto`; если duration считается на клиенте — важно согласовать, суммируем ли только активное время или всё с паузами.

- **Клубы (вход по запросу + несколько чатов)**
  - **Где в коде (backend):**
    - БД: таблицы `clubs`, `club_members` (миграции 010–014).
    - Репозитории: `ClubMembersRepository` (`findByClubAndUser`, `countActiveMembers`, `findMembersByClub`, `findActiveClubsByUser`).
    - Роуты: `backend/src/api/clubs.routes.ts` (`POST /api/clubs/:id/join`, `POST /api/clubs/:id/leave`, `GET /api/clubs/my` и т.д.).
    - Чаты: `backend/src/api/messages.routes.ts`, сущность/таблица `messages`, WS‑сервер `chatWs.ts`.
  - **Где в коде (mobile):**
    - Клубы: `ClubsService`, `ClubDetailsScreen`, `MyClubsScreen`, модели клуба/членства.
    - Сообщения: `MessagesService`, `ClubMessagesTab`, `ClubChatModel`, экран чата клуба.
  - **Вход по запросу (membership workflow):**
    - **БД и доменная модель:**
      - Добавить статусы членства: либо расширить существующее поле `status` в `club_members` (enum `pending/active/rejected/blocked`), либо ввести отдельное поле для заявок — рекомендуется расширить статус.
      - Миграция: обновить тип `status`, данные по умолчанию для текущих записей (все существующие сделать `active`).
    - **API backend:**
      - Обновить `POST /api/clubs/:id/join`:
        - Вместо мгновенного active‑членства создавать заявку `status = pending`.
        - Для уже активных участников возвращать корректную ошибку или id существующего membership (без дублей).
      - Добавить эндпоинты для админки клуба:
        - `GET /api/clubs/:id/membership-requests` — список pending‑заявок (только для лидера/тренера с нужной ролью).
        - `POST /api/clubs/:id/membership-requests/:userId/approve|reject` — управление заявками (можно объединить в один PATCH c действием).
      - В `GET /api/clubs/:id` и `GET /api/clubs/my` добавить/уточнить поля membershipStatus, чтобы UI мог показывать «заявка отправлена»/«в клубе».
    - **Mobile:**
      - В `ClubsService`:
        - Обновить `joinClub()` под новый контракт (обработка статуса `pending`).
        - Добавить методы для получения заявок и подтверждения/отклонения (будущие экраны лидера).
      - В `ClubDetailsScreen`:
        - Добавить состояния кнопки: «Отправить заявку» → «Заявка отправлена» → «Вы в клубе».
        - Скрывать/блокировать часть функционала, пока membership не `active`.
      - В `MyClubsScreen`/профиле:
        - Отображать отдельным образом pending‑клубы (можно отдельным списком или пометкой).
  - **Несколько чатов у клуба (подчаты):**
    - **БД/модель:**
      - Ввести сущность «канал клуба» (например, таблица `club_channels` с полями `id`, `club_id`, `type`, `name`, `description`, `is_default`).
      - Связать существующие сообщения `messages` с каналами (`channel_id` уже используется, сейчас формат `club:{clubId}`, нужно адаптировать к `club:{clubId}:{channelId}` или хранить отдельный `club_channel_id`).
    - **API backend:**
      - Эндпоинты:
        - `GET /api/clubs/:id/channels` — список подчатов клуба.
        - `POST /api/clubs/:id/channels` — создание нового подчата (ограничить лидером/тренером).
        - Обновить `GET/POST /api/messages/clubs/:clubId` так, чтобы они принимали `channelId` (query/path), и фильтровали/создавали сообщения по конкретному подчату.
      - Обновить WS‑формат канала (`club:{clubId}:{channelId}`) и проверку членства в `chatWs.ts`.
    - **Mobile:**
      - Модели: добавить `ClubChannelModel` и поле `channels` в модели клуба или отдельный сервис `getClubChannels`.
      - `MessagesService`:
        - Методы `getClubChannels(clubId)`, `getClubChatMessages(clubId, channelId, ...)`, `sendClubMessage(clubId, channelId, text)`.
      - `ClubMessagesTab`:
        - Первый экран — выбор подчата (список каналов), затем сам чат выбранного подчата.
        - Навигация из `ClubDetailsScreen` с выбранным типом чата (например, «Тренировки» → сразу соответствующий подчат).

- **Сообщения (поведение поля ввода)**
  - **Где в коде (mobile):**
    - `ClubMessagesTab` / экран чата клуба (UI списка + composer).
    - Вспомогательные виджеты ввода (TextField, `FocusNode`, контроллеры прокрутки).
  - **Что менять:**
    - Явно зафиксировать сценарий после `sendClubMessage()`:
      - Не дергать `unfocus()` на поле ввода, если мы хотим оставить клавиатуру открытой.
      - Контролировать scroll: вызывать прокрутку к последнему сообщению только один раз и только если пользователь не скроллит историю (guard от «прыжков»).
    - Вынести composer в отдельный виджет с явной передачей `FocusNode` и `ScrollController`, чтобы избежать побочных эффектов при rebuild всего экрана.
    - Добавить тест/мануальный сценарий: отправка серии сообщений, длинный список, поведение клавиатуры/скролла.

- **События (кнопка «Отметиться»)**
  - **Где в коде (mobile):**
    - `EventDetailsScreen` (кнопки join/leave/check‑in), состояние `EventDetailsModel` (флаги участия и check‑in).
    - `EventsService.checkInEvent` (HTTP‑вызов `POST /api/events/:id/check-in`).
  - **Что менять:**
    - Определить новый UX:
      - Либо убрать отдельную кнопку «Отметиться» и запускать check‑in автоматически (например, при старте пробежки по событию или при достижении точки старта).
      - Либо переназвать/переместить кнопку, чтобы она не «мозолила глаза» как отдельное действие.
    - В коде:
      - Удалить/спрятать существующую кнопку в `EventDetailsScreen` и связанные локализации (или переиспользовать под новое действие).
      - Обновить логику, где вызывается `checkInEvent`: связать её с Run‑флоу или другим действием (потребуется дополнительная навигация/контекст события в Run).
    - Возможный backend‑апдейт: если check‑in станет привязан к пробежке, можно связать его с `runId` (новое поле/endpoint).

  - **Brainstorm: вкладка События MVP (Gemini, 2026-02-13)**
    - **Контекст из product_spec 5.5:** Check-in с GPS 200–500 м от старта; для зачёта — минимум 1 км в территории; сценарий 16.3 — кнопки «Начать пробежку» и «Завершить».
    - **Идея:** Check-in доступен только при выполнении условий: (1) пользователь записан на событие; (2) время события близко (30 мин до — 1 ч после); (3) пользователь в геозоне (200–500 м от старта).
    - **Варианты UX для check-in:**

      | Вариант | Описание | Плюсы | Минусы |
      |---------|----------|-------|--------|
      | **Swipe-to-run** | Карточка «Начать пробежку» со свайпом на экране события | Интерактивно, меньше случайных нажатий | Нужно открыть экран события |
      | **Push-уведомление** | Push, когда пользователь на месте и вовремя | Проактивно | Нужны разрешения, может быть навязчиво |
      | **QR-код** | Организатор показывает QR, участник сканирует | Надёжное подтверждение присутствия | Нужны действия организатора, реализация сканера |

    - **Рекомендация Gemini для MVP:** Swipe-to-run — карточка с предложением начать пробежку, активация свайпом. Появляется только когда пользователь на месте и в окне check-in.
    - **Примечание:** Backend check-in: окно 15 мин до — 30 мин после старта, радиус 500 м. Роут событий в Runterra: `/event/:id`.
    - **Принятые решения (2026-02-13):** Оформлены в `docs/changes/2026-02-13-events-checkin-decisions.md`. Кратко: Swipe-to-run + Check-in+Run; окно 30 мин до — 1 ч после; проверка 1 км в территории; фильтр «Участвую»; вне условий — карточка disabled с пояснением.

- **Тренеры (роль и функционал)**
  - **Где в коде (backend):**
    - `club_members.role` (enum leader/trainer/member), миграция 014.
    - `clubs.routes.ts` — возвращает роль пользователя в клубе (`userRole`, `myRole`).
    - `events.routes.ts` — уже поддерживает `organizerType`/`organizerId` (trainer/club).
    - `users/profile` — роль в клубе и клубы пользователя.
  - **Где в коде (mobile):**
    - Модели клуба/членства (поле `role`), `ClubDetailsScreen`, `MyClubsScreen`.
    - `CreateEventScreen` — выбор организатора (клуб/тренер).
  - **Что менять (потенциально):**
    - Сформулировать доменную модель тренера:
      - Какие действия ему доступны: создание/редактирование событий, просмотр участников и их результатов, управление тренировками.
      - Как это отличается от лидера (leader) и обычного участника.
    - По коду:
      - Backend: добавить проверки ролей в `events.routes.ts` и `clubs.routes.ts` (например, создавать события клуба могут `leader` и `trainer`).
      - Mobile: добавить отдельный раздел/экран для тренера (список его событий, управление тренировками клуба, быстрые действия из профиля или вкладки клуба).
      - Чаты: возможно, отдельные тренерские чаты/подчаты (см. раздел про несколько чатов).
  - **Открытые вопросы:** конкретный список прав тренера и приоритет этой роли в MVP‑роадмапе (что обязательно к релизу, а что можно отложить).

#### Разбиение на конкретные задачи (Z1–Z9 — выполнено)

Все 9 задач реализованы (коммиты cf855bc, df7980a, 0e39c11, 3b1d22b). Детали в docs/progress.md.

- **Z1. Run / вкладка «Пробежка» — переименовать кнопку** ✅
  - Обновить тексты в `mobile/l10n/app_*.arb` с «Начать пробежку» → «Старт».
  - Обновить использование этих ключей в `RunScreen`/`RunTrackingScreen` и проверить UI.

- **Z2. Run / вкладка «Пробежка» — пауза в пробежке** ✅
  - Добавить статус `paused` в `RunSessionStatus` и поля в `RunSession`.
  - В `RunService` реализовать `pauseRun()`/`resumeRun()`, остановку таймера и GPS-сбора в паузе.
  - В `RunScreen`/`RunTrackingScreen` добавить кнопки «Пауза»/«Продолжить» и логику переключения состояний.
  - Пройтись по экранам результата/истории, убедиться, что duration/pace считаются корректно с учётом пауз.

- **Z3. Клубы — модель членства «по запросу» (backend)** ✅
  - Добавить новые значения статуса (`pending/approved/rejected`) в `club_members` (миграция + enum в коде).
  - Обновить `ClubMembersRepository` и типы DTO, чтобы статус учитывался во всех выборках.
  - Изменить `POST /api/clubs/:id/join` на создание заявки со статусом `pending`.

- **Z4. Клубы — управление заявками (backend + mobile)** ✅
  - Добавить эндпоинты `GET /api/clubs/:id/membership-requests` и `POST/PATCH /api/clubs/:id/membership-requests/:userId` (approve/reject).
  - Добавить проверки ролей (leader/trainer) на этих эндпоинтах.
  - В `ClubsService` добавить методы для загрузки/подтверждения заявок.
  - Реализовать на mobile простой экран/листинг запросов для лидера клуба.

- **Z5. Клубы — несколько чатов (структура каналов)** ✅
  - Спроектировать и создать таблицу `club_channels` (id, club_id, type, name, is_default).
  - Обновить `messages`/WS так, чтобы сообщения были привязаны к конкретному каналу (channelId или club_channel_id).
  - Добавить эндпоинт `GET /api/clubs/:id/channels` и, при необходимости, `POST /api/clubs/:id/channels`.

- **Z6. Клубы — несколько чатов (mobile)** ✅
  - Добавить модель `ClubChannelModel` и методы `getClubChannels` в `MessagesService`/`ClubsService`.
  - Обновить `ClubMessagesTab` под два шага: выбор подчата → экран чата подчата.
  - Обновить навигацию из `ClubDetailsScreen` с возможностью перехода сразу в нужный подчат.

- **Z7. Сообщения — стабилизация поведения ввода** ✅
  - Проанализировать текущий код composer’а в `ClubMessagesTab` (FocusNode, scroll).
  - Зафиксировать целевое поведение (оставлять клавиатуру открытой после отправки) и внести правки в логику `sendMessage`.
  - При необходимости вынести composer в отдельный виджет с управляемым `FocusNode` и `ScrollController`.

- **Z8. События — Swipe-to-run check-in (решения приняты 2026-02-13)** ✅
  - Решения зафиксированы в `docs/changes/2026-02-13-events-checkin-decisions.md`.
  - Реализовать: карточка Swipe-to-run на `EventDetailsScreen` (свайп = check-in + старт пробежки); фильтр «Участвую»; вне условий — disabled с пояснением.
  - Backend: окно 30 мин до — 1 ч после; проверка 1 км в территории; параметр `participantOnly` в GET /api/events.

- **Z9. Тренеры — зафиксировать доменную модель и права** ✅
  - В отдельном документе (например, `docs/adr/00xx-trainers-role.md`) описать права и обязанности тренера vs лидера.
  - На backend обновить проверки ролей в `clubs.routes.ts`/`events.routes.ts` согласно принятой модели.
  - На mobile добавить минимум UI для тренера (отдельная секция/экран), использующий уже существующие API.


План реализации: Новый фидбек (2026-02-12, продукт/UX)

 Контекст

 В infra/README.md раздел «Новый фидбек» содержит 5 направлений улучшений продукта, разбитых на 9 задач (Z1–Z9). Ниже —
  верифицированный план реализации на основе исследования текущего кода.

 ---
 Приоритизация и порядок
 ┌───────────┬──────────────────────────────────────────┬─────────────┬─────────────────────┐
 │ Приоритет │                  Задача                  │  Сложность  │     Зависимости     │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 1         │ Z1. Переименовать кнопку «Старт»         │ Trivial     │ —                   │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 2         │ Z7. Стабилизация ввода сообщений         │ Low         │ —                   │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 3         │ Z8. Убрать кнопку «Отметиться»           │ Low         │ Нужно решение по UX │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 4         │ Z2. Пауза в пробежке                     │ Medium      │ —                   │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 5         │ Z3. Членство по запросу (backend)        │ Medium      │ —                   │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 6         │ Z4. Управление заявками (backend+mobile) │ Medium      │ Z3                  │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 7         │ Z5. Подчаты клубов (backend)             │ High        │ —                   │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 8         │ Z6. Подчаты клубов (mobile)              │ High        │ Z5                  │
 ├───────────┼──────────────────────────────────────────┼─────────────┼─────────────────────┤
 │ 9         │ Z9. Тренеры — доменная модель            │ Design only │ —                   │
 └───────────┴──────────────────────────────────────────┴─────────────┴─────────────────────┘
 ---
 Z1. Run — переименовать кнопку «Начать пробежку» → «Старт»

 Файлы:
 - mobile/l10n/app_ru.arb — ключ runStart: "Начать пробежку" → "Старт"
 - mobile/l10n/app_en.arb — ключ runStart: "Start run" → "Start"

 Что делать:
 - Обновить значения ключа runStart в обоих ARB-файлах
 - Кнопка в run_tracking_screen.dart:357-364 использует AppLocalizations.of(context)!.runStart — менять не нужно

 Проверка: Запустить приложение, перейти на вкладку Run, убедиться что кнопка показывает «Старт» / «Start»

 ---
 Z2. Run — пауза в пробежке

 Файлы для изменения:
 - mobile/lib/shared/models/run_session.dart — добавить paused в RunSessionStatus
 - mobile/lib/shared/api/run_service.dart — добавить pauseRun() / resumeRun()
 - mobile/lib/features/run/run_tracking_screen.dart — UI кнопок пауза/продолжить, логика таймера
 - mobile/l10n/app_en.arb + app_ru.arb — новые ключи

 Изменения в модели:
 enum RunSessionStatus { running, paused, completed }
 Добавить поля в RunSession:
 - Duration accumulatedDuration — накопленное активное время до паузы
 - DateTime? pausedAt — время последней паузы (для расчёта)

 Изменения в RunService:
 - pauseRun(): сохранить accumulatedDuration = now - startedAt - уже_накопленные_паузы, остановить GPS-подписку,
 установить status = paused
 - resumeRun(): записать новый startedAt или использовать accumulatedDuration как base, возобновить GPS, установить
 status = running
 - stopRun(): при расчёте duration использовать accumulatedDuration + (now - lastResumedAt) если running, или просто
 accumulatedDuration если paused
 - GPS: при паузе — отменить _positionSubscription, при resume — пересоздать

 Изменения в RunTrackingScreen:
 - Таймер (строки 69-77): при paused показывать замороженное время (accumulatedDuration), не инкрементировать
 - UI кнопок (строки 357-451):
   - Состояние running: показывать «Пауза» (иконка pause) + «Завершить» (иконка stop, красная)
   - Состояние paused: показывать «Продолжить» (иконка play_arrow) + «Завершить» (иконка stop, красная)
 - Вынести _TrackingState → добавить paused

 Новые ARB-ключи:
 - runPause / runResume (EN: "Pause" / "Resume", RU: "Пауза" / "Продолжить")

 На backend ничего менять не нужно — CreateRunDto принимает duration как число, клиент будет отправлять только активное
  время.

 Маршрут на карте: единая полилиния (без разрывов в местах паузы). GPS-точки во время паузы не записываются, поэтому
 линия просто соединит последнюю точку до паузы с первой после.

 Проверка: Начать пробежку → поставить на паузу → убедиться что таймер остановился, GPS не записывается → продолжить →
 завершить → проверить что duration = только активное время

 ---
 Z3. Клубы — членство по запросу (backend)

 Текущее состояние: club_members.status уже имеет CHECK constraint с 'pending' в списке допустимых значений (миграция
 006). ClubMembersRepository.create() принимает status параметр. Т.е. схема БД уже готова.

 Файлы для изменения:
 - backend/src/api/clubs.routes.ts — изменить POST /join и GET /:id
 - backend/src/db/repositories/club_members.repository.ts — добавить методы для pending

 Изменения в clubs.routes.ts:
 - POST /api/clubs/:id/join (строки 355-434):
   - Вместо create(clubId, userId, 'active', 'member') → create(clubId, userId, 'pending', 'member')
   - Вместо реактивации activate() для inactive → создавать новый pending
   - Возвращать { status: 'pending' } вместо active membership
 - GET /api/clubs/:id (строки 174-260):
   - Добавить membershipStatus в ответ (для показа «Заявка отправлена» в UI)

 Изменения в ClubMembersRepository:
 - Добавить findPendingByClub(clubId) — список pending заявок
 - Добавить approveMembership(clubId, userId) — status: 'pending' → 'active'
 - Добавить rejectMembership(clubId, userId) — status: 'pending' → 'inactive' или удалить запись

 Проверка: POST /join → проверить что создаётся запись со status=pending. GET /clubs/:id показывает
 membershipStatus=pending.

 ---
 Z4. Клубы — управление заявками (backend + mobile)

 Зависит от Z3.

 Backend — новые эндпоинты в clubs.routes.ts:
 - GET /api/clubs/:id/membership-requests — список pending заявок (только leader/trainer)
 - POST /api/clubs/:id/membership-requests/:userId/approve — одобрить (leader/trainer)
 - POST /api/clubs/:id/membership-requests/:userId/reject — отклонить (leader/trainer)

 Mobile — файлы:
 - mobile/lib/shared/api/clubs_service.dart — методы getMembershipRequests(), approveMembership(), rejectMembership()
 - mobile/lib/features/club/club_details_screen.dart — обновить кнопку Join:
   - isMember == false && membershipStatus == null → кнопка «Подать заявку»
   - membershipStatus == 'pending' → disabled кнопка «Заявка отправлена»
   - membershipStatus == 'active' → текущее поведение «Вы участник»
 - Новый виджет/экран: список заявок для лидера клуба (показывать на ClubDetailsScreen или отдельным экраном)

 Новые ARB-ключи: clubRequestJoin, clubRequestPending, clubRequestApprove, clubRequestReject, clubMembershipRequests

 Проверка: Пользователь A подаёт заявку → лидер видит заявку в списке → одобряет → пользователь A видит себя участником

 ---
 Z5. Клубы — подчаты (backend)

 Файлы для изменения:
 - Новая миграция backend/src/db/migrations/015_club_channels.sql
 - Новый репозиторий backend/src/db/repositories/club_channels.repository.ts
 - backend/src/api/clubs.routes.ts или новый channels.routes.ts — эндпоинты
 - backend/src/api/messages.routes.ts — добавить channelId в запросы
 - backend/src/ws/chatWs.ts — обновить формат канала

 Миграция:
 CREATE TABLE club_channels (
   id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
   club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
   type VARCHAR(50) NOT NULL DEFAULT 'general',
   name VARCHAR(100) NOT NULL,
   is_default BOOLEAN NOT NULL DEFAULT false,
   created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
 );
 -- Создать default-каналы для существующих клубов
 INSERT INTO club_channels (club_id, type, name, is_default)
   SELECT id, 'general', 'Общий', true FROM clubs WHERE status = 'active';
 -- Добавить channel_id в messages (nullable для обратной совместимости)
 ALTER TABLE messages ADD COLUMN club_channel_id UUID REFERENCES club_channels(id);

 Эндпоинты:
 - GET /api/clubs/:id/channels — список каналов клуба
 - POST /api/clubs/:id/channels — создать канал (leader/trainer)
 - Обновить GET/POST /api/messages/clubs/:clubId — добавить query param channelId

 WebSocket: формат club:{clubId}:{channelId}

 Проверка: Создать клуб → автоматически появляется канал «Общий» → отправить сообщение в канал → получить через WS

 ---
 Z6. Клубы — подчаты (mobile)

 Зависит от Z5.

 Файлы:
 - Новая модель mobile/lib/shared/models/club_channel_model.dart
 - mobile/lib/shared/api/messages_service.dart — добавить getClubChannels(), обновить getClubChatMessages() и
 sendClubMessage() с channelId
 - mobile/lib/features/messages/tabs/club_messages_tab.dart — добавить экран выбора канала между списком клубов и чатом

 Навигация: Список клубов → Список каналов клуба → Чат канала

 Проверка: Открыть клуб → увидеть список каналов → зайти в канал → отправить/получить сообщение

 ---
 Z7. Сообщения — стабилизация ввода

 Текущее состояние: В club_messages_tab.dart нет явного FocusNode. TextField управляет фокусом автоматически. После
 sendClubMessage() вызывается _messageController.clear() (строка 279), но фокус не контролируется.

 Файлы:
 - mobile/lib/features/messages/tabs/club_messages_tab.dart

 Изменения:
 1. Добавить FocusNode _focusNode в state (dispose в dispose())
 2. Передать в TextField: focusNode: _focusNode
 3. В _sendMessage() после _messageController.clear() — вызвать _focusNode.requestFocus() чтобы клавиатура оставалась
 открытой
 4. В _scrollToBottom() — использовать WidgetsBinding.instance.addPostFrameCallback для предотвращения конфликта scroll
  + rebuild
 5. Auto-scroll только если пользователь был near bottom (уже есть guard _isNearBottom() — убедиться что он работает
 корректно)

 Проверка: Отправить несколько сообщений подряд → клавиатура не закрывается → список не прыгает

 ---
 Z8. События — Swipe-to-run check-in (решения: docs/changes/2026-02-13-events-checkin-decisions.md)

 Текущее состояние: Кнопка «Отметиться» в event_details_screen.dart (строки 422-442) — убрать/заменить.

 Принятые решения: Swipe-to-run; Check-in+Run; окно 30 мин до — 1 ч после; проверка 1 км; фильтр «Участвую»;
 вне условий — disabled с пояснением.

 Backend:
 - events.repository.ts: окно check-in 30 мин до — 1 ч после; проверка 1 км в территории
 - events.routes.ts: GET /api/events — параметр participantOnly (joinedByMe)
 - EventsRepository.findAll — поддержка participantOnly + userId

 Mobile:
 - EventDetailsScreen: карточка Swipe-to-run (свайп → checkInEvent + переход на Run с eventId)
 - Вне условий (не в геозоне / вне окна): карточка disabled с пояснением
 - EventsScreen: фильтр «Участвую» (participantOnly)
 - EventsService.getEvents — параметр participantOnly

 Проверка: Участник события → открыть детали → при на месте и в окне — свайп → check-in + старт пробежки

 ---
 Z9. Тренеры — зафиксировать доменную модель

 Это задача на проектирование, не на код.

 Что сделать:
 - Создать docs/adr/0005-trainers-role.md с описанием:
   - Какие права у тренера vs лидера vs участника
   - Какие экраны/действия доступны тренеру
   - Приоритет для MVP
 - Текущее состояние: роль trainer существует в БД (миграция 014), лидер может назначить её. Но никаких проверок прав
 тренера в коде нет — только leader имеет привилегии.

 Проверка: Документ написан, согласован с product owner

 ---
 Документация (после каждой задачи)

 - Обновить docs/progress.md
 - Создать/обновить docs/changes/ файлы при изменении поведения
 - Создать ADR при архитектурных решениях
 - Убрать выполненные задачи из infra/README.md секции TODO/фидбек

 ---
 Верификация (end-to-end)

 1. Backend: cd backend && npm test — все тесты проходят
 2. Mobile: cd mobile && flutter analyze && flutter test — без ошибок
 3. Ручное тестирование: каждая задача имеет свой чеклист выше
