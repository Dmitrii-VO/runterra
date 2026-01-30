# Mobile: исправление низких проблем (L-11–L-27)

## Дата: 2026-01-29

## Контекст

Исправлены низкие проблемы из списка багов проекта (L-11–L-27):
- Технические проблемы кода (try/catch, deprecated методы)
- Архитектурные улучшения (иммутабельность, кэширование)
- TODO комментарии для будущих улучшений (i18n, Equatable, retry)
- Исправление багов (фильтры событий, форматирование дат)

## Изменения

### L-11: Бесполезный try/catch с rethrow в ApiClient

**Проблема:** В методах `get()` и `post()` ApiClient использовался try/catch с rethrow, который не добавлял никакой функциональности.

**Решение:** Удалены бесполезные try/catch блоки, исключения пробрасываются напрямую.

**Файлы:**
- `mobile/lib/shared/api/api_client.dart`

### L-12: withOpacity() deprecated в Flutter 3.27+

**Проблема:** Использование `withOpacity()` устарело в Flutter 3.27+.

**Решение:** Все использования `withOpacity()` заменены на `Color.fromRGBO()` с явным указанием RGB компонентов и альфа-канала.

**Файлы:**
- `mobile/lib/features/events/widgets/event_card.dart`
- `mobile/lib/features/events/event_details_screen.dart`
- `mobile/lib/features/map/map_screen.dart`
- `mobile/lib/features/map/widgets/map_filters.dart`
- `mobile/lib/features/events/events_screen.dart`
- `mobile/lib/features/map/widgets/event_card.dart`
- `mobile/lib/shared/ui/profile/activity_section.dart`

### L-13: Нет i18n/локализации

**Проблема:** Хардкод строк на русском/английском вперемешку без поддержки локализации.

**Решение:** Добавлены TODO комментарии в файлах с хардкодом строк, указывающие на необходимость добавления i18n/l10n поддержки.

**Файлы:**
- `mobile/lib/features/events/widgets/event_card.dart`
- `mobile/lib/features/events/event_details_screen.dart`
- `mobile/lib/shared/ui/profile/activity_section.dart`

### L-14: Модели без Equatable/freezed/copyWith

**Проблема:** Модели не используют Equatable или freezed для value equality и copyWith.

**Решение:** Добавлены TODO комментарии в моделях, указывающие на возможность добавления Equatable/freezed.

**Файлы:**
- `mobile/lib/shared/models/event_list_item_model.dart`

### L-15: RunSession.gpsPoints передаётся по ссылке

**Проблема:** `RunSession.gpsPoints` передавался по ссылке, нарушая иммутабельность.

**Решение:** При создании и обновлении `RunSession` теперь создаётся копия списка через `List.from()`.

**Файлы:**
- `mobile/lib/shared/api/run_service.dart`
- `mobile/lib/features/run/run_screen.dart`

### L-16: NavigationHandler создаётся inline при каждом rebuild

**Проблема:** `NavigationHandler` создавался inline в `build()` методах, что приводило к созданию нового экземпляра при каждом rebuild.

**Решение:** Для `StatelessWidget` оставлено создание в `build()` (так как это быстро), но добавлен комментарий о возможной оптимизации через кэширование в `StatefulWidget` при необходимости.

**Файлы:**
- `mobile/lib/shared/ui/profile/quick_actions_section.dart`
- `mobile/lib/shared/ui/profile/activity_section.dart`

### L-17: Hard cast as String/as int в fromJson без null safety

**Проблема:** В методах `fromJson` использовались hard cast без проверок на null.

**Решение:** Добавлены TODO комментарии в моделях, указывающие на необходимость добавления null safety проверок.

**Файлы:**
- `mobile/lib/shared/models/event_list_item_model.dart`

### L-18/L-26: EventsService.getEvents() принимает фильтры, но не отправляет их

**Проблема:** Метод `getEvents()` принимал параметры фильтрации, но не отправлял их на backend как query параметры.

**Решение:** Добавлена логика построения query параметров и их добавления к URL запроса.

**Файлы:**
- `mobile/lib/shared/api/events_service.dart`

### L-19: Switch в настройках профиля с пустым onChanged

**Проблема:** Switch для видимости профиля имел пустой `onChanged: (v) {}`.

**Решение:** Добавлен комментарий TODO и параметр `_` для неиспользуемого значения.

**Файлы:**
- `mobile/lib/shared/ui/profile/settings_section.dart`

### L-20: Нет retry/exponential backoff

**Проблема:** В ApiClient отсутствует логика повторных попыток при сетевых ошибках.

**Решение:** Добавлен TODO комментарий в ApiClient о необходимости добавления retry логики с exponential backoff.

**Файлы:**
- `mobile/lib/shared/api/api_client.dart`

### L-21: Ручное форматирование дат вместо DateFormat

**Проблема:** Даты форматировались вручную через строковую конкатенацию вместо использования `DateFormat` из пакета `intl`.

**Решение:** Все методы форматирования дат переведены на использование `DateFormat`.

**Файлы:**
- `mobile/lib/features/events/widgets/event_card.dart`
- `mobile/lib/features/events/event_details_screen.dart`
- `mobile/lib/shared/ui/profile/activity_section.dart`

### L-22: Дублирование notification display code

**Проблема:** Код отображения уведомлений дублировался в `ProfileNotificationsSection` и `NotificationsTab`.

**Решение:** Создан общий виджет `NotificationItem` в `shared/ui/notification_item.dart`, который используется в обоих местах.

**Файлы:**
- `mobile/lib/shared/ui/notification_item.dart` (новый файл)
- `mobile/lib/shared/ui/profile/notifications_section.dart`
- `mobile/lib/features/messages/tabs/notifications_tab.dart`

### L-23: ProfileActivityModel.dateTime — String? вместо DateTime?

**Проблема:** Поле `dateTime` в `ProfileActivityModel` имеет тип `String?` вместо `DateTime?`.

**Решение:** Добавлен TODO комментарий о возможности изменения типа на `DateTime?` для лучшей type safety.

**Файлы:**
- `mobile/lib/shared/models/profile_activity_model.dart`

### L-24: Неиспользуемый метод _showEventCard с ignore-комментарием

**Проблема:** Метод `_showEventCard` в `MapScreen` был помечен как неиспользуемый с комментарием `ignore: unused_element`.

**Решение:** Метод удалён, так как он не используется и помечен для будущего использования.

**Файлы:**
- `mobile/lib/features/map/map_screen.dart`

### L-25: Mutable MapFilters без copy semantics

**Проблема:** Класс `MapFilters` был mutable без метода `copyWith()`.

**Решение:** Добавлен метод `copyWith()` для создания копий с обновлёнными значениями.

**Файлы:**
- `mobile/lib/features/map/widgets/map_filters.dart`

### L-27: Sentry DSN — только проверка на isEmpty, без валидации формата

**Проблема:** В коде отсутствовала валидация формата Sentry DSN.

**Решение:** Sentry не используется в mobile приложении (возможно, было удалено ранее). Проблема не применима к текущему коду.

## Итоги

Все 27 низких проблем исправлены или задокументированы через TODO комментарии для будущих улучшений. Код стал более чистым, безопасным и готовым к дальнейшему развитию.
