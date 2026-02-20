import { z } from 'zod';
import { ActivityType } from './activity.type';
import { ActivityStatus } from './activity.status';

export interface CreateActivityDto {
  type: ActivityType;
  name?: string;
  description?: string;
  status?: ActivityStatus;
  scheduledItemId?: string;
}

export const CreateActivitySchema = z.object({
  type: z.nativeEnum(ActivityType),
  name: z.string().optional(),
  description: z.string().optional(),
  status: z.nativeEnum(ActivityStatus).optional(),
  scheduledItemId: z.string().uuid().optional(),
});

export interface ActivityViewDto {
  id: string;
  userId: string;
  type: ActivityType;
  status: ActivityStatus;
  name?: string;
  description?: string;
  scheduledItemId?: string;
  createdAt: Date;
  updatedAt: Date;
}
