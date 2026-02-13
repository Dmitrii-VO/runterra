# Изменения: Карта (Maps)

## История изменений

### 2026-02-13 — Территории: полигоны вместо кругов

- **Контекст:** docs/tasks/gemini-map-zones-analysis-report.md — круги создают наложения и пустые зоны на границах.
- **Backend:** TerritoryViewDto.geometry (опционально), generateSquareGeometry в territories.config.ts — квадраты 1000×1000 м вокруг центра. GET /api/map/data возвращает территории с geometry.
- **Mobile:** TerritoryMapModel.geometry, MapScreen — PolygonMapObject при geometry.length >= 3, иначе CircleMapObject (fallback).
- **Подробности:** [2026-02-13-territory-zones-polygons.md](2026-02-13-territory-zones-polygons.md)

### 2026-02-06 — Реальные территории на карте (три популярных беговых парка СПб)

- **Backend:** `GET /api/map/data` больше не использует встроенный массив mock‑территорий (`territory-1/2/3` с условными названиями). Вместо этого он подтягивает территории через `getTerritoriesForCity(cityId, clubId?)` из нового конфига `modules/territories/territories.config.ts`, где описаны три реальные популярные беговые локации Санкт‑Петербурга: «Приморский парк Победы (Крестовский остров)», «ЦПКиО им. Кирова (Елагин остров)» и «Парк 300-летия Санкт-Петербурга`. Фильтры `onlyActive` и `clubId` применяются поверх этих данных.
- **Итог:** Карта теперь показывает осмысленные территории для бега в СПб, согласованные с эндпоинтом `/api/territories`, при этом данные по‑прежнему берутся из in‑memory конфига (без таблицы территорий), что соответствует текущему skeleton‑этапу.

### 2026-02-06 — Унификация формата ошибок для GET /api/map/data

- **Backend:** Эндпоинт `GET /api/map/data` при внутренних ошибках больше не возвращает `{ error: "Internal server error" }`, вместо этого использует единый формат ADR-0002: `500` с телом `{ code: "internal_error", message: "Internal server error" }`. Валидационные ошибки по `cityId` уже ранее приведены к `validation_error` с `details.fields`.
- **Итог:** Все ошибки карты на backend теперь следуют общей политике ошибок API `{ code, message, details? }` из `docs/api-errors-and-validation.md`.

### 2026-02-04 — Code review: кнопка закрытия bottom sheet клубов

- **Контекст:** Проверка реализации раздела «Карта и трекинг» из infra/README.md.
- **Найдена проблема:** В `_showClubsBottomSheet()` при ошибке загрузки списка клубов кнопка отображала текст «Повторить» (`retry`), но фактически закрывала bottom sheet через `Navigator.pop(context)`. Это вводило пользователя в заблуждение.
- **Исправление:** Текст кнопки заменён с `retry` на `cancel` («Закрыть»), что соответствует фактическому поведению.
- **Файлы:** `mobile/lib/features/map/map_screen.dart`.

### 2026-02-04 — Кнопка «Найти клуб» и удаление фильтров с карты

- **Контекст:** Пункты раздела «Карта и трекинг» в infra/README.md: переход на карту с отображением клубов; убрать фильтры «сегодня / неделя / мой клуб» с карты.
- **Найти клуб:** FindClubAction ведёт на `/map?showClubs=true`. MapScreen принимает параметр `showClubs`; после загрузки карты и города при `showClubs == true` один раз показывается bottom sheet (DraggableScrollableSheet) со списком клубов города — загрузка через ClubsService.getClubs(cityId), заголовок «Клубы», тап по клубу — закрытие sheet и переход на `/club/:id`. i18n: mapClubsSheetTitle, mapClubsEmpty.
- **Удаление фильтров:** С MapScreen удалены состояние `_showFilters`, поле `_filters`, кнопка фильтра в AppBar, виджет MapFiltersPanel. Вызовы getMapData выполняются только с параметром cityId (без dateFilter, clubId, onlyActive). Файл map_filters.dart оставлен в проекте для возможного использования в «Слоях карты».
- **Файлы:** `mobile/lib/shared/navigation/navigation_handler.dart`, `mobile/lib/app.dart`, `mobile/lib/features/map/map_screen.dart`, `mobile/l10n/app_en.arb`, `mobile/l10n/app_ru.arb`.

### 2026-02-04 — Фильтр «Мой клуб» на карте и в списке событий

- **Источник правды для «моего клуба»:** Реализованы `CurrentClubService` (mobile) и поле `user.primaryClubId` в GET `/api/users/me/profile` (backend). CurrentClubService хранит currentClubId, синхронизируется с профилем при init(), обновляется при присоединении к клубу (ClubDetailsScreen после join). См. [changes/users.md](changes/users.md), [changes/clubs.md](changes/clubs.md).
- **Список событий:** На экране событий (EventsScreen) добавлен чип «Мой клуб» (filtersMyClub): при выборе подставляется `clubId` из CurrentClubService в запрос `EventsService.getEvents`, список перезапрашивается. См. [changes/events.md](changes/events.md).
- **Карта:** `GET /api/map/data` по-прежнему поддерживает `clubId`; на MapScreen панель фильтров удалена, передача `clubId` на карту отложена до реализации системы слоёв (см. раздел «Слои карты» в infra/README.md).

### 2026-02-04 — Трекинг пробежки на карте (маршрут в реальном времени)

- **Контекст:** Реализация первого пункта раздела «Карта и трекинг» в infra/README.md — отображение маршрута в реальном времени во время бега.
- **Изменения:** Карта (Yandex MapKit) используется не только на MapScreen, но и на экране бега (RunScreen) в состоянии running. Виджет `RunRouteMap` строит полилинию из GPS-точек сессии (PolylineMapObject), управляет камерой (следование за последней точкой). MapScreen и API карты без изменений.
- **Файлы:** `mobile/lib/features/run/widgets/run_route_map.dart` (новый), `mobile/lib/features/run/run_screen.dart`. Подробности — [changes/runs.md](changes/runs.md).

### 2025-01-27

**Maps MVP — Реализация согласно 123.md**

- **API endpoint для карты:** Создан роутер `backend/src/api/map.routes.ts` с эндпоинтом:
  - `GET /api/map/data` — данные для карты (территории + события)
  - Query params: `bounds` (опционально, TODO: не обрабатывается), `dateFilter` (today/week, ✅ реализовано), `clubId` (✅ реализовано), `onlyActive` (✅ реализовано)
  - Возвращает: `MapDataDto` с территориями и событиями

- **Расширение DTO:**
  - `MapDataDto`: добавлены поля `territories` и `events` для отображения на карте
  - `TerritoryViewDto`: добавлено поле `clubId` для отображения клуба-владельца
  - `EventListItemDto`: добавлено поле `startLocation` для отображения маркеров на карте

- **Модели для mobile:**
  - `MapDataModel`: модель данных карты (территории + события)
  - `TerritoryMapModel`: модель территории для отображения на карте
  - `EventListItemModel`: добавлено поле `startLocation` (координаты для маркеров)

- **MapService:** Создан `mobile/lib/shared/api/map_service.dart` с методом:
  - `getMapData()` — получение данных для карты с поддержкой фильтров

- **UI компоненты карты:**
  - `MapScreen`: переработан для отображения карты с территориями и событиями
    - Стартовая позиция: GPS координаты пользователя (fallback: СПб)
    - Загрузка данных через MapService
    - Обработка ошибок и состояний загрузки
  - `TerritoryBottomSheet`: bottom sheet при тапе на территорию
    - Поля: название, статус, клуб-владелец, счётчик (TODO), CTA
  - `EventCard`: карточка события при тапе на маркер
    - Поля: когда, где, организатор, кнопка "Присоединиться"
  - `MyLocationButton`: кнопка "Моё местоположение"
    - Центрирует карту на GPS координатах пользователя
  - `MapFiltersPanel`: панель фильтров
    - Фильтры: Сегодня/неделя, Мой клуб, Только активные территории

- **Зависимости:** Добавлен пакет `intl: ^0.19.0` для форматирования дат

**Архитектурные решения:**
- Стартовая позиция: primary — GPS координаты, fallback — дефолтные координаты СПб
- Полигоны территорий: placeholder-круги вокруг центра координат (без PostGIS)
- Цвета статусов территорий: 🟦 CAPTURED (синий), ⚪ FREE (серый), 🟨 CONTESTED (жёлтый), LOCKED (тёмно-серый)
- Клубы: не показываются отдельными маркерами, только как владелец территории или организатор события
- Фильтры: минимальный набор согласно MVP (без сложных комбинаций)
- Реалтайм-обновления: простые обновления через перезагрузку данных (TODO: polling или при изменении viewport)

**Критичные доработки (2025-01-27):**

- ✅ **Отрисовка территорий (CircleAnnotation):** Реализовано отображение территорий через CircleAnnotation с радиусом 500м, цветами по статусам (🟦 CAPTURED, ⚪ FREE, 🟨 CONTESTED, LOCKED). Территории отображаются на карте и обновляются при загрузке данных.
- ✅ **Обработка тапов на территории:** Реализована обработка тапов на CircleAnnotation через класс `_TerritoryTapListenerImpl`, который реализует `OnCircleAnnotationClickListener`. При тапе показывается `TerritoryBottomSheet` с информацией о территории.
- ✅ **Фильтры в backend:** Реализована обработка фильтров `onlyActive` (только активные территории) и `dateFilter` (today/week) в API `/api/map/data`. Фильтры работают на уровне backend и применяются к mock-данным.
- ⚠️ **Маркеры событий:** Структура готова (`_updateEventsAnnotations`), но отображение через SymbolAnnotation требует дополнительной настройки иконок Mapbox. Для MVP можно использовать простые маркеры или отложить до следующей итерации.
- ⚠️ **Viewport/bounds:** Структура готова (`_loadMapDataWithBounds`), но требует доработки для получения bounds из `CameraBounds` (временная заглушка используется). Обновление при изменении viewport можно добавить через подписку на события камеры.

**Ограничения (согласно 123.md):**
- ⚠️ Частично реализовано: отображение маркеров событий (структура готова, требует настройки иконок)
- ❌ НЕ реализовано: подсветка территорий/событий пользователя (TODO: персонализация)
- ❌ НЕ реализовано: offline-просмотр тайлов (используется встроенный кеш Mapbox)
- ✅ Реализовано: архитектурная основа, модели, сервисы, UI компоненты, отображение территорий, обработка тапов, фильтры

**Файлы:**

**Backend (созданы):**
- `backend/src/api/map.routes.ts`

**Backend (изменены):**
- `backend/src/api/index.ts` — добавлен роутер map
- `backend/src/modules/map/map.dto.ts` — расширен MapDataDto
- `backend/src/modules/territories/territory.dto.ts` — добавлено поле clubId
- `backend/src/modules/events/event.dto.ts` — добавлено поле startLocation в EventListItemDto
- `backend/src/api/events.routes.ts` — добавлено startLocation в mock-данные
- `backend/src/api/map.routes.ts` — добавлено startLocation в mock-события

**Mobile (созданы):**
- `mobile/lib/shared/models/map_data_model.dart`
- `mobile/lib/shared/models/territory_map_model.dart`
- `mobile/lib/shared/models/event_start_location.dart` — общий класс для координат точки старта события (используется в EventListItemModel и EventDetailsModel)
- `mobile/lib/shared/api/map_service.dart`
- `mobile/lib/features/map/widgets/territory_bottom_sheet.dart`
- `mobile/lib/features/map/widgets/event_card.dart`
- `mobile/lib/features/map/widgets/my_location_button.dart`
- `mobile/lib/features/map/widgets/map_filters.dart`

**Mobile (изменены):**
- `mobile/lib/features/map/map_screen.dart` — переработан для Maps MVP:
  - Добавлена отрисовка территорий через CircleAnnotation (радиус 500м, цвета по статусам)
  - Добавлена обработка тапов на территории через `_TerritoryTapListenerImpl` (класс реализует `OnCircleAnnotationClickListener`)
  - Добавлена структура для обновления данных при изменении viewport (`_loadMapDataWithBounds`)
  - Добавлена структура для отображения маркеров событий (`_updateEventsAnnotations`, требует доработки иконок)
  - Реализована загрузка GPS координат при инициализации (fallback: СПб)
- `mobile/lib/shared/models/event_list_item_model.dart` — добавлено поле startLocation, удален дублирующий класс `EventStartLocation` (вынесен в отдельный файл)
- `mobile/lib/shared/models/event_details_model.dart` — удален дублирующий класс `EventStartLocation` (используется общий файл)
- `mobile/lib/features/map/widgets/my_location_button.dart` — исправлен конфликт импортов Position (используется префикс `geo` для geolocator)
- `mobile/lib/features/map/widgets/map_filters.dart` — исправлена ошибка типа bool? → bool
- `mobile/pubspec.yaml` — добавлен пакет intl

### 2026-01-29

**Mobile: исправление радиуса территорий на карте**

- **Проблема:** в `MapScreen` свойство `circleRadius` для `CircleAnnotation` получало значение `_territoryRadiusMeters = 500.0` напрямую, из-за чего 500 интерпретировалось как пиксели экрана, а не географические метры. Территории отображались как слишком большие круги, неадекватно масштабировались при изменении уровня зума.
- **Решение (техническое, без доменной логики):**
  - Добавлен пересчёт радиуса территории из метров в пиксели на основе формулы WebMercator: вычисляется `metersPerPixel` для текущей широты и `zoom`, затем `circleRadius` устанавливается как `_territoryRadiusMeters / metersPerPixel`.
  - Подписка на изменение камеры через `onCameraChangeListener` в `MapWidget` позволяет обновлять радиусы при заметном изменении zoom (порог ~0.1), чтобы круги примерно соответствовали 500 м на местности при разных уровнях зума.
  - Вся бизнес-логика территорий остаётся заглушками; изменения касаются только визуального приближения placeholder-кругов к радиусу 500 м.
- **Затронутые файлы:**
  - `mobile/lib/features/map/map_screen.dart` — добавлен расчёт `circleRadius` в пикселях на основе zoom/широты и обработчик `onCameraChanged`.

### 2026-02-02

- **Обработка 401 при загрузке данных карты (mobile):** в `MapService.getMapData()` добавлено явное распознавание HTTP 401 — выбрасывается `ApiException('unauthorized', ...)`. В `MapScreen._loadMapData()` при 401 выполняется попытка обновить токен (`ServiceLocator.refreshAuthToken()`) и повторный запрос; при повторном 401 — редирект на экран входа (`context.go('/login')`). Backend не изменён.

**Файлы:** `mobile/lib/shared/api/map_service.dart`, `mobile/lib/features/map/map_screen.dart`.

- **Обязательный cityId для данных карты (backend):** эндпоинт `GET /api/map/data` теперь требует query‑параметр `cityId`; при его отсутствии возвращается `400 validation_error` с кодом `city_required`, при неизвестном городе — `city_not_found`. Для указанного города данные карты ограничиваются только его территориями и событиями: mock‑территории получают `cityId` из запроса, события выбираются из БД с фильтром `city_id = :cityId`. Viewport центрируется по `center` города из модуля `cities`.
- **Mobile MapService: cityId в запросах:** метод `MapService.getMapData` расширен обязательным параметром `cityId` и всегда добавляет его в query‑строку `/api/map/data?cityId=...`. Дополнительно пробрасываются фильтры `dateFilter`, `clubId`, `onlyActive` как и раньше.
- **Выбор и кеширование текущего города (mobile):** добавлен сервис `CurrentCityService` (DI через `ServiceLocator`), который хранит `currentCityId` в SharedPreferences и синхронизирует его с профилем пользователя (`GET /api/users/me/profile`). При первом запуске без города показывается диалог выбора города (СПб и др. из `/api/cities`), выбранный `cityId` сохраняется локально; TODO: в будущем отправлять выбор на backend.
- **Нормализация Yandex MapKit под город:** `MapScreen` инициализируется только после выбора города, использует `CurrentCityService.getCurrentCity()` для получения центра/границ города и устанавливает стартовую позицию камеры по `city.center` с городским zoom (12). Добавлен обработчик `onCameraPositionChanged`, который ограничивает zoom диапазоном `[9.0; 19.0]` и «обрезает» целевую точку камеры по прямоугольнику `bounds` города, не позволяя выйти за пределы города.
- **Передача cityId/clubId с клиента и дополнительная фильтрация:** при загрузке карты `MapScreen` всегда передаёт `cityId = currentCityId` (и `clubId` из фильтров, если выбран) в `MapService.getMapData`. Модели событий/территорий содержат `cityId`, что позволяет при необходимости дополнительно отфильтровать объекты на клиенте и гарантировать отсутствие кросс‑городовых данных на карте.
