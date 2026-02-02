/**
 * Message entity for chat (city / club channels).
 */

export type MessageChannelType = 'city' | 'club';

export interface Message {
  id: string;
  channelType: MessageChannelType;
  channelId: string;
  userId: string;
  text: string;
  createdAt: Date;
  updatedAt: Date;
}
