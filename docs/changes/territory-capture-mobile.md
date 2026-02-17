# Захват территорий из мобильного приложения + targetMetric в тренировках

**Дата:** 2026-02-17

## Контекст

Аудит связки backend/mobile выявил, что POST /api/territories/:id/capture реализован на бэкенде, но не вызывается из мобильного приложения. Также targetMetric тренировки не отображался в списке тренировок.

## Изменения

### 1. Метод captureTerritory в TerritoriesService

**Файл:** `mobile/lib/shared/api/territories_service.dart`

- Добавлен `captureTerritory(territoryId, clubId)` — POST на `/api/territories/{id}/capture`
- При ошибке парсит `{ code, message }` из ответа и бросает `ApiException`

### 2. Кнопка захвата в TerritoryBottomSheet

**Файл:** `mobile/lib/features/map/widgets/territory_bottom_sheet.dart`

- Добавлена state-переменная `_isCapturing`
- Добавлен метод `_captureTerritory(info)`: вызывает API, показывает snackbar, обновляет данные
- В action bar добавлен `IconButton.filled` с иконкой `Icons.flag` между "Run for Zone" и leaderboard
- Кнопка показывается только при `info.myClubProgress != null` (у пользователя есть клуб)
- Loading state: `CircularProgressIndicator` вместо иконки во время запроса

### 3. targetMetric в списке тренировок

**Файл:** `mobile/lib/features/trainer/workouts_list_screen.dart`

- `Row` заменён на `Wrap` (3 чипа могут не влезть в строку)
- Добавлен третий `Chip` с локализованным targetMetric (Distance/Time/Pace)
- Добавлен метод `_localizeTargetMetric(l10n, metric)`

### 4. Локализация

**Файлы:** `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb`

| Ключ | EN | RU |
|------|----|----|
| `captureButton` | Capture | Захватить |
| `captureSuccess` | Territory capture contribution submitted! | Вклад в захват территории отправлен! |
| `captureError` | Could not capture: {message} | Не удалось захватить: {message} |

## Что не менялось

- TerritoryDetailsScreen (`/territory/:id`) — не показывает league-информацию, оставлено как есть (основной UX — bottom sheet)
- Backend — без изменений, эндпоинт capture уже существовал

## 5. Фикс: myClubProgress всегда null для реальных клубов (2026-02-17)

**Файл:** `backend/src/api/territories.routes.ts`

**Проблема:** Mock-лидерборд содержит фейковые `clubId` (`mock-club-0`, `mock-club-1`, ...), а реальные пользователи состоят в клубах с UUID из БД. `resolveMyClubProgress` ищет пересечение — совпадение невозможно → `myClubProgress = null` всегда → bottom sheet показывает «Найти клуб» дважды (в Battle Progress и Action Bar).

**Решение:** После вызова `resolveMyClubProgress`, если результат null и у пользователя есть клуб — создаётся синтетическая запись:
- `position` = последнее место + 1
- `totalKm` = 0
- `gapToLeader` = -(km лидера)
- Запись добавляется в `leaderboard` (виден в полном лидерборде) и в `myClubProgress`

**Результат:** Пользователь в клубе видит Battle Progress с позицией своего клуба и кнопку «Run for Zone» в action bar. Нет дублирования «Найти клуб».

## Верификация

- `flutter analyze` — 0 errors (8 pre-existing info warnings)
- `flutter test` — 22 passed
- `npm test` (backend) — 139 passed
