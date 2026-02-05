/**
 * DTOs for messages API and WebSocket broadcast.
 */

export interface MessageViewDto {
  id: string;
  text: string;
  userId: string;
  userName: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface CreateMessageDto {
  text: string;
}

export interface ClubChatViewDto {
  id: string;
  clubId: string;
  clubName?: string;
  clubDescription?: string;
  clubLogo?: string;
  lastMessageAt?: string;
  lastMessageText?: string;
  lastMessageUserId?: string;
  createdAt: string;
  updatedAt: string;
}
