# Спецификация реализации функционала "Тренер" (Trainer 2.0)

## 1. Контекст и Цели

Текущая реализация роли `TRAINER` в клубах является номинальной. Цель данной спецификации — превратить тренера в функциональную единицу системы, предоставив инструменты для ведения профиля и создания библиотеки тренировок.

Ссылки:
- Роли и права: `docs/adr/0005-trainers-role.md`
- Формат ошибок и валидация: `docs/adr/0002-*` (Zod, `{ code, message, details? }`)

---

## 2. Архитектура и Сущности

### 2.1. Профиль Тренера (`TrainerProfile`)

Глобальный профиль пользователя как специалиста. Существует в единственном экземпляре для `User`, независимо от количества клубов, в которых он состоит.

**Таблица:** `trainer_profiles`

| Поле | Тип | Описание |
|---|---|---|
| `userId` | UUID (PK, FK) | Связь с таблицей пользователей (1:1) |
| `bio` | Text | Описание, философия, подход к тренировкам |
| `specialization` | Array\<Enum\> | `MARATHON`, `SPRINT`, `TRAIL`, `RECOVERY`, `GENERAL` |
| `experienceYears` | Integer | Стаж работы/тренировок (лет) |
| `certificates` | JSONB | Список сертификатов `[{ name, date, organization }]` |
| `createdAt` | Timestamp | Дата создания профиля |

**Правила доступа к профилю:**
- Создание/редактирование — только пока пользователь имеет роль `trainer` или `leader` хотя бы в одном клубе
- При понижении роли (до `member` во всех клубах) — профиль остаётся видимым (read-only), но недоступен для редактирования
- Просмотр — любой авторизованный пользователь

**Future (не MVP):**
- `rating` (Float) — рейтинг 0.0–5.0
- `isVerified` (Boolean) — верификация администрацией
- `socialLinks` (JSONB) — Instagram, Telegram, Strava

---

### 2.2. Библиотека Тренировок (`Workout`)

Шаблоны тренировок, которые тренер создаёт один раз и переиспользует в расписании.

**Таблица:** `workouts`

| Поле | Тип | Описание |
|---|---|---|
| `id` | UUID (PK) | Уникальный ID тренировки |
| `authorId` | UUID (FK) | ID тренера (User) |
| `clubId` | UUID (FK, Nullable) | ID клуба (если тренировка принадлежит клубу) |
| `name` | String | Название ("Интервалы 8x400", "Восстановительная") |
| `description` | Text | Текстовое описание задачи и плана тренировки |
| `type` | Enum | `RECOVERY`, `TEMPO`, `INTERVAL`, `FARTLEK`, `LONG_RUN` |
| `difficulty` | Enum | `BEGINNER`, `INTERMEDIATE`, `ADVANCED`, `PRO` |
| `targetMetric` | Enum | `DISTANCE`, `TIME`, `PACE` (основная цель) |
| `createdAt` | Timestamp | Дата создания |

**Правила видимости:**
- `clubId != null` → видна всем членам этого клуба
- `clubId == null` → видна только автору (личная библиотека)

**Future (не MVP):**
- `isPublic` (Boolean) — видимость для других тренеров
- `structure` (JSONB) — структурированный план тренировки (конструктор, см. секцию 8.1)

---

### 2.3. Интеграция с Событиями (`Event`)

Расширение существующей таблицы событий для связи с библиотекой тренировок.

**Изменения в таблице:** `events`

| Поле | Тип | Описание |
|---|---|---|
| `workoutId` | UUID (FK, Nullable) | Ссылка на шаблон тренировки |
| `trainerId` | UUID (FK, Nullable) | Ведущий тренер занятия (может отличаться от `organizerId`) |

Семантика `trainerId`: это тренер, который **проводит** занятие. Он может отличаться от `organizerId` (организатора события). Например, лидер клуба создаёт событие (`organizerId`), а провести его назначает конкретного тренера (`trainerId`).

**Future (не MVP):**
- `actualDistance` (Integer) — фактическая дистанция, заполняется тренером вручную через PATCH

---

## 3. API Endpoints

Все эндпоинты защищены глобальным `authMiddleware` (ADR-0002). Валидация тел запросов — через Zod-схемы с `validateBody` middleware. Ошибки валидации: HTTP 400, `{ code: "validation_error", message: "...", details: { fields: [...] } }`.

### 3.1. TrainerProfile

| Метод | Путь | Описание | Кто может |
|---|---|---|---|
| `GET` | `/api/trainer/profile` | Свой профиль тренера | Автор (trainer/leader в любом клубе) |
| `GET` | `/api/trainer/profile/:userId` | Публичный просмотр профиля | Любой авторизованный |
| `POST` | `/api/trainer/profile` | Создать профиль | trainer/leader в любом клубе |
| `PATCH` | `/api/trainer/profile` | Обновить свой профиль | Автор (trainer/leader в любом клубе) |

**`POST /api/trainer/profile` — Request Body:**
```json
{
  "bio": "string (optional)",
  "specialization": ["MARATHON", "SPRINT"],
  "experienceYears": 5,
  "certificates": [{ "name": "...", "date": "...", "organization": "..." }]
}
```

**`GET /api/trainer/profile/:userId` — Response:**
```json
{
  "userId": "uuid",
  "bio": "...",
  "specialization": ["MARATHON"],
  "experienceYears": 5,
  "certificates": [...],
  "createdAt": "2026-01-15T10:00:00Z"
}
```

### 3.2. Workouts

| Метод | Путь | Описание | Кто может |
|---|---|---|---|
| `GET` | `/api/workouts` | Список: свои + клубные (`?clubId=...`) | trainer/leader (свои); член клуба (клубные) |
| `GET` | `/api/workouts/:id` | Детали шаблона | Автор или член клуба (если clubId) |
| `POST` | `/api/workouts` | Создать шаблон | trainer/leader в любом клубе |
| `PATCH` | `/api/workouts/:id` | Обновить шаблон | Только автор |
| `DELETE` | `/api/workouts/:id` | Удалить шаблон | Только автор (если не привязан к будущему событию) |

**`POST /api/workouts` — Request Body:**
```json
{
  "clubId": "uuid | null",
  "name": "Интервалы 8x400",
  "description": "Разминка 10 мин, 8 ускорений по 400 м через 90 сек отдыха, заминка",
  "type": "INTERVAL",
  "difficulty": "INTERMEDIATE",
  "targetMetric": "DISTANCE"
}
```

**`GET /api/workouts` — Query Parameters:**
- `clubId` (optional) — фильтр по клубу. Без параметра — только личные шаблоны автора

**`GET /api/workouts/:id` — Response:**
```json
{
  "id": "uuid",
  "authorId": "uuid",
  "clubId": "uuid | null",
  "name": "...",
  "description": "...",
  "type": "INTERVAL",
  "difficulty": "INTERMEDIATE",
  "targetMetric": "DISTANCE",
  "createdAt": "2026-01-15T10:00:00Z"
}
```

**`DELETE /api/workouts/:id` — Ограничения:**
- Если шаблон привязан к будущему событию (`events.workoutId = :id` AND `events.date > now()`), удаление запрещено
- Ответ: HTTP 409, `{ code: "workout_in_use", message: "Workout is linked to upcoming events" }`

### 3.3. Event Extension

| Метод | Путь | Описание | Кто может |
|---|---|---|---|
| `PATCH` | `/api/events/:id` | Добавить/обновить `workoutId`, `trainerId` | leader/trainer клуба (организатор или тренер клуба) |

**Request Body (расширение существующего PATCH):**
```json
{
  "workoutId": "uuid | null",
  "trainerId": "uuid | null"
}
```

**Валидация:**
- `workoutId` — должен ссылаться на существующий workout, принадлежащий тому же клубу или автору
- `trainerId` — должен быть пользователем с ролью trainer/leader в клубе события

---

## 4. Права доступа (матрица)

### 4.1. Определение «является тренером»

Пользователь считается тренером, если имеет роль `trainer` или `leader` хотя бы в одном активном клубе. Проверка: `SELECT 1 FROM club_members WHERE user_id = :userId AND role IN ('trainer', 'leader') AND status = 'active' LIMIT 1`.

### 4.2. Матрица прав

| Действие | member | trainer | leader | Примечание |
|---|---|---|---|---|
| Создать TrainerProfile | ❌ | ✅ | ✅ | В любом клубе |
| Редактировать свой TrainerProfile | ❌ | ✅ | ✅ | Пока есть роль |
| Просмотреть чужой TrainerProfile | ✅ | ✅ | ✅ | Любой авторизованный |
| Создать Workout | ❌ | ✅ | ✅ | |
| Редактировать свой Workout | ❌ | ✅ (автор) | ✅ (автор) | Только автор шаблона |
| Удалить свой Workout | ❌ | ✅ (автор) | ✅ (автор) | Если не привязан к будущим событиям |
| Просмотреть клубный Workout | ✅ (член клуба) | ✅ | ✅ | Члены клуба |
| Просмотреть личный Workout | ❌ | ✅ (автор) | ✅ (автор) | Только автор |
| Назначить workoutId на событие | ❌ | ✅ (клуб) | ✅ (клуб) | trainer/leader клуба события |
| Назначить trainerId на событие | ❌ | ❌ | ✅ (клуб) | Только leader клуба |

---

## 5. Ограничения MVP

### 5.1. Что входит в MVP

- **TrainerProfile**: bio, specialization, experienceYears, certificates — CRUD
- **Workouts**: простые шаблоны (название, описание текстом, тип, сложность, целевая метрика) — CRUD
- **Event integration**: привязка workoutId и trainerId к событию
- **Zod-схемы** для всех DTO
- **Миграции** для `trainer_profiles`, `workouts`, расширение `events`
- **Mobile**: экран профиля тренера (просмотр + редактирование), список тренировок, простая форма создания/редактирования тренировки
- **i18n**: ключи для обоих ARB файлов

### 5.2. Что НЕ входит в MVP (Future)

| Функционал | Описание |
|---|---|
| Rating | Рейтинг тренера (0.0–5.0) |
| isVerified | Верификация администрацией |
| socialLinks | Ссылки на соцсети |
| isPublic (workouts) | Публичная видимость шаблонов для других тренеров |
| Structure (конструктор) | Структурированный план тренировки с шагами (см. 8.1) |
| actualDistance | Фактическая дистанция события, заполняемая тренером |
| План/Факт сравнение | Сравнение GPS трека с планом тренировки |
| Журнал посещаемости | Статистика посещений для тренера |
| Аналитика прогресса | Отслеживание прогресса учеников |

---

## 6. Пользовательские сценарии (User Stories)

### 6.1. Тренер: Создание профиля
1. Пользователь с ролью `trainer` или `leader` в любом клубе получает доступ к разделу «Кабинет тренера».
2. Заполняет bio, стаж, специализацию, сертификаты.
3. Профиль становится доступен для просмотра всем авторизованным пользователям.

### 6.2. Тренер: Создание шаблона тренировки
1. Тренер заходит в «Мои тренировки» → «Создать».
2. Заполняет простую форму: название, описание (текст), тип, сложность, целевая метрика.
3. Опционально привязывает к клубу (тогда шаблон виден членам клуба).
4. Сохраняет шаблон.

### 6.3. Тренер: Привязка тренировки к событию
1. При создании/редактировании события тренер/лидер выбирает шаблон из библиотеки.
2. Опционально назначает ведущего тренера (trainerId).
3. Описание из шаблона отображается в карточке события.

### 6.4. Атлет: Просмотр
1. Участник видит событие в ленте.
2. В карточке события видит привязанную тренировку (название, описание, тип, сложность).
3. Может просмотреть профиль ведущего тренера.

---

## 7. Этапы реализации (Roadmap)

### Этап 1: Backend — БД и API
- [ ] Создать Zod-схемы для всех DTO (TrainerProfile, Workout, Event extension)
- [ ] Создать миграцию для `trainer_profiles`
- [ ] Создать миграцию для `workouts`
- [ ] Обновить миграцию `events` (добавить `workoutId`, `trainerId` FK)
- [ ] Реализовать репозитории: `trainerProfiles.repository.ts`, `workouts.repository.ts`
- [ ] Реализовать роуты: `trainer.routes.ts` (CRUD профиля)
- [ ] Реализовать роуты: `workouts.routes.ts` (CRUD шаблонов)
- [ ] Расширить `events.routes.ts` (PATCH с workoutId/trainerId)
- [ ] Middleware проверки роли тренера (helper `isTrainerInAnyClub(userId)`)
- [ ] Тесты для всех новых эндпоинтов

### Этап 2: Mobile — Профиль и Библиотека
- [ ] Модели: `TrainerProfile`, `Workout`
- [ ] Сервисы: `TrainerService`, `WorkoutsService` (через `ApiClient.getInstance()`)
- [ ] Экран просмотра профиля тренера (public view)
- [ ] Экран редактирования профиля тренера
- [ ] Экран списка тренировок («Мои тренировки»)
- [ ] Простая форма создания/редактирования тренировки (текстовое описание, без конструктора)

### Этап 3: Mobile — Интеграция с Событиями
- [ ] Выбор шаблона тренировки при создании/редактировании события
- [ ] Выбор ведущего тренера при создании/редактировании события
- [ ] Отображение тренировки в карточке события (название, описание, тип, сложность)
- [ ] Ссылка на профиль тренера из карточки события

---

## 8. Future: расширения после MVP

### 8.1. Конструктор тренировок (структурированный план)

Поле `structure` (JSONB) в таблице `workouts` — структурированный план с шагами:

```json
{
  "totalDistanceEst": 8200,
  "totalDurationEst": 3600,
  "steps": [
    {
      "order": 1,
      "type": "warmup",
      "duration": 600,
      "notes": "Легкий бег + суставная разминка"
    },
    {
      "order": 2,
      "type": "interval",
      "repeats": 8,
      "work": {
        "distance": 400,
        "targetPace": "3:45",
        "zone": 4
      },
      "recovery": {
        "time": 90,
        "type": "active"
      }
    },
    {
      "order": 3,
      "type": "cooldown",
      "duration": 600,
      "notes": "Заминка + растяжка"
    }
  ]
}
```

Реализация конструктора предполагает:
- UI-форму с добавлением шагов (drag-n-drop или список)
- Визуализацию плана тренировки (график отрезков)
- Сравнение «План / Факт» после пробежки

### 8.2. Рейтинг и верификация
- Рейтинг тренера (оценки участников после событий)
- Верификация администрацией (isVerified badge)
- Ссылки на соцсети (socialLinks)

### 8.3. Аналитика
- Сравнение GPS трека с планом тренировки
- Журнал посещаемости для тренера
- Статистика прогресса учеников

---

## 9. i18n ключи

Примерный список ключей для обоих ARB файлов (`app_en.arb`, `app_ru.arb`):

### TrainerProfile
| Ключ | EN | RU |
|---|---|---|
| `trainerProfile` | Trainer Profile | Профиль тренера |
| `trainerEditProfile` | Edit Trainer Profile | Редактировать профиль |
| `trainerBio` | About | О себе |
| `trainerBioHint` | Describe your coaching philosophy... | Опишите ваш подход к тренировкам... |
| `trainerSpecialization` | Specialization | Специализация |
| `trainerExperience` | Experience (years) | Стаж (лет) |
| `trainerCertificates` | Certificates | Сертификаты |
| `trainerCertificateName` | Certificate name | Название сертификата |
| `trainerCertificateDate` | Date | Дата |
| `trainerCertificateOrg` | Organization | Организация |
| `trainerAddCertificate` | Add certificate | Добавить сертификат |
| `trainerProfileSaved` | Profile saved | Профиль сохранён |
| `trainerProfileNotAvailable` | Trainer profile not available | Профиль тренера недоступен |
| `trainerRoleRequired` | You need a trainer role in a club to edit your profile | Для редактирования профиля нужна роль тренера в клубе |

### Specializations
| Ключ | EN | RU |
|---|---|---|
| `specMarathon` | Marathon | Марафон |
| `specSprint` | Sprint | Спринт |
| `specTrail` | Trail | Трейл |
| `specRecovery` | Recovery | Восстановление |
| `specGeneral` | General | Общая подготовка |

### Workouts
| Ключ | EN | RU |
|---|---|---|
| `workouts` | Workouts | Тренировки |
| `myWorkouts` | My Workouts | Мои тренировки |
| `createWorkout` | Create Workout | Создать тренировку |
| `editWorkout` | Edit Workout | Редактировать тренировку |
| `workoutName` | Name | Название |
| `workoutDescription` | Description | Описание |
| `workoutDescriptionHint` | Describe the workout plan... | Опишите план тренировки... |
| `workoutType` | Type | Тип |
| `workoutDifficulty` | Difficulty | Сложность |
| `workoutTargetMetric` | Target metric | Целевая метрика |
| `workoutClub` | Club (optional) | Клуб (опционально) |
| `workoutPersonal` | Personal | Личная |
| `workoutSaved` | Workout saved | Тренировка сохранена |
| `workoutDeleted` | Workout deleted | Тренировка удалена |
| `workoutDeleteConfirm` | Delete this workout? | Удалить тренировку? |
| `workoutInUse` | Cannot delete: linked to upcoming events | Нельзя удалить: привязана к будущим событиям |
| `workoutEmpty` | No workouts yet | Тренировок пока нет |

### Workout Types
| Ключ | EN | RU |
|---|---|---|
| `typeRecovery` | Recovery | Восстановительная |
| `typeTempo` | Tempo | Темповая |
| `typeInterval` | Interval | Интервальная |
| `typeFartlek` | Fartlek | Фартлек |
| `typeLongRun` | Long Run | Длительная |

### Difficulty
| Ключ | EN | RU |
|---|---|---|
| `diffBeginner` | Beginner | Начинающий |
| `diffIntermediate` | Intermediate | Средний |
| `diffAdvanced` | Advanced | Продвинутый |
| `diffPro` | Pro | Профи |

### Target Metric
| Ключ | EN | RU |
|---|---|---|
| `metricDistance` | Distance | Дистанция |
| `metricTime` | Time | Время |
| `metricPace` | Pace | Темп |

### Event Integration
| Ключ | EN | RU |
|---|---|---|
| `eventWorkout` | Workout | Тренировка |
| `eventSelectWorkout` | Select workout | Выбрать тренировку |
| `eventTrainer` | Trainer | Тренер |
| `eventSelectTrainer` | Select trainer | Выбрать тренера |
| `eventNoWorkout` | No workout assigned | Тренировка не назначена |

---

## 10. Zod-схемы (Backend)

Все DTO валидируются через Zod. Схемы создаются в `src/modules/trainer/trainer.dto.ts` и `src/modules/workout/workout.dto.ts`.

### TrainerProfile DTO
```typescript
const specializations = ['MARATHON', 'SPRINT', 'TRAIL', 'RECOVERY', 'GENERAL'] as const;

const certificateSchema = z.object({
  name: z.string().min(1).max(200),
  date: z.string().optional(),
  organization: z.string().optional(),
});

const createTrainerProfileSchema = z.object({
  bio: z.string().max(2000).optional(),
  specialization: z.array(z.enum(specializations)).min(1),
  experienceYears: z.number().int().min(0).max(50),
  certificates: z.array(certificateSchema).max(20).optional(),
});

const updateTrainerProfileSchema = createTrainerProfileSchema.partial();
```

### Workout DTO
```typescript
const workoutTypes = ['RECOVERY', 'TEMPO', 'INTERVAL', 'FARTLEK', 'LONG_RUN'] as const;
const difficulties = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'PRO'] as const;
const targetMetrics = ['DISTANCE', 'TIME', 'PACE'] as const;

const createWorkoutSchema = z.object({
  clubId: z.string().uuid().nullable().optional(),
  name: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  type: z.enum(workoutTypes),
  difficulty: z.enum(difficulties),
  targetMetric: z.enum(targetMetrics),
});

const updateWorkoutSchema = createWorkoutSchema.partial().omit({ clubId: true });
```

### Event Extension DTO
```typescript
// Extension to existing event update schema
const eventTrainerFieldsSchema = z.object({
  workoutId: z.string().uuid().nullable().optional(),
  trainerId: z.string().uuid().nullable().optional(),
});
```
