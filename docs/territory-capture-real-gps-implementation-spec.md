# Спецификация: Реальный захват территорий по GPS и Приватные пробежки

**Дата:** 2026-02-17  
**Статус:** Approved (Ready for Implementation)

## 1. Цель

1.  **Реальный захват:** Перейти от mock-данных к начислению очков территориям на основе реальных GPS-треков пробежек.
2.  **Автоматический вклад:** Если участник клуба бежит по территории, очки (метры) автоматически начисляются этому клубу в этой зоне.
3.  **Приватные пробежки:** Реализовать `private` события (Group Runs), которые видны только участникам, но скрыты от остальных на карте и в списках.

---

## 2. Принятые технические решения

### 2.1. Идемпотентность и Дубликаты
*   Мобильное приложение может повторять отправку пробежки при сбоях сети.
*   **Решение:** В БД добавляется уникальный индекс `(user_id, started_at)`. Повторная отправка той же пробежки будет игнорироваться (или возвращать успешный статус без дублирования данных).

### 2.2. Конфликт выбора клуба
*   Пользователь может состоять в нескольких клубах (`active`).
*   **Решение:**
    *   Если у пользователя **0 активных клубов**: пробежка сохраняется, вклад в территории = 0.
    *   Если **1 активный клуб**: вклад начисляется этому клубу автоматически (если не выбран другой).
    *   Если **>1 активных клубов**: Пользователь **обязан** выбрать клуб. Если `scoringClubId` не передан, API возвращает ошибку `400 Bad Request` с кодом `club_required_for_scoring`.

### 2.3. Геометрия и ID территорий
*   Геометрия территорий остается в **конфигурационном файле** (не в БД) для MVP.
*   ID территорий (например, `spb-petrogradskiy`) считаются **неизменяемыми ключами**.
*   Связь БД -> Конфиг идет по строковому `territory_id`.

### 2.4. Сезоны
*   Сезон = Календарный месяц.
*   Закрытие сезона происходит "на лету": запросы фильтруют данные по `season_start = <1-е число текущего месяца>`. Background jobs для закрытия сезона пока не требуются.

---

## 3. План Реализации (Implementation Plan)

### Этап 0: Инфраструктура Данных (Data Layer Refactoring)
*Критический этап для обеспечения целостности данных (Run + Scores).*

1.  **Рефакторинг `BaseRepository`:**
    *   Изменить сигнатуру методов `query`, `queryOne`, `queryMany`: добавить опциональный параметр `client?: PoolClient`.
    *   Если `client` передан — использовать его для запроса (внутри транзакции).
    *   Если `client` не передан — использовать `this.getPool()` (как сейчас).
    *   Реализовать метод `transaction<T>(callback: (client: PoolClient) => Promise<T>): Promise<T>`.

2.  **Обновление `RunsRepository`:**
    *   Обновить метод `create`, чтобы он принимал опциональный `client`.
    *   Это позволит вызывать `runsRepo.create(data, client)` внутри транзакции.

3.  **Миграция БД:**
    *   Применить миграцию `021_real_territory_scoring.sql` (уже создана).

### Этап 1: Логика Захвата (Territory Capture Logic)

1.  **Геометрия (`src/modules/territories/utils/geo.ts`):**
    *   Реализовать `isPointInPolygon(point, polygon)` (алгоритм Ray Casting).
    *   Реализовать `calculateRunContribution(gpsPoints, territories)`:
        *   Вход: трек пробежки и конфиг территорий.
        *   Логика: разбиение на сегменты, фильтрация по BBox, суммирование длин сегментов, попавших в полигоны.
        *   Выход: `Map<TerritoryId, Meters>`.

2.  **Сервис/Логика обработки:**
    *   Создать функцию-оркестратор сохранения пробежки, которая открывает транзакцию.

### Этап 2: API Пробежек (Runs API)

1.  **Обновление `POST /api/runs`:**
    *   **Входные данные:** Добавить `scoringClubId`.
    *   **Валидация (до транзакции):**
        *   Если `scoringClubId` есть: проверить, что юзер `active` в этом клубе.
        *   Если нет: проверить кол-во активных клубов.
            *   0 -> OK (без очков).
            *   1 -> OK (авто-выбор).
            *   >1 -> **Ошибка 400** `club_required_for_scoring`.
    *   **Транзакция (Atomic Operation):**
        1.  `runsRepo.create(runData, client)`.
        2.  Если есть клуб для начисления:
            *   `geo.calculateRunContribution(...)`.
            *   `INSERT INTO territory_run_contributions ...` (через client).
            *   `INSERT ... ON CONFLICT DO UPDATE` в `territory_club_scores` (через client).
    *   **Обработка ошибок:**
        *   Дубликат `(user_id, started_at)` -> Игнорировать или вернуть 200 (idempotency).

### Этап 3: API Территорий (Territories API)

1.  **`GET /api/territories`:**
    *   Загружать геометрию из `territories.config.ts`.
    *   Загружать очки из БД (`territory_club_scores`) для текущего сезона.
    *   Мержить данные:
        *   Если очков нет -> статус `Free`.
        *   Если есть лидер -> статус `Captured`.
        *   Если борьба (разрыв < X% или смена лидера) -> статус `Contested`.

### Этап 4: Приватные События (Private Events)

1.  **Репозиторий `EventsRepository`:**
    *   Обновить методы `findAll`, `findMapEvents` чтобы они принимали `currentUserId`.
    *   Добавить условие в SQL: `AND (visibility = 'public' OR (visibility = 'private' AND EXISTS(participants...)))`.

2.  **Контроллеры:**
    *   `GET /api/events`: Передавать `req.user.id` в репозиторий.
    *   `GET /api/events/:id`: Если `private` и нет прав -> 404.

### Этап 5: Мобильное приложение (Mobile)

1.  **UI Выбора клуба:**
    *   Добавить проверку активных клубов перед отправкой.
    *   Модальное окно выбора.
2.  **Обработка ошибок:**
    *   Обработка 400 `club_required_for_scoring` -> открыть выбор клуба -> повторить отправку.

---

## 4. Схема Базы Данных (Schema & Migrations)

### 4.1. Обновление существующих таблиц

```sql
-- Runs: фиксация клуба и защита от дублей
ALTER TABLE runs ADD COLUMN scoring_club_id UUID; -- Nullable
CREATE UNIQUE INDEX idx_runs_user_started ON runs(user_id, started_at);

-- Events: приватность
ALTER TABLE events ADD COLUMN visibility VARCHAR(20) DEFAULT 'public' NOT NULL;
ALTER TABLE events ADD CONSTRAINT events_visibility_check CHECK (visibility IN ('public', 'private'));
CREATE INDEX idx_events_visibility ON events(visibility);
```

### 4.2. Новые таблицы для скоринга

**`territory_run_contributions`** — Детальный журнал вкладов (для аудита и пересчета).

```sql
CREATE TABLE territory_run_contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID NOT NULL REFERENCES runs(id) ON DELETE CASCADE,
    territory_id VARCHAR(128) NOT NULL, -- Matches ID in territories.config.ts
    club_id UUID NOT NULL REFERENCES clubs(id),
    meters INTEGER NOT NULL DEFAULT 0,
    season_start TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(run_id, territory_id) -- Защита от двойного начисления за одну зону
);
```

**`territory_club_scores`** — Агрегированные очки (Fast Read для лидербордов).

```sql
CREATE TABLE territory_club_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    territory_id VARCHAR(128) NOT NULL,
    club_id UUID NOT NULL REFERENCES clubs(id),
    season_start TIMESTAMP WITH TIME ZONE NOT NULL,
    total_meters BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(territory_id, club_id, season_start) -- Ключ для Upsert
);
CREATE INDEX idx_territory_scores_season ON territory_club_scores(territory_id, season_start);
```

---

## 5. Детали Алгоритмов

### 5.1. Расчет вклада (Territory Capture)

Алгоритм выполняется в транзакции при создании пробежки (`POST /api/runs`).

1.  **Input:** Массив GPS координат пробежки.
2.  **Process:**
    *   Итерируемся по сегментам трека `(p[i], p[i+1])`.
    *   Считаем длину сегмента (в метрах).
    *   Находим середину сегмента (midpoint).
    *   Проверяем попадание midpoint в полигоны территорий (используя Ray Casting algorithm).
    *   *Оптимизация:* Сначала фильтруем территории по Bounding Box (min/max lat/lon).
3.  **Output:** Map `<TerritoryID, Meters>`.

### 5.2. Приватные события (`GET /api/events`, `GET /api/map/data`)

*   **Фильтрация:**
    Все списковые методы должны применять условие:
    ```sql
    WHERE (
      visibility = 'public' 
      OR (
        visibility = 'private' 
        AND EXISTS (
          SELECT 1 FROM event_participants ep 
          WHERE ep.event_id = events.id AND ep.user_id = :currentUserId
        )
      )
    )
    ```
*   **Детали (`GET /api/events/:id`):**
    *   Если событие `private` и пользователь не участник/организатор -> `404 Not Found` (Security through obscurity).
