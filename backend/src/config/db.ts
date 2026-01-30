/**
 * Конфигурация подключения к PostgreSQL
 * 
 * Настройки читаются из переменных окружения.
 * Используется для подготовки слоя БД, без реального подключения.
 */

export interface DbConfig {
  host: string;
  port: number;
  database: string;
  user: string;
  password: string;
}

const DEFAULT_DB_PORT = 5432;

function parseDbPort(): number {
  const raw = process.env.DB_PORT ?? '';
  if (raw === '') return DEFAULT_DB_PORT;
  const n = parseInt(raw, 10);
  if (Number.isNaN(n) || n < 1 || n > 65535) return DEFAULT_DB_PORT;
  return n;
}

/**
 * Получение конфигурации БД из переменных окружения
 * In production, DB_PASSWORD must be set; otherwise throws.
 *
 * @returns Конфигурация подключения к PostgreSQL
 */
export function getDbConfig(): DbConfig {
  const password = process.env.DB_PASSWORD ?? '';
  if (process.env.NODE_ENV === 'production' && !password.trim()) {
    throw new Error('DB_PASSWORD must be set in production');
  }
  return {
    host: process.env.DB_HOST || 'localhost',
    port: parseDbPort(),
    database: process.env.DB_NAME || 'runterra',
    user: process.env.DB_USER || 'postgres',
    password,
  };
}
