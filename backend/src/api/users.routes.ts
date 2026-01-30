/**
 * API роутер для модуля пользователей
 * 
 * Содержит эндпоинты для работы с пользователями:
 * - GET /api/users - список пользователей
 * - GET /api/users/:id - пользователь по ID
 * - POST /api/users - создание пользователя
 * 
 * На текущей стадии (skeleton) все эндпоинты возвращают заглушки.
 * TODO: Реализовать контроллеры и бизнес-логику в будущем.
 */

import { Router, Request, Response } from 'express';
import { User, UserStatus, CreateUserDto, CreateUserSchema, userToViewDto, ProfileDto, UserStats } from '../modules/users';
import { ClubRole } from '../modules/clubs';
import { NotificationType, Notification } from '../modules/notifications';
import { ActivityStatus } from '../modules/activities';
import { validateBody } from './validateBody';

const router = Router();

/**
 * GET /api/users
 * 
 * Возвращает список пользователей.
 * 
 * TODO: Реализовать пагинацию, фильтрацию, сортировку.
 */
router.get('/', (_req: Request, res: Response) => {
  // Заглушка: возвращаем массив из одного пользователя
  const mockUsers: User[] = [
    {
      id: '1',
      firebaseUid: 'firebase-uid-1',
      email: 'user@example.com',
      name: 'Test User',
      avatarUrl: undefined,
      cityId: undefined,
      isMercenary: false,
      status: UserStatus.ACTIVE,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  res.status(200).json(mockUsers.map(userToViewDto));
});

/**
 * GET /api/users/me/profile
 * 
 * Возвращает агрегированные данные личного кабинета текущего пользователя.
 * 
 * TODO: Реализовать авторизацию и получение данных из БД.
 * MOCK: данные ниже — заглушка. TODO: replace with real data / ProfileService.
 */
router.get('/me/profile', (_req: Request, res: Response) => {
  // MOCK — фейковые данные для skeleton. Не использовать в проде.
  const mockProfile: ProfileDto = {
    user: {
      id: '1',
      name: 'Test User',
      avatarUrl: undefined,
      cityId: 'city-spb',
      cityName: 'Санкт-Петербург',
      isMercenary: false,
      status: UserStatus.ACTIVE,
    },
    club: {
      id: 'club-1',
      name: 'Бегуны Петербурга',
      role: ClubRole.MEMBER,
    },
    stats: {
      trainingCount: 5,
      territoriesParticipated: 3,
      contributionPoints: 150,
    },
    nextActivity: {
      id: 'activity-1',
      name: 'Утренняя пробежка',
      dateTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(), // завтра
      status: ActivityStatus.PLANNED,
    },
    lastActivity: {
      id: 'activity-2',
      name: 'Вечерняя тренировка',
      dateTime: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(), // 2 дня назад
      status: ActivityStatus.COMPLETED,
      result: 'counted',
      message: '+10 баллов, вклад в территорию',
    },
    notifications: [
      {
        id: 'notif-1',
        userId: '1',
        type: NotificationType.NEW_TRAINING,
        title: 'Новая тренировка',
        message: 'Ваш клуб создал новую тренировку',
        read: false,
        createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 часа назад
      },
      {
        id: 'notif-2',
        userId: '1',
        type: NotificationType.TERRITORY_THREAT,
        title: 'Территория под угрозой',
        message: 'Территория вашего клуба атакуется',
        read: true,
        createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000), // 5 часов назад
      },
    ],
  };

  res.status(200).json(mockProfile);
  // TODO: replace with real data. Remove mockProfile when ProfileService exists.
});

/**
 * GET /api/users/:id
 * 
 * Возвращает пользователя по ID.
 * 
 * TODO: Реализовать проверку существования пользователя.
 */
router.get('/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  // Заглушка: возвращаем пользователя с переданным ID
  const mockUser: User = {
    id,
    firebaseUid: `firebase-uid-${id}`,
    email: `user${id}@example.com`,
    name: `User ${id}`,
    avatarUrl: undefined,
    cityId: undefined,
    isMercenary: false,
    status: UserStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(200).json(userToViewDto(mockUser));
});

/**
 * POST /api/users
 * 
 * Создает нового пользователя.
 * 
 * Техническая валидация: тело запроса проверяется через CreateUserSchema.
 * TODO: Реализовать проверку уникальности firebaseUid.
 */
router.post('/', validateBody(CreateUserSchema), (req: Request<{}, User, CreateUserDto>, res: Response) => {
  const dto = req.body;

  // Заглушка: возвращаем созданного пользователя
  const mockUser: User = {
    id: 'new-user-id',
    firebaseUid: dto.firebaseUid,
    email: dto.email,
    name: dto.name,
    avatarUrl: dto.avatarUrl,
    cityId: dto.cityId,
    isMercenary: dto.isMercenary ?? false,
    status: dto.status || UserStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(201).json(userToViewDto(mockUser));
});

export default router;
