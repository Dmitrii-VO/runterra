# Fix: несоответствие адрес ≠ координаты в пикере локации

**Дата:** 2026-02-24

## Проблема

Три взаимосвязанных бага приводили к ситуации, когда адрес и координаты события расходились:

1. **Bug A** (`_onSuggestItemSelected`): адрес (`_selectedAddress`) устанавливался из `item.displayText` даже если у подсказки не было поля `center` (координат). В этом случае пин оставался на текущей позиции, а адрес — от другого места.

2. **Bug B** (`_onCameraPositionChanged`): при ручном перетаскивании карты после выбора подсказки `_selectedAddress` не сбрасывался. Пин ушёл, адрес остался старым.

3. **Bug C** (`create_event_screen.dart` / `edit_event_screen.dart`, `_pickLocation`): автозаполнение адреса срабатывало только когда поле пустое. При редактировании события старый адрес не обновлялся.

## Исправления

### `location_picker_screen.dart`

**Fix A** — `_onSuggestItemSelected`:
- Если `item.center == null` — досрочный `return`, подсказка игнорируется
- `_selectedAddress` устанавливается только вместе с координатами

**Fix B** — `_onCameraPositionChanged`:
- При `reason == CameraUpdateReason.gestures` и `finished == true` — `_selectedAddress = null`
- Гарантирует: после ручного перемещения пина адрес больше не показывается

**Fix C (UX)** — нижняя карточка:
- Добавлен адрес под координатами (если `_selectedAddress != null`)
- Пользователь видит, что именно будет записано перед нажатием «Подтвердить»

### `create_event_screen.dart` и `edit_event_screen.dart`

**Fix D** — `_pickLocation`:
- Убрано условие `.isEmpty` — адрес из пикера всегда перезаписывает поле «Название локации»

## Затронутые файлы

- `mobile/lib/features/map/location_picker_screen.dart`
- `mobile/lib/features/events/create_event_screen.dart`
- `mobile/lib/features/events/edit_event_screen.dart`

## Что не изменилось

- Логика сохранения координат
- Backend, модели, роутинг, l10n
- Поведение при выборе подсказки с координатами (работает как раньше)
