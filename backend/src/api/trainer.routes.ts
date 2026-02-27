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
import {
  getUsersRepository,
  getTrainerProfilesRepository,
  getClubMembersRepository,
  getMessagesRepository,
  getTrainerGroupsRepository,
} from '../db/repositories';
import {
  CreateTrainerProfileSchema,
  UpdateTrainerProfileSchema,
  CreateTrainerGroupSchema,
} from '../modules/trainer';
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

/**
 * POST /api/trainer/clients/:userId — add a client (trainer/leader in a shared club)
 */
router.post('/clients/:userId', async (req: Request, res: Response) => {
  try {
    const trainerId = await resolveUserId(req, res);
    if (!trainerId) return;

    const { userId: clientId } = req.params;
    if (!isValidUuid(clientId)) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'userId must be a valid UUID',
        details: { fields: [{ field: 'userId', message: 'Invalid UUID', code: 'invalid_uuid' }] },
      });
    }

    if (trainerId === clientId) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'Cannot add yourself as a client',
      });
    }

    // Verify caller has trainer or leader role in at least one club where target is also a member
    const clubMembersRepo = getClubMembersRepository();
    const trainerMemberships = await clubMembersRepo.findActiveClubsByUser(trainerId);
    const trainerClubs = trainerMemberships.filter(m => m.role === 'trainer' || m.role === 'leader');

    let hasSharedClub = false;
    for (const tc of trainerClubs) {
      const clientMembership = await clubMembersRepo.findByClubAndUser(tc.clubId, clientId);
      if (clientMembership && clientMembership.status === 'active') {
        hasSharedClub = true;
        break;
      }
    }

    if (!hasSharedClub) {
      return res.status(403).json({
        code: 'forbidden',
        message: 'You must be a trainer or leader in a club where the target is a member',
      });
    }

    const messagesRepo = getMessagesRepository();
    await messagesRepo.addTrainerClient(trainerId, clientId);
    res.status(201).json({ ok: true });
  } catch (error) {
    logger.error('Error adding trainer client', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * DELETE /api/trainer/clients/:userId — remove a client
 */
router.delete('/clients/:userId', async (req: Request, res: Response) => {
  try {
    const trainerId = await resolveUserId(req, res);
    if (!trainerId) return;

    const { userId: clientId } = req.params;
    if (!isValidUuid(clientId)) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'userId must be a valid UUID',
        details: { fields: [{ field: 'userId', message: 'Invalid UUID', code: 'invalid_uuid' }] },
      });
    }

    const messagesRepo = getMessagesRepository();
    const removed = await messagesRepo.removeTrainerClient(trainerId, clientId);
    if (!removed) {
      return res.status(404).json({ code: 'not_found', message: 'Client relationship not found' });
    }
    res.status(200).json({ ok: true });
  } catch (error) {
    logger.error('Error removing trainer client', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/trainer/groups — list groups in a club (as trainer or member)
 */
router.get('/groups', async (req: Request, res: Response) => {
  try {
    const userId = await resolveUserId(req, res);
    if (!userId) return;

    const { clubId } = req.query;
    if (!clubId || typeof clubId !== 'string' || !isValidUuid(clubId)) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'clubId query parameter is required and must be a valid UUID',
      });
    }

    const repo = getTrainerGroupsRepository();
    // Fetch groups where user is trainer
    const leadingGroups = await repo.findByTrainerAndClub(userId, clubId);
    // Fetch groups where user is member
    const memberGroups = await repo.findByMemberAndClub(userId, clubId);

    // Merge and unique by ID
    const allGroups = [...leadingGroups];
    for (const mg of memberGroups) {
      if (!allGroups.some(g => g.id === mg.id)) {
        allGroups.push(mg);
      }
    }

    // Sort by createdAt DESC
    allGroups.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    res.status(200).json(allGroups);
  } catch (error) {
    logger.error('Error fetching trainer groups', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * POST /api/trainer/groups — create a group
 */
router.post('/groups', validateBody(CreateTrainerGroupSchema), async (req: Request, res: Response) => {
  try {
    const trainerId = await resolveUserId(req, res);
    if (!trainerId) return;

    const { clubId, name, memberIds } = req.body;

    // Verify trainer is indeed a trainer/leader in this club
    const clubMembersRepo = getClubMembersRepository();
    const membership = await clubMembersRepo.findByClubAndUser(clubId, trainerId);
    if (!membership || membership.status !== 'active' || (membership.role !== 'trainer' && membership.role !== 'leader')) {
      return res.status(403).json({
        code: 'forbidden',
        message: 'You must be a trainer or leader in this club to create groups',
      });
    }

    // Verify all memberIds are active members of the club
    const allMembersActive = await clubMembersRepo.verifyActiveMembers(clubId, memberIds);
    if (!allMembersActive) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'One or more users are not active members of the club',
      });
    }

    const repo = getTrainerGroupsRepository();
    const group = await repo.create({
      clubId,
      trainerId,
      name,
      memberIds,
    });
    res.status(201).json(group);
  } catch (error) {
    logger.error('Error creating trainer group', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

export default router;
