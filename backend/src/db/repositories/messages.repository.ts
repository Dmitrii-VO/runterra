/**
 * Messages repository - database operations for chat messages
 */

import { BaseRepository } from './base.repository';
import { Message, MessageChannelType } from '../../modules/messages/message.entity';
import type { MessageViewDto } from '../../modules/messages/message.dto';

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
  }): Promise<Message> {
    const row = await this.queryOne<MessageRow>(
      `INSERT INTO messages (channel_type, channel_id, user_id, text)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [data.channelType, data.channelId, data.userId, data.text]
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
}
