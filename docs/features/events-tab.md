# Вкладка «События»

Функционал вкладки «События» мобильного приложения Runterra.

## Назначение

Просмотр, создание и участие в беговых событиях (тренировки, забеги, групповые пробежки). Точка входа для планирования и записи на активности клубов и тренеров.

## EventsScreen — список событий

### Фильтры

| Фильтр | Параметр | Описание |
|--------|----------|----------|
| Дата | dateFilter | Сегодня / Завтра / 7 дней (today, tomorrow, next7days) |
| Только открытые | onlyOpen | По умолчанию true — события со статусом OPEN и не прошедшие |
| Мой клуб | clubId | Из CurrentClubService.primaryClubId |
| Участвую | participantOnly | Только события, на которые записан пользователь |

Фильтры проксируются в `EventsService.getEvents(cityId, dateFilter, clubId, onlyOpen, participantOnly)`.

### Действия

- **Pull-to-refresh** — перезагрузка списка
- **FAB** — переход на `CreateEventScreen` (`/event/create`)
- **Тап по карточке** — `EventDetailsScreen` (`/event/:id`)

### Состояния

- Loading
- Empty (нет событий по фильтрам)
- Error + retry

---

## EventDetailsScreen — детали события

### Отображаемая информация

- Название, тип события
- Дата и время
- Точка старта (координаты)
- **Мини-карта** — Yandex MapKit, круг в точке старта, zoom 15; тап → переход на вкладку Карта с центрированием (`/map?lat=..&lon=..`)
- Организатор (название клуба или имя тренера)
- Список участников (GET /api/events/:id/participants)

### Кнопки участия

| Состояние | Кнопка | Действие |
|-----------|--------|----------|
| Не записан | «Присоединиться» | POST /api/events/:id/join |
| Записан | «Вы участвуете» (disabled) | — |
| Записан | «Отменить участие» | POST /api/events/:id/leave |

### SwipeToRunCard — check-in + старт пробежки

Карточка «Начать пробежку» со свайпом. При свайпе:
1. Выполняется check-in (POST /api/events/:id/check-in с координатами)
2. Запускается пробежка с переходом на вкладку «Пробежка»

**Условия отображения активной карточки:**
- Пользователь записан на событие
- Время в окне: 30 мин до — 1 ч после старта
- Пользователь в геозоне (радиус 500 м от точки старта)

**Вне условий:** карточка disabled с пояснением (например, «Подойдите к точке старта»)

---

## CreateEventScreen — создание события

**Доступ:** FAB на экране списка событий.

**Поля формы:**
- Тип события
- Дата и время
- Точка старта: кнопка «Выбрать на карте» → `LocationPickerScreen` (Yandex карта с пином по центру)
- Организатор: автоопределение — текущий клуб или тренер из профиля
- Лимит участников (опционально)

**После успеха:** переход на `EventDetailsScreen` по `event.id`.

---

## API

| Метод | Назначение |
|-------|------------|
| GET /api/events | Список событий (cityId, dateFilter, clubId, onlyOpen, participantOnly) |
| GET /api/events/:id | Детали события (isParticipant, participantStatus) |
| GET /api/events/:id/participants | Список участников |
| POST /api/events | Создание события |
| POST /api/events/:id/join | Запись на событие |
| POST /api/events/:id/leave | Отмена участия |
| POST /api/events/:id/check-in | Check-in (longitude, latitude) |

**Check-in:** окно 30 мин до — 1 ч после старта, радиус 500 м от точки старта.

---

## Навигация

- `/events` — вкладка (список)
- `/event/create` — создание
- `/event/:id` — детали

---

## Связанные файлы

- `mobile/lib/features/events/events_screen.dart`
- `mobile/lib/features/events/event_details_screen.dart`
- `mobile/lib/features/events/create_event_screen.dart`
- `mobile/lib/features/events/widgets/event_card.dart`
- `mobile/lib/features/events/widgets/event_mini_map.dart`
- `mobile/lib/features/map/location_picker_screen.dart`
- `mobile/lib/shared/api/events_service.dart`
- `backend/src/api/events.routes.ts`
