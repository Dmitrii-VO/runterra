/**
 * API роутер для модуля пробежек
 * 
 * Содержит эндпоинты для работы с пробежками:
 * - POST /api/runs - создание пробежки
 * 
 * На текущей стадии (skeleton) все эндпоинты возвращают заглушки.
 * TODO: Реализовать контроллеры и бизнес-логику в будущем.
 */

import { Router, Request, Response } from 'express';
import { RunStatus, RunViewDto, CreateRunDto, CreateRunSchema } from '../modules/runs';
import { validateBody } from './validateBody';

const router = Router();

/**
 * POST /api/runs
 * 
 * Создает новую пробежку.
 * 
 * Принимает:
 * - activityId (опционально) - ID тренировки
 * - startedAt - время начала (ISO 8601)
 * - endedAt - время окончания (ISO 8601)
 * - duration - длительность в секундах
 * - distance - расстояние в метрах
 * - gpsPoints (опционально) - массив GPS точек
 * 
 * Техническая валидация: тело запроса проверяется через CreateRunSchema.
 * TODO: Реализовать проверку существования пользователя.
 * TODO: Добавить валидацию пробежки (слишком короткая, слишком быстрая).
 * TODO: Получить userId из авторизации.
 */
router.post('/', validateBody(CreateRunSchema), (req: Request<{}, RunViewDto, CreateRunDto>, res: Response) => {
  const dto = req.body;

  // Parse dates from ISO strings
  const startedAt = new Date(dto.startedAt);
  const endedAt = new Date(dto.endedAt);

  // TODO: Validate dates, duration, distance
  // TODO: Check if run is too short (e.g., less than 100 meters)
  // TODO: Check if speed is too high (e.g., more than 30 km/h)
  // TODO: Get userId from authorization token

  // Заглушка: возвращаем созданную пробежку
  const mockRun: RunViewDto = {
    id: `run-${Date.now()}`,
    userId: 'current-user-id', // TODO: Получить из токена авторизации
    activityId: dto.activityId,
    startedAt: startedAt,
    endedAt: endedAt,
    duration: dto.duration,
    distance: dto.distance,
    status: RunStatus.COMPLETED, // TODO: Validate and set INVALID if needed
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(201).json(mockRun);
});

export default router;
