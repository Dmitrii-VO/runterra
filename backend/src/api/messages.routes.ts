/**
 * API router for messages (city and club chat).
 * GET/POST /api/messages/global, GET/POST /api/messages/clubs/:clubId
 */

import { Router, Request, Response } from 'express';
import { CreateMessageSchema } from '../modules/messages';
import type { MessageViewDto } from '../modules/messages/message.dto';
import { validateBody } from './validateBody';
import { getMessagesRepository, getUsersRepository } from '../db/repositories';
import { broadcast } from '../ws/chatWs';
import { logger } from '../shared/logger';

const router = Router();

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 50;

function parsePagination(query: { limit?: string; offset?: string }): { limit: number; offset: number } {
  const limit = query.limit ? parseInt(query.limit, 10) : DEFAULT_LIMIT;
  const offset = query.offset ? parseInt(query.offset, 10) : 0;
  return {
    limit: Number.isFinite(limit) && limit > 0 ? Math.min(limit, MAX_LIMIT) : DEFAULT_LIMIT,
    offset: Number.isFinite(offset) && offset >= 0 ? offset : 0,
  };
}

function getAuthUid(req: Request): string {
  const uid = req.authUser?.uid;
  if (!uid) {
    throw new Error('Auth user required');
  }
  return uid;
}

/**
 * GET /api/messages/global
 * Query: limit, offset. Uses current user's cityId from DB.
 */
router.get('/global', async (req: Request, res: Response) => {
  try {
    const uid = getAuthUid(req);
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      res.status(401).json({
        code: 'unauthorized',
        message: 'User not found',
      });
      return;
    }
    if (!user.cityId) {
      res.status(400).json({
        code: 'user_city_required',
        message: 'User must have a city set to use global chat',
      });
      return;
    }

    const { limit, offset } = parsePagination(req.query as { limit?: string; offset?: string });
    const messagesRepo = getMessagesRepository();
    const list = await messagesRepo.findByChannel(
      'city',
      user.cityId,
      limit,
      offset
    );
    res.status(200).json(list);
  } catch (error) {
    logger.error('Error fetching global messages', { error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

/**
 * POST /api/messages/global
 * Body: { text }. Uses current user's cityId. Broadcasts to channel city:{cityId}.
 */
router.post('/global', validateBody(CreateMessageSchema), async (req: Request, res: Response) => {
  try {
    const uid = getAuthUid(req);
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      res.status(401).json({
        code: 'unauthorized',
        message: 'User not found',
      });
      return;
    }
    if (!user.cityId) {
      res.status(400).json({
        code: 'user_city_required',
        message: 'User must have a city set to use global chat',
      });
      return;
    }

    const { text } = req.body as { text: string };
    const messagesRepo = getMessagesRepository();
    const message = await messagesRepo.create({
      channelType: 'city',
      channelId: user.cityId,
      userId: user.id,
      text,
    });

    const dto: MessageViewDto = {
      id: message.id,
      text: message.text,
      userId: message.userId,
      userName: user.name,
      createdAt: message.createdAt.toISOString(),
      updatedAt: message.updatedAt.toISOString(),
    };

    broadcast(`city:${user.cityId}`, dto);
    res.status(201).json(dto);
  } catch (error) {
    logger.error('Error sending global message', { error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

/**
 * GET /api/messages/clubs/:clubId
 * Query: limit, offset. Access check: stub (allowed for now).
 */
router.get('/clubs/:clubId', async (req: Request, res: Response) => {
  const { clubId } = req.params;
  try {
    getAuthUid(req);
    const { limit, offset } = parsePagination(req.query as { limit?: string; offset?: string });
    const messagesRepo = getMessagesRepository();
    const list = await messagesRepo.findByChannel(
      'club',
      clubId,
      limit,
      offset
    );
    res.status(200).json(list);
  } catch (error) {
    logger.error('Error fetching club messages', { error: error, clubId });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

/**
 * POST /api/messages/clubs/:clubId
 * Body: { text }. Access check: stub (allowed for now). Broadcasts to channel club:{clubId}.
 */
router.post(
  '/clubs/:clubId',
  validateBody(CreateMessageSchema),
  async (req: Request, res: Response) => {
    const { clubId } = req.params;
    try {
      const uid = getAuthUid(req);
      const usersRepo = getUsersRepository();
      const user = await usersRepo.findByFirebaseUid(uid);
      if (!user) {
        res.status(401).json({
          code: 'unauthorized',
          message: 'User not found',
        });
        return;
      }

      const { text } = req.body as { text: string };
      const messagesRepo = getMessagesRepository();
      const message = await messagesRepo.create({
        channelType: 'club',
        channelId: clubId,
        userId: user.id,
        text,
      });

      const dto: MessageViewDto = {
        id: message.id,
        text: message.text,
        userId: message.userId,
        userName: user.name,
        createdAt: message.createdAt.toISOString(),
        updatedAt: message.updatedAt.toISOString(),
      };

      broadcast(`club:${clubId}`, dto);
      res.status(201).json(dto);
    } catch (error) {
      logger.error('Error sending club message', { error: error, clubId });
      res.status(500).json({
        code: 'internal_error',
        message: 'Internal server error',
      });
    }
  }
);

export default router;
