# Журнал ошибок и исправлений (Errors Runbook)

Документ для повторных проверок логов: что уже исправлено, что считать новым. При команде «посмотри ошибки в логах» — сначала читать этот файл, затем логи; реагировать только на ошибки, которых нет в списке «Исправлено».

---

## Как пользоваться

1. **Перед разбором логов** — прочитать этот файл (секция «Исправлено»).
2. **Скачать/посмотреть логи** (ssh runterra, journalctl, error-*.log).
3. **Сопоставить с runbook:** если ошибка совпадает с пунктом из «Исправлено» — не предлагать правку заново. Работать только с ошибками, которых нет в «Исправлено».
4. **В конце** прочитать **docs/progress.md** и соотнести найденные (новые) ошибки с прогрессом: недавние фичи, деплои — чтобы интерпретировать ошибки в контексте.
5. После исправления новой ошибки — добавить в «Исправлено» с датой; при необходимости кратко в docs/progress.md.

---

## Исправлено (не предлагать повторно)

Формат: краткое описание | сигнатура в логах | что сделано | дата.

- **Пробежка с нулевой длительностью (500)**  
  Сигнатура: `"Error creating run"`, `runs_duration_positive`, `constraint`, `duration` 0.  
  Что сделано: в `backend/src/api/runs.routes.ts` добавлена проверка `duration >= 30` до вызова репозитория; при нарушении возврат 400 с сообщением «duration must be at least 30 seconds».  
  Дата: 2026-02-03.

- **Глобальные сообщения — невалидный cityId (500)**
  Сигнатура: `"Error fetching global messages"`, `string_to_uuid`, `parameter $2 = '...'`, код 22P02.
  Что сделано: в `backend/src/api/messages.routes.ts` для GET `/global` добавлена валидация `cityId` как UUID; при невалидном значении возврат 400 «cityId must be a valid UUID».
  Дата: 2026-02-03.

- **Повторный старт пробежки — `Exception: Run already started`**
  Сигнатура: на вкладках «Пробежка» и «Карта» внизу показывается красный баннер `Ошибка при запуске пробежки: Exception: Run already started`, при этом UI остаётся в состоянии «Начать пробежку» без таймера и маршрута.
  Что сделано: (1) в `RunService` добавлен метод `clearCompletedSession()` для очистки завершённых сессий; (2) `startRun()` автоматически очищает завершённые (completed) сессии перед стартом — выбрасывает исключение только для running-сессий; (3) в `RunScreen.initState()` при возврате на вкладку восстанавливается UI для running и completed сессий; (4) `_backToIdle()` теперь вызывает `clearCompletedSession()`; (5) при исключении «Run already started» показывается диалог с выбором «Продолжить» или «Отменить и начать заново»; (6) добавлены i18n ключи `runStuckSessionTitle`, `runStuckSessionMessage`, `runStuckSessionResume`, `runStuckSessionCancel` (EN/RU).
  Дата: 2026-02-04.

- **Batch resolve organizer display names — `string_to_uuid` (warn)**
  Сигнатура: `"Failed to batch resolve organizer display names"`, `string_to_uuid`, код `22P02`, `routine: "string_to_uuid"`.
  Контекст: в таблице `events` есть исторические записи с невалидными `organizer_id` (`'1'`, `'demo-club-1'`). `getOrganizerDisplayNamesBatch` передавал их в `findByIds` → PostgreSQL не мог привести к UUID.
  Что сделано: в `backend/src/api/helpers/organizer-display.ts` добавлена UUID-валидация (regex) перед передачей ID в `findByIds` — невалидные ID пропускаются без запроса к БД. Тестовые моки обновлены с `'club-1'` на валидный UUID.
  Дата: 2026-02-09.

- **Клубы — невалидный `clubId` в GET `/api/clubs/:id` (500)**
  Сигнатура: `"Error fetching club"`, `string_to_uuid`, `code` `22P02`, `clubId: "new-club-id"`, `parameter $1`.
  Что сделано: исправлено в рамках «Исправление архитектурных недостатков клубов» (2026-02-08) — добавлена валидация `isValidClubId()` (строгий UUID) на все эндпоинты `/api/clubs/:id*`. Невалидный ID возвращает 400 вместо 500. В логах за 08-09.02 ошибка не воспроизводится.
  Дата: 2026-02-08.

---

## Известные открытые (не из логов backend)

- **Trainer profile edit — 500 при GET /api/trainer/profile/edit (исправление в коде, ожидает деплой) (22P02 string_to_uuid)**
  Сигнатура: `Error fetching trainer profile`, `code: 22P02`, `routine: string_to_uuid`, запрос `GET /api/trainer/profile/edit` → 500 (в access-логах путь виден как `/profile/edit`).
  Наблюдение: ошибка уже фиксируется в backend error-логах (например, `error-2026-02-16.log`: `GET /profile/edit` → 500).
  Причина: роут `GET /api/trainer/profile/:userId` принимает `userId=edit` (не UUID) и передаёт в запрос к БД → PostgreSQL падает на приведении к UUID. Частая причина на клиенте: маршрут `/trainer/edit` матчится как `/trainer/:userId` (userId="edit").
  Исправление в коде (ожидает деплой): в mobile переставить роуты так, чтобы `/trainer/edit` был выше `/trainer/:userId`; в backend добавить UUID-валидацию `:userId` (400 вместо 500).

- **Вылет при «Начать пробежку» в Nox** — краш на эмуляторе при старте foreground service (GPS). Решение не вводили: оставлен фоновый режим и в debug по запросу. Не бэкенд, не логи runterra.

---

## Анализ логов Mobile/Logcat (2026-02-17)

Ошибки, найденные в логах `logs/1.txt`, `logs/2.txt`, `logs/3.txt` (Android Emulator).

### 1. Flutter Lifecycle Exception (Критично)
- **Сигнатура:** `Uncaught error: dependOnInheritedWidgetOfExactType<_LocalizationsScope>() or dependOnInheritedElement() was called before _MapScreenState.initState() completed.`
- **Причина:** В `MapScreen` (или связанном виджете) происходит обращение к `context` (например, `Theme.of(context)` или `AppLocalizations.of(context)`) внутри метода `initState()`, где контекст еще не полностью инициализирован для наследования.
- **Статус:** **ОТКРЫТА**. Требует правки кода: перенести логику в `didChangeDependencies()` или использовать `addPostFrameCallback`.

### 2. Ошибки авторизации Google / Firebase (Конфигурация)
- **Сигнатура:** `NEED_REMOTE_CONSENT`, `NETWORK_ERROR`, `FIS_AUTH_ERROR`, `[GoogleAuthUtil] error status: NEED_REMOTE_CONSENT`.
- **Причина:**
  1. Эмулятор не имеет корректного доступа к сети или Google Play Services.
  2. Несовпадение SHA-1 отпечатков (Debug Keystore vs Firebase Console).
  3. Отсутствие или устаревший `google-services.json`.
- **Статус:** **Конфигурация среды**. Проверить `google-services.json` и SHA-1.

### 3. Графические ошибки эмулятора (Шум)
- **Сигнатура:** `EGL Error: Success (12288)`, `ANativeWindow::dequeueBuffer failed`, `[ERROR:flutter/impeller/toolkit/egl/egl.cc(56)]`.
- **Причина:** Известная проблема графического движка Impeller (Flutter) на некоторых эмуляторах Android.
- **Статус:** **Игнорировать** (не влияет на продакшн на реальных устройствах).

### 4. Системный шум Google Play Services (Шум)
- **Сигнатура:** `Phenotype API error`, `RcsClientLib: Unexpected error`, `DomainFilterImpl: Error while reading domain filter`.
- **Причина:** Внутренние сбои сервисов Google на образе эмулятора.
- **Статус:** **Игнорировать**.

---

## Ожидаемые предупреждения (не ошибки)

- **POST "/" и GET "/" → 404** — запросы к корню от сканеров/ботов; 404-обработчик возвращает `{ code, message }` (исправлено 2026-02-02). В логах level `warn`. Не требуюют правок.

## Где смотреть логи

- **Backend (runterra):**  
  - systemd: `ssh runterra "journalctl -u runterra-backend -n 500 --no-pager"`  
  - Файлы: `ssh runterra "tail -200 /home/user1/runterra/logs/error-YYYY-MM-DD.log"`  
- **Mobile (local):**
  - `adb logcat -d > logs/logcat.txt`
- **Дата в имени файла** — по UTC (или по серверу). Для «сегодня» подставлять актуальную дату.

При добавлении нового пункта в «Исправлено» указывать дату и файлы/коммиты, чтобы не дублировать правки.
