/**
 * Workout DTOs and Zod schemas
 */

import { z } from 'zod';

const workoutTypes = ['RECOVERY', 'TEMPO', 'INTERVAL', 'FARTLEK', 'LONG_RUN'] as const;
const difficulties = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'PRO'] as const;
const targetMetrics = ['DISTANCE', 'TIME', 'PACE'] as const;

export const CreateWorkoutSchema = z.object({
  clubId: z.string().uuid().nullable().optional(),
  name: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  type: z.enum(workoutTypes),
  difficulty: z.enum(difficulties),
  targetMetric: z.enum(targetMetrics),
  targetValue: z.number().int().min(1).optional(),
  targetZone: z.string().max(50).optional(),
});

export const UpdateWorkoutSchema = CreateWorkoutSchema.partial().omit({ clubId: true });

export type CreateWorkoutDto = z.infer<typeof CreateWorkoutSchema>;
export type UpdateWorkoutDto = z.infer<typeof UpdateWorkoutSchema>;
