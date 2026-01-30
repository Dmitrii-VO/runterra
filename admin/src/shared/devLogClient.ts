/**
 * Dev-only client for sending error logs to the remote dev log server.
 *
 * PURPOSE:
 * - In DEV (when NEXT_PUBLIC_DEV_LOG_SERVER is set), send API/UI errors to the dev log server.
 * - In PROD, no requests are made. Isolated and easy to remove after dev phase.
 */

const BASE_URL =
  (typeof process !== 'undefined' && process.env.NEXT_PUBLIC_DEV_LOG_SERVER) || '';

const IS_DEV = BASE_URL.length > 0;

/** Do not send these keys in context (tokens, passwords, etc.). */
const SENSITIVE_KEYS = new Set(
  ['token', 'password', 'authorization', 'cookie', 'secret', 'apikey'].map((k) => k.toLowerCase())
);

function sanitizeContext(context: Record<string, unknown> | undefined): Record<string, unknown> | undefined {
  if (!context || typeof context !== 'object') return undefined;
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(context)) {
    if (!SENSITIVE_KEYS.has(k.toLowerCase())) out[k] = v;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

/**
 * Sends an error log to the dev log server. No-op in prod or when URL is not set.
 * Fire-and-forget; does not throw.
 */
export function sendDevLog(
  message: string,
  context?: { error?: string; stackTrace?: string; [key: string]: unknown }
): void {
  if (!IS_DEV) return;

  const url = BASE_URL.replace(/\/?$/, '') + '/log';
  const body = JSON.stringify({
    level: 'error',
    message,
    timestamp: new Date().toISOString(),
    context: sanitizeContext(context),
  });

  fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  }).catch(() => {});
}
