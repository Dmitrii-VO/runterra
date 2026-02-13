/**
 * Zod schema for CreateMessageDto (text max 500 per domain).
 */

import { z } from 'zod';

export const CreateMessageSchema = z.object({
  text: z.string().min(1).max(500),
  // Optional club sub-channel (UUID).
  // If omitted, message belongs to the legacy club chat (no channels).
  channelId: z.string().uuid().optional(),
});

export type CreateMessageSchemaType = z.infer<typeof CreateMessageSchema>;
