import http from 'http';
import { loadEnv, getEnvConfig } from './shared/config/env';

// Load .env before any other code reads process.env
loadEnv();

import { createApp } from './app';
import { assertFirebaseAuthConfigured } from './modules/auth';
import { closeDbPool } from './db/client';
import { logger } from './shared/logger';
import { initChatWs, closeChatWs } from './ws/chatWs';

// SECURITY: Startup-check для авторизации
// В production сервер не должен запускаться, пока заглушка Firebase авторизации
// не будет заменена реальной интеграцией через Firebase Admin SDK.
assertFirebaseAuthConfigured();

const { port: PORT } = getEnvConfig();

const app = createApp();
const server = http.createServer(app);
initChatWs(server);

// Слушаем на всех интерфейсах (0.0.0.0) только в dev, в production — localhost
// ЗАЧЕМ: В dev нужен доступ из Android эмулятора (10.0.2.2), в production — безопасность
const listenAddress = process.env.NODE_ENV === 'production' ? 'localhost' : '0.0.0.0';
server.listen(PORT, listenAddress, () => {
  logger.info('Server is running', {
    httpUrl: `http://localhost:${PORT}`,
    networkUrl: listenAddress === '0.0.0.0' ? `http://0.0.0.0:${PORT}` : undefined,
    environment: process.env.NODE_ENV || 'development',
  });
});

let isShuttingDown = false;

async function gracefulShutdown(signal: 'SIGTERM' | 'SIGINT'): Promise<void> {
  if (isShuttingDown) {
    return;
  }

  isShuttingDown = true;

  logger.info('Received shutdown signal', { signal });

  try {
    closeChatWs();
    await closeDbPool();
    logger.info('Database pool closed on shutdown', { signal });
  } catch (error) {
    const err = error as Error;
    logger.error('Error while closing database pool on shutdown', {
      signal,
      errorMessage: err.message,
      stack: err.stack,
    });
  } finally {
    process.exit(0);
  }
}

process.on('SIGTERM', () => {
  void gracefulShutdown('SIGTERM');
});

process.on('SIGINT', () => {
  void gracefulShutdown('SIGINT');
});
