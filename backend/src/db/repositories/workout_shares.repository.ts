/**
 * WorkoutShares repository — friend-to-friend workout sharing
 */

import { BaseRepository } from './base.repository';
import { Workout, WorkoutBlock, Surface } from '../../modules/workout/workout.entity';

export interface WorkoutShare {
  id: string;
  workoutId: string;
  senderId: string;
  recipientId: string;
  sharedAt: Date;
  accepted: boolean;
}

interface WorkoutShareRow {
  id: string;
  workout_id: string;
  sender_id: string;
  recipient_id: string;
  shared_at: Date;
  accepted: boolean;
}

interface WorkoutRow {
  id: string;
  author_id: string;
  club_id: string | null;
  name: string;
  description: string | null;
  type: string;
  difficulty: string;
  surface: string | null;
  blocks: unknown | null;
  target_metric: string;
  target_value: number | null;
  target_zone: string | null;
  distance_m: number | null;
  heart_rate_target: number | null;
  pace_target: number | null;
  rep_count: number | null;
  rep_distance_m: number | null;
  exercise_name: string | null;
  exercise_instructions: string | null;
  is_template: boolean;
  is_favorite: boolean;
  scheduled_at: Date | null;
  hill_elevation_m: number | null;
  created_at: Date;
}

function rowToShare(row: WorkoutShareRow): WorkoutShare {
  return {
    id: row.id,
    workoutId: row.workout_id,
    senderId: row.sender_id,
    recipientId: row.recipient_id,
    sharedAt: row.shared_at,
    accepted: row.accepted,
  };
}

function rowToWorkout(row: WorkoutRow): Workout {
  return {
    id: row.id,
    authorId: row.author_id,
    clubId: row.club_id || undefined,
    name: row.name,
    description: row.description || undefined,
    type: row.type,
    difficulty: row.difficulty,
    surface: (row.surface as Surface) || undefined,
    blocks: (row.blocks as WorkoutBlock[]) || undefined,
    distanceM: row.distance_m ?? undefined,
    heartRateTarget: row.heart_rate_target ?? undefined,
    paceTarget: row.pace_target ?? undefined,
    repCount: row.rep_count ?? undefined,
    repDistanceM: row.rep_distance_m ?? undefined,
    exerciseName: row.exercise_name ?? undefined,
    exerciseInstructions: row.exercise_instructions ?? undefined,
    isTemplate: row.is_template,
    isFavorite: row.is_favorite,
    scheduledAt: row.scheduled_at ?? undefined,
    hillElevationM: row.hill_elevation_m ?? undefined,
    createdAt: row.created_at,
  };
}

export class WorkoutSharesRepository extends BaseRepository {
  /** Share a workout with a recipient */
  async share(workoutId: string, senderId: string, recipientId: string): Promise<WorkoutShare> {
    const row = await this.queryOne<WorkoutShareRow>(
      `INSERT INTO workout_shares (workout_id, sender_id, recipient_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (workout_id, recipient_id) DO UPDATE SET shared_at = NOW()
       RETURNING *`,
      [workoutId, senderId, recipientId],
    );
    if (!row) throw new Error('Insert workout_shares failed');
    return rowToShare(row);
  }

  /** Get incoming shares for a user (not yet accepted) */
  async findReceivedByUser(userId: string): Promise<Array<WorkoutShare & { workout: Workout; senderName: string }>> {
    const rows = await this.queryMany<WorkoutShareRow & WorkoutRow & { sender_name: string }>(
      `SELECT ws.*, w.*, u.name AS sender_name
       FROM workout_shares ws
       JOIN workouts w ON w.id = ws.workout_id
       JOIN users u ON u.id = ws.sender_id
       WHERE ws.recipient_id = $1 AND ws.accepted = false
       ORDER BY ws.shared_at DESC`,
      [userId],
    );
    return rows.map(row => ({
      id: row.id,
      workoutId: row.workout_id,
      senderId: row.sender_id,
      recipientId: row.recipient_id,
      sharedAt: row.shared_at,
      accepted: row.accepted,
      senderName: row.sender_name,
      workout: rowToWorkout(row),
    }));
  }

  /** Accept a share: copy workout as new object for recipient, mark accepted (atomic) */
  async accept(shareId: string, recipientId: string): Promise<Workout> {
    await this.query('BEGIN');
    try {
      // Lock the share row; only process if not yet accepted
      const share = await this.queryOne<WorkoutShareRow>(
        'SELECT * FROM workout_shares WHERE id = $1 AND recipient_id = $2 AND accepted = false FOR UPDATE',
        [shareId, recipientId],
      );
      if (!share) {
        await this.query('ROLLBACK');
        throw new Error('Share not found');
      }

      // Copy the workout for the recipient (new object, original unchanged)
      const copied = await this.queryOne<WorkoutRow>(
        `INSERT INTO workouts (
           author_id, name, description, type, difficulty, surface, blocks,
           target_metric, target_value, target_zone,
           distance_m, heart_rate_target, pace_target, rep_count, rep_distance_m,
           exercise_name, exercise_instructions,
           is_template, scheduled_at, hill_elevation_m
         )
         SELECT
           $1, name, description, type, difficulty, surface, blocks,
           target_metric, target_value, target_zone,
           distance_m, heart_rate_target, pace_target, rep_count, rep_distance_m,
           exercise_name, exercise_instructions,
           false, NULL, hill_elevation_m
         FROM workouts WHERE id = $2
         RETURNING *`,
        [recipientId, share.workout_id],
      );
      if (!copied) {
        await this.query('ROLLBACK');
        throw new Error('Failed to copy workout');
      }

      await this.query('UPDATE workout_shares SET accepted = true WHERE id = $1', [shareId]);
      await this.query('COMMIT');
      return rowToWorkout(copied);
    } catch (e) {
      await this.query('ROLLBACK');
      throw e;
    }
  }
}

let instance: WorkoutSharesRepository | null = null;

export function getWorkoutSharesRepository(): WorkoutSharesRepository {
  if (!instance) {
    instance = new WorkoutSharesRepository();
  }
  return instance;
}
