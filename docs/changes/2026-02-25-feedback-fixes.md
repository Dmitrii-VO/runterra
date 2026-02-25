# Feedback-фиксы (2026-02-25)

## Контекст

Реализованы 8 фидбеков от пользователя по мобильному приложению.

## Изменения

### 1. Карта не центрируется при входе (`map_screen.dart`)

**Проблема:** Карта показывала Москву/мир, затем анимировала на СПб. При загрузке данных — вторая анимация.

**Фикс:**
- Убран вызов `_centerMapOnStartPosition()` из `_loadMapData` — теперь центрирование только в `_onMapCreated`
- Анимация изменена с `duration: 0.5` на `duration: 0.0` — карта появляется сразу в нужном месте
- Поле `_hasFocusPoint` удалено (стало неиспользуемым)

### 2. Кнопка «Назад» на старте пробежки (`run_tracking_screen.dart`)

**Проблема:** Нельзя вернуться с экрана «Начать пробежку» на журнал.

**Фикс:** В `AppBar` добавлен `leading: IconButton(Icons.arrow_back)` при `_state == idle && widget.onRunCompleted != null`.

### 3. Входящие сообщения двигают список (`club_messages_tab.dart`)

**Проблема:** При прокрутке вверх (чтение истории) входящие сообщения всё равно скроллили вниз (порог 80px был слишком большим).

**Фикс:**
- Добавлен флаг `_userScrolledAway` — устанавливается в `true` когда пользователь отскроллил >200px от дна
- `_isNearBottom()` возвращает `false` если `_userScrolledAway == true`
- `NotificationListener` теперь вызывает `_onScrollNotification()` который управляет флагами

### 4. Кнопка «↓» в чате (`club_messages_tab.dart`)

**Фикс:** `FloatingActionButton.small` с иконкой `keyboard_arrow_down` появляется в правом нижнем углу списка при `_showScrollToBottom == true`. При нажатии — прокручивает вниз и сбрасывает `_userScrolledAway`.

### 5. Баннер активного клуба + территории (`map_screen.dart`)

**Добавлено:**
- State: `_activeClub`, `_currentTerritory`, `_myClubs`, `_territoryCheckTimer`
- В `initState` вызывается `_loadActiveClub()` (загружает список клубов пользователя)
- После загрузки данных карты запускается `Timer.periodic(30s)` → `_checkCurrentTerritory()`
- `_findTerritoryAtPoint(lat, lon)`: point-in-polygon (ray casting) для полигонов, haversine для кругов
- Баннер в заголовке карты: `[Клуб: X ▾] [Территория: Y]`; тап на клуб (при >1 клубе) → bottom sheet выбора

### 6. Типы событий ограничены (`create_event_screen.dart`)

**Фикс:** Удалены `group_run` и `club_event` из `DropdownButtonFormField`. Остались только `training` и `open_event`.

### 7. Вкладка «События» — только `open_event` (`events_screen.dart`)

**Фикс:** В `_fetchCityEvents()` добавлен client-side фильтр: `.where((event) => event.type == 'open_event')`.

### 8. FAB скрыт от обычных пользователей (`events_screen.dart`)

**Фикс:**
- `_resolveTrainingClubId()` теперь устанавливает `_myRoleInClub` (из `MyClubModel.role`)
- `_buildFab()` возвращает `null` на вкладке «Тренировки» если роль не `trainer` / `leader`
- `_tabController.addListener(() => setState(() {}))` — FAB перестраивается при смене таба

### Новые ключи l10n (EN + RU)

| Ключ | EN | RU |
|------|----|----|
| `mapActiveClub(name)` | `Club: {name}` | `Клуб: {name}` |
| `mapNoActiveClub` | `No club` | `Нет клуба` |
| `mapCurrentTerritory(name)` | `Territory: {name}` | `Территория: {name}` |
| `mapNoTerritory` | `No territory` | `Нет территории` |
| `selectClub` | `Select club` | `Выбрать клуб` |
| `messagesScrollToBottom` | `Scroll to bottom` | `В конец` |

## Проверка

- `flutter analyze` — 0 errors, 35 info (pre-existing deprecation warnings)
- Новых ошибок не добавлено
