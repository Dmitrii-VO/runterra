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
import { isPointWithinCityBounds } from '../modules/cities/city.utils';

const router = Router();

/**
 * GET /api/events
 * 
 * Возвращает список событий с фильтрацией.
 * 
 * Query параметры:
 * - cityId: string (обязателен) — идентификатор города
 * - dateFilter?: 'today' | 'tomorrow' | 'next7days'
 * - clubId?: string
 * - difficultyLevel?: 'beginner' | 'intermediate' | 'advanced'
 * - eventType?: 'group_run' | 'training' | 'competition' | 'club_event'
 * - limit?: number (default 50)
 * - offset?: number (default 0)
 * 
 * По умолчанию возвращает только события со статусом OPEN или FULL.
 */
router.get('/', async (req: Request, res: Response) => {
  const query = req.query as Record<string, string | undefined>;
  const { cityId, dateFilter, clubId, difficultyLevel, eventType, limit, offset } = query;
  
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
    const repo = getEventsRepository();
    const events = await repo.findAll({
      cityId,
      dateFilter: dateFilter as 'today' | 'tomorrow' | 'next7days' | undefined,
      clubId,
      difficultyLevel,
      eventType: eventType as EventType | undefined,
      limit: limit ? parseInt(limit, 10) : 50,
      offset: offset ? parseInt(offset, 10) : 0,
    });
    
    // Map to DTO format
    const eventsDto: EventListItemDto[] = events.map(event => ({
      id: event.id,
      name: event.name,
      type: event.type,
      status: event.status,
      startDateTime: event.startDateTime,
      startLocation: event.startLocation,
      locationName: event.locationName,
      organizerId: event.organizerId,
      organizerType: event.organizerType,
      difficultyLevel: event.difficultyLevel,
      participantCount: event.participantCount,
      territoryId: event.territoryId,
      cityId: event.cityId,
    }));
    
    res.status(200).json(eventsDto);
  } catch (error) {
    logger.error('Error fetching events', { error });
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * GET /api/events/:id
 * 
 * Возвращает событие по ID.
 */
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const repo = getEventsRepository();
    const event = await repo.findById(id);
    
    if (!event) {
      res.status(404).json({ error: 'Event not found' });
      return;
    }
    
    const eventDto: EventDetailsDto = {
      id: event.id,
      name: event.name,
      type: event.type,
      status: event.status,
      startDateTime: event.startDateTime,
      startLocation: event.startLocation,
      locationName: event.locationName,
      organizerId: event.organizerId,
      organizerType: event.organizerType,
      difficultyLevel: event.difficultyLevel,
      description: event.description,
      participantLimit: event.participantLimit,
      participantCount: event.participantCount,
      territoryId: event.territoryId,
      cityId: event.cityId,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    };

    res.status(200).json(eventDto);
  } catch (error) {
    logger.error('Error fetching event', { eventId: id, error });
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /api/events
 * 
 * Создает новое событие.
 */
router.post('/', validateBody(CreateEventSchema), async (req: Request<{}, EventDetailsDto, CreateEventDto>, res: Response) => {
  const dto = req.body;

  if (!isPointWithinCityBounds(dto.startLocation, dto.cityId)) {
    return res.status(400).json({
      code: 'validation_error',
      message: 'Request body validation failed',
      details: {
        fields: [
          {
            field: 'startLocation',
            message: 'startLocation coordinates are outside city bounds',
            code: 'coordinates_out_of_city',
          },
        ],
      },
    });
  }

  try {
    const repo = getEventsRepository();
    const event = await repo.create({
      name: dto.name,
      type: dto.type,
      startDateTime: new Date(dto.startDateTime),
      startLocation: dto.startLocation,
      locationName: dto.locationName,
      organizerId: dto.organizerId,
      organizerType: dto.organizerType,
      difficultyLevel: dto.difficultyLevel,
      description: dto.description,
      participantLimit: dto.participantLimit,
      territoryId: dto.territoryId,
      cityId: dto.cityId,
    });
    
    const eventDto: EventDetailsDto = {
      id: event.id,
      name: event.name,
      type: event.type,
      status: event.status,
      startDateTime: event.startDateTime,
      startLocation: event.startLocation,
      locationName: event.locationName,
      organizerId: event.organizerId,
      organizerType: event.organizerType,
      difficultyLevel: event.difficultyLevel,
      description: event.description,
      participantLimit: event.participantLimit,
      participantCount: event.participantCount,
      territoryId: event.territoryId,
      cityId: event.cityId,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    };

    res.status(201).json(eventDto);
  } catch (error) {
    logger.error('Error creating event', { error });
    res.status(500).json({ error: 'Internal server error' });
  }
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
