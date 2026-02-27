# Миграция open_event и правки mobile

**Дата:** 2026-02-28

## Описание

Добавлена поддержка типа события `open_event` в БД и внесены точечные исправления в mobile: отключение лишнего refresh токена при навигации и упрощение контракта пикера локации.

## Backend

### Миграция `029_events_type_open_event.sql`

- Обновлён CHECK-ограничение для колонки `events.type`: в допустимые значения добавлен `'open_event'`.
- Устранена ошибка check_violation при вставке событий типа OPEN_EVENT.

## Mobile

### app.dart

- Убрана автоматическая подстановка вызова `ServiceLocator.refreshAuthToken` при проверке маршрутов (в логике redirect/refresh). Это предотвращает лишние запросы при каждом переходе по маршрутам.

### LocationPickerScreen

- Результат возврата из пикера приведён к строго типизированному `Map<String, double>` с ключами `latitude` и `longitude`.
- Поле `address` удалено из payload, возвращаемого при `Navigator.pop` — экраны, использующие пикер, получают только координаты.

## Файлы

| Файл | Действие |
|------|----------|
| `backend/src/db/migrations/029_events_type_open_event.sql` | Новый |
| `mobile/lib/app.dart` | Изменён (убрана подстановка refreshAuthToken при route checks) |
| `mobile/lib/features/map/location_picker_screen.dart` | Изменён (тип возврата без address) |
