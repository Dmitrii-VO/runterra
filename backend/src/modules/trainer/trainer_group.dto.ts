/**
 * Trainer group DTOs and Zod schemas
 */

import { z } from 'zod';

export const CreateTrainerGroupSchema = z.object({
  clubId: z.string().uuid(),
  name: z.string().min(1).max(100),
  memberIds: z.array(z.string().uuid()).min(1),
});

export type CreateTrainerGroupDto = z.infer<typeof CreateTrainerGroupSchema>;

export interface TrainerGroupViewDto {
  id: string;
  clubId: string;
  trainerId: string;
  name: string;
  createdAt: string;
  memberCount: number;
}
