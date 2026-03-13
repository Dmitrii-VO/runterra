# Вкладка «Расписание» — Blueprint-подход (2026-03-13)

## Проблема

Вкладка «Расписание» в клубе существовала как изолированный «остров» данных без связи с Events, картой и лентой тренировок. Обнаружены критические баги и отсутствующая функциональность.

## Исправленные баги

### WeeklyScheduleItemModel (CRITICAL)
`fromJson` читал `json['type']` — ключ не существует в backend DTO (поле называется `activityType`). Следствие: тип всегда `note`, иконка всегда оранжевая, subtitle всегда пустой (т.к. `noteText` тоже не существует в ответе). Исправлено: убраны поля `type`/`eventId`/`noteText`, добавлены `activityType`/`workoutId`/`description`, добавлен `bool get isNote`.

### PersonalScheduleItemModel (CRITICAL)
`fromJson` делал `json['startTime'] as String` — null cast crash при наличии записей, т.к. backend `PersonalScheduleItemDto` не имеет `startTime`. Исправлено: поле убрано из модели и payload.

### ClubScheduleScreen (UI)
- Хардкод `['Пн','Вт','Ср','Чт','Пт','Сб','Вс']` → `DateFormat.E(locale)` из `intl`
- `Text("Нет данных")` → `l10n.scheduleEmptyDay`
- FAB виден всем → скрыт для обычных участников (только `leader`/`trainer`)
- `FutureBuilder` с HTTP-вызовом в диалоге → workouts загружаются в `initState`
- Payload создания note: убраны поля `type` и `noteText` (не существуют в Zod-схеме)

## Новая функциональность: кнопка «Провести»

Кнопка `Icons.play_circle_outline` рядом с каждым workout-шаблоном (не с заметками). Открывает стандартный экран создания Event с предзаполненными полями:
- `name` → название шаблона
- `type` → тип активности (training, tempo и т.д.)
- `time` → время начала из шаблона
- `workoutId` → связанная тренировка из библиотеки

Тренер добавляет только локацию → Event создаётся в системе, появляется на карте и в ленте «Тренировки».

## Затронутые файлы

**Mobile:**
- `shared/models/schedule_model.dart` — обе модели переписаны
- `features/club/club_schedule_screen.dart` — переработан полностью
- `features/club/personal_schedule_screen.dart` — убраны ссылки на `startTime`/`noteText`
- `features/events/create_event_screen.dart` — +3 prefill параметра
- `app.dart` — extra для роли, query params для prefill
- `features/club/club_details_screen.dart` — передаёт `extra: club.userRole`
- `l10n/app_en.arb`, `l10n/app_ru.arb` — +2 ключа

**Backend:**
- `modules/schedule/schedule-generator.service.ts` — `@deprecated` на `generateNextMonth`

**Docs:**
- `docs/adr/0010-schedule-blueprint.md` — новый ADR
