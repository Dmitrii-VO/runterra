# Тренер: приватный / клубный / участник

**Дата:** 2026-02-24

## Контекст

Расширение модели тренера: до этого TrainerProfile требовал `isTrainerInAnyClub()`. Независимый тренер не мог создать профиль без клубной роли. Реализована модель «два независимых аспекта» (Вариант D).

## Два независимых аспекта

| Аспект | Механизм | Что даёт |
|---|---|---|
| **Тренерский профиль** | `trainer_profiles.accepts_private_clients` | Профессиональная витрина, личные события, видимость в discovery |
| **Клубная роль** | `club_members.role = trainer/leader` | Права управления клубом, создание клубных событий |

## Изменения

### Backend

#### DB Migration `027_trainer_private.sql`
```sql
ALTER TABLE trainer_profiles
  ADD COLUMN IF NOT EXISTS accepts_private_clients BOOLEAN NOT NULL DEFAULT false;
```

#### `trainer.entity.ts`
- Добавлено поле `acceptsPrivateClients: boolean`

#### `trainer.dto.ts`
- `acceptsPrivateClients: z.boolean().optional()` добавлено в `CreateTrainerProfileSchema` и `UpdateTrainerProfileSchema` (через `.partial()`)

#### `trainer_profiles.repository.ts`
- Обновлены `create`, `update`, `rowToProfile` для поддержки `accepts_private_clients`
- Новый метод `findPublicTrainers({ cityId?, specialization? })` — JOIN с users, фильтр по `accepts_private_clients = true`

#### `trainer.routes.ts`
- **Удалён** `isTrainerInAnyClub()` гейт из `POST /api/trainer/profile` и `PATCH /api/trainer/profile`
- Теперь любой аутентифицированный пользователь с `bio + ≥1 specialization` может создать профиль
- Добавлен **`GET /api/trainer`** — discovery endpoint (список тренеров с `accepts_private_clients = true`)

#### `events.routes.ts`
Добавлена авторизация создания событий в `POST /api/events`:
- `organizerType = 'club'` → `isTrainerOrLeaderInClub(userId, organizerId)` (403 иначе)
- `organizerType = 'trainer'` → `accepts_private_clients = true` + `organizerId === userId` (403 иначе)

### Mobile

#### `shared/models/trainer_profile.dart`
- `TrainerProfile`: добавлено поле `acceptsPrivateClients: bool`
- Новый класс `PublicTrainerEntry` для discovery-экрана

#### `shared/api/trainer_service.dart`
- `createProfile()`: новый параметр `acceptsPrivateClients`
- Новый метод `getTrainers({ cityId?, specialization? })` → `GET /api/trainer`

#### `features/trainer/trainer_edit_profile_screen.dart`
- Добавлен `SwitchListTile` «Принимаю частных клиентов» (`acceptsPrivateClients`)
- При сохранении передаётся в create/update

#### `features/trainer/trainer_profile_screen.dart`
- Показывает `Chip` «Приватный тренер» если `acceptsPrivateClients = true`

#### `features/profile/edit_profile_screen.dart`
- Секция «Тренер» внизу формы: toggle `acceptsPrivateClients` + кнопка «Настроить тренерский профиль»
- Загружает тренерский профиль в `initState`

#### `features/profile/profile_screen.dart`
- Тренерская карточка (Trainer Profile / Edit Trainer Profile / Workouts) показывается **только если** у пользователя есть TrainerProfile
- Добавлена кнопка «Найти тренера» → `/trainers`

#### `features/trainer/trainers_list_screen.dart` (новый)
- Discovery-экран: список тренеров с `accepts_private_clients = true`
- Фильтр по специализации (FilterChips)
- Карточка тренера: аватар (инициал), имя, bio, specialization chips → переход на `/trainer/:userId`

#### `app.dart`
- Новый роут `/trainers` → `TrainersListScreen`

### i18n (оба ARB файла)
- `trainerSection` — заголовок секции в EditProfileScreen
- `trainerAcceptsClients` — label toggle
- `trainerAcceptsClientsHint` — подсказка под toggle
- `trainerSetupProfile` — кнопка «Настроить тренерский профиль»
- `trainerPrivateBadge` — badge «Приватный тренер»
- `findTrainers` — заголовок discovery экрана
- `trainersList` — список тренеров
- `trainersEmpty`, `trainersLoadError`

## Матрица прав (итоговая)

| Действие | member | club trainer | private trainer | both |
|---|---|---|---|---|
| Создать TrainerProfile | ✅ (bio+spec) | ✅ | ✅ | ✅ |
| Видеть в discovery | ❌ | ❌ | ✅ | ✅ |
| Создать личное событие | ❌ | ❌ | ✅ | ✅ |
| Создать событие клуба | ❌ | ✅ | ❌ | ✅ |
| Личные тренировки (workout) | ❌ | ✅ | ✅ | ✅ |

## Что НЕ изменилось

- Клубные роли `trainer`/`leader`/`member` и их права — без изменений
- `isTrainerOrLeaderInClub()` — остаётся для клубных операций
- Events flow для участников — join event как обычно
- Workouts: `clubId = null` = личные, `clubId != null` = клубные
