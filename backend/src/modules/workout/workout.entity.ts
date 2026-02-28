/**
 * Workout entity
 */

export type Surface = 'ROAD' | 'TRACK' | 'TRAIL';

export type SegmentType = 'WARMUP' | 'RUN' | 'REST' | 'COOLDOWN';

export type DurationType = 'TIME' | 'DISTANCE' | 'MANUAL';

export type RecoveryType = 'JOG' | 'WALK' | 'STAND';

export interface WorkoutSegment {
  type: SegmentType;
  durationValue: number; // seconds or meters
  durationType: DurationType;
  targetValue?: string; // e.g. "4:00" or "160"
  targetZone?: string; // e.g. "Z1", "Z5", "100% threshold"
  recoveryType?: RecoveryType;
  instructions?: string;
  mediaUrl?: string;
}

export interface WorkoutBlock {
  repeatCount: number;
  segments: WorkoutSegment[];
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
  targetMetric: string;
  targetValue?: number;
  targetZone?: string;
  createdAt: Date;
}
