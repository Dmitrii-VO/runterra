/**
 * API роутер для модуля клубов
 *
 * Содержит эндпоинты для работы с клубами:
 * - GET /api/clubs - список клубов
 * - GET /api/clubs/:id - клуб по ID (при auth — isMember, membershipStatus)
 * - POST /api/clubs - создание клуба
 * - POST /api/clubs/:id/join - присоединение к клубу
 * - POST /api/clubs/:id/leave - выход из клуба
 */

import { Router, Request, Response } from 'express';
import { ClubStatus, ClubViewDto, CreateClubDto, CreateClubSchema, UpdateClubDto, UpdateClubSchema } from '../modules/clubs';
import { findCityById } from '../modules/cities/cities.config';
import { validateBody } from './validateBody';
import { getUsersRepository, getClubMembersRepository, getClubsRepository } from '../db/repositories';
import { logger } from '../shared/logger';
import { isValidClubId } from '../shared/clubId';

const router = Router();

function respondInvalidClubId(res: Response): Response {
  return res.status(400).json({
    code: 'validation_error',
    message: 'Path validation failed',
    details: {
      fields: [
        {
          field: 'clubId',
          message: 'clubId has invalid format',
          code: 'club_id_invalid',
        },
      ],
    },
  });
}

/**
 * GET /api/clubs
 *
 * Возвращает список клубов.
 *
 * TODO: Реализовать пагинацию, сортировку.
 */
router.get('/', async (req: Request, res: Response) => {
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

  const city = findCityById(cityId);
  if (!city) {
    return res.status(400).json({
      code: 'validation_error',
      message: 'Query validation failed',
      details: {
        fields: [
          {
            field: 'cityId',
            message: 'Unknown cityId',
            code: 'city_not_found',
          },
        ],
      },
    });
  }

  try {
    const clubsRepo = getClubsRepository();
    const clubs = await clubsRepo.findByCityId(cityId);

    const clubsDto: ClubViewDto[] = clubs.map(club => ({
      id: club.id,
      name: club.name,
      description: club.description,
      status: club.status,
      cityId: club.cityId,
      createdAt: club.createdAt,
      updatedAt: club.updatedAt,
    }));

    res.status(200).json(clubsDto);
  } catch (error) {
    logger.error('Error fetching clubs', { cityId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * GET /api/clubs/:id
 *
 * Возвращает клуб по ID. При наличии auth добавляет isMember и membershipStatus.
 */
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  if (!isValidClubId(id)) {
    return respondInvalidClubId(res);
  }

  try {
    const clubsRepo = getClubsRepository();
    const club = await clubsRepo.findById(id);

    if (!club) {
      return res.status(404).json({
        code: 'not_found',
        message: 'Club not found',
        details: { clubId: id },
      });
    }

    const city = findCityById(club.cityId);

    // Count active members
    const clubMembersRepo = getClubMembersRepository();
    const membersCount = await clubMembersRepo.countActiveMembers(id);

    const clubDto: ClubViewDto & {
      isMember: boolean;
      membershipStatus?: string;
      userRole?: string | null;
      cityName?: string;
      membersCount?: number;
      territoriesCount?: number;
      cityRank?: number;
    } = {
      id: club.id,
      name: club.name,
      description: club.description,
      status: club.status,
      cityId: club.cityId,
      createdAt: club.createdAt,
      updatedAt: club.updatedAt,
      isMember: false,
      userRole: null,
      cityName: city?.name,
      membersCount,
      territoriesCount: 0, // TODO: calculate from territories
      cityRank: 0, // TODO: calculate rank
    };

    const uid = req.authUser?.uid;
    if (uid) {
      try {
        const usersRepo = getUsersRepository();
        const user = await usersRepo.findByFirebaseUid(uid);
        if (user) {
          const membership = await clubMembersRepo.findByClubAndUser(id, user.id);
          clubDto.isMember = membership?.status === 'active';
          if (membership) {
            clubDto.membershipStatus = membership.status;
            clubDto.userRole = membership.role;
          }
        }
      } catch (error) {
        logger.error('Error fetching club membership', { clubId: id, error });
      }
    }

    res.status(200).json(clubDto);
  } catch (error) {
    logger.error('Error fetching club', { clubId: id, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * POST /api/clubs
 *
 * Создает новый клуб.
 *
 * Техническая валидация: тело запроса проверяется через CreateClubSchema.
 * TODO: Реализовать проверку уникальности названия.
 */
router.post('/', validateBody(CreateClubSchema), async (req: Request<{}, ClubViewDto, CreateClubDto>, res: Response) => {
  const dto = req.body;
  const uid = req.authUser?.uid;

  if (!uid) {
    return res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
  }

  try {
    // Get current user
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'Authentication required',
        details: {
          fields: [{ field: 'userId', message: 'User not found for this token', code: 'invalid_user' }],
        },
      });
    }

    // Validate city exists
    const city = findCityById(dto.cityId);
    if (!city) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'Request body validation failed',
        details: {
          fields: [
            {
              field: 'cityId',
              message: 'Unknown cityId',
              code: 'city_not_found',
            },
          ],
        },
      });
    }

    // Create club
    const clubsRepo = getClubsRepository();
    const club = await clubsRepo.create(
      dto.name,
      dto.cityId,
      user.id,
      dto.description,
      dto.status ?? ClubStatus.ACTIVE
    );

    // Auto-add creator as active leader
    const clubMembersRepo = getClubMembersRepository();
    await clubMembersRepo.create(club.id, user.id, 'active', 'leader');

    const clubDto: ClubViewDto = {
      id: club.id,
      name: club.name,
      description: club.description,
      status: club.status,
      cityId: club.cityId,
      createdAt: club.createdAt,
      updatedAt: club.updatedAt,
    };

    res.status(201).json(clubDto);
  } catch (error) {
    logger.error('Error creating club', { dto, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * POST /api/clubs/:id/join
 *
 * Присоединение текущего пользователя к клубу. userId из auth (Firebase UID → users.id).
 * Ошибки в формате ADR-0002.
 */
router.post('/:id/join', async (req: Request, res: Response) => {
  const { id: clubId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }
  const uid = req.authUser?.uid;
  if (!uid) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
    return;
  }

  try {
    // Check if club exists
    const clubsRepo = getClubsRepository();
    const club = await clubsRepo.findById(clubId);
    if (!club) {
      res.status(404).json({
        code: 'not_found',
        message: 'Club not found',
        details: { clubId },
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
          fields: [{ field: 'userId', message: 'User not found for this token', code: 'invalid_user' }],
        },
      });
      return;
    }

    const clubMembersRepo = getClubMembersRepository();
    const existing = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (existing) {
      if (existing.status !== 'active') {
        const membership = await clubMembersRepo.activate(clubId, user.id);
        res.status(201).json({
          id: membership?.id ?? existing.id,
          clubId: existing.clubId,
          userId: existing.userId,
          status: membership?.status ?? 'active',
          createdAt: existing.createdAt,
        });
        return;
      }
      res.status(400).json({
        code: 'already_member',
        message: 'Already a member of this club',
        details: { clubId },
      });
      return;
    }

    const membership = await clubMembersRepo.create(clubId, user.id, 'active');
    res.status(201).json({
      id: membership.id,
      clubId: membership.clubId,
      userId: membership.userId,
      status: membership.status,
      createdAt: membership.createdAt,
    });
  } catch (error) {
    logger.error('Error joining club', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * POST /api/clubs/:id/leave
 *
 * Выход текущего пользователя из клуба.
 * userId из auth (Firebase UID → users.id).
 */
router.post('/:id/leave', async (req: Request, res: Response) => {
  const { id: clubId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }
  const uid = req.authUser?.uid;
  if (!uid) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
    return;
  }

  try {
    // Check if club exists
    const clubsRepo = getClubsRepository();
    const club = await clubsRepo.findById(clubId);
    if (!club) {
      res.status(404).json({
        code: 'not_found',
        message: 'Club not found',
        details: { clubId },
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
          fields: [{ field: 'userId', message: 'User not found for this token', code: 'invalid_user' }],
        },
      });
      return;
    }

    const clubMembersRepo = getClubMembersRepository();
    const existing = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!existing) {
      res.status(400).json({
        code: 'not_member',
        message: 'Not a member of this club',
        details: { clubId },
      });
      return;
    }
    if (existing.status !== 'active') {
      res.status(400).json({
        code: 'already_left',
        message: 'Already left this club',
        details: { clubId },
      });
      return;
    }

    const membership = await clubMembersRepo.deactivate(clubId, user.id);
    res.status(200).json({
      id: membership?.id ?? existing.id,
      clubId: existing.clubId,
      userId: existing.userId,
      status: membership?.status ?? 'inactive',
      createdAt: existing.createdAt,
    });
  } catch (error) {
    logger.error('Error leaving club', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * PATCH /api/clubs/:id
 *
 * Редактирование клуба (название, описание).
 * Только лидер клуба может редактировать.
 */
router.patch('/:id', validateBody(UpdateClubSchema), async (req: Request<{ id: string }, ClubViewDto, UpdateClubDto>, res: Response) => {
  const { id: clubId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }

  const uid = req.authUser?.uid;
  if (!uid) {
    return res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
  }

  const dto = req.body;

  try {
    // Get current user
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'Authentication required',
        details: {
          fields: [{ field: 'userId', message: 'User not found for this token', code: 'invalid_user' }],
        },
      });
    }

    // Check if club exists
    const clubsRepo = getClubsRepository();
    const club = await clubsRepo.findById(clubId);
    if (!club) {
      return res.status(404).json({
        code: 'not_found',
        message: 'Club not found',
        details: { clubId },
      });
    }

    // Check if user is a leader
    const clubMembersRepo = getClubMembersRepository();
    const membership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || membership.role !== 'leader') {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only club leaders can edit the club',
        details: { clubId },
      });
    }

    // Update club
    const updatedClub = await clubsRepo.update(clubId, {
      name: dto.name,
      description: dto.description,
    });

    if (!updatedClub) {
      return res.status(500).json({
        code: 'internal_error',
        message: 'Failed to update club',
        details: undefined,
      });
    }

    const clubDto: ClubViewDto = {
      id: updatedClub.id,
      name: updatedClub.name,
      description: updatedClub.description,
      status: updatedClub.status,
      cityId: updatedClub.cityId,
      createdAt: updatedClub.createdAt,
      updatedAt: updatedClub.updatedAt,
    };

    res.status(200).json(clubDto);
  } catch (error) {
    logger.error('Error updating club', { clubId, dto, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

export default router;
