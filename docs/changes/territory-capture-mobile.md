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

## Верификация

- `flutter analyze` — 0 errors (8 pre-existing info warnings)
- `flutter test` — 22 passed
- `npm test` (backend) — 139 passed
