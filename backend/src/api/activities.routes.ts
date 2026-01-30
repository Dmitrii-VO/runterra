/**
 * API роутер для модуля активностей
 * 
 * Содержит эндпоинты для работы с активностями:
 * - GET /api/activities - список активностей
 * - GET /api/activities/:id - активность по ID
 * - POST /api/activities - создание активности
 * 
 * На текущей стадии (skeleton) все эндпоинты возвращают заглушки.
 * TODO: Реализовать контроллеры и бизнес-логику в будущем.
 */

import { Router, Request, Response } from 'express';
import { ActivityType, ActivityStatus, ActivityViewDto, CreateActivityDto, CreateActivitySchema } from '../modules/activities';
import { validateBody } from './validateBody';

const router = Router();

/**
 * GET /api/activities
 * 
 * Возвращает список активностей.
 * 
 * TODO: Реализовать пагинацию, фильтрацию, сортировку.
 */
router.get('/', (_req: Request, res: Response) => {
  // Заглушка: возвращаем массив из одной активности
  const mockActivities: ActivityViewDto[] = [
    {
      id: '1',
      userId: 'user-1',
      type: ActivityType.RUNNING,
      status: ActivityStatus.PLANNED,
      name: 'Morning Run',
      description: 'Test activity description',
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  res.status(200).json(mockActivities);
});

/**
 * GET /api/activities/:id
 * 
 * Возвращает активность по ID.
 * 
 * TODO: Реализовать проверку существования активности.
 */
router.get('/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  // Заглушка: возвращаем активность с переданным ID
  const mockActivity: ActivityViewDto = {
    id,
    userId: 'user-1',
    type: ActivityType.RUNNING,
    status: ActivityStatus.PLANNED,
    name: `Activity ${id}`,
    description: `Description for activity ${id}`,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(200).json(mockActivity);
});

/**
 * POST /api/activities
 * 
 * Создает новую активность.
 * 
 * Техническая валидация: тело запроса проверяется через CreateActivitySchema.
 * TODO: Реализовать проверку существования пользователя.
 */
router.post('/', validateBody(CreateActivitySchema), (req: Request<{}, ActivityViewDto, CreateActivityDto>, res: Response) => {
  const dto = req.body;

  // Заглушка: возвращаем созданную активность
  // TODO: Получить userId из авторизации
  const mockActivity: ActivityViewDto = {
    id: 'new-activity-id',
    userId: 'current-user-id', // TODO: Получить из токена авторизации
    type: dto.type,
    status: dto.status || ActivityStatus.PLANNED,
    name: dto.name,
    description: dto.description,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(201).json(mockActivity);
});

export default router;
