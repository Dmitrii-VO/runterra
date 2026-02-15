# Territory Card Redesign — фикс багов и доработка

**Дата:** 2026-02-16

## Контекст

Ревью реализации спеки `2026-02-14-territory-card-redesign.md` выявило 8 багов и недореализованных секций.

## Изменения

### Backend

#### territories.config.ts
- Добавлена функция `resolveMyClubProgress(leaderboard, userClubIds)` — ищет первый клуб пользователя в leaderboard, возвращает `ClubProgressDto | null` с вычисленным `gapToLeader`
- `materialize` разделён на `materializeLight` (для карты — без leaderboard, myClubProgress, seasonEndsAt) и `materializeFull` (для деталей — с полными данными)
- `getTerritoriesForCity` использует `materializeLight` → уменьшен размер ответа `/api/map/data`
- `getTerritoryById` использует `materializeFull`

#### territories.routes.ts
- `GET /api/territories/:id` — теперь async
- Резолвит клубы пользователя через `clubMembersRepo.findActiveClubsByUser(userId)`
- Заполняет `myClubProgress` из leaderboard для клубов пользователя
- Non-critical: при ошибке резолва myClubProgress — возвращает территорию без него (с логированием)

### Mobile — модели и сервис

#### territory_league_models.dart
- `seasonEndsAt`: null-guard — fallback на 1-е число следующего месяца

#### map_service.dart
- Новый метод `getTerritoryDetails(id)` → `GET /api/territories/:id`
- Возвращает `TerritoryMapModel` с полными данными (leaderboard, myClubProgress)

### Mobile — UI

#### territory_bottom_sheet.dart
- Lazy-load: при открытии вызывает `getTerritoryDetails` через `ServiceLocator.mapService`
- Loading state: название территории + CircularProgressIndicator
- Error state: иконка ошибки + текст `loadError` + кнопка Retry
- LinearProgressIndicator: добавлен `.clamp(0.0, 1.0)`
- CONTESTED badge: при >=2 клубов в leaderboard — badge «Оспаривается (N)» с оранжевым фоном
- Capture status вынесен в отдельный виджет `_buildCaptureStatusBadge`
- Удалён `_captureStatus` метод — логика перенесена в badge

#### leaderboard_sheet.dart
- Ограничение до 10 записей (`_maxLeaderboardEntries`)
- Если myClubProgress != null и position > 10: показывает «...» + строку своего клуба
- Hardcoded `'km'` заменён на `l10n.leaderKm(...)` (i18n)

#### map_screen.dart
- Новый список `_captureLabels` для PlacemarkMapObject
- `_updateCaptureLabels()`: при `clubId != null` — создаёт PlacemarkMapObject с инициалами клуба в центроиде полигона
- `_createTextIcon(text)`: программная генерация иконки (белый круг + текст)
- `mapObjects` теперь включает `_captureLabels`

## Затронутые файлы

- `backend/src/modules/territories/territories.config.ts`
- `backend/src/api/territories.routes.ts`
- `mobile/lib/shared/models/territory_league_models.dart`
- `mobile/lib/shared/api/map_service.dart`
- `mobile/lib/features/map/widgets/territory_bottom_sheet.dart`
- `mobile/lib/features/map/widgets/leaderboard_sheet.dart`
- `mobile/lib/features/map/map_screen.dart`
