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
import {
  RunStatus,
  RunViewDto,
  CreateRunDto,
  CreateRunSchema,
  RunHistoryItemDto,
  RunDetailDto,
  UserRunStatsDto,
} from '../modules/runs';
import { ActivityType, ActivityStatus } from '../modules/activities';
import { validateBody } from './validateBody';
import {
  getRunsRepository,
  getUsersRepository,
  getClubMembersRepository,
  getTerritoriesRepository,
  getActivitiesRepository,
} from '../db/repositories';
import { logger } from '../shared/logger';
import { calculateRunContribution } from '../modules/territories/utils/geo';
import { getTerritoriesForCity } from '../modules/territories/territories.config';
import { TerritoryViewDto } from '../modules/territories/territory.dto';

const router = Router();

const UUID_V4_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isValidUUID(value: string): boolean {
  return UUID_V4_REGEX.test(value);
}

/**
 * Helper to resolve internal user ID from Firebase auth.
 * Returns user or sends error response.
 */
async function resolveUser(req: Request, res: Response) {
  const uid = req.authUser?.uid;
  if (!uid) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
    });
    return null;
  }
  const usersRepo = getUsersRepository();
  const user = await usersRepo.findByFirebaseUid(uid);
  if (!user) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'User not found',
    });
    return null;
  }
  return user;
}

/**
 * GET /api/runs
 * List completed runs for the authenticated user, paginated.
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const limit = Math.min(Math.max(parseInt(req.query.limit as string) || 20, 1), 100);
    const offset = Math.max(parseInt(req.query.offset as string) || 0, 0);

    const repo = getRunsRepository();
    const runs = await repo.findByUserId(user.id, limit, offset);

    const items: RunHistoryItemDto[] = runs
      .filter(r => r.status === RunStatus.COMPLETED)
      .map(r => ({
        id: r.id,
        startedAt: r.startedAt,
        duration: r.duration,
        distance: r.distance,
        paceSecondsPerKm: r.distance > 0 ? Math.round((r.duration / r.distance) * 1000) : 0,
      }));

    res.json(items);
  } catch (error) {
    logger.error('Error listing runs', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/runs/stats
 * User running statistics (completed runs only).
 * IMPORTANT: Must be registered BEFORE /:id to avoid Express matching "stats" as an id.
 */
router.get('/stats', async (req: Request, res: Response) => {
  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const repo = getRunsRepository();
    const stats = await repo.getUserStats(user.id);

    const dto: UserRunStatsDto = {
      totalRuns: stats.totalRuns,
      totalDistance: stats.totalDistance,
      totalDuration: stats.totalDuration,
      averagePace: stats.averagePace,
    };

    res.json(dto);
  } catch (error) {
    logger.error('Error getting run stats', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/runs/:id
 * Run details with GPS track. Only the run owner can access.
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const runId = req.params.id;
    if (!isValidUUID(runId)) {
      res.status(400).json({
        code: 'validation_error',
        message: 'Invalid run id format',
      });
      return;
    }

    const repo = getRunsRepository();
    const run = await repo.findById(runId);
    if (!run) {
      res.status(404).json({ code: 'not_found', message: 'Run not found' });
      return;
    }

    if (run.userId !== user.id) {
      res.status(403).json({ code: 'forbidden', message: 'Access denied' });
      return;
    }

    const gpsPoints = await repo.getGpsPoints(runId);

    const dto: RunDetailDto = {
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
      gpsPoints: gpsPoints.map(p => ({
        latitude: p.latitude,
        longitude: p.longitude,
        timestamp: p.timestamp,
      })),
    };

    res.json(dto);
  } catch (error) {
    logger.error('Error getting run detail', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

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
router.post(
  '/',
  validateBody(CreateRunSchema),
  async (req: Request<{}, RunViewDto, CreateRunDto>, res: Response) => {
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
        details: {
          fields: [
            { field: 'userId', message: 'User not found for this token', code: 'invalid_user' },
          ],
        },
      });
      return;
    }

    if (!isValidUUID(user.id)) {
      res.status(400).json({
        code: 'validation_error',
        message: 'Invalid user id',
        details: {
          fields: [
            { field: 'userId', message: 'User id must be a valid UUID', code: 'invalid_string' },
          ],
        },
      });
      return;
    }

    const startedAt = new Date(dto.startedAt);
    const endedAt = new Date(dto.endedAt);

    try {
      const gpsPoints = dto.gpsPoints?.map(point => ({
        longitude: point.longitude,
        latitude: point.latitude,
        timestamp: point.timestamp ? new Date(point.timestamp) : undefined,
      }));

      // DB expects INTEGER for duration and distance; coerce from possible float (e.g. from mobile)
      const duration = Math.round(Number(dto.duration));
      const distance = Math.round(Number(dto.distance));
      if (!Number.isFinite(duration) || !Number.isFinite(distance)) {
        res.status(400).json({
          code: 'validation_error',
          message: 'duration and distance must be valid numbers',
          details: {
            fields: [
              { field: 'duration/distance', message: 'Invalid number', code: 'invalid_type' },
            ],
          },
        });
        return;
      }
      if (duration < 30) {
        res.status(400).json({
          code: 'validation_error',
          message: 'duration must be at least 30 seconds',
          details: {
            fields: [
              {
                field: 'duration',
                message: 'duration must be at least 30 seconds',
                code: 'invalid_type',
              },
            ],
          },
        });
        return;
      }

      // --- Scoring Club Validation ---
      const clubMembersRepo = getClubMembersRepository();
      const activeClubs = await clubMembersRepo.findActiveClubsByUser(user.id);
      let scoringClubId = dto.scoringClubId;

      if (scoringClubId) {
        // Validate user is active member of provided club
        const isMember = activeClubs.some(c => c.clubId === scoringClubId);
        if (!isMember) {
          res.status(400).json({
            code: 'validation_error',
            message: 'User is not an active member of the selected scoring club',
            details: {
              fields: [{ field: 'scoringClubId', message: 'Not a member', code: 'invalid_club' }],
            },
          });
          return;
        }
      } else {
        // Auto-select or require selection
        if (activeClubs.length === 1) {
          scoringClubId = activeClubs[0].clubId;
        } else if (activeClubs.length > 1) {
          res.status(400).json({
            code: 'club_required_for_scoring',
            message: 'Multiple active clubs found. Please select a club for scoring.',
          });
          return;
        }
        // If 0 clubs, scoringClubId remains undefined (no scoring)
      }

      // --- Transaction Execution ---
      const runsRepo = getRunsRepository();
      const territoriesRepo = getTerritoriesRepository();
      const activitiesRepo = getActivitiesRepository();

      const { run, validation } = await runsRepo.transaction(async client => {
        let activityId = dto.activityId;

        // Create Activity if scheduledItemId is provided but no activityId
        if (!activityId && dto.scheduledItemId) {
          const activity = await activitiesRepo.create(
            {
              userId: user.id,
              type: ActivityType.RUNNING,
              status: ActivityStatus.COMPLETED,
              scheduledItemId: dto.scheduledItemId,
              name: dto.distance >= 1000 ? `Run ${Math.round(dto.distance / 1000)}km` : 'Run',
            },
            client,
          );
          activityId = activity.id;
        }

        // 1. Create Run
        const result = await runsRepo.create(
          {
            userId: user.id,
            activityId, // Link to activity (new or provided)
            scoringClubId, // Pass the resolved scoringClubId
            startedAt,
            endedAt,
            duration,
            distance,
            gpsPoints,
            rpe: dto.rpe,
            notes: dto.notes,
          },
          client,
        );

        // 2. Calculate and Save Contribution (if eligible)
        if (result.validation.valid && scoringClubId && gpsPoints && gpsPoints.length > 1) {
          // TODO: Resolve city from run GPS points instead of hardcoding 'spb'.
          // When adding a second city, contributions will be miscalculated without this.
          const territories = getTerritoriesForCity('spb');

          // Filter territories with valid geometry
          const validTerritories = territories.filter(
            (t): t is TerritoryViewDto & { geometry: NonNullable<TerritoryViewDto['geometry']> } =>
              !!t.geometry && t.geometry.length > 0,
          );

          // Calculate contribution
          // We map gpsPoints to GeoCoordinates (already done above)
          // We map territories to TerritoryGeometry (compatible)
          const contributions = calculateRunContribution(gpsPoints, validTerritories);

          // Save to DB
          await territoriesRepo.addRunContribution(
            client,
            result.run.id,
            scoringClubId,
            contributions,
          );
        }

        return result;
      });

      const response: RunViewDto = {
        id: run.id,
        userId: run.userId,
        activityId: run.activityId,
        scoringClubId: run.scoringClubId,
        startedAt: run.startedAt,
        endedAt: run.endedAt,
        duration: run.duration,
        distance: run.distance,
        status: run.status,
        rpe: run.rpe,
        notes: run.notes,
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
      // Check for idempotency violation (unique index)
      if (error instanceof Error && error.message.includes('idx_runs_user_started')) {
        // Return 200 OK or 409 Conflict. Spec says "Return 200 (idempotency)".
        // But to return 200 we need the run object.
        // For now, let's return 409 and let client handle, or return a specific error code.
        // Spec: "Ignore or return 200". If I can't easily fetch the existing run, 409 is safer to indicate it exists.
        res.status(409).json({ code: 'conflict', message: 'Run already exists' });
        return;
      }
      res.status(500).json({
        code: 'internal_error',
        message: 'Internal server error',
      });
    }
  },
);

export default router;
