# Backend

Backend сервиса Runterra.

## Текущая стадия

Минимальный Node.js + TypeScript backend с базовой структурой:
- ✅ Express сервер
- ✅ Health-check endpoint (`/health`)
- ✅ Слой для PostgreSQL (заглушка, без подключения)
- ✅ Архитектура авторизации Firebase (заглушки, без подключения)
- ✅ Модуль пользователей (типы и DTO, без логики)
- ✅ Модуль городов (типы и DTO, без логики)
- ✅ Модуль карты (типы и DTO, без логики)
- ✅ Модуль территорий (типы и DTO, без логики)
- ✅ Модуль клубов (типы и DTO, без логики)
- ✅ Модуль активностей (типы и DTO, без логики)
- ✅ API endpoints (роутеры с заглушками)
- ❌ Без бизнес-логики

## Структура проекта

```
backend/
├── src/
│   ├── app.ts        # Создание и настройка Express приложения
│   ├── server.ts     # Запуск сервера
│   ├── api/          # API роутеры
│   │   ├── index.ts  # Главный роутер API
│   │   ├── users.routes.ts      # Роутер пользователей
│   │   ├── cities.routes.ts     # Роутер городов
│   │   ├── clubs.routes.ts      # Роутер клубов
│   │   ├── territories.routes.ts # Роутер территорий
│   │   └── activities.routes.ts # Роутер активностей
│   ├── auth/         # Модуль авторизации Firebase
│   │   ├── types.ts  # Интерфейсы и типы для авторизации
│   │   ├── service.ts # Сервис авторизации (заглушка)
│   │   └── index.ts  # Экспорт модуля
│   ├── config/
│   │   └── db.ts     # Конфигурация PostgreSQL из env
│   ├── db/
│   │   └── client.ts # Модуль для работы с PostgreSQL (заглушка)
│   ├── modules/      # Модули приложения
│   │   ├── auth/     # Модуль авторизации (Firebase провайдеры)
│   │   ├── users/    # Модуль пользователей
│   │   │   ├── user.entity.ts # Интерфейс User и UserStatus
│   │   │   ├── user.dto.ts    # CreateUserDto, UpdateUserDto
│   │   │   └── index.ts       # Экспорт модуля
│   │   ├── cities/   # Модуль городов
│   │   │   ├── city.entity.ts # Интерфейс City и CityCoordinates
│   │   │   ├── city.dto.ts   # CreateCityDto, UpdateCityDto
│   │   │   └── index.ts      # Экспорт модуля
│   │   └── map/      # Модуль карты
│   │       ├── map.types.ts  # MapCoordinates, MapViewport
│   │       ├── map.dto.ts   # MapDataDto
│   │       └── index.ts     # Экспорт модуля
│   │   └── territories/ # Модуль территорий
│   │       ├── territory.status.ts # TerritoryStatus enum
│   │       ├── territory.entity.ts # Territory и TerritoryCoordinates
│   │       ├── territory.dto.ts   # CreateTerritoryDto, TerritoryViewDto
│   │       └── index.ts           # Экспорт модуля
│   │   └── clubs/      # Модуль клубов
│   │       ├── club.status.ts     # ClubStatus enum
│   │       ├── club.entity.ts     # Club
│   │       ├── club.dto.ts        # CreateClubDto, ClubViewDto
│   │       └── index.ts           # Экспорт модуля
│   │   └── activities/ # Модуль активностей
│   │       ├── activity.type.ts   # ActivityType enum
│   │       ├── activity.status.ts # ActivityStatus enum
│   │       ├── activity.entity.ts # Activity
│   │       ├── activity.dto.ts   # CreateActivityDto, ActivityViewDto
│   │       └── index.ts           # Экспорт модуля
│   └── shared/       # Общие утилиты
├── package.json      # Зависимости и скрипты
└── tsconfig.json     # Конфигурация TypeScript
```

## Запуск

```bash
# Установка зависимостей
npm install

# Запуск в режиме разработки
npm run dev

# Сборка проекта
npm run build

# Запуск собранного проекта
npm start
```

Сервер запускается на `http://localhost:3000` (или порт из переменной окружения `PORT`).

### Запуск на сервере (SSH runterra)

Миграции:
```bash
npm run migrate   # или npm run migrate:prod после сборки
```

Одноразовая правка: активировать клуб «Лупкины» (чтобы он отображался в списке и в профиле):
```bash
# Из каталога backend на сервере, с настроенным .env / DATABASE_URL:
psql "$DATABASE_URL" -f scripts/fix-lupkiny-club.sql
# Или явно:
psql -h localhost -U postgres -d runterra -f scripts/fix-lupkiny-club.sql
```

**Важно:** Сервер слушает на всех интерфейсах (`0.0.0.0`), что позволяет подключаться к нему:
- С локальной машины: `http://localhost:3000`
- Из Android эмулятора: `http://10.0.2.2:3000`
- Из сети: `http://<IP_адрес_компьютера>:3000`

Health-check endpoint: `GET /health`

## API Endpoints

API роутеры созданы для всех доменов и возвращают заглушки (mock-данные).

**ВАЖНО**: На текущей стадии (skeleton) все эндпоинты возвращают только заглушки без бизнес-логики, без работы с БД, без авторизации.

### Пользователи (`/api/users`)
- `GET /api/users` - список пользователей
- `GET /api/users/:id` - пользователь по ID
- `POST /api/users` - создание пользователя

### Города (`/api/cities`)
- `GET /api/cities` - список городов
- `GET /api/cities/:id` - город по ID
- `POST /api/cities` - создание города

### Клубы (`/api/clubs`)
- `GET /api/clubs` - список клубов
- `GET /api/clubs/:id` - клуб по ID
- `POST /api/clubs` - создание клуба

### Территории (`/api/territories`)
- `GET /api/territories` - список территорий
- `GET /api/territories/:id` - территория по ID
- `POST /api/territories` - создание территории

### Активности (`/api/activities`)
- `GET /api/activities` - список активностей
- `GET /api/activities/:id` - активность по ID
- `POST /api/activities` - создание активности

TODO для будущей реализации:
- Добавить валидацию DTO через `class-validator` или `zod`
- Реализовать контроллеры с бизнес-логикой
- Добавить middleware для авторизации
- Добавить обработку ошибок
- Реализовать пагинацию, фильтрацию, сортировку для списков

## Конфигурация PostgreSQL

Слой для работы с PostgreSQL подготовлен, но **не подключается автоматически** при старте сервера.

Конфигурация читается из переменных окружения:
- `DB_HOST` (по умолчанию: `localhost`)
- `DB_PORT` (по умолчанию: `5432`)
- `DB_NAME` (по умолчанию: `runterra`)
- `DB_USER` (по умолчанию: `postgres`)
- `DB_PASSWORD` (по умолчанию: пустая строка)

**ВАЖНО**: На текущей стадии (skeleton) подключение к БД не выполняется. Модуль `src/db/client.ts` содержит только заглушку для будущего использования.

## Архитектура авторизации Firebase

Слой авторизации подготовлен для работы с Firebase Authentication, но **не подключается к Firebase** на текущей стадии.

Структура:
- `src/auth/types.ts` - интерфейсы и типы (`FirebaseUser`, `TokenVerificationResult`, `AuthService`)
- `src/auth/service.ts` - сервис с заглушками для проверки токенов
- `src/auth/index.ts` - экспорт модуля

**ВАЖНО (обновлено 2026-02-06)**: 
- В production окружении backend использует реальную проверку ID токенов через Firebase Admin SDK (пакет `firebase-admin`), credentials читаются из переменных окружения (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`).
- В non-production окружениях при отсутствии этих переменных остаётся техническая заглушка, которая derive-ит uid и прочие поля из JWT-пэйлоада (для удобства локальной разработки без настроенного Firebase).

TODO для будущей реализации:
- Добавить отдельные конфигурации Firebase проектов для dev/staging/prod и описать их в документации.

## Модуль пользователей

Модуль пользователей подготовлен на стадии skeleton: содержит только типы и DTO без бизнес-логики.

Структура:
- `src/modules/users/user.entity.ts` - интерфейс `User` и enum `UserStatus`
- `src/modules/users/user.dto.ts` - DTO для создания и обновления пользователей (`CreateUserDto`, `UpdateUserDto`)
- `src/modules/users/index.ts` - экспорт модуля

**Модель пользователя (`User`)**:
- Связан с Firebase Authentication через `firebaseUid`
- Содержит базовые данные: `id`, `email`, `displayName`, `photoURL`
- Имеет статус (`ACTIVE`, `INACTIVE`, `BLOCKED`)
- Включает метаданные: `createdAt`, `updatedAt`

**ВАЖНО**: 
- Нет репозиториев для работы с БД
- Нет сервисов с бизнес-логикой
- API endpoints есть, но возвращают только заглушки
- Нет валидации DTO
- Нет работы с БД

TODO для будущей реализации:
- Создать репозиторий для работы с PostgreSQL
- Реализовать сервис с бизнес-логикой создания/обновления пользователей
- Реализовать контроллеры с реальной логикой вместо заглушек
- Добавить валидацию DTO через `class-validator` или `zod`
- Реализовать миграции БД для таблицы пользователей

## Модуль городов

Модуль городов подготовлен на стадии skeleton: содержит только типы и DTO без бизнес-логики.

Структура:
- `src/modules/cities/city.entity.ts` - интерфейс `City` и `CityCoordinates`
- `src/modules/cities/city.dto.ts` - DTO для создания и обновления городов (`CreateCityDto`, `UpdateCityDto`)
- `src/modules/cities/index.ts` - экспорт модуля

**Модель города (`City`)**:
- Содержит базовые данные: `id`, `name`, `coordinates`
- Координаты представлены через интерфейс `CityCoordinates` (longitude, latitude) для работы с Mapbox
- Включает метаданные: `createdAt`, `updatedAt`

**ВАЖНО**: 
- Нет репозиториев для работы с БД
- Нет сервисов с бизнес-логикой
- API endpoints есть, но возвращают только заглушки
- Нет валидации DTO
- Нет работы с БД

TODO для будущей реализации:
- Создать репозиторий для работы с PostgreSQL
- Реализовать сервис с бизнес-логикой создания/обновления городов
- Реализовать контроллеры с реальной логикой вместо заглушек
- Добавить валидацию DTO через `class-validator` или `zod`
- Реализовать миграции БД для таблицы городов

## Модуль карты

Модуль карты подготовлен на стадии skeleton: содержит только типы и DTO без бизнес-логики.

Структура:
- `src/modules/map/map.types.ts` - интерфейсы `MapCoordinates` и `MapViewport`
- `src/modules/map/map.dto.ts` - DTO для ответа API карты (`MapDataDto`)
- `src/modules/map/index.ts` - экспорт модуля

**Типы карты**:
- `MapCoordinates` - координаты точки на карте (longitude, latitude)
- `MapViewport` - область видимости карты (center, zoom)
- `MapDataDto` - DTO для ответа API карты (viewport + метаданные)

**ВАЖНО**: 
- Нет геометрии (bounds, полигоны)
- Нет координатных вычислений
- Нет интеграций с Mapbox/PostGIS
- Нет репозиториев для работы с БД
- Нет сервисов с бизнес-логикой
- Нет API endpoints для карты
- Нет валидации DTO
- Нет работы с БД

TODO для будущей реализации:
- Интеграция с Mapbox для отображения карт
- Работа с PostGIS для геопространственных данных
- Координатные вычисления
- Создать репозиторий для работы с PostgreSQL
- Реализовать сервис с бизнес-логикой работы с картой
- Добавить API endpoints для карты
- Добавить валидацию DTO через `class-validator` или `zod`

## Модуль территорий

Модуль территорий подготовлен на стадии skeleton: содержит только типы и DTO без бизнес-логики.

Структура:
- `src/modules/territories/territory.status.ts` - enum `TerritoryStatus`
- `src/modules/territories/territory.entity.ts` - интерфейс `Territory` и `TerritoryCoordinates`
- `src/modules/territories/territory.dto.ts` - DTO для создания и отображения территорий (`CreateTerritoryDto`, `TerritoryViewDto`)
- `src/modules/territories/index.ts` - экспорт модуля

**Модель территории (`Territory`)**:
- Содержит базовые данные: `id`, `name`, `status`, `coordinates`, `cityId`
- Координаты представлены через интерфейс `TerritoryCoordinates` (longitude, latitude) для работы с Mapbox
- Имеет статус (`FREE`, `CAPTURED`, `CONTESTED`, `LOCKED`)
- Связана с городом через `cityId` и с пользователем через `capturedByUserId` (если захвачена)
- Включает метаданные: `createdAt`, `updatedAt`

**ВАЖНО**: 
- Нет геометрии (полигоны, границы территорий)
- Нет расчётов захвата
- Нет PostGIS
- Нет таймеров
- Нет репозиториев для работы с БД
- Нет сервисов с бизнес-логикой
- API endpoints есть, но возвращают только заглушки
- Нет валидации DTO
- Нет работы с БД
- Только контракты (interfaces, enums, DTO)

TODO для будущей реализации:
- Создать репозиторий для работы с PostgreSQL
- Реализовать сервис с бизнес-логикой создания/обновления территорий
- Реализовать контроллеры с реальной логикой вместо заглушек
- Добавить валидацию DTO через `class-validator` или `zod`
- Реализовать миграции БД для таблицы территорий
- Геометрия границ (PostGIS)
- Логика расчётов захвата
- Таймеры для процесса захвата

## Модуль клубов

Модуль клубов подготовлен на стадии skeleton: содержит только типы и DTO без бизнес-логики.

Структура:
- `src/modules/clubs/club.status.ts` - enum `ClubStatus`
- `src/modules/clubs/club.entity.ts` - интерфейс `Club`
- `src/modules/clubs/club.dto.ts` - DTO для создания и отображения клубов (`CreateClubDto`, `ClubViewDto`)
- `src/modules/clubs/index.ts` - экспорт модуля

**Модель клуба (`Club`)**:
- Содержит базовые данные: `id`, `name`, `description`, `status`
- Имеет статус (`ACTIVE`, `INACTIVE`, `DISBANDED`, `PENDING`)
- Включает метаданные: `createdAt`, `updatedAt`

**ВАЖНО**: 
- Нет ролей участников
- Нет связей с пользователями
- Нет репозиториев для работы с БД
- Нет сервисов с бизнес-логикой
- API endpoints есть, но возвращают только заглушки
- Нет валидации DTO
- Нет работы с БД
- Только контракты (interfaces, enums, DTO)

TODO для будущей реализации:
- Создать репозиторий для работы с PostgreSQL
- Реализовать сервис с бизнес-логикой создания/обновления клубов
- Реализовать контроллеры с реальной логикой вместо заглушек
- Добавить валидацию DTO через `class-validator` или `zod`
- Реализовать миграции БД для таблицы клубов
- Роли участников
- Связи с пользователями

## Модуль активностей

Модуль активностей подготовлен на стадии skeleton: содержит только типы и DTO без бизнес-логики.

Структура:
- `src/modules/activities/activity.type.ts` - enum `ActivityType`
- `src/modules/activities/activity.status.ts` - enum `ActivityStatus`
- `src/modules/activities/activity.entity.ts` - интерфейс `Activity`
- `src/modules/activities/activity.dto.ts` - DTO для создания и отображения активностей (`CreateActivityDto`, `ActivityViewDto`)
- `src/modules/activities/index.ts` - экспорт модуля

**Модель активности (`Activity`)**:
- Содержит базовые данные: `id`, `userId`, `type`, `status`, `name`, `description`
- Имеет тип активности (`RUNNING`, `WALKING`, `CYCLING`, `TRAINING`)
- Имеет статус (`PLANNED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`)
- Связана с пользователем через `userId`
- Включает метаданные: `createdAt`, `updatedAt`

**ВАЖНО**: 
- Нет GPS координат
- Нет check-in точек
- Нет расчётов дистанции, времени, скорости
- Нет маршрута
- Нет репозиториев для работы с БД
- Нет сервисов с бизнес-логикой
- API endpoints есть, но возвращают только заглушки
- Нет валидации DTO
- Нет работы с БД
- Только контракты (interfaces, enums, DTO)

TODO для будущей реализации:
- Создать репозиторий для работы с PostgreSQL
- Реализовать сервис с бизнес-логикой создания/обновления активностей
- Реализовать контроллеры с реальной логикой вместо заглушек
- Добавить валидацию DTO через `class-validator` или `zod`
- Реализовать миграции БД для таблицы активностей
- GPS координаты и маршрут
- Check-in точки
- Расчёты дистанции, времени, скорости
