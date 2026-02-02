/**
 * Zod schema for CreateMessageDto (text max 500 per domain).
 */

import { z } from 'zod';

export const CreateMessageSchema = z.object({
  text: z.string().min(1).max(500),
});

export type CreateMessageSchemaType = z.infer<typeof CreateMessageSchema>;
