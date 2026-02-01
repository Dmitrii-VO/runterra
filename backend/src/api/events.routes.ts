/**
 * API роутер для модуля событий
 * 
 * Содержит эндпоинты для работы с событиями:
 * - GET /api/events - список событий
 * - GET /api/events/:id - событие по ID
 * - POST /api/events - создание события
 * - POST /api/events/:id/join - запись на событие
 * - POST /api/events/:id/check-in - check-in на событие
 */

import { Router, Request, Response } from 'express';
import { EventType, EventStatus, EventDetailsDto, EventListItemDto, CreateEventDto, CreateEventSchema } from '../modules/events';
import { validateBody } from './validateBody';
import { getEventsRepository } from '../db/repositories';
import { logger } from '../shared/logger';

const router = Router();

/**
 * GET /api/events
 * 
 * Возвращает список событий.
 * 
 * ВАЖНО: Правило фильтрации статусов:
 * - Список возвращает только события со статусом OPEN или FULL
 * - События со статусом DRAFT исключаются из списка (не показываются публично)
 * - DRAFT события доступны только организатору через GET /api/events/:id (позже, с проверкой прав)
 * - CANCELLED и COMPLETED могут быть включены в список в зависимости от фильтров (TODO)
 * 
 * Query параметры для фильтров (TODO: не обрабатываются):
 * - dateFilter?: 'today' | 'tomorrow' | 'next7days'
 * - clubId?: string
 * - difficultyLevel?: string
 * - eventType?: string
 * - onlyOpen?: boolean
 * 
 * TODO: Реализовать пагинацию, фильтрацию, сортировку.
 * TODO: Реализовать исключение DRAFT из списка.
 */
router.get('/', (req: Request, res: Response) => {
  // TODO: Обработать query параметры для фильтров
  // TODO: Исключить события со статусом DRAFT из списка
  const query = req.query as Record<string, string | undefined>;
  const { dateFilter, clubId, difficultyLevel, eventType, onlyOpen } = query;
  
  // Заглушка: возвращаем массив из нескольких событий
  const mockEvents: EventListItemDto[] = [
    {
      id: '1',
      name: 'Утренняя пробежка в парке',
      type: EventType.GROUP_RUN,
      status: EventStatus.OPEN,
      startDateTime: new Date(),
      startLocation: {
        longitude: 30.3351,
        latitude: 59.9343,
      },
      locationName: 'Центральный парк',
      organizerId: 'club-1',
      organizerType: 'club',
      difficultyLevel: 'beginner',
      participantCount: 5,
      territoryId: 'territory-1',
    },
    {
      id: '2',
      name: 'Интервальная тренировка',
      type: EventType.TRAINING,
      status: EventStatus.OPEN,
      startDateTime: new Date(Date.now() + 86400000), // завтра
      startLocation: {
        longitude: 30.3451,
        latitude: 59.9443,
      },
      locationName: 'Стадион',
      organizerId: 'trainer-1',
      organizerType: 'trainer',
      difficultyLevel: 'advanced',
      participantCount: 8,
    },
  ];

  res.status(200).json(mockEvents);
});

/**
 * GET /api/events/:id
 * 
 * Возвращает событие по ID.
 * 
 * TODO: Реализовать проверку существования события.
 */
router.get('/:id', (req: Request, res: Response) => {
  const { id } = req.params;

  // Заглушка: возвращаем событие с переданным ID
  const mockEvent: EventDetailsDto = {
    id,
    name: `Событие ${id}`,
    type: EventType.GROUP_RUN,
    status: EventStatus.OPEN,
    startDateTime: new Date(),
    startLocation: {
      longitude: 30.3159,
      latitude: 59.9343,
    },
    locationName: 'Центральный парк',
    organizerId: 'club-1',
    organizerType: 'club',
    difficultyLevel: 'beginner',
    description: `Описание события ${id}`,
    participantLimit: 20,
    participantCount: 5,
    territoryId: 'territory-1',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(200).json(mockEvent);
});

/**
 * POST /api/events
 * 
 * Создает новое событие.
 * 
 * Техническая валидация: тело запроса проверяется через CreateEventSchema.
 * TODO: Реализовать проверку прав организатора.
 */
router.post('/', validateBody(CreateEventSchema), (req: Request<{}, EventDetailsDto, CreateEventDto>, res: Response) => {
  const dto = req.body;

  // Заглушка: возвращаем созданное событие
  // TODO: Получить organizerId из авторизации
  const mockEvent: EventDetailsDto = {
    id: 'new-event-id',
    name: dto.name,
    type: dto.type,
    status: EventStatus.OPEN,
    startDateTime: dto.startDateTime,
    startLocation: dto.startLocation,
    locationName: dto.locationName,
    organizerId: dto.organizerId,
    organizerType: dto.organizerType,
    difficultyLevel: dto.difficultyLevel,
    description: dto.description,
    participantLimit: dto.participantLimit,
    participantCount: 0, // TODO: вычислять
    territoryId: dto.territoryId,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  res.status(201).json(mockEvent);
});

/**
 * POST /api/events/:id/join
 * 
 * Запись на событие.
 * Проверяет: существование события, статус, лимит участников.
 */
router.post('/:id/join', async (req: Request, res: Response) => {
  const { id } = req.params;
  
  // TODO: Получить userId из авторизации (сейчас mock)
  const userId = (req as unknown as { user?: { id: string } }).user?.id || 'mock-user-id';

  try {
    const repo = getEventsRepository();
    const result = await repo.joinEvent(id, userId);
    
    if (result.error) {
      res.status(400).json({
        success: false,
        error: result.error,
        eventId: id,
      });
      return;
    }
    
    res.status(200).json({
      success: true,
      message: 'Successfully registered for event',
      eventId: id,
      participant: result.participant,
    });
  } catch (error) {
    logger.error('Error joining event', { eventId: id, userId, error });
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

/**
 * POST /api/events/:id/check-in
 * 
 * Check-in на событие через GPS.
 * Проверяет: GPS координаты (500м радиус), время (15 мин до / 30 мин после).
 * 
 * Body: { longitude: number, latitude: number }
 */
router.post('/:id/check-in', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { longitude, latitude } = req.body as { longitude?: number; latitude?: number };
  
  // Validate coordinates
  if (typeof longitude !== 'number' || typeof latitude !== 'number') {
    res.status(400).json({
      success: false,
      error: 'Missing or invalid coordinates. Required: { longitude: number, latitude: number }',
    });
    return;
  }
  
  // TODO: Получить userId из авторизации (сейчас mock)
  const userId = (req as unknown as { user?: { id: string } }).user?.id || 'mock-user-id';

  try {
    const repo = getEventsRepository();
    const result = await repo.checkIn(id, userId, { longitude, latitude });
    
    if (result.error) {
      res.status(400).json({
        success: false,
        error: result.error,
        eventId: id,
      });
      return;
    }
    
    res.status(200).json({
      success: true,
      message: 'Check-in successful',
      eventId: id,
      participant: result.participant,
    });
  } catch (error) {
    logger.error('Error checking in to event', { eventId: id, userId, error });
    res.status(500).json({
      success: false,
      error: 'Internal server error',
    });
  }
});

export default router;
