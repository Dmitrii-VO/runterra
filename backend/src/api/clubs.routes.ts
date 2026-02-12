/**
 * API роутер для модуля клубов
 *
 * Содержит эндпоинты для работы с клубами:
 * - GET /api/clubs - список клубов
 * - GET /api/clubs/my - список клубов текущего пользователя
 * - GET /api/clubs/:id - клуб по ID (при auth — isMember, membershipStatus)
 * - POST /api/clubs - создание клуба
 * - POST /api/clubs/:id/join - присоединение к клубу
 * - POST /api/clubs/:id/leave - выход из клуба
 */

import { Router, Request, Response } from 'express';
import { z } from 'zod';
import {
  ClubStatus,
  ClubViewDto,
  CreateClubDto,
  CreateClubSchema,
  MyClubViewDto,
  UpdateClubDto,
  UpdateClubSchema,
} from '../modules/clubs';
import { findCityById } from '../modules/cities/cities.config';
import { validateBody } from './validateBody';
import { getUsersRepository, getClubMembersRepository, getClubsRepository, getClubChannelsRepository } from '../db/repositories';
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
 * GET /api/clubs/my
 *
 * Returns all active clubs where current user is a member.
 */
router.get('/my', async (req: Request, res: Response) => {
  const uid = req.authUser?.uid;
  if (!uid) {
    return res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
  }

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      return res.status(401).json({
        code: 'unauthorized',
        message: 'User not found',
      });
    }

    const clubMembersRepo = getClubMembersRepository();
    const myMemberships = await clubMembersRepo.findActiveClubsByUser(user.id);
    const myClubs: MyClubViewDto[] = myMemberships.map((membership) => {
      const city = findCityById(membership.clubCityId);
      return {
        id: membership.clubId,
        name: membership.clubName,
        description: membership.clubDescription,
        cityId: membership.clubCityId,
        cityName: city?.name,
        status: membership.clubStatus as ClubStatus,
        role: membership.role as MyClubViewDto['role'],
        joinedAt: membership.joinedAt,
      };
    });

    res.status(200).json(myClubs);
  } catch (error) {
    logger.error('Error fetching my clubs', { error });
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

    // Resolve creator name
    const usersRepo = getUsersRepository();
    const creator = await usersRepo.findById(club.creatorId);
    const creatorName = creator
      ? `${creator.firstName ?? ''} ${creator.lastName ?? ''}`.trim() || null
      : null;

    const clubDto: ClubViewDto & {
      isMember: boolean;
      membershipStatus?: string;
      userRole?: string | null;
      cityName?: string;
      membersCount?: number;
      territoriesCount?: number;
      cityRank?: number;
      creatorId?: string;
      creatorName?: string | null;
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
      creatorId: club.creatorId,
      creatorName,
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

    // Create default channel for the club
    const clubChannelsRepo = getClubChannelsRepository();
    await clubChannelsRepo.createDefaultForClub(club.id);

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
      if (existing.status === 'active') {
        res.status(400).json({
          code: 'already_member',
          message: 'Already a member of this club',
          details: { clubId },
        });
        return;
      }
      if (existing.status === 'pending') {
        res.status(400).json({
          code: 'already_pending',
          message: 'Membership request already pending',
          details: { clubId },
        });
        return;
      }
      // inactive/suspended → set to pending for re-application
      const membership = await clubMembersRepo.setStatus(clubId, user.id, 'pending');
      res.status(201).json({
        id: membership?.id ?? existing.id,
        clubId: existing.clubId,
        userId: existing.userId,
        status: 'pending',
        createdAt: existing.createdAt,
      });
      return;
    }

    const membership = await clubMembersRepo.create(clubId, user.id, 'pending');
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

    // Check if user is leader
    if (existing.role === 'leader') {
      const memberCount = await clubMembersRepo.countActiveMembers(clubId);
      if (memberCount > 1) {
        res.status(400).json({
          code: 'leader_cannot_leave',
          message: 'Transfer leadership before leaving the club',
          details: { activeMembersCount: memberCount },
        });
        return;
      }
      // Leader is alone — allow leave (club becomes empty)
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
 * GET /api/clubs/:id/members
 *
 * Returns list of active members for a club. Available to all authenticated users.
 */
router.get('/:id/members', async (req: Request, res: Response) => {
  const { id: clubId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }

  try {
    const clubsRepo = getClubsRepository();
    const club = await clubsRepo.findById(clubId);
    if (!club) {
      return res.status(404).json({
        code: 'not_found',
        message: 'Club not found',
        details: { clubId },
      });
    }

    const clubMembersRepo = getClubMembersRepository();
    const members = await clubMembersRepo.findMembersByClub(clubId);

    res.status(200).json(members);
  } catch (error) {
    logger.error('Error fetching club members', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

const UpdateMemberRoleSchema = z.object({
  role: z.enum(['member', 'trainer', 'leader']),
});

/**
 * PATCH /api/clubs/:id/members/:userId/role
 *
 * Update role of a club member. Only leaders can change roles.
 */
router.patch('/:id/members/:userId/role', validateBody(UpdateMemberRoleSchema), async (req: Request, res: Response) => {
  const { id: clubId, userId: targetUserId } = req.params;
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

  const { role } = req.body as { role: 'member' | 'trainer' | 'leader' };

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

    // Check if requester is a leader
    const clubMembersRepo = getClubMembersRepository();
    const requesterMembership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!requesterMembership || requesterMembership.role !== 'leader') {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only club leaders can change member roles',
        details: { clubId },
      });
    }

    // Check if target user is a member
    const targetMembership = await clubMembersRepo.findByClubAndUser(clubId, targetUserId);
    if (!targetMembership || targetMembership.status !== 'active') {
      return res.status(404).json({
        code: 'not_found',
        message: 'Member not found in this club',
        details: { clubId, userId: targetUserId },
      });
    }

    // Update role
    const updated = await clubMembersRepo.updateRole(clubId, targetUserId, role);
    if (!updated) {
      return res.status(500).json({
        code: 'internal_error',
        message: 'Failed to update role',
        details: undefined,
      });
    }

    res.status(200).json({
      userId: updated.userId,
      clubId: updated.clubId,
      role: updated.role,
      status: updated.status,
    });
  } catch (error) {
    logger.error('Error updating member role', { clubId, targetUserId, role, error });
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

/**
 * DELETE /api/clubs/:id
 *
 * Disband (delete) a club. Only the club leader can disband.
 * Deactivates all memberships and sets club status to 'disbanded'.
 */
router.delete('/:id', async (req: Request, res: Response) => {
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

  try {
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

    const clubsRepo = getClubsRepository();
    const club = await clubsRepo.findById(clubId);
    if (!club) {
      return res.status(404).json({
        code: 'not_found',
        message: 'Club not found',
        details: { clubId },
      });
    }

    // Verify leader role
    const clubMembersRepo = getClubMembersRepository();
    const membership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || membership.role !== 'leader') {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only club leaders can disband the club',
        details: { clubId },
      });
    }

    // Deactivate all memberships
    await clubMembersRepo.deactivateAllMembers(clubId);

    // Set club status to disbanded
    await clubsRepo.update(clubId, { status: ClubStatus.DISBANDED });

    res.status(200).json({
      code: 'club_disbanded',
      message: 'Club disbanded',
    });
  } catch (error) {
    logger.error('Error disbanding club', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * GET /api/clubs/:id/channels
 *
 * List channels for a club. Available to active members.
 */
router.get('/:id/channels', async (req: Request, res: Response) => {
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

  try {
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

    const clubMembersRepo = getClubMembersRepository();
    const membership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || membership.status !== 'active') {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only active members can view channels',
        details: { clubId },
      });
    }

    const clubChannelsRepo = getClubChannelsRepository();
    const channels = await clubChannelsRepo.findByClub(clubId);

    res.status(200).json(channels.map(ch => ({
      id: ch.id,
      clubId: ch.clubId,
      type: ch.type,
      name: ch.name,
      isDefault: ch.isDefault,
      createdAt: ch.createdAt,
    })));
  } catch (error) {
    logger.error('Error fetching club channels', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * POST /api/clubs/:id/channels
 *
 * Create a new channel in a club. Only leader/trainer can create.
 */
router.post('/:id/channels', async (req: Request, res: Response) => {
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

  const { name, type } = req.body as { name?: string; type?: string };
  if (!name || typeof name !== 'string' || name.trim().length === 0) {
    return res.status(400).json({
      code: 'validation_error',
      message: 'Channel name is required',
      details: {
        fields: [{ field: 'name', message: 'Name is required', code: 'required' }],
      },
    });
  }

  try {
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

    const clubMembersRepo = getClubMembersRepository();
    const membership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || !['leader', 'trainer'].includes(membership.role)) {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only leaders and trainers can create channels',
        details: { clubId },
      });
    }

    const clubChannelsRepo = getClubChannelsRepository();
    const channel = await clubChannelsRepo.create(clubId, name.trim(), type || 'general');

    res.status(201).json({
      id: channel.id,
      clubId: channel.clubId,
      type: channel.type,
      name: channel.name,
      isDefault: channel.isDefault,
      createdAt: channel.createdAt,
    });
  } catch (error) {
    logger.error('Error creating club channel', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * GET /api/clubs/:id/membership-requests
 *
 * List pending membership requests. Only leader/trainer can view.
 */
router.get('/:id/membership-requests', async (req: Request, res: Response) => {
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

  try {
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

    const clubMembersRepo = getClubMembersRepository();
    const requesterMembership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!requesterMembership || !['leader', 'trainer'].includes(requesterMembership.role)) {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only leaders and trainers can view membership requests',
        details: { clubId },
      });
    }

    const pending = await clubMembersRepo.findPendingByClub(clubId);
    res.status(200).json(pending);
  } catch (error) {
    logger.error('Error fetching membership requests', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * POST /api/clubs/:id/membership-requests/:userId/approve
 *
 * Approve a pending membership request. Only leader/trainer can approve.
 */
router.post('/:id/membership-requests/:userId/approve', async (req: Request, res: Response) => {
  const { id: clubId, userId: targetUserId } = req.params;
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

  try {
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

    const clubMembersRepo = getClubMembersRepository();
    const requesterMembership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!requesterMembership || !['leader', 'trainer'].includes(requesterMembership.role)) {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only leaders and trainers can approve membership requests',
        details: { clubId },
      });
    }

    const approved = await clubMembersRepo.approveMembership(clubId, targetUserId);
    if (!approved) {
      return res.status(404).json({
        code: 'not_found',
        message: 'No pending request found for this user',
        details: { clubId, userId: targetUserId },
      });
    }

    res.status(200).json({
      userId: approved.userId,
      clubId: approved.clubId,
      status: approved.status,
      role: approved.role,
    });
  } catch (error) {
    logger.error('Error approving membership', { clubId, targetUserId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * POST /api/clubs/:id/membership-requests/:userId/reject
 *
 * Reject a pending membership request. Only leader/trainer can reject.
 */
router.post('/:id/membership-requests/:userId/reject', async (req: Request, res: Response) => {
  const { id: clubId, userId: targetUserId } = req.params;
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

  try {
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

    const clubMembersRepo = getClubMembersRepository();
    const requesterMembership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!requesterMembership || !['leader', 'trainer'].includes(requesterMembership.role)) {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only leaders and trainers can reject membership requests',
        details: { clubId },
      });
    }

    const rejected = await clubMembersRepo.rejectMembership(clubId, targetUserId);
    if (!rejected) {
      return res.status(404).json({
        code: 'not_found',
        message: 'No pending request found for this user',
        details: { clubId, userId: targetUserId },
      });
    }

    res.status(200).json({
      code: 'request_rejected',
      message: 'Membership request rejected',
    });
  } catch (error) {
    logger.error('Error rejecting membership', { clubId, targetUserId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

export default router;
