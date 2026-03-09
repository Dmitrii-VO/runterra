# Интерактивная карта: система слоёв

**Дата:** 2026-03-09
**Версия:** 1.0.6

## Что изменилось

Добавлена панель управления слоями карты — кнопка-иконка в правом верхнем углу, при нажатии разворачивается в список из 5 переключателей.

### Слои

| Слой | Тип данных | По умолчанию |
|------|------------|--------------|
| А — Территории | Полигоны + метки клубов | Вкл |
| Б — Соревнования | События типа `open_event` | Вкл |
| В — Местные события | `group_run`, `training`, `club_event` | Вкл |
| Г — Где бегать | POI: парки и стадионы СПб | Выкл |
| Д — Маршруты | Заглушка (disabled toggle) | Выкл |

### Новые файлы

- `mobile/lib/shared/models/map_layer_model.dart` — `MapLayer` enum + иммутабельный `MapLayerState`
- `mobile/lib/features/map/widgets/map_layers_panel.dart` — UI-панель слоёв

### Изменённые файлы

- `mobile/lib/features/map/map_screen.dart` — интеграция панели, разделение рендеринга по слоям, POI-маркеры (6 площадок СПб), teal иконка
- `mobile/l10n/app_en.arb`, `app_ru.arb` — 6 новых L10n ключей

### Удалённые файлы

- `mobile/lib/features/map/widgets/map_filters.dart` — мёртвый код (нет ни одного импорта)

## Технические решения

- **Бэкенд не трогаем** — POI хардкодены в Flutter как `static const`, routes stub не нужен
- **`competition`** тип в `EventType` не существует → слой Б = только `open_event`
- **Race condition fix** — `_updateCaptureLabels()` re-check layer state перед финальным `setState` (adversarial review, H1)
- **City guard** — `_updateVenueMarkers()` показывает POI только для города `spb` (adversarial review, H2)
- **Явный event type filter** — неизвестные типы событий не попадают ни в один слой, `false` вместо catch-all (adversarial review, M1)

## POI «Где бегать» (СПб)

1. Парк Победы
2. ЦПКиО им. Кирова (Елагин остров)
3. Удельный парк
4. Парк 300-летия
5. Петровский стадион
6. Южно-Приморский парк
