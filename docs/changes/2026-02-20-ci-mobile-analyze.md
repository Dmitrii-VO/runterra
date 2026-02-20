# Fix CI: Mobile analyze — nullable startLocation и unused_element

**Дата:** 2026-02-20

## Проблема

CI (Mobile job) падал на шаге **Analyze code** (`flutter analyze --no-fatal-infos`):

- **Run:** https://github.com/Dmitrii-VO/runterra/actions/runs/22214895707
- **Ошибки (2):**
  - `test/models/event_list_item_model_test.dart:34:34` — The property 'latitude' can't be unconditionally accessed because the receiver can be 'null' • unchecked_use_of_nullable_value
  - `test/models/event_list_item_model_test.dart:35:34` — The property 'longitude' can't be unconditionally accessed because the receiver can be 'null' • unchecked_use_of_nullable_value

В модели `EventListItemModel.startLocation` имеет тип `EventStartLocation?`; в тесте к полям обращались без проверки на null.

## Решение

1. **event_list_item_model_test.dart:** заменено `event.startLocation.latitude` / `event.startLocation.longitude` на `event.startLocation!.latitude` / `event.startLocation!.longitude` (в тесте JSON всегда содержит startLocation).
2. **club_schedule_screen.dart:** удалена неиспользуемая функция `_backendDayToUi` (unused_element, на локальной машине давала warning и exit 1).

## Результат

- `flutter analyze --no-fatal-infos` в mobile завершается с exit code 0.
- Остаются только info (deprecated, empty_catches); ошибок и предупреждений нет.
