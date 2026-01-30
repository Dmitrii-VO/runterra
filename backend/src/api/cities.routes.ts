/**
 * API роутер для модуля городов
 * 
 * Содержит эндпоинты для работы с городами:
 * - GET /api/cities - список городов
 * - GET /api/cities/:id - город по ID
 * - POST /api/cities - создание города
 * 
 * На текущей стадии (skeleton) все эндпоинты возвращают заглушки.
 * TODO: Реализовать контроллеры и бизнес-логику в будущем.
 */

import { Router, Request, Response } from 'express';
import { City, CreateCityDto, CreateCitySchema } from '../modules/cities';
import { validateBody } from './validateBody';

const router = Router();

/**
 * GET /api/cities
 * 
 * Возвращает список городов.
 * 
 * TODO: Реализовать пагинацию, фильтрацию, сортировку.
 */
router.get('/', (_req: Request, res: Response) => {
  // Заглушка: возвращаем массив из одного города
  const mockCities: City[] = [
    {
      id: '1',
      name: 'Москва',
      coordinates: {
        longitude: 37.6173,
        latitude: 55.7558,
      },
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  res.status(200).json(mockCities);
});

/**
 * GET /api/cities/:id
 * 
 * Возвращает город по ID.
 * 
 * TODO: Реализовать проверку существования города.
 */
router.get('/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  // Заглушка: возвращаем город с переданным ID
  const mockCity: City = {
    id,
    name: `City ${id}`,
    coordinates: {
      longitude: 37.6173,
      latitude: 55.7558,
    },
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(200).json(mockCity);
});

/**
 * POST /api/cities
 * 
 * Создает новый город.
 * 
 * Техническая валидация: тело запроса проверяется через CreateCitySchema.
 * TODO: Реализовать проверку уникальности названия.
 */
router.post('/', validateBody(CreateCitySchema), (req: Request<{}, City, CreateCityDto>, res: Response) => {
  const dto = req.body;

  // Заглушка: возвращаем созданный город
  const mockCity: City = {
    id: 'new-city-id',
    name: dto.name,
    coordinates: dto.coordinates,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(201).json(mockCity);
});

export default router;
