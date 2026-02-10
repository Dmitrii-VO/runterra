# Журнал тренировок (история пробежек)

Дата: 2026-02-10

## Контекст

Тестировщик совершил реальную пробежку (8.73 км, 64 мин), она записалась в БД с GPS-треком (768 точек), но посмотреть её было негде — вкладка «Пробежка» показывала только экран трекинга (старт/стоп/результат).

## Изменения

### Backend (2 файла)

**`backend/src/api/runs.routes.ts`** — 3 новых GET-эндпоинта:
- `GET /api/runs` — список пробежек пользователя (только completed), пагинация `?limit=&offset=`
- `GET /api/runs/stats` — статистика: totalRuns, totalDistance, totalDuration, averagePace
- `GET /api/runs/:id` — детали пробежки с GPS-треком (проверка владельца, 403 для чужих)

Добавлен хелпер `resolveUser()` для DRY авторизации в GET-эндпоинтах.

**`backend/src/modules/runs/run.dto.ts`** — 3 новых DTO:
- `RunHistoryItemDto` — компактный элемент списка (id, startedAt, duration, distance, paceSecondsPerKm)
- `RunDetailDto` — extends RunViewDto + gpsPoints[]
- `UserRunStatsDto` — агрегированная статистика

### Mobile (11 файлов, из них 6 новых)

**Модели (3 файла):**
- `run_history_item.dart` (НОВЫЙ) — RunHistoryItem.fromJson()
- `run_stats.dart` (НОВЫЙ) — RunStats.fromJson()
- `run_model.dart` (изменён) — добавлены GpsPointModel и RunDetailModel (extends RunModel + gpsPoints)

**Сервис:**
- `run_service.dart` (изменён) — 3 новых метода: getRunHistory(), getRunStats(), getRunDetail()

**UI (5 файлов):**
- `run_screen.dart` (переписан) — роутер: активная сессия → RunTrackingScreen, иначе → RunHistoryScreen
- `run_tracking_screen.dart` (НОВЫЙ) — весь код трекинга (idle/running/completed) вынесен из старого RunScreen
- `run_history_screen.dart` (НОВЫЙ) — журнал тренировок: карточка статистики + список пробежек + empty state + FAB «Начать»
- `run_detail_screen.dart` (НОВЫЙ) — детали пробежки: карта с маршрутом + сетка метрик 2×3
- `widgets/run_detail_map.dart` (НОВЫЙ) — статическая карта с полилинией маршрута, маркерами старт (зелёный) / финиш (красный), автозум на bounding box

**Навигация:**
- `app.dart` (изменён) — добавлен роут `/run/detail/:id` → RunDetailScreen

**Локализация (13 новых ключей):**
- runHistoryTitle, runHistoryEmpty, runHistoryEmptyHint, runHistoryToday, runHistoryYesterday
- runStatsTitle, runStatsTotalRuns, runStatsTotalDistance, runStatsAvgPace
- runDetailTitle, runDetailLoadError, runGpsPoints

## Поведение

1. При открытии вкладки «Пробежка» без активной сессии → отображается журнал тренировок
2. В журнале вверху — карточка статистики (кол-во пробежек, общая дистанция, средний темп)
3. Ниже — список пробежек (дата, дистанция, время, темп)
4. Тап по пробежке → экран деталей с картой маршрута и метриками
5. FAB «Начать пробежку» → переключает на экран трекинга
6. После завершения и закрытия результата → возврат в журнал (с автообновлением)
7. При наличии активной/завершённой сессии — автоматически показывается экран трекинга

### Стрелка направления на карте трекинга

**`mobile/lib/features/run/widgets/run_route_map.dart`** — заменён маркер текущей позиции:
- Вместо синего `CircleMapObject` — навигационная стрелка (`PlacemarkMapObject`)
- Стрелка рисуется программно через `dart:ui Canvas`: синий шеврон (navigation arrow) в белом круге с тенью
- Иконка генерируется один раз в `initState` → `_generateArrowIcon()`, кэшируется как `Uint8List` (PNG)
- Поворот стрелки по `Position.heading` (0–360°, 0 = север) через `direction` + `RotationType.rotate`
- Fallback: если `heading < 0` (нет данных компаса/движения) — показывается прежний синий кружок

## Верификация

- Backend: `npm run test` — 80 тестов пройдено
- Mobile: `flutter analyze` — 4 info (все pre-existing deprecated_member_use)
- Mobile: `flutter test` — 19 тестов пройдено
