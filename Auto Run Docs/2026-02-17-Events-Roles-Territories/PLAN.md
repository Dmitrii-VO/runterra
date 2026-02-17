# План реализации: Поиск по адресу, Редактирование событий, Лидер=Тренер, Территории только для клубов

## Обзор задач

1. **Поиск по адресу при создании события** — добавить текстовый поиск адреса (geocoding) в LocationPickerScreen
2. **Редактирование событий** — полный CRUD: backend endpoint + mobile экран
3. **Лидеру клуба дать функционал тренера** — лидер получает все возможности тренера без отдельной роли
4. **Территории — только участники клубов** — бегуны без клуба не вносят вклад в захват территорий

---

## Фаза 1: Поиск по адресу (Geocoding)

### Текущее состояние
- `LocationPickerScreen` — полноэкранная Yandex карта с пином по центру
- Пользователь двигает карту, координаты берутся из центра камеры
- Нет ни поиска адреса, ни reverse geocoding

### План
**Backend:**
- Новый endpoint `GET /api/geocode?query=...&cityId=...` — проксирует запрос к Yandex Geocoder API
- Зачем proxy: API ключ не утекает на клиент; можно кэшировать; можно ограничить bbox города
- Возвращает массив `{ address: string, lat: number, lon: number }[]`
- Используем Yandex Geocoder HTTP API (https://geocode-maps.yandex.ru/1.x/)

**Mobile:**
- В `LocationPickerScreen` добавить `SearchBar` / `TextField` сверху экрана
- При вводе текста (debounce 500ms) → вызов `GET /api/geocode?query=...`
- Результаты показываются в выпадающем списке поверх карты
- При выборе результата → камера перемещается к координатам
- Reverse geocoding: при остановке камеры → `GET /api/geocode?lat=...&lon=...` (reverse) → показ адреса под строкой поиска
- `CreateEventScreen` получает обратно и координаты, и адрес

### Файлы
- `backend/src/api/geocode.routes.ts` (новый)
- `backend/src/api/index.ts` (регистрация роута)
- `mobile/lib/shared/api/geocode_service.dart` (новый)
- `mobile/lib/shared/di/service_locator.dart` (регистрация)
- `mobile/lib/features/map/location_picker_screen.dart` (UI поиска)
- `mobile/lib/features/events/create_event_screen.dart` (получение адреса)
- `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb` (новые ключи)

---

## Фаза 2: Редактирование событий

### Текущее состояние
- `POST /api/events` — создание
- `PATCH /api/events/:id` — только `workoutId`/`trainerId`
- Нет endpoint для редактирования основных полей
- Нет mobile-экрана редактирования

### План
**Backend:**
- Расширить `PATCH /api/events/:id` или создать новый `PUT /api/events/:id`
- Zod-схема `UpdateEventSchema`: name, description, date, latitude, longitude, address, participantLimit, type — все optional
- Проверка прав: только организатор (organizerId) или лидер клуба-организатора
- Нельзя редактировать: organizerType, organizerId, status (для этого отдельные endpoints)
- Нельзя редактировать завершённые/отменённые события

**Mobile:**
- Переиспользовать `CreateEventScreen` → общий `EventFormScreen` с режимами create/edit
- Или создать отдельный `EditEventScreen` (предпочтительнее для простоты, чтобы не усложнять create)
- На `EventDetailsScreen` добавить кнопку «Редактировать» (видна только организатору/лидеру)
- Навигация: `/events/:id/edit`

### Файлы
- `backend/src/api/events.routes.ts` (расширение PATCH)
- `backend/src/modules/events/event.dto.ts` (новая Zod-схема)
- `backend/src/db/repositories/events.repository.ts` (метод update)
- `backend/src/api/__tests__/events.routes.test.ts` (тесты)
- `mobile/lib/features/events/edit_event_screen.dart` (новый)
- `mobile/lib/features/events/event_details_screen.dart` (кнопка edit)
- `mobile/lib/shared/api/events_service.dart` (метод updateEvent)
- `mobile/lib/shared/models/event_model.dart` (если нужно)
- GoRouter routes
- i18n ключи

---

## Фаза 3: Лидер = Тренер

### Текущее состояние
- Хелпер `isTrainerInAnyClub()` проверяет роль `trainer` ИЛИ `leader`
- `isTrainerOrLeaderInClub()` — то же
- Тренерский профиль: `POST /api/trainer/profile` — требует `isTrainerInAnyClub`
- Тренировки: CRUD — проверки через `isTrainerOrLeaderInClub`
- **Проблема:** На mobile экранах проверки идут по роли `trainer`, а не по `trainer || leader`

### Что нужно проверить и исправить
**Backend** — уже корректно обрабатывает leader как trainer (хелперы `trainer-role.ts`). Нужно проверить:
- Все роуты тренера/тренировок — используют ли хелперы или хардкодят роль
- `CreateEventScreen` — dropdown тренеров включает ли лидеров

**Mobile** — проверить:
- `CreateEventScreen`: `_canAssignTrainer` — проверяет `role == 'leader'`, но для выбора workout'ов и отображения тренерского функционала нужна проверка `role == 'trainer' || role == 'leader'`
- Профиль: показывать секцию тренера и для лидера
- `ProfileScreen` / настройки: ссылки на тренерский профиль и тренировки для лидера
- Список тренеров в событии: backend `GET /api/events` список тренеров — включает ли лидеров

### Файлы
- `mobile/lib/features/events/create_event_screen.dart` (проверки ролей)
- `mobile/lib/features/profile/profile_screen.dart` (секция тренера для лидера)
- `backend/src/api/events.routes.ts` (проверить загрузку списка тренеров)
- Возможно минимальные правки

---

## Фаза 4: Территории — только участники клубов

### Текущее состояние
- `POST /api/territories/:id/capture` — **уже** проверяет членство в клубе (active)
- `POST /api/runs` — сохраняет пробежку, **не** связывает с территорией
- Территории пока mock — нет реального подсчёта km из пробежек
- В product_spec: «бегун без клуба — наёмник, не вносит вклад»

### Что нужно сделать
Поскольку территории пока mock, основное:
1. **Backend:** В `POST /api/runs` — если пользователь не в клубе, пробежка сохраняется, но НЕ будет учитываться для территорий (когда подсчёт будет реализован). Добавить поле `clubId` к run (nullable) — записывается автоматически, если бегун в клубе.
2. **Backend миграция:** `ALTER TABLE runs ADD COLUMN club_id UUID REFERENCES clubs(id) ON DELETE SET NULL` — привязка пробежки к клубу в момент сохранения.
3. **Backend `POST /api/runs`:** При создании пробежки — lookup активного клуба пользователя, записать `club_id`. Если не в клубе — `club_id = NULL`.
4. **Mobile:** На экране территорий / bottom sheet — если пользователь не в клубе, показывать CTA «Вступи в клуб, чтобы захватывать территории» (уже частично реализовано).
5. **ADR:** Зафиксировать решение — пробежки без клуба не учитываются в территориальном подсчёте.

### Файлы
- `backend/src/db/migrations/021_runs_club_id.sql` (новая миграция)
- `backend/src/api/runs.routes.ts` (добавить club_id при создании)
- `backend/src/db/repositories/runs.repository.ts` (сохранение club_id)
- `backend/src/modules/runs/run.entity.ts` (поле clubId)
- `backend/src/api/__tests__/runs.routes.test.ts` (тесты)
- `docs/adr/0008-runs-club-association.md` (новый ADR)

---

## Порядок реализации

1. **Фаза 3** (Лидер = Тренер) — минимальные изменения, быстро
2. **Фаза 4** (Территории — только клубы) — миграция + небольшие изменения
3. **Фаза 1** (Поиск по адресу) — новый функционал, средний объём
4. **Фаза 2** (Редактирование событий) — самый большой объём работы

## Оценка затронутых файлов
- Фаза 1: ~7 файлов (2 новых)
- Фаза 2: ~8 файлов (1–2 новых)
- Фаза 3: ~3–5 файлов (0 новых)
- Фаза 4: ~5 файлов (1–2 новых)
- **Итого: ~20 файлов**
