/**
 * API роутер для модуля событий
 * 
 * Содержит эндпоинты для работы с событиями:
 * - GET /api/events - список событий
 * - GET /api/events/:id - событие по ID
 * - POST /api/events - создание события
 * - POST /api/events/:id/join - запись на событие
 * - POST /api/events/:id/check-in - check-in на событие
 * - GET /api/events/:id/participants - список участников события
 */

import { Router, Request, Response } from 'express';
import {
  EventType,
  EventStatus,
  EventDetailsDto,
  EventListItemDto,
  EventParticipantViewDto,
  CreateEventDto,
  CreateEventSchema,
} from '../modules/events';
import { validateBody } from './validateBody';
import { getEventsRepository, getUsersRepository } from '../db/repositories';
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
 * GET /api/events/:id/participants
 *
 * Возвращает список участников события.
 */
router.get('/:id/participants', async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const repo = getEventsRepository();
    const event = await repo.findById(id);
    if (!event) {
      res.status(404).json({ error: 'Event not found' });
      return;
    }

    const participants = await repo.getParticipants(id);
    if (participants.length === 0) {
      res.status(200).json([]);
      return;
    }

    const usersRepo = getUsersRepository();
    const users = await usersRepo.findByIds(participants.map(participant => participant.userId));
    const usersById = new Map(users.map(user => [user.id, user]));

    const participantDtos: EventParticipantViewDto[] = participants.map(participant => {
      const user = usersById.get(participant.userId);
      return {
        id: participant.id,
        userId: participant.userId,
        name: user?.name ?? null,
        avatarUrl: user?.avatarUrl,
        status: participant.status,
        checkedInAt: participant.checkedInAt ? participant.checkedInAt.toISOString() : undefined,
      };
    });

    res.status(200).json(participantDtos);
  } catch (error) {
    logger.error('Error fetching event participants', { eventId: id, error });
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
 * userId берётся из auth (Firebase UID → users.id).
 * Ошибки возвращаются в формате ADR-0002 { code, message, details? }.
 */
router.post('/:id/join', async (req: Request, res: Response) => {
  const { id } = req.params;
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
    const userId = user.id;

    const repo = getEventsRepository();
    const result = await repo.joinEvent(id, userId);

    if (result.error) {
      const code = result.error.includes('full')
        ? 'event_full'
        : result.error.includes('Already registered')
          ? 'already_registered'
          : result.error.includes('not found')
            ? 'event_not_found'
            : result.error.includes('status')
              ? 'event_not_open'
              : 'join_failed';
      res.status(400).json({
        code,
        message: result.error,
        details: { eventId: id },
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
    logger.error('Error joining event', { eventId: id, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

/**
 * POST /api/events/:id/check-in
 *
 * Check-in на событие через GPS.
 * userId берётся из auth (Firebase UID → users.id).
 * Ошибки в формате ADR-0002 { code, message, details? }.
 * Body: { longitude: number, latitude: number }
 */
router.post('/:id/check-in', async (req: Request, res: Response) => {
  const { id } = req.params;
  const { longitude, latitude } = req.body as { longitude?: number; latitude?: number };

  if (typeof longitude !== 'number' || typeof latitude !== 'number') {
    res.status(400).json({
      code: 'validation_error',
      message: 'Request body validation failed',
      details: {
        fields: [
          {
            field: longitude === undefined ? 'longitude' : 'latitude',
            message: 'Missing or invalid coordinates. Required: { longitude: number, latitude: number }',
            code: 'invalid_type',
          },
        ],
      },
    });
    return;
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
    const userId = user.id;

    const repo = getEventsRepository();
    const result = await repo.checkIn(id, userId, { longitude, latitude });

    if (result.error) {
      const code = result.error.includes('Not registered')
        ? 'not_registered'
        : result.error.includes('Already checked in')
          ? 'already_checked_in'
          : result.error.includes('cancelled')
            ? 'registration_cancelled'
            : result.error.includes('not found')
              ? 'event_not_found'
              : result.error.includes('not yet available')
                ? 'check_in_too_early'
                : result.error.includes('closed')
                  ? 'check_in_too_late'
                  : result.error.includes('Too far')
                    ? 'check_in_too_far'
                    : 'check_in_failed';
      res.status(400).json({
        code,
        message: result.error,
        details: { eventId: id },
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
    logger.error('Error checking in to event', { eventId: id, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
      details: undefined,
    });
  }
});

export default router;
