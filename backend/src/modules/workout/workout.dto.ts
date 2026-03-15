/**
 * Workout DTOs and Zod schemas
 */

import { z } from 'zod';

const workoutTypes = [
  'FUNCTIONAL', 'TEMPO', 'RECOVERY', 'ACCELERATIONS',
  'EASY_RUN', 'LONG_RUN', 'INTERVALS', 'PROGRESSION', 'HILL_RUN',
] as const;
const difficulties = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'PRO'] as const;
const targetMetrics = ['DISTANCE', 'TIME', 'PACE'] as const;
const surfaces = ['ROAD', 'TRACK', 'TRAIL'] as const;
const blockTypes = ['warmup', 'work', 'rest', 'cooldown', 'interval_config', 'progression_segment'] as const;

/** Workout block — flat MVP blocks plus structured interval_config / progression_segment types */
export const WorkoutBlockSchema = z.object({
  type: z.enum(blockTypes),
  durationMin: z.number().int().min(1).optional(),
  distanceM: z.number().int().min(1).optional(),
  paceTarget: z.number().int().min(1).optional(), // seconds/km
  heartRate: z.number().int().min(1).optional(),
  note: z.string().max(500).optional(),
  // interval_config fields
  reps: z.number().int().min(1).optional(),
  restDistanceM: z.number().int().min(1).optional(),
  restDurationMin: z.number().int().min(1).optional(),
  recoveryDistanceM: z.number().int().min(1).optional(),
  recoveryDurationMin: z.number().int().min(1).optional(),
  warmup: z.object({ valueM: z.number().int().min(1) }).optional(),
  paceTargetSecPerKm: z.number().int().min(1).optional(),
  // progression_segment / cooldown fields
  value: z.number().int().min(1).optional(),
});

export const CreateWorkoutSchema = z.object({
  clubId: z.string().uuid().nullable().optional(),
  name: z.string().min(1).max(200),
  description: z.string().max(5000).optional(),
  type: z.enum(workoutTypes),
  difficulty: z.enum(difficulties).optional().default('BEGINNER'),
  targetMetric: z.enum(targetMetrics).optional(),
  targetValue: z.number().int().min(1).optional(),
  targetZone: z.string().max(50).optional(),
  surface: z.enum(surfaces).optional(),
  blocks: z.array(WorkoutBlockSchema).optional(),
  // Type-specific fields
  distanceM: z.number().int().min(1).optional(),
  heartRateTarget: z.number().int().min(1).optional(),
  paceTarget: z.number().int().min(1).optional(),
  repCount: z.number().int().min(1).optional(),
  repDistanceM: z.number().int().min(1).optional(),
  exerciseName: z.string().max(200).optional(),
  exerciseInstructions: z.string().max(5000).optional(),
  // Personal workout fields
  isTemplate: z.boolean().optional(),
  scheduledAt: z.string().datetime().nullable().optional(),
  hillElevationM: z.number().int().min(1).optional(),
});

export const UpdateWorkoutSchema = CreateWorkoutSchema.partial().omit({ clubId: true });

export type CreateWorkoutDto = z.infer<typeof CreateWorkoutSchema>;
export type UpdateWorkoutDto = z.infer<typeof UpdateWorkoutSchema>;
export type WorkoutBlockDto = z.infer<typeof WorkoutBlockSchema>;
