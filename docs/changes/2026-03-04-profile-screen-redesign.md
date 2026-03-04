# Профиль: исправление nextActivity/lastActivity + редизайн ProfileScreen

**Дата:** 2026-03-04

## Проблема

`ProfileActivitySection` всегда показывал «Нет запланированных тренировок» и «Нет последних тренировок» — backend возвращал `nextActivity: undefined, lastActivity: undefined` (TODO-заглушка в `users.routes.ts:148`). Параллельно выполнен редизайн ProfileScreen.

## Изменения

### Backend

**`backend/src/db/repositories/events.repository.ts`**
- Добавлен метод `getNextEventForUser(userId: string)` — возвращает ближайшее будущее событие, на которое зарегистрирован пользователь:
  - JOIN `event_participants` + `events`
  - Фильтр: `status IN ('registered', 'checked_in')` AND `start_date_time > NOW()`
  - Сортировка: `ORDER BY start_date_time ASC LIMIT 1`

**`backend/src/db/repositories/runs.repository.ts`**
- Добавлен метод `getLastRun(userId: string)` — последняя пробежка пользователя (`ORDER BY started_at DESC LIMIT 1`)

**`backend/src/api/users.routes.ts`**
- Заглушки `nextActivity: undefined, lastActivity: undefined` заменены на реальные запросы через репозитории
- Статусы маппятся на `ActivityStatus` enum: `checked_in → IN_PROGRESS`, `registered → PLANNED`, последняя пробежка → `COMPLETED` (result: `counted`/`not_counted` по статусу run)

**`backend/src/db/repositories/__mocks__/index.ts`**
- `mockEventsRepository.getNextEventForUser` → `jest.fn().mockResolvedValue(null)`
- `mockRunsRepository.getLastRun` → `jest.fn().mockResolvedValue(null)`

### Mobile

**`mobile/lib/features/profile/profile_screen.dart`** — полный редизайн:

| До | После |
|---|---|
| `Scaffold + AppBar + ListView` | `Scaffold + CustomScrollView` |
| Фиксированный `AppBar` с заголовком | `SliverAppBar` (expandedHeight: 200, pinned) |
| `ProfileHeaderSection` — карточка в скролле | `_ProfileHeroHeader` в `flexibleSpace` SliverAppBar |

**Новый виджет `_ProfileHeroHeader`:**
- Фон: градиент из `colorScheme.primary`
- Тёмный overlay снизу для читаемости текста
- `CircleAvatar` 36px radius (fallback — инициалы)
- Display name + статус-чип (если `user.status.isNotEmpty`)

Импорт `header_section.dart` удалён из экрана (виджет `ProfileHeaderSection` сохранён в файле, просто не используется в ProfileScreen).

## Тесты

- Backend: 156/156 тестов зелёные
- Mobile: `flutter analyze` — 0 errors

## Не изменялось

- Section-виджеты в `shared/ui/profile/` (кроме удаления из Screen)
- `ProfileModel`, `ProfileActivityModel` (уже соответствовали backend DTO)
- `profile.dto.ts`
- `docs/domain_map.html` (схема БД не изменилась)

---

# UX-оптимизация QuickActions и порядка секций

**Дата:** 2026-03-04

## Проблема

Секция `ProfileQuickActionsSection` содержала нерелевантные CTA: "Открыть карту" дублировала нижний таб навигации, "Найти людей" — социальный discovery, не CTA. `ProfileStatsSection` располагалась ниже `ProfilePersonalInfoSection`, хотя статистика важнее для первого взгляда.

## Изменения

### `mobile/lib/shared/ui/profile/quick_actions_section.dart`

- Убраны кнопки "Открыть карту" (`ElevatedButton` + `OpenMapAction`) и "Найти людей" (`/people`)
- При `hasClub || isMercenary` — `return const SizedBox.shrink()` (секция не рендерится)
- Для новых пользователей без клуба — только два `OutlinedButton.icon`: "Найти клуб" и "Создать клуб"

### `mobile/lib/features/profile/profile_screen.dart`

- `ProfileStatsSection` перемещена выше `ProfilePersonalInfoSection`
- "Найти людей" перенесено в `Card > ListTile` (после Trainer Card) — стилистически консистентно с Workouts/Trainer карточками

## Порядок секций (после изменения)

1. ProfileStatsSection
2. ProfilePersonalInfoSection
3. Club Card (если hasClub)
4. CitySection
5. ProfileActivitySection
6. ProfileQuickActionsSection (только для !hasClub && !isMercenary)
7. Workouts Card
8. Trainer Card (если тренер)
9. People Card («Найти людей»)
10. ProfileNotificationsSection

## Тесты

- `flutter analyze lib/` — 0 issues
