/**
 * API routes for trainer profile
 *
 * GET    /api/trainers                — public trainer discovery (accepts_private_clients=true)
 * GET    /api/trainer/profile         — own profile
 * GET    /api/trainer/profile/:userId — public view
 * POST   /api/trainer/profile         — create profile (bio + ≥1 specialization required)
 * PATCH  /api/trainer/profile         — update own profile
 */

import { Router, Request, Response } from 'express';
import { validateBody } from './validateBody';
import { getUsersRepository, getTrainerProfilesRepository } from '../db/repositories';
import { CreateTrainerProfileSchema, UpdateTrainerProfileSchema } from '../modules/trainer';
import { logger } from '../shared/logger';
import { isValidUuid } from '../shared/validation';

const router = Router();

/** Resolve internal userId from Firebase auth */
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
      details: { fields: [{ field: 'userId', message: 'User not found for this token', code: 'invalid_user' }] },
    });
    return null;
  }
  return user.id;
}

// GET /api/trainers — public trainer discovery
router.get('/', async (req: Request, res: Response) => {
  try {
    const { cityId, specialization } = req.query as Record<string, string | undefined>;
    const repo = getTrainerProfilesRepository();
    const trainers = await repo.findPublicTrainers({ cityId, specialization });
    res.status(200).json(trainers);
  } catch (error) {
    logger.error('Error fetching public trainers', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

// GET /api/trainer/profile — own profile
router.get('/profile', async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const repo = getTrainerProfilesRepository();
    const profile = await repo.findByUserId(userId);
    if (!profile) {
      return res.status(404).json({ code: 'not_found', message: 'Trainer profile not found' });
    }
    res.status(200).json(profile);
  } catch (error) {
    logger.error('Error fetching own trainer profile', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

// GET /api/trainer/profile/:userId — public view
router.get('/profile/:userId', async (req: Request, res: Response) => {
  try {
    const { userId } = req.params;
    if (!isValidUuid(userId)) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'userId must be a valid UUID',
        details: { fields: [{ field: 'userId', message: 'Invalid UUID', code: 'invalid_uuid' }] },
      });
    }
    const repo = getTrainerProfilesRepository();
    const profile = await repo.findByUserId(userId);
    if (!profile) {
      return res.status(404).json({ code: 'not_found', message: 'Trainer profile not found' });
    }
    res.status(200).json(profile);
  } catch (error) {
    logger.error('Error fetching trainer profile', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

// POST /api/trainer/profile — create (any authenticated user with bio + specialization)
router.post('/profile', validateBody(CreateTrainerProfileSchema), async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const repo = getTrainerProfilesRepository();
    const existing = await repo.findByUserId(userId);
    if (existing) {
      return res.status(409).json({ code: 'conflict', message: 'Trainer profile already exists' });
    }

    const profile = await repo.create({
      userId,
      bio: req.body.bio,
      specialization: req.body.specialization,
      experienceYears: req.body.experienceYears,
      certificates: req.body.certificates,
      acceptsPrivateClients: req.body.acceptsPrivateClients ?? false,
    });
    res.status(201).json(profile);
  } catch (error) {
    logger.error('Error creating trainer profile', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

// PATCH /api/trainer/profile — update own profile
router.patch('/profile', validateBody(UpdateTrainerProfileSchema), async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const repo = getTrainerProfilesRepository();
    const profile = await repo.update(userId, req.body);
    if (!profile) {
      return res.status(404).json({ code: 'not_found', message: 'Trainer profile not found' });
    }
    res.status(200).json(profile);
  } catch (error) {
    logger.error('Error updating trainer profile', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

export default router;
