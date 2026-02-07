# Исправления по Feedback (2026-02-06)

Дата: 2026-02-08

## Обзор

Реализованы исправления для трёх критических проблем, выявленных в Feedback (2026-02-06).

## Пробежка: отображение позиции и темпа

### Проблема
- При старте пробежки не отображалась текущая позиция на карте
- Отсутствовала кнопка «Найти себя» для центрирования карты
- Темп считался некорректно до стабилизации GPS

### Решение

**Mobile:**
- `mobile/lib/features/run/widgets/run_route_map.dart`:
  - Добавлен `CircleMapObject` для отображения текущей позиции (синий круг с белой обводкой)
  - Добавлена FAB кнопка «Найти себя» (`runFindMe`) в правом нижнем углу карты
  - Публичный метод `centerOnCurrentPosition()` для центрирования камеры
- `mobile/lib/features/run/run_screen.dart`:
  - Увеличен минимальный порог для расчёта темпа с 0.01 км (10м) до 0.05 км (50м)
  - Добавлено отображение текущего темпа во время пробежки (или "—" если данных недостаточно)
- `mobile/l10n/*.arb`:
  - Добавлен ключ `runFindMe` для локализации кнопки

### Файлы
- `mobile/lib/features/run/widgets/run_route_map.dart`
- `mobile/lib/features/run/run_screen.dart`
- `mobile/l10n/app_ru.arb`
- `mobile/l10n/app_en.arb`

## Клубы: реальное создание и получение

### Проблема
- `POST /api/clubs` и `GET /api/clubs/:id` возвращали моки
- Создатель клуба не добавлялся в участники автоматически
- Название и описание клуба не сохранялись

### Решение

**Backend:**
- Миграция `010_clubs.sql`:
  - Создана таблица `clubs` с полями: id (UUID), name, description, status, city_id, creator_id, created_at, updated_at
  - Добавлены индексы для city_id, creator_id, status
- `backend/src/db/repositories/clubs.repository.ts`:
  - Создан ClubsRepository с методами: findById, findByCityId, create, update, delete
  - Singleton-функция getClubsRepository()
- `backend/src/modules/clubs/club.entity.ts`:
  - Добавлено поле `creatorId: string` в интерфейс Club
- `backend/src/api/clubs.routes.ts`:
  - `GET /api/clubs`: получение клубов из БД через ClubsRepository.findByCityId()
  - `GET /api/clubs/:id`: получение клуба из БД, возврат 404 если не найден
  - `POST /api/clubs`: создание клуба в БД + автоматическое добавление создателя в club_members со статусом active

### Файлы
- `backend/src/db/migrations/010_clubs.sql`
- `backend/src/db/repositories/clubs.repository.ts`
- `backend/src/db/repositories/index.ts`
- `backend/src/modules/clubs/club.entity.ts`
- `backend/src/api/clubs.routes.ts`

## События: time-based статус completed

### Проблема
- Прошедшие события отображались со статусом «Открыто»
- В модели событий отсутствовало поле `endDateTime`
- Статус обновлялся только по лимиту участников

### Решение

**Backend:**
- Миграция `011_events_end_date_time.sql`:
  - Добавлено поле `end_date_time TIMESTAMP WITH TIME ZONE` в таблицу events
  - Для существующих событий установлено end_date_time = start_date_time + 2 часа
  - Добавлен индекс для end_date_time
- `backend/src/modules/events/event.entity.ts`:
  - Добавлено поле `endDateTime?: Date` в интерфейс Event
- `backend/src/modules/events/event.dto.ts`:
  - Добавлено поле `endDateTime?: Date` в CreateEventDto, EventDetailsDto, EventListItemDto
  - Обновлена схема CreateEventSchema для поддержки endDateTime
- `backend/src/db/repositories/events.repository.ts`:
  - Добавлено поле `end_date_time` в EventRow
  - Обновлена функция `rowToEvent` для маппинга endDateTime
  - Создана функция `computeEventStatus(row)` для вычисления актуального статуса:
    - Если endDateTime прошло → COMPLETED
    - Если лимит участников достигнут → FULL
    - Иначе → статус из БД
  - Обновлён метод `create()` для сохранения endDateTime

### Логика computeEventStatus
```typescript
// Приоритет статусов:
// 1. CANCELLED/COMPLETED из БД сохраняются
// 2. Если endDateTime < now → COMPLETED
// 3. Если participantCount >= participantLimit → FULL
// 4. Иначе → статус из БД (OPEN/DRAFT)
```

### Файлы
- `backend/src/db/migrations/011_events_end_date_time.sql`
- `backend/src/modules/events/event.entity.ts`
- `backend/src/modules/events/event.dto.ts`
- `backend/src/db/repositories/events.repository.ts`

## Тестирование

**Рекомендуемые проверки:**

1. **Пробежка:**
   - Начать пробежку и убедиться, что текущая позиция отображается синим кружком
   - Нажать кнопку «Найти себя» — карта должна центрироваться на текущей позиции
   - Проверить, что темп не отображается (показывается "—") пока не пройдено 50+ метров
   - После 50м темп должен отображаться корректно

2. **Клубы:**
   - Создать новый клуб через мобильное приложение
   - Проверить, что клуб отображается с правильным названием и описанием
   - Убедиться, что создатель автоматически является участником клуба
   - Проверить GET /api/clubs/:id для существующего и несуществующего клуба

3. **События:**
   - Создать событие с endDateTime в прошлом
   - Убедиться, что событие отображается со статусом «Завершено»
   - Создать событие с endDateTime в будущем
   - Убедиться, что событие отображается со статусом «Открыто»
   - После наступления endDateTime статус должен автоматически стать «Завершено»

## Возможные риски

1. **Миграции БД**: необходимо применить миграции 010 и 011 перед запуском обновлённого backend
2. **Обратная совместимость**: старые события без end_date_time будут иметь endDateTime = undefined, статус будет вычисляться только по participantLimit
3. **Mobile**: после обновления локализации может потребоваться перезапуск приложения для применения новых строк

## Следующие шаги

- [ ] Запустить миграции на production: `npm run migrate:prod`
- [ ] Протестировать создание клуба на production
- [ ] Протестировать создание события с endDateTime
- [ ] Проверить отображение прошедших событий
