/**
 * API роутер для модуля пользователей
 *
 * Содержит эндпоинты для работы с пользователями:
 * - GET /api/users - список пользователей
 * - GET /api/users/me/profile - профиль текущего пользователя
 * - PATCH /api/users/me/profile - обновление профиля (currentCityId и др.)
 * - GET /api/users/:id - пользователь по ID
 * - POST /api/users - создание пользователя
 * - DELETE /api/users/me - удаление аккаунта
 */

import { Router, Request, Response } from 'express';
import {
  User,
  CreateUserDto,
  CreateUserSchema,
  userToViewDto,
  ProfileDto,
  ProfileActivityDto,
  UpdateProfileSchema,
  UserSearchResultDto,
  PublicProfileDto,
  PublicRunDto,
} from '../modules/users';
import { validateBody } from './validateBody';
import {
  getUsersRepository,
  getRunsRepository,
  getClubMembersRepository,
  getClubsRepository,
  getEventsRepository,
} from '../db/repositories';
import { ActivityStatus } from '../modules/activities';
import { findCityById } from '../modules/cities/cities.config';
import { ClubRole } from '../modules/clubs';
import { logger } from '../shared/logger';

const router = Router();

function splitDisplayName(displayName?: string): { firstName?: string; lastName?: string } {
  if (!displayName) return {};
  const parts = displayName.trim().split(/\s+/);
  if (parts.length === 0) return {};
  if (parts.length === 1) return { firstName: parts[0] };
  return { firstName: parts[0], lastName: parts.slice(1).join(' ') };
}

/**
 * GET /api/users
 *
 * Возвращает список пользователей.
 * Query: limit, offset
 */
router.get('/', async (req: Request, res: Response) => {
  const { limit, offset } = req.query as { limit?: string; offset?: string };

  try {
    const repo = getUsersRepository();
    const users = await repo.findAll(
      limit ? parseInt(limit, 10) : 50,
      offset ? parseInt(offset, 10) : 0,
    );
    res.status(200).json(users.map(userToViewDto));
  } catch (error) {
    logger.error('Error fetching users', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/users/me/profile
 *
 * Возвращает агрегированные данные личного кабинета текущего пользователя.
 */
router.get('/me/profile', async (req: Request, res: Response) => {
  const firebaseUid = req.authUser?.uid;
  if (!firebaseUid) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
    return;
  }

  try {
    const usersRepo = getUsersRepository();
    const runsRepo = getRunsRepository();

    // Найти или создать пользователя
    let user = await usersRepo.findByFirebaseUid(firebaseUid);
    if (!user) {
      // Создаём пользователя если не существует (первый вход)
      const displayName = req.authUser?.displayName ?? 'New User';
      const { firstName, lastName } = splitDisplayName(displayName);
      user = await usersRepo.create({
        firebaseUid,
        email: req.authUser?.email ?? 'user@example.com', // TODO: из Firebase token
        name: displayName,
        firstName: firstName ?? displayName,
        lastName,
        avatarUrl: req.authUser?.photoURL,
      });
    }

    // Получаем статистику пробежек
    const runStats = await runsRepo.getUserStats(user.id);

    const clubMembersRepo = getClubMembersRepository();
    const clubsRepo = getClubsRepository();
    const rawPrimaryClubId = await clubMembersRepo.findPrimaryClubIdByUser(user.id);
    const membership = rawPrimaryClubId
      ? await clubMembersRepo.findByClubAndUser(rawPrimaryClubId, user.id)
      : null;
    const primaryClub = rawPrimaryClubId ? await clubsRepo.findById(rawPrimaryClubId) : null;
    const primaryClubId = primaryClub?.id;

    const club = primaryClub
      ? {
          id: primaryClub.id,
          name: primaryClub.name,
          role: (membership?.role ?? 'member') as ClubRole,
        }
      : null;

    const eventsRepo = getEventsRepository();

    // nextActivity: next upcoming event the user is registered for
    const nextEvent = await eventsRepo.getNextEventForUser(user.id);
    const nextActivity: ProfileActivityDto | undefined = nextEvent
      ? {
          id: nextEvent.id,
          name: nextEvent.name,
          dateTime: nextEvent.start_date_time,
          status: nextEvent.ep_status === 'checked_in' ? ActivityStatus.IN_PROGRESS : ActivityStatus.PLANNED,
        }
      : undefined;

    // lastActivity: most recent run
    const lastRun = await runsRepo.getLastRun(user.id);
    const lastActivity: ProfileActivityDto | undefined = lastRun
      ? {
          id: lastRun.id,
          dateTime: lastRun.started_at,
          status: ActivityStatus.COMPLETED,
          result: lastRun.status === 'completed' ? 'counted' : 'not_counted',
        }
      : undefined;

    const profile: ProfileDto = {
      user: {
        id: user.id,
        name: user.name,
        firstName: user.firstName,
        lastName: user.lastName,
        birthDate: user.birthDate,
        country: user.country,
        gender: user.gender,
        avatarUrl: user.avatarUrl,
        cityId: user.cityId,
        cityName: user.cityId ? findCityById(user.cityId)?.name : undefined,
        primaryClubId: primaryClubId ?? undefined,
        isMercenary: user.isMercenary,
        status: user.status,
        profileVisible: user.profileVisible ?? true,
      },
      club,
      stats: {
        trainingCount: runStats.totalRuns,
        territoriesParticipated: 0, // TODO: из territories
        contributionPoints: Math.floor(runStats.totalDistance / 100), // 1 балл за 100м
      },
      nextActivity,
      lastActivity,
      // TODO: получить из notifications
      notifications: [],
    };

    res.status(200).json(profile);
  } catch (error) {
    logger.error('Error fetching profile', { firebaseUid, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * PATCH /api/users/me/profile
 *
 * Обновляет профиль текущего пользователя (например currentCityId).
 * Тело: { currentCityId?: string }.
 */
router.patch(
  '/me/profile',
  validateBody(UpdateProfileSchema),
  async (req: Request, res: Response) => {
    const firebaseUid = req.authUser?.uid;
    if (!firebaseUid) {
      res.status(401).json({
        code: 'unauthorized',
        message: 'Authorization required',
        details: { reason: 'missing_header' },
      });
      return;
    }

    try {
      const usersRepo = getUsersRepository();
      const user = await usersRepo.findByFirebaseUid(firebaseUid);
      if (!user) {
        res.status(404).json({
          code: 'not_found',
          message: 'User not found',
        });
        return;
      }

      const body = req.body as {
        currentCityId?: string;
        name?: string;
        firstName?: string;
        lastName?: string;
        birthDate?: string;
        country?: string;
        gender?: 'male' | 'female';
        avatarUrl?: string;
        profileVisible?: boolean;
      };
      const updates: {
        cityId?: string | null;
        name?: string;
        firstName?: string;
        lastName?: string;
        birthDate?: string | null;
        country?: string;
        gender?: 'male' | 'female';
        avatarUrl?: string;
        profileVisible?: boolean;
      } = {};
      if (body.currentCityId !== undefined) {
        const cityId = body.currentCityId.trim();
        if (cityId && !findCityById(cityId)) {
          res.status(400).json({
            code: 'validation_error',
            message: 'Request body validation failed',
            details: {
              fields: [
                {
                  field: 'currentCityId',
                  message: 'Unknown cityId',
                  code: 'unknown_city',
                },
              ],
            },
          });
          return;
        }
        updates.cityId = cityId || null;
      }
      if (body.name !== undefined) updates.name = body.name;
      if (body.firstName !== undefined) updates.firstName = body.firstName;
      if (body.lastName !== undefined) updates.lastName = body.lastName;
      if (body.birthDate !== undefined) updates.birthDate = body.birthDate;
      if (body.country !== undefined) updates.country = body.country;
      if (body.gender !== undefined) updates.gender = body.gender;
      if (body.avatarUrl !== undefined) updates.avatarUrl = body.avatarUrl;
      if (body.profileVisible !== undefined) updates.profileVisible = body.profileVisible;

      if (body.firstName !== undefined || body.lastName !== undefined) {
        const resolvedFirstName = body.firstName ?? user.firstName ?? user.name;
        const resolvedLastName = body.lastName ?? user.lastName;
        const combinedName = [resolvedFirstName, resolvedLastName].filter(Boolean).join(' ').trim();
        if (combinedName) updates.name = combinedName;
      }

      if (Object.keys(updates).length > 0) {
        await usersRepo.update(user.id, updates);
      }

      res.status(200).json({ success: true });
    } catch (error) {
      logger.error('Error updating profile', { firebaseUid, error });
      res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
    }
  },
);

/**
 * GET /api/users/me/nav-status
 *
 * Returns flags for dynamic UI navigation (tabs visibility).
 */
router.get('/me/nav-status', async (req: Request, res: Response) => {
  const firebaseUid = req.authUser?.uid;
  if (!firebaseUid) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
    });
    return;
  }

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(firebaseUid);
    if (!user) {
      // Return default false if user not created yet
      res.status(200).json({ hasClubs: false, hasTrainers: false });
      return;
    }

    const status = await usersRepo.getNavigationStatus(user.id);
    res.status(200).json(status);
  } catch (error) {
    logger.error('Error fetching nav status', { firebaseUid, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/users/search
 *
 * Search users by name (ILIKE). Excludes the requesting user and hidden profiles.
 * Query: q (required, min 2 chars), cityId?, limit (1-50, default 20), offset (default 0).
 */
router.get('/search', async (req: Request, res: Response) => {
  const { q, cityId, limit: limitStr, offset: offsetStr } = req.query as {
    q?: string;
    cityId?: string;
    limit?: string;
    offset?: string;
  };

  if (!q || q.trim().length < 2) {
    res.status(400).json({
      code: 'validation_error',
      message: 'Query must be at least 2 characters',
      details: {
        fields: [{ field: 'q', message: 'Must be at least 2 characters', code: 'min_length' }],
      },
    });
    return;
  }

  const limit = Math.min(50, Math.max(1, limitStr ? parseInt(limitStr, 10) : 20));
  const offset = Math.max(0, offsetStr ? parseInt(offsetStr, 10) : 0);

  try {
    const repo = getUsersRepository();
    const firebaseUid = req.authUser!.uid;
    const currentUser = await repo.findByFirebaseUid(firebaseUid);
    if (!currentUser) {
      res.status(404).json({ code: 'not_found', message: 'User not found' });
      return;
    }

    const results = await repo.searchByName(q.trim(), {
      cityId: cityId?.trim() || undefined,
      excludeUserId: currentUser.id,
      limit,
      offset,
    });

    const dtos: UserSearchResultDto[] = results.map((r) => ({
      id: r.id,
      name: r.name,
      firstName: r.firstName,
      lastName: r.lastName,
      avatarUrl: r.avatarUrl,
      cityId: r.cityId,
      cityName: r.cityId ? findCityById(r.cityId)?.name : undefined,
      clubName: r.clubName,
    }));

    res.status(200).json(dtos);
  } catch (error) {
    logger.error('Error searching users', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/users/:id/profile
 *
 * Returns public profile with run stats and recent runs for another user.
 * 404 if user not found or profile is hidden (profileVisible = false).
 */
router.get('/:id/profile', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findById(id);

    if (!user || user.profileVisible === false) {
      res.status(404).json({ code: 'not_found', message: 'User not found' });
      return;
    }

    const runsRepo = getRunsRepository();
    const runStats = await runsRepo.getUserStats(user.id);

    const recentRunEntities = await runsRepo.findByUserId(user.id, 5, 0);
    const recentRuns: PublicRunDto[] = recentRunEntities
      .filter((r) => r.status === 'completed')
      .slice(0, 5)
      .map((r) => ({
        id: r.id,
        startedAt: r.startedAt.toISOString(),
        distance: r.distance,
        duration: r.duration,
        pace:
          r.distance > 0 ? Math.round((r.duration / r.distance) * 1000) : 0,
      }));

    const clubMembersRepo = getClubMembersRepository();
    const clubsRepo = getClubsRepository();
    const primaryClubId = await clubMembersRepo.findPrimaryClubIdByUser(user.id);
    const primaryClub = primaryClubId ? await clubsRepo.findById(primaryClubId) : null;

    const profile: PublicProfileDto = {
      user: {
        id: user.id,
        name: user.name,
        firstName: user.firstName,
        lastName: user.lastName,
        avatarUrl: user.avatarUrl,
        cityId: user.cityId,
        cityName: user.cityId ? findCityById(user.cityId)?.name : undefined,
      },
      club: primaryClub ? { id: primaryClub.id, name: primaryClub.name } : null,
      stats: {
        totalRuns: runStats.totalRuns,
        totalDistanceKm:
          Math.round((runStats.totalDistance / 1000) * 10) / 10,
        totalDurationMin: Math.round(runStats.totalDuration / 60),
        averagePace: runStats.averagePace,
        contributionPoints: Math.floor(runStats.totalDistance / 100),
      },
      recentRuns,
    };

    res.status(200).json(profile);
  } catch (error) {
    logger.error('Error fetching public profile', { userId: id, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/users/:id
 *
 * Возвращает пользователя по ID.
 */
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const repo = getUsersRepository();
    const user = await repo.findById(id);

    if (!user) {
      res.status(404).json({ code: 'not_found', message: 'User not found' });
      return;
    }

    res.status(200).json(userToViewDto(user));
  } catch (error) {
    logger.error('Error fetching user', { userId: id, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * POST /api/users
 *
 * Создает нового пользователя.
 */
router.post(
  '/',
  validateBody(CreateUserSchema),
  async (req: Request<{}, User, CreateUserDto>, res: Response) => {
    const dto = req.body;

    try {
      const cityId = dto.cityId?.trim();
      if (cityId && !findCityById(cityId)) {
        res.status(400).json({
          code: 'validation_error',
          message: 'Request body validation failed',
          details: {
            fields: [
              {
                field: 'cityId',
                message: 'Unknown cityId',
                code: 'unknown_city',
              },
            ],
          },
        });
        return;
      }

      const repo = getUsersRepository();

      // Проверяем уникальность firebaseUid
      const existing = await repo.findByFirebaseUid(dto.firebaseUid);
      if (existing) {
        res
          .status(409)
          .json({ code: 'conflict', message: 'User with this firebaseUid already exists' });
        return;
      }

      const user = await repo.create({
        firebaseUid: dto.firebaseUid,
        email: dto.email,
        name: dto.name,
        avatarUrl: dto.avatarUrl,
        cityId: cityId || undefined,
        isMercenary: dto.isMercenary,
      });

      res.status(201).json(userToViewDto(user));
    } catch (error) {
      logger.error('Error creating user', { error });
      res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
    }
  },
);

/**
 * DELETE /api/users/me
 *
 * Удаляет аккаунт текущего пользователя.
 * Каскадно удаляет: runs, event_participants.
 */
router.delete('/me', async (req: Request, res: Response) => {
  const firebaseUid = req.authUser?.uid;
  if (!firebaseUid) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
    return;
  }

  try {
    const repo = getUsersRepository();
    const user = await repo.findByFirebaseUid(firebaseUid);

    if (!user) {
      res.status(404).json({ code: 'not_found', message: 'User not found' });
      return;
    }

    await repo.delete(user.id);

    res.status(200).json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (error) {
    logger.error('Error deleting user', { firebaseUid, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/users/me/calendar?year=2026&month=3
 *
 * Returns training calendar for the current month: completed runs + registered events.
 * Only non-empty days are returned.
 * Query params: year (2000-2100), month (1-12). Defaults to current UTC month.
 */
router.get('/me/calendar', async (req: Request, res: Response) => {
  const firebaseUid = req.authUser?.uid;
  if (!firebaseUid) {
    res.status(401).json({ code: 'unauthorized', message: 'Authorization required' });
    return;
  }

  const now = new Date();
  const yearRaw = req.query.year ? parseInt(req.query.year as string, 10) : now.getUTCFullYear();
  const monthRaw = req.query.month ? parseInt(req.query.month as string, 10) : now.getUTCMonth() + 1;

  if (isNaN(yearRaw) || yearRaw < 2000 || yearRaw > 2100) {
    res.status(400).json({ code: 'validation_error', message: 'Invalid year', details: { fields: [{ field: 'year', message: 'Must be between 2000 and 2100', code: 'invalid' }] } });
    return;
  }
  if (isNaN(monthRaw) || monthRaw < 1 || monthRaw > 12) {
    res.status(400).json({ code: 'validation_error', message: 'Invalid month', details: { fields: [{ field: 'month', message: 'Must be between 1 and 12', code: 'invalid' }] } });
    return;
  }

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(firebaseUid);
    if (!user) {
      res.status(404).json({ code: 'not_found', message: 'User not found' });
      return;
    }

    const [runs, events] = await Promise.all([
      getRunsRepository().getRunsForMonth(user.id, yearRaw, monthRaw),
      getEventsRepository().getRegisteredEventsForMonth(user.id, yearRaw, monthRaw),
    ]);

    // Group by date
    const dayMap = new Map<string, { date: string; runs: typeof runs; events: typeof events }>();

    for (const run of runs) {
      if (!dayMap.has(run.date)) dayMap.set(run.date, { date: run.date, runs: [], events: [] });
      dayMap.get(run.date)!.runs.push(run);
    }
    for (const event of events) {
      if (!dayMap.has(event.date)) dayMap.set(event.date, { date: event.date, runs: [], events: [] });
      dayMap.get(event.date)!.events.push(event);
    }

    const days = Array.from(dayMap.values())
      .map(d => ({
        date: d.date,
        runs: d.runs.map(r => ({ id: r.id, distanceM: r.distanceM, durationS: r.durationS })),
        events: d.events.map(e => ({ id: e.id, name: e.name })),
      }))
      .sort((a, b) => a.date.localeCompare(b.date));

    res.json({ days });
  } catch (error) {
    logger.error('Error fetching calendar', { firebaseUid, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

export default router;
