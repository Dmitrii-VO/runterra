/**
 * Application env config (non-DB).
 *
 * DB config lives in config/db.ts (single source for PostgreSQL).
 * This module only provides app-level settings (e.g. port).
 */

const DEFAULT_PORT = 3000;

/**
 * Parses PORT from env; returns default if missing or invalid.
 * Avoids NaN from parseInt without radix or invalid input.
 */
function parsePort(): number {
  const raw = process.env.PORT ?? '';
  if (raw === '') return DEFAULT_PORT;
  const n = parseInt(raw, 10);
  if (Number.isNaN(n) || n < 1 || n > 65535) return DEFAULT_PORT;
  return n;
}

export interface EnvConfig {
  port: number;
}

import dotenv from 'dotenv';

/**
 * Load env from .env file. Must be called explicitly from entry point (e.g. server.ts)
 * so env is not a side effect of importing this module.
 */
export function loadEnv(): void {
  dotenv.config();
}

/**
 * Returns app-level config from env. DB config is in config/db.ts.
 */
export function getEnvConfig(): EnvConfig {
  return { port: parsePort() };
}
