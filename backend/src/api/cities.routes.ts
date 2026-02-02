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
import { CreateCityDto, CreateCitySchema } from '../modules/cities';
import { validateBody } from './validateBody';
import { findCityById, getAllCities } from '../modules/cities/cities.config';

const router = Router();

/**
 * GET /api/cities
 * 
 * Возвращает список городов.
 * 
 * TODO: Реализовать пагинацию, фильтрацию, сортировку.
 */
router.get('/', (_req: Request, res: Response) => {
  const cities = getAllCities();
  res.status(200).json(cities);
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

  const city = findCityById(id);

  if (!city) {
    return res.status(404).json({
      code: 'not_found',
      message: 'City not found',
      details: { id },
    });
  }

  res.status(200).json(city);
});

/**
 * POST /api/cities
 * 
 * Создает новый город.
 * 
 * Техническая валидация: тело запроса проверяется через CreateCitySchema.
 * TODO: Реализовать проверку уникальности названия.
 */
router.post('/', validateBody(CreateCitySchema), (req: Request<{}, unknown, CreateCityDto>, res: Response) => {
  const dto = req.body;

  // Заглушка: возвращаем город с переданными полями без сохранения.
  // Реальное сохранение появится после внедрения БД для городов.
  const now = new Date();

  res.status(201).json({
    id: 'new-city-id',
    name: dto.name,
    center: dto.center,
    bounds: dto.bounds,
    coordinates: dto.center,
    createdAt: now,
    updatedAt: now,
  });
});

export default router;
