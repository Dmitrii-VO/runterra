/**
 * Messages repository - database operations for chat messages
 */

import { BaseRepository } from './base.repository';
import { Message, MessageChannelType } from '../../modules/messages/message.entity';
import type { MessageViewDto, DirectChatViewDto } from '../../modules/messages/message.dto';

interface MessageRow {
  id: string;
  channel_type: string;
  channel_id: string;
  user_id: string;
  text: string;
  created_at: Date;
  updated_at: Date;
}

interface MessageWithUserNameRow extends MessageRow {
  user_name: string | null;
}

function rowToMessage(row: MessageRow): Message {
  return {
    id: row.id,
    channelType: row.channel_type as MessageChannelType,
    channelId: row.channel_id,
    userId: row.user_id,
    text: row.text,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

interface MessageWithRoleRow extends MessageWithUserNameRow {
  sender_role: string | null;
}

interface DirectMessageRow {
  id: string;
  sender_id: string;
  receiver_id: string;
  text: string;
  created_at: Date;
  updated_at: Date;
  user_name: string | null;
}

interface DirectChatRow {
  user_id: string;
  user_name: string;
  user_avatar: string | null;
  last_message_text: string | null;
  last_message_at: Date | null;
}

function rowToMessageViewDto(row: MessageWithUserNameRow): MessageViewDto {
  return {
    id: row.id,
    text: row.text,
    userId: row.user_id,
    userName: row.user_name || null,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

function rowToMessageViewDtoWithRole(row: MessageWithRoleRow): MessageViewDto {
  return {
    id: row.id,
    text: row.text,
    userId: row.user_id,
    userName: row.user_name || null,
    senderRole: row.sender_role || null,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

function directRowToMessageViewDto(row: DirectMessageRow): MessageViewDto {
  return {
    id: row.id,
    text: row.text,
    userId: row.sender_id,
    userName: row.user_name || null,
    createdAt: row.created_at.toISOString(),
    updatedAt: row.updated_at.toISOString(),
  };
}

function rowToDirectChatViewDto(row: DirectChatRow): DirectChatViewDto {
  return {
    userId: row.user_id,
    userName: row.user_name,
    userAvatar: row.user_avatar,
    lastMessageText: row.last_message_text,
    lastMessageAt: row.last_message_at ? row.last_message_at.toISOString() : null,
  };
}

let messagesRepositoryInstance: MessagesRepository | null = null;

export function getMessagesRepository(): MessagesRepository {
  if (!messagesRepositoryInstance) {
    messagesRepositoryInstance = new MessagesRepository();
  }
  return messagesRepositoryInstance;
}

export class MessagesRepository extends BaseRepository {
  async create(data: {
    channelType: MessageChannelType;
    channelId: string;
    userId: string;
    text: string;
    clubChannelId?: string;
  }): Promise<Message> {
    // For club chats, club_channel_id must always be provided (enforced by DB check constraint after migration 016).
    if (data.channelType === 'club' && !data.clubChannelId) {
      throw new Error('clubChannelId is required for club messages');
    }

    const row = await this.queryOne<MessageRow>(
      `INSERT INTO messages (channel_type, channel_id, user_id, text, club_channel_id)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [data.channelType, data.channelId, data.userId, data.text, data.clubChannelId ?? null]
    );
    return rowToMessage(row!);
  }

  async findByChannel(
    channelType: MessageChannelType,
    channelId: string,
    limit: number,
    offset: number
  ): Promise<MessageViewDto[]> {
    const rows = await this.queryMany<MessageWithUserNameRow>(
      `SELECT m.id, m.channel_type, m.channel_id, m.user_id, m.text, m.created_at, m.updated_at, u.name AS user_name
       FROM messages m
       JOIN users u ON u.id = m.user_id
       WHERE m.channel_type = $1 AND m.channel_id = $2
       ORDER BY m.created_at DESC
       LIMIT $3 OFFSET $4`,
      [channelType, channelId, limit, offset]
    );
    return rows.map(rowToMessageViewDto);
  }

  async findByClubChannel(
    clubId: string,
    clubChannelId: string,
    limit: number,
    offset: number
  ): Promise<MessageViewDto[]> {
    const rows = await this.queryMany<MessageWithUserNameRow>(
      `SELECT m.id, m.channel_type, m.channel_id, m.user_id, m.text, m.created_at, m.updated_at, u.name AS user_name
       FROM messages m
       JOIN users u ON u.id = m.user_id
       WHERE m.channel_type = 'club'
         AND m.channel_id = $1
         AND m.club_channel_id = $2
       ORDER BY m.created_at DESC
       LIMIT $3 OFFSET $4`,
      [clubId, clubChannelId, limit, offset]
    );
    return rows.map(rowToMessageViewDto);
  }

  /** Find club messages with sender role (JOIN club_members) */
  async findByClubChannelWithRole(
    clubId: string,
    clubChannelId: string,
    limit: number,
    offset: number
  ): Promise<MessageViewDto[]> {
    const rows = await this.queryMany<MessageWithRoleRow>(
      `SELECT m.id, m.channel_type, m.channel_id, m.user_id, m.text, m.created_at, m.updated_at,
              u.name AS user_name, cm.role AS sender_role
       FROM messages m
       JOIN users u ON u.id = m.user_id
       LEFT JOIN club_members cm ON cm.club_id = m.channel_id::uuid AND cm.user_id = m.user_id AND cm.status = 'active'
       WHERE m.channel_type = 'club'
         AND m.channel_id = $1
         AND m.club_channel_id = $2
       ORDER BY m.created_at DESC
       LIMIT $3 OFFSET $4`,
      [clubId, clubChannelId, limit, offset]
    );
    return rows.map(rowToMessageViewDtoWithRole);
  }

  // --- Trainer clients ---

  /** Add trainer-client relationship */
  async addTrainerClient(trainerId: string, clientId: string): Promise<void> {
    await this.queryOne(
      `INSERT INTO trainer_clients (trainer_id, client_id) VALUES ($1, $2)
       ON CONFLICT (trainer_id, client_id) DO NOTHING`,
      [trainerId, clientId]
    );
  }

  /** Remove trainer-client relationship */
  async removeTrainerClient(trainerId: string, clientId: string): Promise<boolean> {
    const result = await this.query(
      `DELETE FROM trainer_clients WHERE trainer_id = $1::uuid AND client_id = $2::uuid`,
      [trainerId, clientId]
    );
    return result.rowCount !== null && result.rowCount > 0;
  }

  /** Check if trainer-client relationship exists */
  async isTrainerClient(trainerId: string, clientId: string): Promise<boolean> {
    const row = await this.queryOne(
      `SELECT 1 FROM trainer_clients WHERE trainer_id = $1::uuid AND client_id = $2::uuid`,
      [trainerId, clientId]
    );
    return !!row;
  }

  /** Get list of trainer's clients with last message info */
  async getTrainerClients(trainerId: string): Promise<DirectChatViewDto[]> {
    const rows = await this.queryMany<DirectChatRow>(
      `SELECT tc.client_id AS user_id, u.name AS user_name, u.photo_url AS user_avatar,
              dm.text AS last_message_text, dm.created_at AS last_message_at
       FROM trainer_clients tc
       JOIN users u ON u.id = tc.client_id
       LEFT JOIN LATERAL (
         SELECT text, created_at FROM direct_messages
         WHERE (sender_id = tc.trainer_id AND receiver_id = tc.client_id)
            OR (sender_id = tc.client_id AND receiver_id = tc.trainer_id)
         ORDER BY created_at DESC LIMIT 1
       ) dm ON true
       WHERE tc.trainer_id = $1::uuid
       ORDER BY dm.created_at DESC NULLS LAST, u.name ASC`,
      [trainerId]
    );
    return rows.map(rowToDirectChatViewDto);
  }

  /** Get trainer for a client (or null) */
  async getMyTrainer(clientId: string): Promise<DirectChatViewDto | null> {
    const row = await this.queryOne<DirectChatRow>(
      `SELECT tc.trainer_id AS user_id, u.name AS user_name, u.photo_url AS user_avatar,
              dm.text AS last_message_text, dm.created_at AS last_message_at
       FROM trainer_clients tc
       JOIN users u ON u.id = tc.trainer_id
       LEFT JOIN LATERAL (
         SELECT text, created_at FROM direct_messages
         WHERE (sender_id = tc.trainer_id AND receiver_id = tc.client_id)
            OR (sender_id = tc.client_id AND receiver_id = tc.trainer_id)
         ORDER BY created_at DESC LIMIT 1
       ) dm ON true
       WHERE tc.client_id = $1::uuid
       ORDER BY dm.created_at DESC NULLS LAST
       LIMIT 1`,
      [clientId]
    );
    return row ? rowToDirectChatViewDto(row) : null;
  }

  /** Check if trainer_clients relationship exists between two users (in either direction) */
  async hasTrainerClientRelationship(userA: string, userB: string): Promise<boolean> {
    const row = await this.queryOne(
      `SELECT 1 FROM trainer_clients
       WHERE (trainer_id = $1::uuid AND client_id = $2::uuid)
          OR (trainer_id = $2::uuid AND client_id = $1::uuid)`,
      [userA, userB]
    );
    return !!row;
  }

  /** Get trainer_id for a pair (needed to check who initiates) */
  async getTrainerIdForPair(userA: string, userB: string): Promise<string | null> {
    const row = await this.queryOne<{ trainer_id: string }>(
      `SELECT trainer_id FROM trainer_clients
       WHERE (trainer_id = $1::uuid AND client_id = $2::uuid)
          OR (trainer_id = $2::uuid AND client_id = $1::uuid)
       LIMIT 1`,
      [userA, userB]
    );
    return row ? row.trainer_id : null;
  }

  // --- Direct messages ---

  /** Get direct messages between two users */
  async getDirectMessages(userA: string, userB: string, limit: number, offset: number): Promise<MessageViewDto[]> {
    const rows = await this.queryMany<DirectMessageRow>(
      `SELECT dm.id, dm.sender_id, dm.receiver_id, dm.text, dm.created_at, dm.updated_at,
              u.name AS user_name
       FROM direct_messages dm
       JOIN users u ON u.id = dm.sender_id
       WHERE (dm.sender_id = $1::uuid AND dm.receiver_id = $2::uuid)
          OR (dm.sender_id = $2::uuid AND dm.receiver_id = $1::uuid)
       ORDER BY dm.created_at DESC
       LIMIT $3 OFFSET $4`,
      [userA, userB, limit, offset]
    );
    return rows.map(directRowToMessageViewDto);
  }

  /** Insert a direct message */
  async insertDirectMessage(senderId: string, receiverId: string, text: string): Promise<MessageViewDto> {
    const row = await this.queryOne<DirectMessageRow>(
      `WITH ins AS (
         INSERT INTO direct_messages (sender_id, receiver_id, text)
         VALUES ($1, $2, $3)
         RETURNING *
       )
       SELECT ins.id, ins.sender_id, ins.receiver_id, ins.text, ins.created_at, ins.updated_at,
              u.name AS user_name
       FROM ins
       JOIN users u ON u.id = ins.sender_id`,
      [senderId, receiverId, text]
    );
    return directRowToMessageViewDto(row!);
  }

  /** Check if there are any direct messages between two users */
  async hasDirectMessages(userA: string, userB: string): Promise<boolean> {
    const row = await this.queryOne(
      `SELECT 1 FROM direct_messages
       WHERE (sender_id = $1 AND receiver_id = $2)
          OR (sender_id = $2 AND receiver_id = $1)
       LIMIT 1`,
      [userA, userB]
    );
    return !!row;
  }
}
