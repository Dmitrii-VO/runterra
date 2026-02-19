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
import { getTerritoriesForCity } from '../modules/territories/territories.config';
import { validateBody } from './validateBody';
import { getUsersRepository, getClubMembersRepository, getClubsRepository, getClubChannelsRepository, getScheduleRepository } from '../db/repositories';
import { logger } from '../shared/logger';
import { isValidClubId } from '../shared/clubId';
import { CreateWeeklyScheduleItemSchema, CreateWeeklyScheduleItemDto, SetupPersonalPlanSchema, SetupPersonalPlanDto } from '../modules/schedule/schedule.dto';
import { CalendarItemDto, GetCalendarQuerySchema } from '../modules/schedule/calendar.dto';
import { scheduleGeneratorService } from '../modules/schedule/schedule-generator.service';


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

    // Territories count (static config: territories with clubId matching this club)
    const territoriesForClub = getTerritoriesForCity(club.cityId, id);
    const territoriesCount = territoriesForClub.length;

    // City rank: membersCount * 1 + territoriesCount * 10 (MVP formula from audit)
    const cityRank = membersCount * 1 + territoriesCount * 10;

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
      territoriesCount,
      cityRank,
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

    // Create club — always PENDING until 2+ active members (auto-activation on approve)
    const clubsRepo = getClubsRepository();

    // Check if user already in a club
    const clubMembersRepo = getClubMembersRepository();
    const activeMemberships = await clubMembersRepo.findActiveByUser(user.id);
    if (activeMemberships.length > 0) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'You are already a member of another club',
        details: {
          fields: [{ field: 'userId', message: 'User already has an active club membership', code: 'already_in_another_club' }],
        },
      });
    }

    const club = await clubsRepo.create(
      dto.name,
      dto.cityId,
      user.id,
      dto.description,
      ClubStatus.PENDING,
    );

    // Auto-add creator as active leader
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

    // Check if user already in ANOTHER club
    const activeMemberships = await clubMembersRepo.findActiveByUser(user.id);
    const inAnotherClub = activeMemberships.find(m => m.clubId !== clubId);
    if (inAnotherClub) {
      res.status(400).json({
        code: 'already_in_another_club',
        message: 'You are already a member of another club',
        details: { clubId: inAnotherClub.clubId },
      });
      return;
    }

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

    // Guardrail: do not allow demoting the last active leader without transferring leadership.
    // The correct flow is to promote another member to leader (which demotes the current leader to trainer).
    if (targetMembership.role === 'leader' && role !== 'leader') {
      const leadersCount = await clubMembersRepo.countActiveLeaders(clubId);
      if (leadersCount <= 1) {
        return res.status(400).json({
          code: 'leader_transfer_required',
          message: 'Transfer leadership before changing leader role',
          details: { clubId },
        });
      }
    }

    // Update role (with leader transfer: demote old leader when promoting new one)
    const updated = await clubMembersRepo.updateRoleWithLeaderTransfer(clubId, targetUserId, role);
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

    // Auto-activate club when 2+ active members
    const membersCount = await clubMembersRepo.countActiveMembers(clubId);
    if (membersCount >= 2) {
      const clubsRepo = getClubsRepository();
      await clubsRepo.update(clubId, { status: ClubStatus.ACTIVE });
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

/**
 * GET /api/clubs/:id/schedule
 *
 * Получить недельный шаблон расписания клуба.
 */
router.get('/:id/schedule', async (req: Request, res: Response) => {
  const { id: clubId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }

  try {
    const scheduleRepo = getScheduleRepository();
    const schedule = await scheduleRepo.findWeeklyByClub(clubId);
    res.status(200).json(schedule);
  } catch (error) {
    logger.error('Error fetching club schedule', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

/**
 * POST /api/clubs/:id/schedule
 *
 * Добавить элемент в недельный шаблон. Только для лидеров и тренеров.
 */
router.post('/:id/schedule', validateBody(CreateWeeklyScheduleItemSchema), async (req: Request, res: Response) => {
  const { id: clubId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }

  const uid = req.authUser?.uid;
  if (!uid) {
    return res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
    });
  }

  const dto = req.body as CreateWeeklyScheduleItemDto;

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      return res.status(401).json({ code: 'unauthorized', message: 'User not found' });
    }

    const membersRepo = getClubMembersRepository();
    const membership = await membersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || !['leader', 'trainer'].includes(membership.role) || membership.status !== 'active') {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only club leaders and trainers can manage schedule',
      });
    }

    const scheduleRepo = getScheduleRepository();
    const newItem = await scheduleRepo.createWeeklyItem(clubId, dto);
    res.status(201).json(newItem);
  } catch (error) {
    logger.error('Error creating schedule item', { clubId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

/**
 * DELETE /api/clubs/:id/schedule/:itemId
 *
 * Удалить элемент из шаблона. Только для лидеров и тренеров.
 */
router.delete('/:id/schedule/:itemId', async (req: Request, res: Response) => {
  const { id: clubId, itemId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }

  const uid = req.authUser?.uid;
  if (!uid) {
    return res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
    });
  }

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      return res.status(401).json({ code: 'unauthorized', message: 'User not found' });
    }

    const membersRepo = getClubMembersRepository();
    const membership = await membersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || !['leader', 'trainer'].includes(membership.role) || membership.status !== 'active') {
      return res.status(403).json({
        code: 'forbidden',
        message: 'Only club leaders and trainers can manage schedule',
      });
    }

    const scheduleRepo = getScheduleRepository();
    const deleted = await scheduleRepo.deleteWeeklyItem(itemId);
    if (!deleted) {
      return res.status(404).json({
        code: 'not_found',
        message: 'Schedule item not found',
      });
    }

    // Trigger sync to soft-delete future events
    await scheduleGeneratorService.syncTemplateChanges(itemId, 'club');

    res.status(204).send();
  } catch (error) {
    logger.error('Error deleting schedule item', { clubId, itemId, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

/**
 * PATCH /api/clubs/:id/schedule/:itemId
 *
 * Обновить элемент шаблона. Только для лидеров и тренеров.
 */
router.patch('/:id/schedule/:itemId', validateBody(CreateWeeklyScheduleItemSchema.partial()), async (req: Request, res: Response) => {
  const { id: clubId, itemId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }

  const uid = req.authUser?.uid;
  if (!uid) {
    return res.status(401).json({ code: 'unauthorized', message: 'Authorization required' });
  }

  const dto = req.body as Partial<CreateWeeklyScheduleItemDto>;

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) return res.status(401).json({ code: 'unauthorized', message: 'User not found' });

    const membersRepo = getClubMembersRepository();
    const membership = await membersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || !['leader', 'trainer'].includes(membership.role) || membership.status !== 'active') {
      return res.status(403).json({ code: 'forbidden', message: 'Access denied' });
    }

    const scheduleRepo = getScheduleRepository();
    const updated = await scheduleRepo.updateWeeklyItem(itemId, dto);
    if (!updated) {
      return res.status(404).json({ code: 'not_found', message: 'Schedule item not found' });
    }

    // Trigger sync with future events
    await scheduleGeneratorService.syncTemplateChanges(itemId, 'club');

    res.status(200).json(updated);
  } catch (error) {
    logger.error('Error updating schedule item', { clubId, itemId, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * POST /api/clubs/:id/members/:userId/personal-schedule
 *
 * Настроить личный план для участника клуба. Только для лидеров и тренеров.
 * Автоматически переключает plan_type в 'personal'.
 */
router.post('/:id/members/:userId/personal-schedule', validateBody(SetupPersonalPlanSchema), async (req: Request, res: Response) => {
  const { id: clubId, userId: targetUserId } = req.params;
  if (!isValidClubId(clubId)) {
    return respondInvalidClubId(res);
  }

  const uid = req.authUser?.uid;
  if (!uid) {
    return res.status(401).json({ code: 'unauthorized', message: 'Authorization required' });
  }

  const { items } = req.body as SetupPersonalPlanDto;

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) return res.status(401).json({ code: 'unauthorized', message: 'User not found' });

    // Проверка прав (только лидеры и тренеры могут менять планы участникам)
    const membersRepo = getClubMembersRepository();
    const requesterMembership = await membersRepo.findByClubAndUser(clubId, user.id);
    if (!requesterMembership || !['leader', 'trainer'].includes(requesterMembership.role) || requesterMembership.status !== 'active') {
      return res.status(403).json({ code: 'forbidden', message: 'Access denied' });
    }

    // Проверка, что целевой пользователь — участник клуба
    const targetMembership = await membersRepo.findByClubAndUser(clubId, targetUserId);
    if (!targetMembership || targetMembership.status !== 'active') {
      return res.status(404).json({ code: 'not_found', message: 'Target member not found in this club' });
    }

    const scheduleRepo = getScheduleRepository();
    
    // 1. Заменяем личный шаблон
    const createdItems = await scheduleRepo.replacePersonalSchedule(targetUserId, items);
    
    // 2. Переключаем тип плана на 'personal'
    await membersRepo.setPlanType(clubId, targetUserId, 'personal');

    res.status(200).json(createdItems);
  } catch (error) {
    logger.error('Error setting personal schedule', { clubId, targetUserId, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/clubs/:id/calendar
 *
 * Календарь событий и заметок для участника клуба.
 * Если у участника 'personal' план — видит свои заметки + события клуба.
 * Если 'club' план — видит события клуба.
 */
router.get('/:id/calendar', async (req: Request, res: Response) => {
  const { id: clubId } = req.params;
  const { month } = GetCalendarQuerySchema.parse(req.query);
  const uid = req.authUser?.uid;

  if (!uid) return res.status(401).json({ code: 'unauthorized', message: 'Auth required' });

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) return res.status(401).json({ code: 'unauthorized', message: 'User not found' });

    const membersRepo = getClubMembersRepository();
    const membership = await membersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || membership.status !== 'active') {
      return res.status(403).json({ code: 'forbidden', message: 'Only club members can view calendar' });
    }

    const eventsRepo = getEventsRepository();
    const scheduleRepo = getScheduleRepository();

    // 1. Получаем события клуба
    const clubEvents = await eventsRepo.findByClubAndMonth(clubId, month);

    // 2. Получаем личные заметки (если план персональный)
    let personalNotes: import('../modules/schedule/schedule.dto').PersonalNoteDto[] = [];
    if (membership.planType === 'personal') {
      personalNotes = await scheduleRepo.findNotesByUserAndMonth(user.id, month);
    }

    // 3. Агрегируем в CalendarItemDto
    const items: CalendarItemDto[] = [];

    // Добавляем события
    clubEvents.forEach(ev => {
      items.push({
        id: ev.id,
        type: 'event',
        date: ev.startDateTime.toISOString().split('T')[0],
        startTime: ev.startDateTime.toISOString().split('T')[1].substring(0, 5),
        name: ev.name,
        description: ev.description,
        activityType: ev.type,
        workoutId: ev.workoutId,
        trainerId: ev.trainerId,
        status: ev.status,
        isPersonal: false,
      });
    });

    // Добавляем заметки
    personalNotes.forEach(note => {
      items.push({
        id: note.id,
        type: 'note',
        date: note.date,
        name: note.name,
        description: note.description,
        activityType: 'note',
        workoutId: note.workoutId,
        trainerId: note.trainerId,
        isPersonal: true,
      });
    });

    // Сортировка по дате и времени
    items.sort((a, b) => {
      if (a.date !== b.date) return a.date.localeCompare(b.date);
      return (a.startTime || '').localeCompare(b.startTime || '');
    });

    res.status(200).json(items);
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({ code: 'validation_error', details: error.errors });
    }
    logger.error('Error fetching calendar', { clubId, month, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

export default router;
