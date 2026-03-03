/**
 * API routes for workouts
 *
 * GET    /api/workouts          — list (personal or by clubId)
 * GET    /api/workouts/:id      — single workout
 * POST   /api/workouts          — create
 * PATCH  /api/workouts/:id      — update (author only)
 * DELETE /api/workouts/:id      — delete (author only, no upcoming events)
 */

import { Router, Request, Response } from 'express';
import { validateBody } from './validateBody';
import {
  getUsersRepository,
  getWorkoutsRepository,
  getClubMembersRepository,
} from '../db/repositories';
import { CreateWorkoutSchema, UpdateWorkoutSchema } from '../modules/workout';
import { isTrainerInAnyClub, isTrainerOrLeaderInClub } from './helpers/trainer-role';
import { logger } from '../shared/logger';

const router = Router();

async function resolveUserId(req: Request, res: Response): Promise<string | null> {
  const uid = req.authUser?.uid;
  if (!uid) {
    res.status(401).json({ code: 'unauthorized', message: 'Authorization required' });
    return null;
  }
  const user = await getUsersRepository().findByFirebaseUid(uid);
  if (!user) {
    res.status(400).json({
      code: 'validation_error',
      message: 'User not found',
      details: {
        fields: [
          { field: 'userId', message: 'User not found for this token', code: 'invalid_user' },
        ],
      },
    });
    return null;
  }
  return user.id;
}

// GET /api/workouts?clubId=
router.get('/', async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const { clubId } = req.query as { clubId?: string };
    const repo = getWorkoutsRepository();

    if (clubId) {
      // Verify user is a member of the club
      const membership = await getClubMembersRepository().findByClubAndUser(clubId, userId);
      if (!membership || membership.status !== 'active') {
        return res.status(403).json({ code: 'forbidden', message: 'Not a member of this club' });
      }
      const workouts = await repo.findByClub(clubId);
      return res.status(200).json(workouts);
    }

    // Personal workouts
    const hasRole = await isTrainerInAnyClub(userId);
    if (!hasRole) {
      return res
        .status(403)
        .json({ code: 'forbidden', message: 'Trainer or leader role required' });
    }

    const workouts = await repo.findByAuthor(userId);
    res.status(200).json(workouts);
  } catch (error) {
    logger.error('Error fetching workouts', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

// GET /api/workouts/:id
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const repo = getWorkoutsRepository();
    const workout = await repo.findById(req.params.id);
    if (!workout) {
      return res.status(404).json({ code: 'not_found', message: 'Workout not found' });
    }

    // Club workout is visible to any active club member.
    if (workout.clubId) {
      const membership = await getClubMembersRepository().findByClubAndUser(workout.clubId, userId);
      if (!membership || membership.status !== 'active') {
        return res.status(403).json({ code: 'forbidden', message: 'Access denied' });
      }
      return res.status(200).json(workout);
    }

    // Personal workout: only author with trainer/leader role.
    if (workout.authorId !== userId) {
      return res.status(403).json({ code: 'forbidden', message: 'Access denied' });
    }
    const hasRole = await isTrainerInAnyClub(userId);
    if (!hasRole) {
      return res
        .status(403)
        .json({ code: 'forbidden', message: 'Trainer or leader role required' });
    }

    res.status(200).json(workout);
  } catch (error) {
    logger.error('Error fetching workout', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

// POST /api/workouts
router.post('/', validateBody(CreateWorkoutSchema), async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const hasRole = await isTrainerInAnyClub(userId);
    if (!hasRole) {
      return res
        .status(403)
        .json({ code: 'forbidden', message: 'Trainer or leader role required' });
    }

    const {
      clubId,
      name,
      description,
      type,
      difficulty,
      surface,
      blocks,
      targetMetric,
      targetValue,
      targetZone,
      distanceM,
      heartRateTarget,
      paceTarget,
      repCount,
      repDistanceM,
      exerciseName,
      exerciseInstructions,
    } = req.body;

    // If clubId provided, verify user is trainer/leader in that specific club
    if (clubId) {
      const isClubTrainer = await isTrainerOrLeaderInClub(userId, clubId);
      if (!isClubTrainer) {
        return res
          .status(403)
          .json({ code: 'forbidden', message: 'Trainer or leader role required in this club' });
      }
    }

    const repo = getWorkoutsRepository();
    const workout = await repo.create({
      authorId: userId,
      clubId: clubId || null,
      name,
      description,
      type,
      difficulty,
      surface,
      blocks,
      targetMetric,
      targetValue,
      targetZone,
      distanceM,
      heartRateTarget,
      paceTarget,
      repCount,
      repDistanceM,
      exerciseName,
      exerciseInstructions,
    });
    res.status(201).json(workout);
  } catch (error) {
    logger.error('Error creating workout', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

// PATCH /api/workouts/:id
router.patch('/:id', validateBody(UpdateWorkoutSchema), async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const repo = getWorkoutsRepository();
    const workout = await repo.findById(req.params.id);
    if (!workout) {
      return res.status(404).json({ code: 'not_found', message: 'Workout not found' });
    }
    if (workout.authorId !== userId) {
      return res
        .status(403)
        .json({ code: 'forbidden', message: 'Only the author can update this workout' });
    }
    const hasRole = await isTrainerInAnyClub(userId);
    if (!hasRole) {
      return res
        .status(403)
        .json({ code: 'forbidden', message: 'Trainer or leader role required' });
    }

    const updated = await repo.update(req.params.id, req.body);
    res.status(200).json(updated);
  } catch (error) {
    logger.error('Error updating workout', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

// DELETE /api/workouts/:id
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const repo = getWorkoutsRepository();
    const workout = await repo.findById(req.params.id);
    if (!workout) {
      return res.status(404).json({ code: 'not_found', message: 'Workout not found' });
    }
    if (workout.authorId !== userId) {
      return res
        .status(403)
        .json({ code: 'forbidden', message: 'Only the author can delete this workout' });
    }
    const hasRole = await isTrainerInAnyClub(userId);
    if (!hasRole) {
      return res
        .status(403)
        .json({ code: 'forbidden', message: 'Trainer or leader role required' });
    }

    const hasEvents = await repo.hasUpcomingEvents(req.params.id);
    if (hasEvents) {
      return res
        .status(409)
        .json({ code: 'workout_in_use', message: 'Workout is linked to upcoming events' });
    }

    await repo.delete(req.params.id);
    res.status(200).json({ success: true, message: 'Workout deleted' });
  } catch (error) {
    // FK violation: workout is still referenced by event rows (incl. past/completed events)
    if ((error as { code?: string }).code === '23503') {
      return res
        .status(409)
        .json({ code: 'workout_in_use', message: 'Workout is linked to events' });
    }
    logger.error('Error deleting workout', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

export default router;
