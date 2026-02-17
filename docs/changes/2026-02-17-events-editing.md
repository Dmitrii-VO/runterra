# Поиск адреса + Редактирование событий (2026-02-17)

## Поиск адреса в LocationPickerScreen

### Что изменилось
В `LocationPickerScreen` добавлен текстовый поиск адреса через Yandex Suggest API.

### Детали
- Используется `YandexSuggest.getSuggestions()` с debounce 400ms
- Поиск ограничен BoundingBox вокруг текущей позиции карты (±0.5°)
- Результаты фильтруются по `SuggestType.geo`, отображаются в overlay ListView
- При выборе результата: камера перемещается с анимацией, адрес сохраняется
- `CreateEventScreen` автозаполняет `_locationNameController` из выбранного адреса

### Файлы
- `mobile/lib/features/map/location_picker_screen.dart` — переработан с добавлением поиска
- `mobile/lib/features/events/create_event_screen.dart` — обработка `address` из LocationPicker
- `mobile/l10n/app_en.arb` / `app_ru.arb` — ключ `locationPickerSearchHint`

---

## Редактирование событий

### Backend

#### UpdateEventSchema (`event.dto.ts`)
Новая Zod-схема — все поля optional:
- `name`, `type`, `startDateTime`, `startLocation`, `locationName`, `description`
- `participantLimit` (nullable), `difficultyLevel` (nullable)
- `workoutId` (nullable), `trainerId` (nullable)

#### events.repository.ts — метод `update()`
Динамический SQL UPDATE с параметризованными индексами. Поддерживает все поля из UpdateEventSchema.

#### PATCH /api/events/:id (`events.routes.ts`)
Заменён trainer-only PATCH на general-purpose:
- **Auth:** club events → `isTrainerOrLeaderInClub(userId, organizerId)`, trainer events → `organizerId === userId`
- **Guard:** completed/cancelled → 400 `event_not_editable`
- **Trainer fields guard:** workoutId/trainerId только для club events
- **startLocation:** валидация через `isPointWithinCityBounds`
- **Обратная совместимость:** старый `{workoutId?, trainerId?}` — валидный subset

#### GET /api/events/:id — поле `isOrganizer`
Для авторизованного пользователя вычисляется и возвращается `isOrganizer: boolean`:
- `organizerType === 'trainer'` → `organizerId === user.id`
- `organizerType === 'club'` → `isTrainerOrLeaderInClub(user.id, organizerId)`

### Mobile

#### EventsService.updateEvent()
Новый метод PATCH `/api/events/$eventId` с optional полями. Паттерн аналогичен `createEvent()`.

#### EditEventScreen (`edit_event_screen.dart`)
Новый экран:
- Загружает событие через `getEventById()`
- Форма: name, type, date/time, location name, map picker, participant limit, description
- Save → `updateEvent()` → snackbar + pop

#### Навигация
- Роут `/event/:id/edit` → `EditEventScreen` в `app.dart`
- Кнопка Edit (Icons.edit) в AppBar `EventDetailsScreen` — только для `isOrganizer == true` и status != completed/cancelled

#### EventDetailsModel
Добавлено поле `isOrganizer: bool?` с parsing из JSON.

### i18n
| Ключ | EN | RU |
|------|----|----|
| `locationPickerSearchHint` | Search address... | Поиск адреса... |
| `eventEditTitle` | Edit Event | Редактирование события |
| `eventEditSave` | Save Changes | Сохранить изменения |
| `eventEditSuccess` | Event updated | Событие обновлено |
| `eventEditError` | Failed to update: {error} | Ошибка обновления: {error} |

### Тесты
- `events-patch.routes.test.ts` — обновлены моки (`update` вместо `updateTrainerFields`)

---

## Подтверждения (без изменений кода)

- **Лидер = тренер:** `isTrainerInAnyClub()` проверяет `role IN ('trainer', 'leader')` — лидеры уже имеют функции тренера.
- **Захват территорий только членами клубов:** Backend 403 для пользователей без клуба; mobile скрывает кнопку захвата при `myClubId == null`.
