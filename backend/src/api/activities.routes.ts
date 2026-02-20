import { Router, Request, Response } from 'express';
import { ActivityType, ActivityStatus, ActivityViewDto, CreateActivityDto, CreateActivitySchema } from '../modules/activities';
import { validateBody } from './validateBody';
import { getActivitiesRepository, getUsersRepository } from '../db/repositories';
import { logger } from '../shared/logger';

const router = Router();

async function resolveUser(req: Request, res: Response) {
  const uid = req.authUser?.uid;
  if (!uid) {
    res.status(401).json({ code: 'unauthorized', message: 'Authorization required' });
    return null;
  }
  const usersRepo = getUsersRepository();
  const user = await usersRepo.findByFirebaseUid(uid);
  if (!user) {
    res.status(401).json({ code: 'unauthorized', message: 'User not found' });
    return null;
  }
  return user;
}

/**
 * GET /api/activities
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const limit = Math.min(Math.max(parseInt(req.query.limit as string) || 20, 1), 100);
    const offset = Math.max(parseInt(req.query.offset as string) || 0, 0);

    const repo = getActivitiesRepository();
    const activities = await repo.findByUserId(user.id, limit, offset);

    const dtos: ActivityViewDto[] = activities.map(a => ({
      id: a.id,
      userId: a.userId,
      type: a.type,
      status: a.status,
      name: a.name,
      description: a.description,
      scheduledItemId: a.scheduledItemId,
      createdAt: a.createdAt,
      updatedAt: a.updatedAt,
    }));

    res.status(200).json(dtos);
  } catch (error) {
    logger.error('Error fetching activities', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/activities/:id
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const { id } = req.params;
    const repo = getActivitiesRepository();
    const activity = await repo.findById(id);

    if (!activity) {
      return res.status(404).json({ code: 'not_found', message: 'Activity not found' });
    }

    if (activity.userId !== user.id) {
      return res.status(403).json({ code: 'forbidden', message: 'Access denied' });
    }

    const dto: ActivityViewDto = {
      id: activity.id,
      userId: activity.userId,
      type: activity.type,
      status: activity.status,
      name: activity.name,
      description: activity.description,
      scheduledItemId: activity.scheduledItemId,
      createdAt: activity.createdAt,
      updatedAt: activity.updatedAt,
    };

    res.status(200).json(dto);
  } catch (error) {
    logger.error('Error fetching activity', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * POST /api/activities
 */
router.post('/', validateBody(CreateActivitySchema), async (req: Request<{}, ActivityViewDto, CreateActivityDto>, res: Response) => {
  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const dto = req.body;
    const repo = getActivitiesRepository();
    
    const activity = await repo.create({
      userId: user.id,
      type: dto.type,
      status: dto.status || ActivityStatus.COMPLETED,
      name: dto.name,
      description: dto.description,
      scheduledItemId: dto.scheduledItemId,
    });

    const viewDto: ActivityViewDto = {
      id: activity.id,
      userId: activity.userId,
      type: activity.type,
      status: activity.status,
      name: activity.name,
      description: activity.description,
      scheduledItemId: activity.scheduledItemId,
      createdAt: activity.createdAt,
      updatedAt: activity.updatedAt,
    };

    res.status(201).json(viewDto);
  } catch (error) {
    logger.error('Error creating activity', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

export default router;
