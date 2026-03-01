/**
 * API router for messages (club chat + trainer direct messages).
 * GET/POST /api/messages/clubs/:clubId
 * GET  /api/messages/trainer/clients
 * GET  /api/messages/trainer/my-trainer
 * GET  /api/messages/direct/:otherUserId
 * POST /api/messages/direct/:otherUserId
 */

import { Router, Request, Response } from 'express';
import { CreateMessageSchema } from '../modules/messages';
import type { MessageViewDto, ClubChatViewDto } from '../modules/messages/message.dto';
import { validateBody } from './validateBody';
import {
  getMessagesRepository,
  getUsersRepository,
  getClubMembersRepository,
  getClubChannelsRepository,
  getTrainerGroupsRepository,
} from '../db/repositories';
import { broadcast } from '../ws/chatWs';
import { logger } from '../shared/logger';
import { isValidClubId } from '../shared/clubId';
import { isValidUuid } from '../shared/validation';
import { z } from 'zod';

const DirectMessageSchema = z.object({
  text: z.string().min(1).max(500),
});

const router = Router();

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 50;

function parsePagination(query: { limit?: string; offset?: string }): {
  limit: number;
  offset: number;
} {
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

async function getOrCreateDefaultChannelId(clubId: string): Promise<string> {
  const clubChannelsRepo = getClubChannelsRepository();
  const existing = await clubChannelsRepo.findDefaultByClub(clubId);
  if (existing) return existing.id;
  const created = await clubChannelsRepo.createDefaultForClub(clubId);
  return created.id;
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
    const memberships = await clubMembersRepo.findActiveClubsByUser(user.id);
    const chats: ClubChatViewDto[] = memberships.map(membership => ({
      id: membership.clubId,
      clubId: membership.clubId,
      clubName: membership.clubName,
      clubDescription: membership.clubDescription,
      clubLogo: undefined,
      lastMessageAt: undefined,
      lastMessageText: undefined,
      lastMessageUserId: undefined,
      createdAt: membership.joinedAt.toISOString(),
      updatedAt: membership.joinedAt.toISOString(),
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
    const channelId = (req.query as Record<string, string | undefined>).channelId;

    const messagesRepo = getMessagesRepository();

    let resolvedChannelId: string;
    if (channelId) {
      if (!isValidUuid(channelId)) {
        res.status(400).json({
          code: 'validation_error',
          message: 'Query validation failed',
          details: {
            fields: [
              {
                field: 'channelId',
                message: 'channelId has invalid format',
                code: 'invalid_format',
              },
            ],
          },
        });
        return;
      }

      const clubChannelsRepo = getClubChannelsRepository();
      const channel = await clubChannelsRepo.findById(channelId);
      if (!channel || channel.clubId !== clubId) {
        res.status(404).json({
          code: 'not_found',
          message: 'Channel not found',
          details: { clubId, channelId },
        });
        return;
      }
      resolvedChannelId = channelId;
    } else {
      // Backward compatible: if client doesn't send channelId, use the default club channel.
      resolvedChannelId = await getOrCreateDefaultChannelId(clubId);
    }

    const list = await messagesRepo.findByClubChannelWithRole(
      clubId,
      resolvedChannelId,
      limit,
      offset,
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

      const { text, channelId: bodyChannelId } = req.body as { text: string; channelId?: string };

      let resolvedChannelId: string;
      if (bodyChannelId) {
        const clubChannelsRepo = getClubChannelsRepository();
        const channel = await clubChannelsRepo.findById(bodyChannelId);
        if (!channel || channel.clubId !== clubId) {
          res.status(400).json({
            code: 'validation_error',
            message: 'Body validation failed',
            details: {
              fields: [
                {
                  field: 'channelId',
                  message: 'channelId is not a channel of this club',
                  code: 'invalid_value',
                },
              ],
            },
          });
          return;
        }
        resolvedChannelId = bodyChannelId;
      } else {
        // Backward compatible: if client doesn't send channelId, use the default club channel.
        resolvedChannelId = await getOrCreateDefaultChannelId(clubId);
      }

      const messagesRepo = getMessagesRepository();
      const message = await messagesRepo.create({
        channelType: 'club',
        channelId: clubId,
        userId: user.id,
        text,
        clubChannelId: resolvedChannelId,
      });

      const dto: MessageViewDto = {
        id: message.id,
        text: message.text,
        userId: message.userId,
        userName: user.name,
        createdAt: message.createdAt.toISOString(),
        updatedAt: message.updatedAt.toISOString(),
      };

      // Broadcast to channel-specific or club-level WS topic
      const channelTopic = `club:${clubId}:${resolvedChannelId}`;
      broadcast(channelTopic, dto);
      // Compatibility: some clients may still be subscribed to club-level topic.
      broadcast(`club:${clubId}`, dto);
      res.status(201).json(dto);
    } catch (error) {
      logger.error('Error sending club message', { error: error, clubId });
      res.status(500).json({
        code: 'internal_error',
        message: 'Internal server error',
      });
    }
  },
);

// --- Helper to resolve userId from Firebase UID ---
async function resolveUser(
  req: Request,
  res: Response,
): Promise<{ id: string; name: string } | null> {
  const uid = getAuthUidOrRespondUnauthorized(req, res);
  if (!uid) return null;
  const user = await getUsersRepository().findByFirebaseUid(uid);
  if (!user) {
    res.status(401).json({ code: 'unauthorized', message: 'User not found' });
    return null;
  }
  return user;
}

/**
 * GET /api/messages/trainer/clients
 * Returns trainer's client list with last message info.
 */
router.get('/trainer/clients', async (req: Request, res: Response) => {
  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const messagesRepo = getMessagesRepository();
    const clients = await messagesRepo.getTrainerClients(user.id);
    res.status(200).json(clients);
  } catch (error) {
    logger.error('Error fetching trainer clients', {
      error: error instanceof Error ? error.message : error,
      stack: error instanceof Error ? error.stack : undefined,
    });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/messages/trainer/my-trainer
 * Returns the trainer for current user (or 404).
 */
router.get('/trainer/my-trainer', async (req: Request, res: Response) => {
  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const messagesRepo = getMessagesRepository();
    const trainer = await messagesRepo.getMyTrainer(user.id);
    if (!trainer) {
      res.status(404).json({ code: 'not_found', message: 'No trainer assigned' });
      return;
    }
    res.status(200).json(trainer);
  } catch (error) {
    logger.error('Error fetching my trainer', {
      error: error instanceof Error ? error.message : error,
      stack: error instanceof Error ? error.stack : undefined,
    });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * GET /api/messages/direct/:otherUserId
 * Returns direct message history between current user and otherUserId.
 * Access: trainer_clients relationship must exist.
 */
router.get('/direct/:otherUserId', async (req: Request, res: Response) => {
  const { otherUserId } = req.params;
  if (!isValidUuid(otherUserId)) {
    res.status(400).json({
      code: 'validation_error',
      message: 'Path validation failed',
      details: {
        fields: [{ field: 'otherUserId', message: 'Invalid UUID', code: 'invalid_format' }],
      },
    });
    return;
  }

  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const messagesRepo = getMessagesRepository();
    const hasRelationship = await messagesRepo.hasTrainerClientRelationship(user.id, otherUserId);
    if (!hasRelationship) {
      res.status(403).json({ code: 'forbidden', message: 'No trainer-client relationship' });
      return;
    }

    const { limit, offset } = parsePagination(req.query as { limit?: string; offset?: string });
    const messages = await messagesRepo.getDirectMessages(user.id, otherUserId, limit, offset);
    res.status(200).json(messages);
  } catch (error) {
    logger.error('Error fetching direct messages', { error });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * POST /api/messages/direct/:otherUserId
 * Send a direct message. Access: trainer_clients relationship must exist.
 * If no message history exists, only trainer can send first.
 */
router.post(
  '/direct/:otherUserId',
  validateBody(DirectMessageSchema),
  async (req: Request, res: Response) => {
    const { otherUserId } = req.params;
    if (!isValidUuid(otherUserId)) {
      res.status(400).json({
        code: 'validation_error',
        message: 'Path validation failed',
        details: {
          fields: [{ field: 'otherUserId', message: 'Invalid UUID', code: 'invalid_format' }],
        },
      });
      return;
    }

    try {
      const user = await resolveUser(req, res);
      if (!user) return;

      const messagesRepo = getMessagesRepository();
      const hasRelationship = await messagesRepo.hasTrainerClientRelationship(user.id, otherUserId);
      if (!hasRelationship) {
        res.status(403).json({ code: 'forbidden', message: 'No trainer-client relationship' });
        return;
      }

      // If no messages exist, only the trainer can initiate
      const hasMessages = await messagesRepo.hasDirectMessages(user.id, otherUserId);
      if (!hasMessages) {
        const trainerId = await messagesRepo.getTrainerIdForPair(user.id, otherUserId);
        if (trainerId !== user.id) {
          res.status(403).json({
            code: 'trainer_initiates_first',
            message: 'Trainer must send the first message',
          });
          return;
        }
      }

      const { text } = req.body as { text: string };
      const dto = await messagesRepo.insertDirectMessage(user.id, otherUserId, text);

      // Broadcast to direct WS channel
      const ids = [user.id, otherUserId].sort();
      const channelKey = `direct:${ids[0]}:${ids[1]}`;
      broadcast(channelKey, dto);

      res.status(201).json(dto);
    } catch (error) {
      logger.error('Error sending direct message', { error });
      res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
    }
  },
);

/**
 * GET /api/messages/trainer-groups/:groupId
 * Query: limit, offset.
 * Access: trainer or members of the group.
 */
router.get('/trainer-groups/:groupId', async (req: Request, res: Response) => {
  const { groupId } = req.params;
  if (!isValidUuid(groupId)) {
    return res.status(400).json({
      code: 'validation_error',
      message: 'groupId must be a valid UUID',
    });
  }

  try {
    const user = await resolveUser(req, res);
    if (!user) return;

    const trainerGroupsRepo = getTrainerGroupsRepository();
    const group = await trainerGroupsRepo.findById(groupId);
    if (!group) {
      return res.status(404).json({ code: 'not_found', message: 'Trainer group not found' });
    }

    // Access check: must be the trainer or a member of the group
    const isMember = await trainerGroupsRepo.isMember(groupId, user.id);
    const isTrainer = group.trainerId === user.id;
    if (!isMember && !isTrainer) {
      return res
        .status(403)
        .json({ code: 'forbidden', message: 'You do not have access to this group' });
    }

    const { limit, offset } = parsePagination(req.query as { limit?: string; offset?: string });
    const messagesRepo = getMessagesRepository();
    const messages = await messagesRepo.findByChannel('trainer_group', groupId, limit, offset);
    res.status(200).json(messages);
  } catch (error) {
    logger.error('Error fetching trainer group messages', { error, groupId });
    res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
  }
});

/**
 * POST /api/messages/trainer-groups/:groupId
 * Send a message to a trainer group.
 * Access: trainer or members of the group.
 */
router.post(
  '/trainer-groups/:groupId',
  validateBody(CreateMessageSchema),
  async (req: Request, res: Response) => {
    const { groupId } = req.params;
    if (!isValidUuid(groupId)) {
      return res.status(400).json({
        code: 'validation_error',
        message: 'groupId must be a valid UUID',
      });
    }

    try {
      const user = await resolveUser(req, res);
      if (!user) return;

      const trainerGroupsRepo = getTrainerGroupsRepository();
      const group = await trainerGroupsRepo.findById(groupId);
      if (!group) {
        return res.status(404).json({ code: 'not_found', message: 'Trainer group not found' });
      }

      // Access check: must be the trainer or a member of the group
      const isMember = await trainerGroupsRepo.isMember(groupId, user.id);
      const isTrainer = group.trainerId === user.id;
      if (!isMember && !isTrainer) {
        return res
          .status(403)
          .json({ code: 'forbidden', message: 'You do not have access to this group' });
      }

      const { text } = req.body as { text: string };
      const messagesRepo = getMessagesRepository();
      const message = await messagesRepo.create({
        channelType: 'trainer_group',
        channelId: groupId,
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

      // Broadcast to trainer group channel
      broadcast(`trainer_group:${groupId}`, dto);
      res.status(201).json(dto);
    } catch (error) {
      logger.error('Error sending trainer group message', { error, groupId });
      res.status(500).json({ code: 'internal_error', message: 'Internal server error' });
    }
  },
);

export default router;
