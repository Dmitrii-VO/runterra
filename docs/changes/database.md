# Единый DB pool (устранение дублирования)

**Дата:** 2026-01-29

## Проблема

Существовали два независимых модуля с PostgreSQL-пулом и коллизией имён `getDbPool()`:

- `backend/src/db/client.ts` — `createDbPool`, `getDbPool`, `closeDbPool`; конфиг из `config/db`.
- `backend/src/shared/db/index.ts` — `initDb`, `getDbPool`, `closeDb`; собственный `getDbConfig` из env.

При импорте обоих модулей создавались два пула → удвоение соединений и утечка ресурсов.

## Решение

Оставлен единый модуль **`backend/src/db/client.ts`** как единственная точка работы с PostgreSQL-пулом.

- Удалён модуль `shared/db` (файл `shared/db/index.ts` и каталог).
- Все будущие обращения к БД — через `db/client`: `getDbConfig` из `config/db`, `createDbPool` / `getDbPool` / `closeDbPool`.

### Корректное завершение работы пула (graceful shutdown)

- В `backend/src/server.ts` добавлен технический обработчик сигналов процесса `SIGTERM` и `SIGINT`.
- При получении сигнала shutdown вызывается `closeDbPool()` из `db/client.ts`, результат логируется через `logger`.
- Цель — гарантировать закрытие всех подключений пула при остановке backend-процесса и избежать утечек ресурсов на уровне PostgreSQL.

## Что не менялось

- Поведение `db/client.ts`, конфигурация БД, логирование ошибок пула.
- Доменная или бизнес-логика не затрагивалась.

---

## DB_PASSWORD обязателен в production (2026-01-29)

**Проблема:** `DB_PASSWORD` по умолчанию подставлялся как пустая строка; в production это недопустимо с точки зрения безопасности.

**Решение:**

- В `backend/src/config/db.ts` в `getDbConfig()`: если `NODE_ENV === 'production'` и `DB_PASSWORD` не задан или пустой (после trim), выбрасывается ошибка `DB_PASSWORD must be set in production` до возврата конфига.

Дефолт пустой строки для dev/local сохранён; проверка срабатывает только при `NODE_ENV === 'production'`.

---

## Единый источник конфигурации БД (2026-01-29)

**Проблема:** Конфигурация БД дублировалась в двух местах: `config/db.ts` (getDbConfig) и `shared/config/env.ts` (getEnvConfig с полями dbHost, dbPort, dbName, dbUser, dbPassword). Тройное дублирование с учётом использования в db/client и server.

**Решение:**

- **Единственный источник конфигурации БД** — `backend/src/config/db.ts`. Функция `getDbConfig()` читает DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD; добавлена проверка `parseInt` на NaN для DB_PORT (fallback 5432 при невалидном значении).
- **EnvConfig** в `shared/config/env.ts` больше не содержит полей БД; остаётся только `port` (приложение). Функция `getEnvConfig()` возвращает только `{ port }`; парсинг порта с проверкой на NaN (fallback 3000).
- Загрузка .env вынесена в явный вызов `loadEnv()` из `server.ts` (нет побочного эффекта при импорте модуля env).
- `server.ts` вызывает `loadEnv()` до остальной логики и использует `getEnvConfig().port` для PORT.
