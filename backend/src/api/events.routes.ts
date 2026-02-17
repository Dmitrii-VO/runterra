/**
 * API роутер для модуля событий
 * 
 * Содержит эндпоинты для работы с событиями:
 * - GET /api/events - список событий
 * - GET /api/events/:id - событие по ID
 * - POST /api/events - создание события
 * - POST /api/events/:id/join - запись на событие
 * - POST /api/events/:id/leave - отмена участия
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
  UpdateEventSchema,
} from '../modules/events';
import { validateBody } from './validateBody';
import { getEventsRepository, getUsersRepository, getWorkoutsRepository } from '../db/repositories';
import { logger } from '../shared/logger';
import { isPointWithinCityBounds } from '../modules/cities/city.utils';
import { getOrganizerDisplayName, getOrganizerDisplayNamesBatch } from './helpers/organizer-display';
import { isTrainerOrLeaderInClub, isLeaderInClub } from './helpers/trainer-role';

const router = Router();

interface EventIntegrationFields {
  workoutId?: string;
  trainerId?: string;
  workoutName?: string;
  workoutDescription?: string;
  workoutType?: string;
  workoutDifficulty?: string;
  trainerName?: string;
}

function resolveTrainerDisplayName(user: {
  name: string;
  firstName?: string;
  lastName?: string;
}): string {
  const first = user.firstName?.trim();
  const last = user.lastName?.trim();
  const fullName = [first, last].filter((v): v is string => Boolean(v)).join(' ').trim();
  if (fullName) return fullName;
  return user.name;
}

async function resolveEventIntegrationFields(
  events: Array<{ id: string; workoutId?: string; trainerId?: string }>,
): Promise<Map<string, EventIntegrationFields>> {
  const result = new Map<string, EventIntegrationFields>();
  if (events.length === 0) return result;

  const workoutIds = Array.from(
    new Set(events.map((event) => event.workoutId).filter((id): id is string => Boolean(id))),
  );
  const trainerIds = Array.from(
    new Set(events.map((event) => event.trainerId).filter((id): id is string => Boolean(id))),
  );

  const workoutsById = new Map<string, Awaited<ReturnType<ReturnType<typeof getWorkoutsRepository>['findById']>>>();
  if (workoutIds.length > 0) {
    const workoutsRepo = getWorkoutsRepository();
    const workouts = await Promise.all(workoutIds.map((id) => workoutsRepo.findById(id)));
    workouts.forEach((workout) => {
      if (workout) workoutsById.set(workout.id, workout);
    });
  }

  const trainersById = new Map<string, Awaited<ReturnType<ReturnType<typeof getUsersRepository>['findByIds']>>[number]>();
  if (trainerIds.length > 0) {
    const trainers = await getUsersRepository().findByIds(trainerIds);
    trainers.forEach((trainer) => {
      trainersById.set(trainer.id, trainer);
    });
  }

  events.forEach((event) => {
    const fields: EventIntegrationFields = {};

    if (event.workoutId) {
      fields.workoutId = event.workoutId;
      const workout = workoutsById.get(event.workoutId);
      if (workout) {
        fields.workoutName = workout.name;
        fields.workoutDescription = workout.description;
        fields.workoutType = workout.type;
        fields.workoutDifficulty = workout.difficulty;
      }
    }

    if (event.trainerId) {
      fields.trainerId = event.trainerId;
      const trainer = trainersById.get(event.trainerId);
      if (trainer) {
        fields.trainerName = resolveTrainerDisplayName(trainer);
      }
    }

    result.set(event.id, fields);
  });

  return result;
}

/**
 * GET /api/events
 * 
 * Возвращает список событий с фильтрацией.
 * 
 * Query параметры:
 * - cityId: string (обязателен) — идентификатор города
 * - dateFilter?: 'today' | 'tomorrow' | 'next7days'
 * - onlyOpen?: 'true' | '1' — only events with status 'open' (exclude 'full')
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
  const { cityId, dateFilter, clubId, difficultyLevel, eventType, participantOnly, onlyOpen, limit, offset } = query;

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
    // participantOnly requires auth to resolve userId
    let participantUserId: string | undefined;
    if (participantOnly === 'true' || participantOnly === '1') {
      const uid = req.authUser?.uid;
      if (!uid) {
        return res.status(401).json({
          code: 'unauthorized',
          message: 'Authorization required for participantOnly filter',
          details: { reason: 'missing_header' },
        });
      }
      const usersRepo = getUsersRepository();
      const user = await usersRepo.findByFirebaseUid(uid);
      if (!user) {
        return res.status(400).json({
          code: 'validation_error',
          message: 'User not found for this token',
          details: { fields: [{ field: 'userId', message: 'User not found', code: 'invalid_user' }] },
        });
      }
      participantUserId = user.id;
    }

    // Resolve current user for visibility filter (optional for public feed)
    let currentUserId: string | undefined;
    if (req.authUser?.uid) {
       const usersRepo = getUsersRepository();
       const user = await usersRepo.findByFirebaseUid(req.authUser.uid);
       if (user) currentUserId = user.id;
    }

    const repo = getEventsRepository();
    const events = await repo.findAll({
      cityId,
      dateFilter: dateFilter as 'today' | 'tomorrow' | 'next7days' | undefined,
      clubId,
      difficultyLevel,
      eventType: eventType as EventType | undefined,
      participantOnly: participantOnly === 'true' || participantOnly === '1',
      participantUserId,
      currentUserId,
      onlyOpen: onlyOpen === 'true' || onlyOpen === '1',
      limit: limit ? parseInt(limit, 10) : 50,
      offset: offset ? parseInt(offset, 10) : 0,
    });
    
    // Resolve organizer display names in batch (two DB queries total)
    const organizerNames = await getOrganizerDisplayNamesBatch(
      events.map((e) => ({ organizerId: e.organizerId, organizerType: e.organizerType })),
    );
    const eventIntegration = await resolveEventIntegrationFields(events);
    const eventsDto: EventListItemDto[] = events.map((event) => ({
      id: event.id,
      name: event.name,
      type: event.type,
      status: event.status,
      startDateTime: event.startDateTime,
      startLocation: event.startLocation,
      locationName: event.locationName,
      organizerId: event.organizerId,
      organizerType: event.organizerType,
      organizerDisplayName: organizerNames.get(
        `${event.organizerType}:${event.organizerId}`,
      ),
      difficultyLevel: event.difficultyLevel,
      participantCount: event.participantCount,
      territoryId: event.territoryId,
      cityId: event.cityId,
      workoutId: eventIntegration.get(event.id)?.workoutId,
      trainerId: eventIntegration.get(event.id)?.trainerId,
      workoutName: eventIntegration.get(event.id)?.workoutName,
      workoutType: eventIntegration.get(event.id)?.workoutType,
      workoutDifficulty: eventIntegration.get(event.id)?.workoutDifficulty,
      trainerName: eventIntegration.get(event.id)?.trainerName,
    }));

    res.status(200).json(eventsDto);
  } catch (error) {
    logger.error('Error fetching events', { error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
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
      res.status(404).json({
        code: 'not_found',
        message: 'Event not found',
        details: { eventId: id },
      });
      return;
    }
    
    let isParticipant: boolean | undefined;
    let participantStatus: EventDetailsDto['participantStatus'];
    let isOrganizer: boolean | undefined;

    const uid = req.authUser?.uid;
    let resolvedUser: { id: string } | null = null;
    if (uid) {
      const usersRepo = getUsersRepository();
      resolvedUser = await usersRepo.findByFirebaseUid(uid);
      if (resolvedUser) {
        const participant = await repo.getParticipant(id, resolvedUser.id);
        if (participant) {
          isParticipant = participant.status === 'registered' || participant.status === 'checked_in';
          participantStatus = participant.status;
        }
        // Check if user is organizer (can edit this event)
        if (event.organizerType === 'trainer') {
          isOrganizer = event.organizerId === resolvedUser.id;
        } else {
          isOrganizer = await isTrainerOrLeaderInClub(resolvedUser.id, event.organizerId);
        }
      }
    }

    // Private events: only participants and organizers can view
    if (event.visibility === 'private') {
      if (!isParticipant && !isOrganizer) {
        res.status(404).json({
          code: 'not_found',
          message: 'Event not found',
          details: { eventId: id },
        });
        return;
      }
    }

    const organizerDisplayName = await getOrganizerDisplayName(event.organizerId, event.organizerType);
    const eventIntegration = await resolveEventIntegrationFields([event]);
    const integration = eventIntegration.get(event.id);

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
      organizerDisplayName,
      difficultyLevel: event.difficultyLevel,
      description: event.description,
      participantLimit: event.participantLimit,
      participantCount: event.participantCount,
      territoryId: event.territoryId,
      cityId: event.cityId,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
      workoutId: integration?.workoutId,
      trainerId: integration?.trainerId,
      workoutName: integration?.workoutName,
      workoutDescription: integration?.workoutDescription,
      workoutType: integration?.workoutType,
      workoutDifficulty: integration?.workoutDifficulty,
      trainerName: integration?.trainerName,
      isParticipant,
      participantStatus,
      isOrganizer,
    };

    res.status(200).json(eventDto);
  } catch (error) {
    logger.error('Error fetching event', { eventId: id, error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
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
      res.status(404).json({
        code: 'not_found',
        message: 'Event not found',
        details: { eventId: id },
      });
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
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
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
      visibility: dto.visibility,
    });

    const organizerDisplayName = await getOrganizerDisplayName(event.organizerId, event.organizerType);

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
      organizerDisplayName,
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
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
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
 * POST /api/events/:id/leave
 *
 * Отмена участия в событии.
 * userId берётся из auth (Firebase UID → users.id).
 * Ошибки возвращаются в формате ADR-0002 { code, message, details? }.
 */
router.post('/:id/leave', async (req: Request, res: Response) => {
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

    const repo = getEventsRepository();
    const result = await repo.leaveEvent(id, user.id);

    if (result.error) {
      const code = result.error.includes('Not registered')
        ? 'not_registered'
        : result.error.includes('Already cancelled')
          ? 'already_cancelled'
          : 'leave_failed';
      res.status(400).json({
        code,
        message: result.error,
        details: { eventId: id },
      });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Participation cancelled',
      eventId: id,
      participant: result.participant,
    });
  } catch (error) {
    logger.error('Error leaving event', { eventId: id, error });
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

  const isFiniteNumber = (v: unknown): v is number =>
    typeof v === 'number' && Number.isFinite(v);

  if (!isFiniteNumber(longitude) || !isFiniteNumber(latitude)) {
    res.status(400).json({
      code: 'validation_error',
      message: 'Request body validation failed',
      details: {
        fields: [
          {
            field: !isFiniteNumber(longitude) ? 'longitude' : 'latitude',
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

/**
 * PATCH /api/events/:id
 *
 * Update event fields. Supports all editable fields (name, type, startDateTime,
 * startLocation, locationName, description, participantLimit, difficultyLevel,
 * workoutId, trainerId).
 *
 * Auth:
 *  - club events: trainer or leader in the organizing club
 *  - trainer events: the organizer (trainer) themselves
 *
 * trainerId assignment is restricted to leaders only.
 * Cannot edit completed/cancelled events.
 */
router.patch('/:id', validateBody(UpdateEventSchema), async (req: Request, res: Response) => {
  const { id } = req.params;
  const uid = req.authUser?.uid;
  if (!uid) {
    return res.status(401).json({ code: 'unauthorized', message: 'Authorization required' });
  }

  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'User not found',
        details: { fields: [{ field: 'userId', message: 'User not found for this token', code: 'invalid_user' }] },
      });
    }
    const userId = user.id;

    const eventsRepo = getEventsRepository();
    const event = await eventsRepo.findById(id);
    if (!event) {
      return res.status(404).json({ code: 'not_found', message: 'Event not found' });
    }

    // Cannot edit completed/cancelled events
    if (event.status === EventStatus.COMPLETED || event.status === EventStatus.CANCELLED) {
      return res.status(400).json({ code: 'event_not_editable', message: 'Cannot edit completed or cancelled events' });
    }

    // Authorization check based on organizer type
    if (event.organizerType === 'club') {
      const hasRole = await isTrainerOrLeaderInClub(userId, event.organizerId);
      if (!hasRole) {
        return res.status(403).json({ code: 'forbidden', message: 'Trainer or leader role required in organizing club' });
      }
    } else {
      // trainer event — only the organizer can edit
      if (event.organizerId !== userId) {
        return res.status(403).json({ code: 'forbidden', message: 'Only the event organizer can edit this event' });
      }
    }

    const { workoutId, trainerId, startLocation, ...rest } = req.body;

    // Keep the existing product constraint: trainer/workout integration fields
    // are only supported for club events.
    if ((workoutId !== undefined || trainerId !== undefined) && event.organizerType !== 'club') {
      return res.status(400).json({
        code: 'validation_error',
        message: 'Trainer fields can only be set on club events',
      });
    }

    // trainerId assignment restricted to leaders (club events only)
    if (trainerId !== undefined) {
      if (event.organizerType !== 'club') {
        return res.status(400).json({ code: 'validation_error', message: 'Trainer fields can only be set on club events' });
      }
      const userIsLeader = await isLeaderInClub(userId, event.organizerId);
      if (!userIsLeader) {
        return res.status(403).json({ code: 'forbidden', message: 'Only club leader can assign a trainer' });
      }
      if (trainerId !== null) {
        const targetIsTrainer = await isTrainerOrLeaderInClub(trainerId, event.organizerId);
        if (!targetIsTrainer) {
          return res.status(400).json({
            code: 'validation_error',
            message: 'Target user is not a trainer or leader in this club',
          });
        }
      }
    }

    // Verify workout exists and belongs to club or author
    if (workoutId !== undefined && workoutId !== null) {
      const workoutsRepo = getWorkoutsRepository();
      const workout = await workoutsRepo.findById(workoutId);
      if (!workout) {
        return res.status(400).json({ code: 'validation_error', message: 'Workout not found' });
      }
      if (event.organizerType === 'club') {
        if (workout.clubId !== event.organizerId && workout.authorId !== userId) {
          return res.status(400).json({ code: 'validation_error', message: 'Workout does not belong to this club or author' });
        }
      }
    }

    // Validate startLocation within city bounds if being updated
    if (startLocation) {
      if (!isPointWithinCityBounds(startLocation, event.cityId)) {
        return res.status(400).json({
          code: 'validation_error',
          message: 'Request body validation failed',
          details: {
            fields: [{
              field: 'startLocation',
              message: 'startLocation coordinates are outside city bounds',
              code: 'coordinates_out_of_city',
            }],
          },
        });
      }
    }

    const updated = await eventsRepo.update(id, {
      ...rest,
      ...(startLocation ? { startLocation } : {}),
      ...(workoutId !== undefined ? { workoutId } : {}),
      ...(trainerId !== undefined ? { trainerId } : {}),
    });
    if (!updated) {
      return res.status(500).json({ code: 'internal_error', message: 'Failed to update event' });
    }

    const organizerDisplayName = await getOrganizerDisplayName(updated.organizerId, updated.organizerType);
    const eventIntegration = await resolveEventIntegrationFields([updated]);
    const integration = eventIntegration.get(updated.id);

    const eventDto: EventDetailsDto = {
      id: updated.id,
      name: updated.name,
      type: updated.type,
      status: updated.status,
      startDateTime: updated.startDateTime,
      startLocation: updated.startLocation,
      locationName: updated.locationName,
      organizerId: updated.organizerId,
      organizerType: updated.organizerType,
      organizerDisplayName,
      difficultyLevel: updated.difficultyLevel,
      description: updated.description,
      participantLimit: updated.participantLimit,
      participantCount: updated.participantCount,
      territoryId: updated.territoryId,
      cityId: updated.cityId,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
      workoutId: integration?.workoutId,
      trainerId: integration?.trainerId,
      workoutName: integration?.workoutName,
      workoutDescription: integration?.workoutDescription,
      workoutType: integration?.workoutType,
      workoutDifficulty: integration?.workoutDifficulty,
      trainerName: integration?.trainerName,
      isOrganizer: true,
    };

    res.status(200).json(eventDto);
  } catch (error) {
    logger.error('Error patching event', { eventId: id, error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

export default router;
