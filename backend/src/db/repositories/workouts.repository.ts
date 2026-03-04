/**
 * Workouts repository
 */

import { BaseRepository } from './base.repository';
import { Workout, Surface, WorkoutBlock } from '../../modules/workout/workout.entity';

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
  created_at: Date;
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
    targetMetric: row.target_metric,
    targetValue: row.target_value ?? undefined,
    targetZone: row.target_zone ?? undefined,
    distanceM: row.distance_m ?? undefined,
    heartRateTarget: row.heart_rate_target ?? undefined,
    paceTarget: row.pace_target ?? undefined,
    repCount: row.rep_count ?? undefined,
    repDistanceM: row.rep_distance_m ?? undefined,
    exerciseName: row.exercise_name ?? undefined,
    exerciseInstructions: row.exercise_instructions ?? undefined,
    createdAt: row.created_at,
  };
}

export class WorkoutsRepository extends BaseRepository {
  async findById(id: string): Promise<Workout | null> {
    const row = await this.queryOne<WorkoutRow>('SELECT * FROM workouts WHERE id = $1', [id]);
    return row ? rowToWorkout(row) : null;
  }

  async findByIds(ids: string[]): Promise<Map<string, Workout>> {
    if (ids.length === 0) return new Map();
    const rows = await this.queryMany<WorkoutRow>(
      'SELECT * FROM workouts WHERE id = ANY($1::uuid[])',
      [ids],
    );
    return new Map(rows.map(r => [r.id, rowToWorkout(r)]));
  }

  async findByAuthor(authorId: string): Promise<Workout[]> {
    const rows = await this.queryMany<WorkoutRow>(
      'SELECT * FROM workouts WHERE author_id = $1 AND club_id IS NULL ORDER BY created_at DESC',
      [authorId],
    );
    return rows.map(rowToWorkout);
  }

  async findByClub(clubId: string): Promise<Workout[]> {
    const rows = await this.queryMany<WorkoutRow>(
      'SELECT * FROM workouts WHERE club_id = $1 ORDER BY created_at DESC',
      [clubId],
    );
    return rows.map(rowToWorkout);
  }

  async create(data: {
    authorId: string;
    clubId?: string | null;
    name: string;
    description?: string;
    type: string;
    difficulty: string;
    surface?: string;
    blocks?: unknown;
    targetMetric: string;
    targetValue?: number;
    targetZone?: string;
    distanceM?: number;
    heartRateTarget?: number;
    paceTarget?: number;
    repCount?: number;
    repDistanceM?: number;
    exerciseName?: string;
    exerciseInstructions?: string;
  }): Promise<Workout> {
    const row = await this.queryOne<WorkoutRow>(
      `INSERT INTO workouts (
         author_id, club_id, name, description, type, difficulty, surface, blocks,
         target_metric, target_value, target_zone,
         distance_m, heart_rate_target, pace_target, rep_count, rep_distance_m,
         exercise_name, exercise_instructions
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18)
       RETURNING *`,
      [
        data.authorId,
        data.clubId || null,
        data.name,
        data.description || null,
        data.type,
        data.difficulty,
        data.surface || null,
        data.blocks ? JSON.stringify(data.blocks) : null,
        data.targetMetric,
        data.targetValue ?? null,
        data.targetZone ?? null,
        data.distanceM ?? null,
        data.heartRateTarget ?? null,
        data.paceTarget ?? null,
        data.repCount ?? null,
        data.repDistanceM ?? null,
        data.exerciseName ?? null,
        data.exerciseInstructions ?? null,
      ],
    );
    if (!row) throw new Error('Insert workouts failed');
    return rowToWorkout(row);
  }

  async update(
    id: string,
    data: {
      name?: string;
      description?: string;
      type?: string;
      difficulty?: string;
      surface?: string;
      blocks?: unknown;
      targetMetric?: string;
      targetValue?: number;
      targetZone?: string;
      distanceM?: number;
      heartRateTarget?: number;
      paceTarget?: number;
      repCount?: number;
      repDistanceM?: number;
      exerciseName?: string;
      exerciseInstructions?: string;
    },
  ): Promise<Workout | null> {
    const sets: string[] = [];
    const params: unknown[] = [];
    let idx = 1;

    if (data.name !== undefined) {
      sets.push(`name = $${idx++}`);
      params.push(data.name);
    }
    if (data.description !== undefined) {
      sets.push(`description = $${idx++}`);
      params.push(data.description);
    }
    if (data.type !== undefined) {
      sets.push(`type = $${idx++}`);
      params.push(data.type);
    }
    if (data.difficulty !== undefined) {
      sets.push(`difficulty = $${idx++}`);
      params.push(data.difficulty);
    }
    if (data.surface !== undefined) {
      sets.push(`surface = $${idx++}`);
      params.push(data.surface);
    }
    if (data.blocks !== undefined) {
      sets.push(`blocks = $${idx++}`);
      params.push(data.blocks ? JSON.stringify(data.blocks) : null);
    }
    if (data.targetMetric !== undefined) {
      sets.push(`target_metric = $${idx++}`);
      params.push(data.targetMetric);
    }
    if (data.targetValue !== undefined) {
      sets.push(`target_value = $${idx++}`);
      params.push(data.targetValue);
    }
    if (data.targetZone !== undefined) {
      sets.push(`target_zone = $${idx++}`);
      params.push(data.targetZone);
    }
    if (data.distanceM !== undefined) {
      sets.push(`distance_m = $${idx++}`);
      params.push(data.distanceM);
    }
    if (data.heartRateTarget !== undefined) {
      sets.push(`heart_rate_target = $${idx++}`);
      params.push(data.heartRateTarget);
    }
    if (data.paceTarget !== undefined) {
      sets.push(`pace_target = $${idx++}`);
      params.push(data.paceTarget);
    }
    if (data.repCount !== undefined) {
      sets.push(`rep_count = $${idx++}`);
      params.push(data.repCount);
    }
    if (data.repDistanceM !== undefined) {
      sets.push(`rep_distance_m = $${idx++}`);
      params.push(data.repDistanceM);
    }
    if (data.exerciseName !== undefined) {
      sets.push(`exercise_name = $${idx++}`);
      params.push(data.exerciseName);
    }
    if (data.exerciseInstructions !== undefined) {
      sets.push(`exercise_instructions = $${idx++}`);
      params.push(data.exerciseInstructions);
    }

    if (sets.length === 0) {
      return this.findById(id);
    }

    params.push(id);
    const row = await this.queryOne<WorkoutRow>(
      `UPDATE workouts SET ${sets.join(', ')} WHERE id = $${idx} RETURNING *`,
      params,
    );
    return row ? rowToWorkout(row) : null;
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.query('DELETE FROM workouts WHERE id = $1', [id]);
    return (result?.rowCount ?? 0) > 0;
  }

  /** Assign a workout template to a client */
  async assignToClient(workoutId: string, trainerId: string, clientId: string, note?: string): Promise<void> {
    await this.query(
      `INSERT INTO workout_assignments (workout_id, trainer_id, client_id, note)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (workout_id, client_id) DO NOTHING`,
      [workoutId, trainerId, clientId, note ?? null],
    );
  }

  /** Assign a workout template to multiple clients (batch) */
  async assignToClients(
    workoutId: string,
    trainerId: string,
    clientIds: string[],
    note?: string,
  ): Promise<number> {
    if (clientIds.length === 0) return 0;
    let assigned = 0;
    for (const clientId of clientIds) {
      const result = await this.query(
        `INSERT INTO workout_assignments (workout_id, trainer_id, client_id, note)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (workout_id, client_id) DO NOTHING`,
        [workoutId, trainerId, clientId, note ?? null],
      );
      assigned += result?.rowCount ?? 0;
    }
    return assigned;
  }

  /** Remove a workout assignment */
  async unassignFromClient(workoutId: string, trainerId: string, clientId: string): Promise<boolean> {
    const result = await this.query(
      `DELETE FROM workout_assignments
       WHERE workout_id = $1 AND trainer_id = $2 AND client_id = $3`,
      [workoutId, trainerId, clientId],
    );
    return (result?.rowCount ?? 0) > 0;
  }

  /** List workouts assigned to a client by their trainer(s) */
  async findAssignedToUser(clientId: string): Promise<Array<Workout & { trainerId: string; trainerName: string; note: string | null; assignedAt: Date }>> {
    const rows = await this.queryMany<WorkoutRow & { trainer_id: string; trainer_name: string; assignment_note: string | null; assigned_at: Date }>(
      `SELECT w.*, wa.trainer_id, u.name AS trainer_name, wa.note AS assignment_note, wa.assigned_at
       FROM workout_assignments wa
       JOIN workouts w ON w.id = wa.workout_id
       JOIN users u ON u.id = wa.trainer_id
       WHERE wa.client_id = $1
       ORDER BY wa.assigned_at DESC`,
      [clientId],
    );
    return rows.map(row => ({
      ...rowToWorkout(row),
      trainerId: row.trainer_id,
      trainerName: row.trainer_name,
      note: row.assignment_note,
      assignedAt: row.assigned_at,
    }));
  }

  async hasUpcomingEvents(workoutId: string): Promise<boolean> {
    const row = await this.queryOne<{ count: string }>(
      `SELECT COUNT(*)::text AS count FROM events
       WHERE workout_id = $1
       AND start_date_time > NOW()
       AND status NOT IN ('cancelled', 'completed')`,
      [workoutId],
    );
    return parseInt(row?.count ?? '0', 10) > 0;
  }
}

let instance: WorkoutsRepository | null = null;

export function getWorkoutsRepository(): WorkoutsRepository {
  if (!instance) {
    instance = new WorkoutsRepository();
  }
  return instance;
}
