/**
 * Minimal structured logger for backend.
 *
 * PURPOSE:
 * - Centralize technical logging on backend.
 * - Write logs to files in logs/ directory (combined.log, error.log).
 * - In DEV, error/warn are also sent to the dev log server (see devLogClient).
 * - Produce JSON logs that are easy to ship to cloud logging later.
 *
 * IMPORTANT:
 * - No product or domain logic here.
 * - This logger only handles technical concerns (levels, timestamps, context).
 */

import * as fs from 'fs';
import * as path from 'path';
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

// Logs directory path (relative to project root)
const LOGS_DIR = path.resolve(__dirname, '../../../logs');

// Ensure logs directory exists
function ensureLogsDir(): void {
  if (!fs.existsSync(LOGS_DIR)) {
    fs.mkdirSync(LOGS_DIR, { recursive: true });
  }
}

// Get current date string for log file names (YYYY-MM-DD)
function getDateString(): string {
  return new Date().toISOString().split('T')[0];
}

// Write log line to file (async, fire-and-forget)
function writeToFile(filename: string, line: string): void {
  try {
    ensureLogsDir();
    const filePath = path.join(LOGS_DIR, filename);
    fs.appendFileSync(filePath, line + '\n', 'utf8');
  } catch (err) {
    // Fallback to console if file write fails
    console.error('Failed to write log to file:', err);
  }
}

function writeLog(payload: LogPayload): void {
  const line = JSON.stringify(payload);
  const dateStr = getDateString();

  // Write to console
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

  // Write to combined log file (all levels)
  writeToFile(`combined-${dateStr}.log`, line);

  // Write errors and warnings to separate file for easy monitoring
  if (payload.level === 'error' || payload.level === 'warn') {
    writeToFile(`error-${dateStr}.log`, line);
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

