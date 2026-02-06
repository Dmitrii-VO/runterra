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
import { ClubStatus, ClubViewDto, CreateClubDto, CreateClubSchema } from '../modules/clubs';
import { findCityById } from '../modules/cities/cities.config';
import { validateBody } from './validateBody';
import { getUsersRepository, getClubMembersRepository } from '../db/repositories';
import { logger } from '../shared/logger';

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

  // Static sample clubs for MVP (no clubs table yet).
  // Align ids with territories config for "owner club" examples.
  const now = new Date();
  const clubs: ClubViewDto[] = [
    {
      id: 'club-1',
      name: 'Runterra Крестовский',
      description: 'Клуб утренних пробежек в Приморском парке Победы и на Крестовском острове.',
      status: ClubStatus.ACTIVE,
      cityId,
      createdAt: now,
      updatedAt: now,
    },
    {
      id: 'club-2',
      name: 'Runterra Парк 300-летия',
      description: 'Сообщество любителей набережной и парка 300-летия Санкт-Петербурга.',
      status: ClubStatus.ACTIVE,
      cityId,
      createdAt: now,
      updatedAt: now,
    },
  ];

  res.status(200).json(clubs);
});

/**
 * GET /api/clubs/:id
 *
 * Возвращает клуб по ID. При наличии auth добавляет isMember и membershipStatus.
 */
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  const cityId = 'spb';
  const city = findCityById(cityId);
  const mockClub: ClubViewDto & {
    isMember: boolean;
    membershipStatus?: string;
    cityName?: string;
    membersCount?: number;
    territoriesCount?: number;
    cityRank?: number;
  } = {
    id,
    name: `Club ${id}`,
    description: `Description for club ${id}`,
    status: ClubStatus.ACTIVE,
    cityId,
    createdAt: new Date(),
    updatedAt: new Date(),
    isMember: false,
    cityName: city?.name,
    membersCount: 0,
    territoriesCount: 0,
    cityRank: 0,
  };

  const uid = req.authUser?.uid;
  if (uid) {
    try {
      const usersRepo = getUsersRepository();
      const user = await usersRepo.findByFirebaseUid(uid);
      if (user) {
        const clubMembersRepo = getClubMembersRepository();
        const membership = await clubMembersRepo.findByClubAndUser(id, user.id);
        mockClub.isMember = membership?.status === 'active';
        if (membership) mockClub.membershipStatus = membership.status;
      }
    } catch (error) {
      logger.error('Error fetching club membership', { clubId: id, error });
    }
  }

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

/**
 * POST /api/clubs/:id/join
 *
 * Присоединение текущего пользователя к клубу. userId из auth (Firebase UID → users.id).
 * Ошибки в формате ADR-0002.
 */
router.post('/:id/join', async (req: Request, res: Response) => {
  const { id: clubId } = req.params;
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

export default router;
