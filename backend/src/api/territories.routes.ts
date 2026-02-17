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
  LeaderboardEntryDto, // Import LeaderboardEntryDto
} from '../modules/territories';
import { getTerritoriesForCity, getTerritoryById, resolveMyClubProgress } from '../modules/territories/territories.config';
import { validateBody } from './validateBody';
import { isPointWithinCityBounds } from '../modules/cities/city.utils';
import { getUsersRepository, getClubMembersRepository, getTerritoriesRepository } from '../db/repositories'; // Import getTerritoriesRepository
import { logger } from '../shared/logger';

const router = Router();

/**
 * GET /api/territories
 * 
 * Возвращает список территорий.
 * Merges static config with real DB scores.
 */
router.get('/', async (req: Request, res: Response) => {
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

  try {
    // 1. Get static config (base territories)
    const territories = getTerritoriesForCity(cityId, clubId);

    // 2. Get real scores from DB
    const territoriesRepo = getTerritoriesRepository();
    const seasonStart = territoriesRepo.getSeasonStart();
    const scores = await territoriesRepo.getTerritoryScores(seasonStart);

    // 3. Merge data
    // Group scores by territory
    const scoresMap = new Map<string, typeof scores>();
    for (const score of scores) {
      const list = scoresMap.get(score.territory_id) || [];
      list.push(score);
      scoresMap.set(score.territory_id, list);
    }

    const mergedTerritories = territories.map(t => {
      const territoryScores = scoresMap.get(t.id);
      
      if (!territoryScores || territoryScores.length === 0) {
        // No scores yet -> Status FREE (default)
        return {
          ...t,
          status: TerritoryStatus.FREE,
          leaderboard: [],
        };
      }

      // Has scores -> Determine leader and status
      // Scores are already sorted by total_meters DESC in SQL
      const leader = territoryScores[0];
      const leaderMeters = parseInt(leader.total_meters, 10);
      
      // Determine status (Simplified: if leader exists, it's captured or contested)
      // Spec: "If leader -> Captured". "If gap < X% -> Contested".
      // For MVP let's say: if leaders > 0 meters -> Captured by leader.
      
      const leaderboard: LeaderboardEntryDto[] = territoryScores.map((s, index) => ({
        clubId: s.club_id,
        clubName: s.club_name,
        totalKm: Math.round(parseInt(s.total_meters, 10) / 100) / 10, // meters -> km with 1 decimal
        position: index + 1,
      }));

      // Find my club progress if clubId filter is present (though GET / usually returns light objects)
      // GET / is light, usually NO leaderboard. But spec says "Merge config ... geometry ... with DB".
      // Let's return light object but with updated status and owner (clubId).
      
      return {
        ...t,
        status: TerritoryStatus.CAPTURED, // For MVP, any score = captured
        clubId: leader.club_id, // Owner
        // We don't necessarily return full leaderboard in list view to save bandwidth,
        // unless requested. But for now let's stick to base implementation which returns Light DTO.
        // Light DTO doesn't have leaderboard.
      };
    });

    res.status(200).json(mergedTerritories);
  } catch (error) {
    logger.error('Error fetching territories', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/territories/:id
 *
 * Returns full territory details including leaderboard and myClubProgress.
 * myClubProgress is resolved from the authenticated user's active clubs.
 */
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  let territory = getTerritoryById(id);
  if (!territory) {
    res.status(404).json({
      code: 'not_found',
      message: 'Territory not found',
      details: { territoryId: id },
    });
    return;
  }

  try {
    // 1. Fetch real scores
    const territoriesRepo = getTerritoriesRepository();
    const seasonStart = territoriesRepo.getSeasonStart();
    const scores = await territoriesRepo.getTerritoryScores(seasonStart);
    
    // Filter for this territory
    const territoryScores = scores.filter(s => s.territory_id === id);

    // 2. Update territory object
    if (territoryScores.length > 0) {
      const leaderboard: LeaderboardEntryDto[] = territoryScores.map((s, index) => ({
        clubId: s.club_id,
        clubName: s.club_name,
        totalKm: Math.round(parseInt(s.total_meters, 10) / 100) / 10,
        position: index + 1,
      }));

      territory = {
        ...territory,
        status: TerritoryStatus.CAPTURED,
        clubId: territoryScores[0].club_id, // Leader
        leaderboard,
      };
    } else {
       // Reset mock leaderboard if real scoring is enabled (or keep mock if we want fallback?)
       // Plan says: "Merge ... if no scores -> Free".
       // So we should clear the mock leaderboard.
       territory = {
         ...territory,
         status: TerritoryStatus.FREE,
         clubId: undefined,
         leaderboard: [],
       };
    }

    // 3. Resolve myClubProgress
    const firebaseUid = req.authUser?.uid;
    if (firebaseUid && territory.leaderboard?.length) {
      const usersRepo = getUsersRepository();
      const user = await usersRepo.findByFirebaseUid(firebaseUid);
      if (user) {
        const clubMembersRepo = getClubMembersRepository();
        const userClubs = await clubMembersRepo.findActiveClubsByUser(user.id);
        const userClubIds = userClubs.map((c: { clubId: string }) => c.clubId);
        territory.myClubProgress = resolveMyClubProgress(territory.leaderboard, userClubIds);

        // If user is in a club but it's not in the leaderboard,
        // inject a synthetic entry so the user sees their starting position
        if (!territory.myClubProgress && userClubs.length > 0) {
          const clubMembership = userClubs[0];
          const leaderboard = territory.leaderboard!;
          const newPosition = leaderboard.length + 1;
          const leaderKm = leaderboard[0]?.totalKm ?? 0;

          const syntheticEntry: LeaderboardEntryDto = {
            clubId: clubMembership.clubId,
            clubName: clubMembership.clubName,
            totalKm: 0,
            position: newPosition,
          };
          // We don't push to main leaderboard to avoid confusing global view, 
          // but maybe we should if we want to show "You are here"?
          // For now, just calculating myClubProgress is enough.
          
          territory.myClubProgress = {
            clubId: clubMembership.clubId,
            clubName: clubMembership.clubName,
            totalKm: 0,
            position: newPosition,
            gapToLeader: -leaderKm,
          };
        }
      }
    }
  } catch (error) {
    logger.warn('Error fetching territory details', { territoryId: id, error });
    // Fallback to static config if DB fails? Or just log and return what we have?
    // Returning what we have (merged) is better.
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
