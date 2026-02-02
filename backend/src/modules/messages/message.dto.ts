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
