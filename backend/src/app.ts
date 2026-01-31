import express, { Express, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import apiRouter from './api';
import { logger } from './shared/logger';

/** Max JSON body size (product_spec and DoS protection). */
const JSON_BODY_LIMIT = '1mb';

/** General API rate limit: 100 requests per minute per IP (product_spec 18.1). */
const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Создание и настройка Express приложения
 * 
 * Минимальный сервер с health-check endpoint и API роутерами.
 * 
 * На текущей стадии (skeleton) API роутеры возвращают только заглушки.
 */
export function createApp(): Express {
  const app = express();

  app.use(cors());

  // JSON body parser with explicit limit (security / DoS)
  app.use(express.json({ limit: JSON_BODY_LIMIT }));

  // Request logging middleware
  app.use((req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();
    
    res.on('finish', () => {
      const duration = Date.now() - start;
      const level = res.statusCode >= 400 ? 'warn' : 'info';
      
      logger[level]('HTTP request', {
        method: req.method,
        path: req.path,
        status: res.statusCode,
        duration: `${duration}ms`,
        ip: req.ip || req.socket.remoteAddress,
      });
    });
    
    next();
  });

  // Health-check endpoint
  app.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'ok',
    });
  });

  // API роутеры (rate limit 100 req/min per IP per product_spec)
  app.use('/api', apiLimiter, apiRouter);

  // Обработчик необработанных ошибок (fallback)
  app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
    // Technical logging for unexpected errors.
    logger.error('Unhandled error in request pipeline', {
      path: _req.path,
      method: _req.method,
      errorMessage: err.message,
      // Stack is kept as string for easier searching in logs.
      stack: err.stack,
    });

    if (!res.headersSent) {
      res.status(500).json({
        error: 'Internal server error',
      });
    }
  });

  return app;
}
