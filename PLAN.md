# План: Выбор клуба для зачета и исправление бага карты

**Дата:** 2026-02-26
**Статус:** Ожидает реализации (Phase 2)

## Цель
1. Добавить возможность выбора клуба, за который идет пробежка, ДО старта трекинга.
2. Исправить баг с множественным открытием BottomSheet при клике на границы районов на карте.

## Шаги реализации

### 1. Модели данных
- [ ] **Файл:** `mobile/lib/shared/models/run_session.dart`
- [ ] Добавить поле `final String? scoringClubId` в класс `RunSession`.
- [ ] Обновить конструктор и метод `copyWith`.

### 2. Сервис пробежек
- [ ] **Файл:** `mobile/lib/shared/api/run_service.dart`
- [ ] Обновить метод `startRun(String? activityId, String? scheduledItemId, {String? scoringClubId})`.
- [ ] Сохранять `scoringClubId` в создаваемой `_currentSession`.
- [ ] Обновить метод `submitRun({String? scoringClubId})`: если параметр не передан явно, использовать `_currentSession?.scoringClubId`.

### 3. Экран трекинга (UI)
- [ ] **Файл:** `mobile/lib/features/run/run_tracking_screen.dart`
- [ ] Добавить `MyClubModel? _selectedScoringClub` в состояние.
- [ ] В `initState` инициализировать его активным клубом из `ServiceLocator.currentClubService`.
- [ ] В `_buildIdleContent` добавить виджет выбора клуба перед кнопкой "Начать".
- [ ] При клике открывать диалог выбора из списка `clubsService.getMyClubs()`.
- [ ] В `_startRun` передавать `_selectedScoringClub?.id` в сервис.

### 4. Исправление карты
- [ ] **Файл:** `mobile/lib/features/map/map_screen.dart`
- [ ] Добавить флаг `bool _isSheetShowing = false` в `_MapScreenState`.
- [ ] В методе `_showTerritoryBottomSheet` добавить защиту: `if (_isSheetShowing) return;`.
- [ ] Устанавливать `_isSheetShowing = true` перед вызовом `showModalBottomSheet`.
- [ ] Сбрасывать в `false` через `.whenComplete(() => setState(() => _isSheetShowing = false))`.

## Верификация
- [ ] Проверить, что при старте пробежки выбранный клуб сохраняется.
- [ ] Проверить, что в конце пробежки данные уходят на сервер с правильным `scoringClubId`.
- [ ] Проверить клик на стыке районов (Невский/Фрунзенский) — должно открываться только одно окно.
