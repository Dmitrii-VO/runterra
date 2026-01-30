/**
 * Dev-only HTTP client for sending error/warn logs to a remote log server.
 *
 * PURPOSE:
 * - In DEV, forward backend error/warn logs to the dev log server (e.g. 176.108.255.4:4000/log).
 * - In PROD, this module does nothing (no requests, no side effects).
 * - Isolated and easy to remove after dev phase.
 *
 * REQUIREMENTS:
 * - Plain HTTP POST, Content-Type: application/json.
 * - No sensitive data (tokens, passwords, GPS tracks) in payload.
 * - Fire-and-forget; must not block or throw.
 */

import type { LogContext } from './logger';

const IS_DEV = process.env.NODE_ENV !== 'production';
// Default dev log server URL when in dev; empty in prod so nothing is sent.
const DEV_LOG_SERVER_URL =
  (process.env.DEV_LOG_SERVER_URL ?? (IS_DEV ? 'http://176.108.255.4:4000' : '')).trim();

/** Keys that must not be sent to the log server (case-insensitive match). */
const SENSITIVE_KEYS = new Set(
  ['token', 'password', 'authorization', 'cookie', 'secret', 'apikey', 'api_key', 'coordinates', 'latitude', 'longitude'].map((k) => k.toLowerCase())
);

function isSensitiveKey(key: string): boolean {
  const lower = key.toLowerCase();
  return SENSITIVE_KEYS.has(lower) || lower.includes('token') || lower.includes('password');
}

function sanitizeContext(context: LogContext | undefined): LogContext | undefined {
  if (!context || typeof context !== 'object') return undefined;
  const out: LogContext = {};
  for (const [k, v] of Object.entries(context)) {
    if (!isSensitiveKey(k)) out[k] = v;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

/**
 * Sends a single log entry to the dev log server.
 * No-op when NODE_ENV === 'production' or DEV_LOG_SERVER_URL is not set.
 * Does not throw; errors are swallowed.
 */
export function sendDevLog(
  level: 'error' | 'warn',
  message: string,
  context?: LogContext
): void {
  if (!IS_DEV || !DEV_LOG_SERVER_URL.trim()) return;

  const url = DEV_LOG_SERVER_URL.replace(/\/?$/, '') + '/log';
  const body = JSON.stringify({
    level,
    message,
    timestamp: new Date().toISOString(),
    context: sanitizeContext(context),
  });

  fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  }).catch(() => {
    // Swallow: dev logging must never affect app behavior.
  });
}
