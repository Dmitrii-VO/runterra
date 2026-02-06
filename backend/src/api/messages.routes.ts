/**
 * API router for messages (club chat).
 * GET/POST /api/messages/clubs/:clubId
 */

import { Router, Request, Response } from 'express';
import { CreateMessageSchema } from '../modules/messages';
import type { MessageViewDto, ClubChatViewDto } from '../modules/messages/message.dto';
import { validateBody } from './validateBody';
import { getMessagesRepository, getUsersRepository, getClubMembersRepository } from '../db/repositories';
import { broadcast } from '../ws/chatWs';
import { logger } from '../shared/logger';
import { isValidClubId } from '../shared/clubId';

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

function getAuthUidOrRespondUnauthorized(req: Request, res: Response): string | null {
  const uid = req.authUser?.uid;
  if (!uid) {
    res.status(401).json({
      code: 'unauthorized',
      message: 'Authorization required',
      details: { reason: 'missing_header' },
    });
    return null;
  }
  return uid;
}

/**
 * GET /api/messages/clubs
 * Returns list of club chats for current user (membership-based).
 */
router.get('/clubs', async (req: Request, res: Response) => {
  try {
    const uid = getAuthUidOrRespondUnauthorized(req, res);
    if (!uid) return;
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      res.status(401).json({
        code: 'unauthorized',
        message: 'User not found',
      });
      return;
    }

    const clubMembersRepo = getClubMembersRepository();
    const memberships = await clubMembersRepo.findActiveByUser(user.id);
    const chats: ClubChatViewDto[] = memberships.map((membership) => ({
      id: membership.id,
      clubId: membership.clubId,
      clubName: `Club ${membership.clubId}`,
      clubDescription: undefined,
      clubLogo: undefined,
      lastMessageAt: undefined,
      lastMessageText: undefined,
      lastMessageUserId: undefined,
      createdAt: membership.createdAt.toISOString(),
      updatedAt: membership.updatedAt.toISOString(),
    }));

    res.status(200).json(chats);
  } catch (error) {
    logger.error('Error fetching club chats', { error: error });
    res.status(500).json({
      code: 'internal_error',
      message: 'Internal server error',
    });
  }
});

/**
 * GET /api/messages/clubs/:clubId
 * Query: limit, offset.
 * Access: only active members of the club.
 */
router.get('/clubs/:clubId', async (req: Request, res: Response) => {
  const { clubId } = req.params;
  if (!isValidClubId(clubId)) {
    res.status(400).json({
      code: 'validation_error',
      message: 'Path validation failed',
      details: {
        fields: [
          {
            field: 'clubId',
            message: 'clubId has invalid format',
            code: 'invalid_format',
          },
        ],
      },
    });
    return;
  }

  try {
    const uid = getAuthUidOrRespondUnauthorized(req, res);
    if (!uid) return;
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) {
      res.status(401).json({
        code: 'unauthorized',
        message: 'User not found',
      });
      return;
    }

    const clubMembersRepo = getClubMembersRepository();
    const membership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
    if (!membership || membership.status !== 'active') {
      res.status(403).json({
        code: 'forbidden',
        message: 'User is not a member of this club',
        details: { clubId },
      });
      return;
    }

    const { limit, offset } = parsePagination(req.query as { limit?: string; offset?: string });
    const messagesRepo = getMessagesRepository();
    const list = await messagesRepo.findByChannel('club', clubId, limit, offset);
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
 * Body: { text }.
 * Access: only active members of the club.
 * Broadcasts to channel club:{clubId}.
 */
router.post(
  '/clubs/:clubId',
  validateBody(CreateMessageSchema),
  async (req: Request, res: Response) => {
    const { clubId } = req.params;
    if (!isValidClubId(clubId)) {
      res.status(400).json({
        code: 'validation_error',
        message: 'Path validation failed',
        details: {
          fields: [
            {
              field: 'clubId',
              message: 'clubId has invalid format',
              code: 'invalid_format',
            },
          ],
        },
      });
      return;
    }

    try {
      const uid = getAuthUidOrRespondUnauthorized(req, res);
      if (!uid) return;
      const usersRepo = getUsersRepository();
      const user = await usersRepo.findByFirebaseUid(uid);
      if (!user) {
        res.status(401).json({
          code: 'unauthorized',
          message: 'User not found',
        });
        return;
      }

      const clubMembersRepo = getClubMembersRepository();
      const membership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
      if (!membership || membership.status !== 'active') {
        res.status(403).json({
          code: 'forbidden',
          message: 'User is not a member of this club',
          details: { clubId },
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
