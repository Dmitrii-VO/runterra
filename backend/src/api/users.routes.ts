/**
 * API роутер для модуля пользователей
 * 
 * Содержит эндпоинты для работы с пользователями:
 * - GET /api/users - список пользователей
 * - GET /api/users/me/profile - профиль текущего пользователя
 * - GET /api/users/:id - пользователь по ID
 * - POST /api/users - создание пользователя
 * - DELETE /api/users/me - удаление аккаунта
 */

import { Router, Request, Response } from 'express';
import { User, UserStatus, CreateUserDto, CreateUserSchema, userToViewDto, ProfileDto } from '../modules/users';
import { ClubRole } from '../modules/clubs';
import { NotificationType } from '../modules/notifications';
import { ActivityStatus } from '../modules/activities';
import { validateBody } from './validateBody';
import { getUsersRepository, getRunsRepository } from '../db/repositories';
import { logger } from '../shared/logger';

const router = Router();

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
      offset ? parseInt(offset, 10) : 0
    );
    res.status(200).json(users.map(userToViewDto));
  } catch (error) {
    logger.error('Error fetching users', { error });
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/users/me/profile
 * 
 * Возвращает агрегированные данные личного кабинета текущего пользователя.
 */
router.get('/me/profile', async (req: Request, res: Response) => {
  // TODO: Получить userId из авторизации
  const firebaseUid = (req as unknown as { user?: { uid: string } }).user?.uid || 'mock-uid-123';
  
  try {
    const usersRepo = getUsersRepository();
    const runsRepo = getRunsRepository();
    
    // Найти или создать пользователя
    let user = await usersRepo.findByFirebaseUid(firebaseUid);
    if (!user) {
      // Создаём пользователя если не существует (первый вход)
      user = await usersRepo.create({
        firebaseUid,
        email: 'user@example.com', // TODO: из Firebase token
        name: 'New User',
      });
    }
    
    // Получаем статистику пробежек
    const runStats = await runsRepo.getUserStats(user.id);
    
    const profile: ProfileDto = {
      user: {
        id: user.id,
        name: user.name,
        avatarUrl: user.avatarUrl,
        cityId: user.cityId,
        cityName: undefined, // TODO: получить из таблицы cities
        isMercenary: user.isMercenary,
        status: user.status,
      },
      // TODO: получить клуб из таблицы club_memberships
      club: undefined,
      stats: {
        trainingCount: runStats.totalRuns,
        territoriesParticipated: 0, // TODO: из territories
        contributionPoints: Math.floor(runStats.totalDistance / 100), // 1 балл за 100м
      },
      // TODO: получить из events/activities
      nextActivity: undefined,
      lastActivity: undefined,
      // TODO: получить из notifications
      notifications: [],
    };

    res.status(200).json(profile);
  } catch (error) {
    logger.error('Error fetching profile', { firebaseUid, error });
    res.status(500).json({ error: 'Internal server error' });
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
      res.status(404).json({ error: 'User not found' });
      return;
    }

    res.status(200).json(userToViewDto(user));
  } catch (error) {
    logger.error('Error fetching user', { userId: id, error });
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/users
 * 
 * Создает нового пользователя.
 */
router.post('/', validateBody(CreateUserSchema), async (req: Request<{}, User, CreateUserDto>, res: Response) => {
  const dto = req.body;

  try {
    const repo = getUsersRepository();
    
    // Проверяем уникальность firebaseUid
    const existing = await repo.findByFirebaseUid(dto.firebaseUid);
    if (existing) {
      res.status(409).json({ error: 'User with this firebaseUid already exists' });
      return;
    }
    
    const user = await repo.create({
      firebaseUid: dto.firebaseUid,
      email: dto.email,
      name: dto.name,
      avatarUrl: dto.avatarUrl,
      cityId: dto.cityId,
      isMercenary: dto.isMercenary,
    });

    res.status(201).json(userToViewDto(user));
  } catch (error) {
    logger.error('Error creating user', { error });
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * DELETE /api/users/me
 * 
 * Удаляет аккаунт текущего пользователя.
 * Каскадно удаляет: runs, event_participants.
 */
router.delete('/me', async (req: Request, res: Response) => {
  // TODO: Получить userId из авторизации
  const firebaseUid = (req as unknown as { user?: { uid: string } }).user?.uid || 'mock-uid-123';
  
  try {
    const repo = getUsersRepository();
    const user = await repo.findByFirebaseUid(firebaseUid);
    
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    
    await repo.delete(user.id);
    
    res.status(200).json({ 
      success: true, 
      message: 'Account deleted successfully' 
    });
  } catch (error) {
    logger.error('Error deleting user', { firebaseUid, error });
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
