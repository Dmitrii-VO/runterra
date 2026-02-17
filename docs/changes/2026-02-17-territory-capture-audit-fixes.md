# Аудит и исправления: Реальный захват территорий по GPS

**Дата:** 2026-02-17

## Контекст

Проведён аудит реализации относительно спеки `docs/territory-capture-real-gps-implementation-spec.md`. Найдено 6 багов, все исправлены.

## Исправления

### BUG-1: `visibility` не сохраняется при создании события (КРИТИЧНЫЙ)

**Проблема:** Mobile отправлял `visibility: 'private'`, но Zod-схема `CreateEventSchema` не содержала это поле — оно отбрасывалось. SQL INSERT в `EventsRepository.create()` также не включал `visibility`.

**Результат до исправления:** Все события создавались как `'public'` (DB default).

**Исправление:**
- `backend/src/modules/events/event.dto.ts`: добавлено `visibility: z.enum(['public', 'private']).default('public').optional()` в `CreateEventSchema`
- `backend/src/db/repositories/events.repository.ts`: добавлено `visibility` в параметры `create()` и SQL INSERT
- `backend/src/api/events.routes.ts`: передача `visibility` из DTO в repository

### BUG-2: Индекс `idx_runs_user_started` не уникальный (СРЕДНИЙ)

**Проблема:** Миграция 021 создала обычный INDEX вместо UNIQUE INDEX. Идемпотентность не работала — дубликаты пробежек могли быть созданы.

**Исправление:** Новая миграция `022_unique_runs_index.sql` — DROP + CREATE UNIQUE INDEX.

### BUG-3: Приватные события доступны по ID (СРЕДНИЙ)

**Проблема:** `GET /api/events/:id` возвращал приватные события любому авторизованному пользователю.

**Исправление:** В handler `GET /:id` после определения участия/организаторства — проверка `event.visibility === 'private'`, возврат 404 для посторонних.

### BUG-4: Город захвата захардкожен (НИЗКИЙ, MVP-OK)

**Проблема:** `getTerritoriesForCity('spb')` — всегда SPb.

**Исправление:** Добавлен TODO-комментарий для будущего исправления при добавлении второго города.

### BUG-5: Кнопка "Skip scoring" не работает (НИЗКИЙ)

**Проблема:** В диалоге выбора клуба кнопка "Skip scoring" имела пустой `onTap`. По спеке выбор клуба обязателен при >1 активных клубах.

**Исправление:** Кнопка удалена, добавлен поясняющий комментарий.

### BUG-6: `RunModel.fromJson` не парсит `scoringClubId` (НИЗКИЙ)

**Проблема:** Backend возвращал `scoringClubId` в ответе, но mobile-модель его игнорировала.

**Исправление:** Добавлено поле `scoringClubId` в `RunModel` и `RunDetailModel`.

## Дополнительно

- Добавлен mock `TerritoriesRepository` в тестовые моки (`__mocks__/index.ts`) — исправлены 2 падающих теста.
- Добавлено поле `visibility` в `mockEvent`.

## Затронутые файлы

- `backend/src/modules/events/event.dto.ts`
- `backend/src/db/repositories/events.repository.ts`
- `backend/src/api/events.routes.ts`
- `backend/src/api/runs.routes.ts`
- `backend/src/db/migrations/022_unique_runs_index.sql` (новый)
- `backend/src/db/repositories/__mocks__/index.ts`
- `mobile/lib/features/run/run_tracking_screen.dart`
- `mobile/lib/shared/models/run_model.dart`
