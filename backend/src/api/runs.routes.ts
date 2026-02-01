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
import { getRunsRepository } from '../db/repositories';
import { logger } from '../shared/logger';

const router = Router();

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

  // Parse dates from ISO strings
  const startedAt = new Date(dto.startedAt);
  const endedAt = new Date(dto.endedAt);

  // TODO: Получить userId из авторизации (сейчас mock)
  const userId = (req as unknown as { user?: { id: string } }).user?.id || 'mock-user-id';

  try {
    const repo = getRunsRepository();
    // Convert GPS point timestamps from string to Date if present
    const gpsPoints = dto.gpsPoints?.map(point => ({
      longitude: point.longitude,
      latitude: point.latitude,
      timestamp: point.timestamp ? new Date(point.timestamp) : undefined,
    }));

    const { run, validation } = await repo.create({
      userId,
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

    // Return 201 with validation info
    res.status(201).json({
      ...response,
      validation: {
        valid: validation.valid,
        errors: validation.errors,
      },
    });
  } catch (error) {
    logger.error('Error creating run', { userId, error });
    res.status(500).json({
      error: 'Internal server error',
    });
  }
});

export default router;
