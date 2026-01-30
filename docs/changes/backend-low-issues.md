# Backend: исправление низких проблем (L-1–L-10)

**Дата:** 2026-01-29

## Обзор

Исправлены технические проблемы кода backend, выявленные при ревью. Изменения касаются только качества кода и не влияют на бизнес-логику или доменные инварианты.

## Изменения

### L-4: Префикс _ для неиспользуемых параметров в error handler

**Файл:** `backend/src/app.ts`

В error handler middleware параметры `req` и `next` не использовались напрямую, но требовались по сигнатуре Express. Добавлен префикс `_` для явного указания неиспользуемых параметров.

**До:**
```typescript
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
```

**После:**
```typescript
app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
```

### L-5: Адрес прослушивания сервера зависит от окружения

**Файл:** `backend/src/server.ts`

Сервер слушал на `0.0.0.0` во всех окружениях. Теперь в production используется `localhost` для безопасности, в dev — `0.0.0.0` для доступа из Android эмулятора.

**До:**
```typescript
app.listen(PORT, '0.0.0.0', () => {
```

**После:**
```typescript
const listenAddress = process.env.NODE_ENV === 'production' ? 'localhost' : '0.0.0.0';
app.listen(PORT, listenAddress, () => {
```

### L-6: Приведение типов для req.query

**Файлы:** `backend/src/api/events.routes.ts`, `backend/src/api/map.routes.ts`

Добавлено явное приведение типов для `req.query` перед деструктуризацией, чтобы избежать проблем с типизацией TypeScript.

**До:**
```typescript
const { dateFilter, clubId, ... } = req.query;
```

**После:**
```typescript
const query = req.query as Record<string, string | undefined>;
const { dateFilter, clubId, ... } = query;
```

### L-7: Роутеры используют barrel exports модулей

**Файлы:** Все файлы в `backend/src/api/*.routes.ts`

Роутеры импортировали типы и DTO напрямую из файлов модулей вместо использования barrel exports (`index.ts`). Все импорты переведены на barrel exports для единообразия и упрощения рефакторинга.

**До:**
```typescript
import { User, UserStatus } from '../modules/users/user.entity';
import { CreateUserDto, CreateUserSchema } from '../modules/users/user.dto';
```

**После:**
```typescript
import { User, UserStatus, CreateUserDto, CreateUserSchema } from '../modules/users';
```

### L-8: Переименование Notification → UserNotification

**Файлы:** 
- `backend/src/modules/notifications/notification.entity.ts`
- `backend/src/modules/notifications/index.ts`
- `backend/src/modules/users/profile.dto.ts`
- `backend/src/api/users.routes.ts`

Интерфейс `Notification` затенял встроенный Web API `Notification` (браузерный API для уведомлений). Переименован в `UserNotification`, добавлен type alias `Notification` в barrel export для обратной совместимости.

**До:**
```typescript
export interface Notification { ... }
```

**После:**
```typescript
export interface UserNotification { ... }
// В index.ts:
export type { UserNotification as Notification } from './notification.entity';
```

### L-2: Исправление дублирующегося re-export в auth barrel

**Файл:** `backend/src/auth/index.ts`

Устранён дублирующийся re-export: `auth/index.ts` экспортировал `export * from './types'`, а `types.ts` реэкспортировал из `modules/auth`. Теперь `auth/index.ts` экспортирует типы напрямую из `types.ts` без промежуточного реэкспорта.

**До:**
```typescript
export * from './types'; // types.ts реэкспортирует из modules/auth
```

**После:**
```typescript
export type { AuthUser, TokenVerificationResult, AuthProvider, FirebaseUser } from './types';
```

### L-10: Переименование isMercantile → isMercenary

**Файлы:**
- `backend/src/modules/users/user.dto.ts`
- `backend/src/modules/users/user.entity.ts`
- `backend/src/modules/users/profile.dto.ts`
- `backend/src/api/users.routes.ts`

Исправлено название поля: `isMercantile` → `isMercenary` (правильное написание слова "наёмник").

**Затронутые места:**
- Интерфейсы `CreateUserDto`, `UpdateUserDto`, `UserViewDto`
- Интерфейс `User` entity
- Интерфейс `ProfileDto.user`
- Zod-схема `CreateUserSchema`
- Mock-данные в `users.routes.ts`
- Комментарии в `profile.dto.ts`

### L-3: Удаление неиспользуемых деструктурированных query-параметров

**Файлы:** `backend/src/api/events.routes.ts`, `backend/src/api/map.routes.ts`

Query-параметры деструктурировались, но не использовались (TODO для будущей реализации). Параметры оставлены для будущего использования, но добавлено приведение типов (см. L-6).

### L-9: tracesSampleRate: 0.0

**Статус:** Не найдено

Конфигурация Sentry с `tracesSampleRate: 0.0` не найдена в коде. Модуль Sentry помечен как deprecated (`backend/src/shared/sentry.ts`), логирование переведено на локальный logger.

### L-1: Неиспользуемые импорты в DTO-файлах

**Статус:** Проверено

Все импорты в DTO-файлах используются. TypeScript compiler и линтер не выявили неиспользуемых импортов.

## Затронутые файлы

### Backend
- `backend/src/app.ts`
- `backend/src/server.ts`
- `backend/src/api/events.routes.ts`
- `backend/src/api/map.routes.ts`
- `backend/src/api/users.routes.ts`
- `backend/src/api/cities.routes.ts`
- `backend/src/api/clubs.routes.ts`
- `backend/src/api/territories.routes.ts`
- `backend/src/api/activities.routes.ts`
- `backend/src/api/runs.routes.ts`
- `backend/src/auth/index.ts`
- `backend/src/modules/notifications/notification.entity.ts`
- `backend/src/modules/notifications/index.ts`
- `backend/src/modules/users/user.dto.ts`
- `backend/src/modules/users/user.entity.ts`
- `backend/src/modules/users/profile.dto.ts`

## Влияние на поведение

- **Бизнес-логика:** Не изменена
- **Доменные инварианты:** Не изменены
- **API контракты:** Не изменены (все изменения внутренние, кроме переименования `isMercantile` → `isMercenary`, которое требует обновления клиентов)
- **Безопасность:** Улучшена (production сервер слушает только localhost)

## Примечания

- Переименование `isMercantile` → `isMercenary` требует обновления мобильного клиента и админки при следующем обновлении API.
- Type alias `Notification` в barrel export сохранён для обратной совместимости, но рекомендуется использовать `UserNotification` в новом коде.
