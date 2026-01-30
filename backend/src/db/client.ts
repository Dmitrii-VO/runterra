import { Pool, PoolConfig } from 'pg';
import { getDbConfig } from '../config/db';
import { logger } from '../shared/logger';

/**
 * Модуль для работы с PostgreSQL
 * 
 * На текущей стадии (skeleton) содержит только заглушку.
 * Реальное подключение к БД не выполняется.
 * 
 * ЗАПРЕЩЕНО:
 * - Автоматическое подключение при старте сервера
 * - Выполнение SQL-запросов
 * - Создание таблиц и миграций
 */

let pool: Pool | null = null;

/**
 * Создание пула подключений к PostgreSQL
 * 
 * ВАЖНО: Функция только создаёт конфигурацию пула, но НЕ подключается к БД.
 * Подключение будет выполнено при первом запросе (lazy connection).
 * 
 * @returns Пул подключений PostgreSQL (не подключён)
 */
export function createDbPool(): Pool {
  if (pool) {
    return pool;
  }

  const config: PoolConfig = getDbConfig();
  
  pool = new Pool(config);
  
  // Обработка ошибок пула (для будущего использования)
  pool.on('error', (err) => {
    logger.error('Unexpected error on idle PostgreSQL client (db/client)', {
      errorMessage: err.message,
      stack: err.stack,
      component: 'database',
      errorType: 'pool_error',
    });
  });

  return pool;
}

/**
 * Получение существующего пула подключений
 * 
 * @returns Пул подключений или null, если пул не создан
 */
export function getDbPool(): Pool | null {
  return pool;
}

/**
 * Закрытие всех подключений в пуле
 * 
 * Используется при завершении работы приложения.
 */
export async function closeDbPool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}
