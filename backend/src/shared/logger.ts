/**
 * Minimal structured logger for backend.
 *
 * PURPOSE:
 * - Centralize technical logging on backend.
 * - In DEV, error/warn are also sent to the dev log server (see devLogClient).
 * - Produce JSON logs that are easy to ship to cloud logging later.
 *
 * IMPORTANT:
 * - No product or domain logic here.
 * - This logger only handles technical concerns (levels, timestamps, context).
 */

import { sendDevLog } from './devLogClient';

export type LogLevel = 'debug' | 'info' | 'warn' | 'error';

export interface LogContext {
  // Free-form technical context; must not contain sensitive PII.
  [key: string]: unknown;
}

interface LogPayload {
  level: LogLevel;
  message: string;
  timestamp: string;
  context?: LogContext;
}

function writeLog(payload: LogPayload): void {
  const line = JSON.stringify(payload);

  switch (payload.level) {
    case 'error':
      console.error(line);
      break;
    case 'warn':
      console.warn(line);
      break;
    case 'info':
      console.info(line);
      break;
    case 'debug':
    default:
      console.debug(line);
      break;
  }

  // Dev-only: forward error/warn to remote log server (fire-and-forget).
  if (payload.level === 'error' || payload.level === 'warn') {
    sendDevLog(payload.level, payload.message, payload.context);
  }
}

function baseLog(level: LogLevel, message: string, context?: LogContext): void {
  writeLog({
    level,
    message,
    timestamp: new Date().toISOString(),
    context,
  });
}

export const logger = {
  debug(message: string, context?: LogContext): void {
    baseLog('debug', message, context);
  },
  info(message: string, context?: LogContext): void {
    baseLog('info', message, context);
  },
  warn(message: string, context?: LogContext): void {
    baseLog('warn', message, context);
  },
  error(message: string, context?: LogContext): void {
    baseLog('error', message, context);
  },
};

