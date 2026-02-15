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
import {
  TerritoryStatus,
  TerritoryViewDto,
  CreateTerritoryDto,
  CreateTerritorySchema,
  CaptureTerritoryDto,
  CaptureTerritorySchema,
} from '../modules/territories';
import { getTerritoriesForCity, getTerritoryById, resolveMyClubProgress } from '../modules/territories/territories.config';
import { validateBody } from './validateBody';
import { isPointWithinCityBounds } from '../modules/cities/city.utils';
import { getUsersRepository, getClubMembersRepository } from '../db/repositories';
import { logger } from '../shared/logger';

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

  const territories = getTerritoriesForCity(cityId, clubId);
  res.status(200).json(territories);
});

/**
 * GET /api/territories/:id
 *
 * Returns full territory details including leaderboard and myClubProgress.
 * myClubProgress is resolved from the authenticated user's active clubs.
 */
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  const territory = getTerritoryById(id);
  if (!territory) {
    res.status(404).json({
      code: 'not_found',
      message: 'Territory not found',
      details: { territoryId: id },
    });
    return;
  }

  // Resolve myClubProgress from user's active clubs
  try {
    const firebaseUid = req.authUser?.uid;
    if (firebaseUid && territory.leaderboard?.length) {
      const usersRepo = getUsersRepository();
      const user = await usersRepo.findByFirebaseUid(firebaseUid);
      if (user) {
        const clubMembersRepo = getClubMembersRepository();
        const userClubs = await clubMembersRepo.findActiveClubsByUser(user.id);
        const userClubIds = userClubs.map((c: { clubId: string }) => c.clubId);
        territory.myClubProgress = resolveMyClubProgress(territory.leaderboard, userClubIds);
      }
    }
  } catch (error) {
    logger.warn('Could not resolve myClubProgress', { territoryId: id, error });
    // Non-critical: return territory without myClubProgress
  }

  res.status(200).json(territory);
});

/**
 * POST /api/territories/:id/capture
 * 
 * Capture or contribute to a territory.
 * ADR-0007: Only ACTIVE club members can capture a territory.
 */
router.post('/:id/capture', validateBody(CaptureTerritorySchema), async (req: Request<{ id: string }, any, CaptureTerritoryDto>, res: Response) => {
  const { id: territoryId } = req.params;
  const { clubId } = req.body;
  const firebaseUid = req.authUser?.uid;

  if (!firebaseUid) {
    return res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
    });
  }

  try {
    const territory = getTerritoryById(territoryId);
    if (!territory) {
      return res.status(404).json({
        code: 'not_found',
        message: 'Territory not found',
        details: { territoryId },
      });
    }

    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(firebaseUid);
    if (!user) {
      return res.status(401).json({
        code: 'unauthorized',
        message: 'User profile not found',
      });
    }

    const clubMembersRepo = getClubMembersRepository();
    const membership = await clubMembersRepo.findByClubAndUser(clubId, user.id);

    if (!membership) {
      return res.status(403).json({
        code: 'forbidden',
        message: 'You must be a member of the club to capture territories for it',
        details: { clubId, status: 'none' },
      });
    }

    if (membership.status !== 'active') {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only active club members can capture territories',
        details: { 
          clubId, 
          status: membership.status,
          requiredStatus: 'active'
        },
      });
    }

    // Success (Mock)
    logger.info('Territory capture contribution successful', {
      territoryId,
      clubId,
      userId: user.id
    });

    res.status(200).json({
      success: true,
      message: 'Contribution accepted',
      territoryId,
      clubId,
    });
  } catch (error) {
    logger.error('Error in territory capture', { territoryId, clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
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
