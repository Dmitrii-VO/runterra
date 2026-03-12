/**
 * Workout entity
 */

export type Surface = 'ROAD' | 'TRACK' | 'TRAIL';

/** Flat workout phase for MVP */
export interface WorkoutBlock {
  type: 'warmup' | 'work' | 'rest' | 'cooldown';
  durationMin?: number;
  distanceM?: number;
  paceTarget?: number; // seconds/km
  heartRate?: number;
  note?: string;
}

export interface Workout {
  id: string;
  authorId: string;
  clubId?: string;
  name: string;
  description?: string;
  type: string;
  difficulty: string;
  surface?: Surface;
  blocks?: WorkoutBlock[];
  // Type-specific fields
  distanceM?: number;
  heartRateTarget?: number;
  paceTarget?: number;
  repCount?: number;
  repDistanceM?: number;
  exerciseName?: string;
  exerciseInstructions?: string;
  createdAt: Date;
}
