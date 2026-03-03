/**
 * Workout DTOs and Zod schemas
 */

import { z } from 'zod';

const workoutTypes = ['FUNCTIONAL', 'TEMPO', 'RECOVERY', 'ACCELERATIONS'] as const;
const difficulties = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'PRO'] as const;
const targetMetrics = ['DISTANCE', 'TIME', 'PACE'] as const;
const surfaces = ['ROAD', 'TRACK', 'TRAIL'] as const;
const segmentTypes = ['WARMUP', 'RUN', 'REST', 'COOLDOWN'] as const;
const durationTypes = ['TIME', 'DISTANCE', 'MANUAL'] as const;
const recoveryTypes = ['JOG', 'WALK', 'STAND'] as const;

export const WorkoutSegmentSchema = z.object({
  type: z.enum(segmentTypes),
  durationValue: z.number().int().min(0),
  durationType: z.enum(durationTypes),
  targetValue: z.string().max(50).optional(),
  targetZone: z.string().max(50).optional(),
  recoveryType: z.enum(recoveryTypes).optional(),
  instructions: z.string().max(1000).optional(),
  mediaUrl: z.string().url().max(500).optional().or(z.literal('')),
});

export const WorkoutBlockSchema = z.object({
  repeatCount: z.number().int().min(1),
  segments: z.array(WorkoutSegmentSchema),
});

export const CreateWorkoutSchema = z.object({
  clubId: z.string().uuid().nullable().optional(),
  name: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  type: z.enum(workoutTypes),
  difficulty: z.enum(difficulties).optional().default('BEGINNER'),
  surface: z.enum(surfaces).optional(),
  blocks: z.array(WorkoutBlockSchema).optional(),
  targetMetric: z.enum(targetMetrics).optional().default('DISTANCE'),
  targetValue: z.number().int().min(1).optional(),
  targetZone: z.string().max(50).optional(),
  // Type-specific fields
  distanceM: z.number().int().min(1).optional(),
  heartRateTarget: z.number().int().min(1).optional(),
  paceTarget: z.number().int().min(1).optional(),
  repCount: z.number().int().min(1).optional(),
  repDistanceM: z.number().int().min(1).optional(),
  exerciseName: z.string().max(200).optional(),
  exerciseInstructions: z.string().max(5000).optional(),
});

export const UpdateWorkoutSchema = CreateWorkoutSchema.partial().omit({ clubId: true });

export type CreateWorkoutDto = z.infer<typeof CreateWorkoutSchema>;
export type UpdateWorkoutDto = z.infer<typeof UpdateWorkoutSchema>;
export type WorkoutSegmentDto = z.infer<typeof WorkoutSegmentSchema>;
export type WorkoutBlockDto = z.infer<typeof WorkoutBlockSchema>;
