# Fix CI: мок ActivitiesRepository для GET /api/activities

**Дата:** 2026-02-20

## Проблема

CI (backend job) падал на тесте:

- **Тест:** `API Routes › GET /api/activities › returns 200 with array`
- **Ожидание:** HTTP 200, тело — массив
- **Факт:** HTTP 500

## Причина

В `backend/src/api/api.test.ts` используется полный мок модуля репозиториев (`jest.mock('../db/repositories')`). Мок находится в `backend/src/db/repositories/__mocks__/index.ts`.

Эндпоинт `GET /api/activities` в `activities.routes.ts` вызывает `getActivitiesRepository().findByUserId(user.id, limit, offset)`. В моке не было ни `getActivitiesRepository`, ни `mockActivitiesRepository`, поэтому при импорте из замоканного модуля `getActivitiesRepository` был `undefined`. Вызов `getActivitiesRepository()` приводил к ошибке, либо возвращаемое значение не имело метода `findByUserId`, в результате в handler вызывался `activities.map(...)` на не-массиве → исключение → 500.

## Решение

В `backend/src/db/repositories/__mocks__/index.ts` добавлены:

1. **mockActivitiesRepository** — объект с методами:
   - `findByUserId` → `jest.fn().mockResolvedValue([])` (пустой массив для списка)
   - `findById` → `jest.fn().mockResolvedValue(null)`
   - `create` → `jest.fn().mockResolvedValue(...)` (stub-активность с полями id, userId, type, status, name, description, scheduledItemId, createdAt, updatedAt)

2. **getActivitiesRepository** — `jest.fn(() => mockActivitiesRepository)`

3. **ActivitiesRepository** — пустой класс в блоке re-export для совместимости типов.

## Результат

- `npm test` в backend: 152 теста проходят.
- CI backend job после push должен проходить; деплой разблокируется после успешного CI.
