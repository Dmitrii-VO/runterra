/**
 * API роутер для модуля территорий
 * 
 * Содержит эндпоинты для работы с территориями:
 * - GET /api/territories - список территорий
 * - GET /api/territories/:id - территория по ID
 * - POST /api/territories - создание территории
 * 
 * На текущей стадии (skeleton) все эндпоинты возвращают заглушки.
 * TODO: Реализовать контроллеры и бизнес-логику в будущем.
 */

import { Router, Request, Response } from 'express';
import { TerritoryStatus, TerritoryViewDto, CreateTerritoryDto, CreateTerritorySchema } from '../modules/territories';
import { validateBody } from './validateBody';
import { isPointWithinCityBounds } from '../modules/cities/city.utils';

const router = Router();

/**
 * GET /api/territories
 * 
 * Возвращает список территорий.
 * 
 * TODO: Реализовать пагинацию, фильтрацию, сортировку.
 */
router.get('/', (req: Request, res: Response) => {
  const query = req.query as Record<string, string | undefined>;
  const { cityId, clubId } = query;

  if (!cityId) {
    return res.status(400).json({
      code: 'validation_error',
      message: 'Query validation failed',
      details: {
        fields: [
          {
            field: 'cityId',
            message: 'cityId is required',
            code: 'city_required',
          },
        ],
      },
    });
  }

  // Заглушка: возвращаем массив из одной территории в указанном городе
  let mockTerritories: TerritoryViewDto[] = [
    {
      id: '1',
      name: 'Test Territory',
      status: TerritoryStatus.FREE,
      coordinates: {
        longitude: 37.6173,
        latitude: 55.7558,
      },
      cityId,
      clubId: 'club-1',
      capturedByUserId: undefined,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  if (clubId) {
    mockTerritories = mockTerritories.filter((t) => t.clubId === clubId);
  }

  res.status(200).json(mockTerritories);
});

/**
 * GET /api/territories/:id
 * 
 * Возвращает территорию по ID.
 * 
 * TODO: Реализовать проверку существования территории.
 */
router.get('/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  // Заглушка: возвращаем территорию с переданным ID
  const mockTerritory: TerritoryViewDto = {
    id,
    name: `Territory ${id}`,
    status: TerritoryStatus.FREE,
    coordinates: {
      longitude: 37.6173,
      latitude: 55.7558,
    },
    cityId: 'spb',
    capturedByUserId: undefined,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(200).json(mockTerritory);
});

/**
 * POST /api/territories
 * 
 * Создает новую территорию.
 * 
 * Техническая валидация: тело запроса проверяется через CreateTerritorySchema.
 * TODO: Реализовать проверку существования города.
 */
router.post('/', validateBody(CreateTerritorySchema), (req: Request<{}, TerritoryViewDto, CreateTerritoryDto>, res: Response) => {
  const dto = req.body;

  if (!isPointWithinCityBounds(dto.coordinates, dto.cityId)) {
    return res.status(400).json({
      code: 'validation_error',
      message: 'Request body validation failed',
      details: {
        fields: [
          {
            field: 'coordinates',
            message: 'coordinates are outside city bounds',
            code: 'coordinates_out_of_city',
          },
        ],
      },
    });
  }

  // Заглушка: возвращаем созданную территорию
  const mockTerritory: TerritoryViewDto = {
    id: 'new-territory-id',
    name: dto.name,
    status: dto.status || TerritoryStatus.FREE,
    coordinates: dto.coordinates,
    cityId: dto.cityId,
    capturedByUserId: undefined,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(201).json(mockTerritory);
});

export default router;
