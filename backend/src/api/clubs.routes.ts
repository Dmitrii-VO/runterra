/**
 * API роутер для модуля клубов
 * 
 * Содержит эндпоинты для работы с клубами:
 * - GET /api/clubs - список клубов
 * - GET /api/clubs/:id - клуб по ID
 * - POST /api/clubs - создание клуба
 * 
 * На текущей стадии (skeleton) все эндпоинты возвращают заглушки.
 * TODO: Реализовать контроллеры и бизнес-логику в будущем.
 */

import { Router, Request, Response } from 'express';
import { ClubStatus, ClubViewDto, CreateClubDto, CreateClubSchema } from '../modules/clubs';
import { validateBody } from './validateBody';

const router = Router();

/**
 * GET /api/clubs
 * 
 * Возвращает список клубов.
 * 
 * TODO: Реализовать пагинацию, фильтрацию, сортировку.
 */
router.get('/', (req: Request, res: Response) => {
  const query = req.query as Record<string, string | undefined>;
  const { cityId } = query;

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

  // Заглушка: возвращаем массив из одного клуба в указанном городе
  const mockClubs: ClubViewDto[] = [
    {
      id: '1',
      name: 'Test Club',
      description: 'Test club description',
      status: ClubStatus.ACTIVE,
      cityId,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  res.status(200).json(mockClubs);
});

/**
 * GET /api/clubs/:id
 * 
 * Возвращает клуб по ID.
 * 
 * TODO: Реализовать проверку существования клуба.
 */
router.get('/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  // Заглушка: возвращаем клуб с переданным ID
  const mockClub: ClubViewDto = {
    id,
    name: `Club ${id}`,
    description: `Description for club ${id}`,
    status: ClubStatus.ACTIVE,
    cityId: 'spb',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(200).json(mockClub);
});

/**
 * POST /api/clubs
 * 
 * Создает новый клуб.
 * 
 * Техническая валидация: тело запроса проверяется через CreateClubSchema.
 * TODO: Реализовать проверку уникальности названия.
 */
router.post('/', validateBody(CreateClubSchema), (req: Request<{}, ClubViewDto, CreateClubDto>, res: Response) => {
  const dto = req.body;

  // Заглушка: возвращаем созданный клуб
  const mockClub: ClubViewDto = {
    id: 'new-club-id',
    name: dto.name,
    description: dto.description,
    status: dto.status || ClubStatus.PENDING,
    cityId: dto.cityId,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(201).json(mockClub);
});

export default router;
