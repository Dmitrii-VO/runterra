import { Request, Response, NextFunction } from 'express';
import { getAuthProvider } from '../modules/auth';
import type { AuthUser } from './types';

/**
 * Authentication middleware for protecting API routes.
 *
 * Uses single auth abstraction (modules/auth AuthProvider).
 *
 * Поведение:
 * - Ожидает заголовок `Authorization: Bearer <token>`
 * - Передаёт токен в AuthProvider.verifyToken()
 * - При невалидном токене возвращает 401
 * - При валидном токене добавляет данные пользователя в req.authUser
 */

declare module 'express-serve-static-core' {
  interface Request {
    authUser?: AuthUser;
    authToken?: string;
  }
}

export async function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
): Promise<void> {
  try {
    const authHeader = req.header('Authorization');

    if (!authHeader) {
      res.status(401).json({
        code: 'unauthorized',
        message: 'Authorization required',
        details: {
          reason: 'missing_header',
        },
      });
      return;
    }

    const [scheme, token] = authHeader.split(' ');

    if (scheme !== 'Bearer' || !token) {
      res.status(401).json({
        code: 'unauthorized',
        message: 'Authorization required',
        details: {
          reason: 'invalid_format',
        },
      });
      return;
    }

    const result = await getAuthProvider().verifyToken(token);

    if (!result.valid || !result.user) {
      res.status(401).json({
        code: 'unauthorized',
        message: 'Authorization required',
        details: {
          reason: 'invalid_token',
        },
      });
      return;
    }

    // Сохраняем данные пользователя и токен в запросе для дальнейшего использования в роутерах
    req.authUser = result.user;
    req.authToken = token;

    next();
  } catch (error) {
    // На skeleton-этапе не делаем подробного логирования, только базовый ответ
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: {
        reason: 'unexpected_error',
      },
    });
  }
}

