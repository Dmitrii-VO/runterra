# Реализация Z8: Swipe-to-run check-in (2026-02-13)

Реализация принятых решений из docs/changes/2026-02-13-events-checkin-decisions.md.

## Backend

### Окно check-in: 30 мин до — 1 ч после
- **Файл:** `backend/src/db/repositories/events.repository.ts`
- **Изменение:** `checkIn()` — windowStart 15→30 мин, windowEnd 30→60 мин
- **Тесты:** `events.repository.test.ts` — обновлены граничные кейсы (40 мин до, 65 мин после)

### Фильтр participantOnly
- **Файл:** `backend/src/api/events.routes.ts`
- **Изменение:** GET /api/events — query `participantOnly=true`; при включении требуется auth, userId резолвится из Firebase UID
- **Файл:** `backend/src/db/repositories/events.repository.ts`
- **Изменение:** `findAll()` — опции `participantOnly`, `participantUserId`; подзапрос по `event_participants`

### Проверка 1 км в территории
Отложена: требует event_id в runs, геометрию территорий и spatial-логику. TODO в docs/changes/2026-02-13-events-checkin-decisions.md.

## Mobile

### Фильтр «Участвую»
- **Файл:** `mobile/lib/features/events/events_screen.dart`
- **Изменение:** FilterChip «Участвую» / «Participating»; состояние `_participantOnly`
- **Файл:** `mobile/lib/shared/api/events_service.dart`
- **Изменение:** `getEvents()` — параметр `participantOnly`
- **l10n:** `filterParticipantOnly` в app_en.arb, app_ru.arb

### Карточка Swipe-to-run
- **Новый файл:** `mobile/lib/features/events/widgets/swipe_to_run_card.dart`
- **Логика:**
  - Окно: 30 мин до — 1 ч после (клиент)
  - Геозона: 500 м (Geolocator.distanceBetween)
  - При свайпе: checkInEvent + startRun(activityId: eventId) + context.go('/run')
  - Вне условий: карточка disabled с пояснением (too early, too late, too far, location error)
- **Интеграция:** `EventDetailsScreen` — карточка между «Вы участник» и «Отменить участие»
- **l10n:** eventSwipeToRunTitle, eventSwipeToRunHint, eventSwipeToRunSuccess, eventSwipeToRunError, eventSwipeToRunAlreadyCheckedIn, eventSwipeToRunTooEarly, eventSwipeToRunTooLate, eventSwipeToRunTooFar, eventSwipeToRunLocationError, eventSwipeToRunCheckingLocation

## Проверки

- Backend: `npm test` — 82 passed (events.repository 16 passed)
- Mobile: `flutter analyze` — 3 info (pre-existing)
- Mobile: `flutter test` — 19 passed

## Codex verification

Запуск Codex high для перепроверки:
```bash
ai\.venv\Scripts\python.exe scripts\ai-crewai.py --provider codex --auth "Code review Z8 Swipe-to-run..."
```
Рекомендуется выполнять вручную в терминале (ожидание 2–5 мин).
