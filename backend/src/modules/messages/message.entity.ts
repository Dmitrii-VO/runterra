/**
 * Message entity for chat (city / club channels / trainer groups).
 */

export type MessageChannelType = 'city' | 'club' | 'trainer_group';

export interface Message {
  id: string;
  channelType: MessageChannelType;
  channelId: string;
  userId: string;
  text: string;
  createdAt: Date;
  updatedAt: Date;
}
