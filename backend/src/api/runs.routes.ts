/**
 * API роутер для модуля пробежек
 * 
 * Содержит эндпоинты для работы с пробежками:
 * - POST /api/runs - создание пробежки
 * 
 * Валидация:
 * - Минимальная дистанция: 100м
 * - Максимальная скорость: 30 км/ч
 * - Минимальная длительность: 30 секунд
 */

import { Router, Request, Response } from 'express';
import { RunStatus, RunViewDto, CreateRunDto, CreateRunSchema } from '../modules/runs';
import { validateBody } from './validateBody';
import { getRunsRepository, getUsersRepository } from '../db/repositories';
import { logger } from '../shared/logger';

const router = Router();

const UUID_V4_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isValidUUID(value: string): boolean {
  return UUID_V4_REGEX.test(value);
}

/**
 * POST /api/runs
 * 
 * Создает новую пробежку с валидацией.
 * 
 * Принимает:
 * - activityId (опционально) - ID тренировки
 * - startedAt - время начала (ISO 8601)
 * - endedAt - время окончания (ISO 8601)
 * - duration - длительность в секундах
 * - distance - расстояние в метрах
 * - gpsPoints (опционально) - массив GPS точек
 * 
 * Валидация:
 * - distance >= 100м
 * - speed <= 30 км/ч
 * - duration >= 30 секунд
 * 
 * Если валидация не пройдена, пробежка сохраняется со статусом INVALID.
 */
router.post('/', validateBody(CreateRunSchema), async (req: Request<{}, RunViewDto, CreateRunDto>, res: Response) => {
  const dto = req.body;

  // User ID must come from auth only (no mock in production)
  const uid = req.authUser?.uid;
  if (!uid) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
    return;
  }

  const usersRepo = getUsersRepository();
  const user = await usersRepo.findByFirebaseUid(uid);
  if (!user) {
    res.status(400).json({
      code: 'validation_error',
      message: 'Authentication required',
      details: { fields: [{ field: 'userId', message: 'User not found for this token', code: 'invalid_user' }] },
    });
    return;
  }

  if (!isValidUUID(user.id)) {
    res.status(400).json({
      code: 'validation_error',
      message: 'Invalid user id',
      details: { fields: [{ field: 'userId', message: 'User id must be a valid UUID', code: 'invalid_string' }] },
    });
    return;
  }

  const startedAt = new Date(dto.startedAt);
  const endedAt = new Date(dto.endedAt);

  try {
    const repo = getRunsRepository();
    const gpsPoints = dto.gpsPoints?.map(point => ({
      longitude: point.longitude,
      latitude: point.latitude,
      timestamp: point.timestamp ? new Date(point.timestamp) : undefined,
    }));

    const { run, validation } = await repo.create({
      userId: user.id,
      activityId: dto.activityId,
      startedAt,
      endedAt,
      duration: dto.duration,
      distance: dto.distance,
      gpsPoints,
    });

    const response: RunViewDto = {
      id: run.id,
      userId: run.userId,
      activityId: run.activityId,
      startedAt: run.startedAt,
      endedAt: run.endedAt,
      duration: run.duration,
      distance: run.distance,
      status: run.status,
      createdAt: run.createdAt,
      updatedAt: run.updatedAt,
    };

    res.status(201).json({
      ...response,
      validation: {
        valid: validation.valid,
        errors: validation.errors,
      },
    });
  } catch (error) {
    logger.error('Error creating run', { userId: user.id, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

export default router;
