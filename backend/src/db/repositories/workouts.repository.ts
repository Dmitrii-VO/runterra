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
    createdAt: row.created_at,
  };
}

export class WorkoutsRepository extends BaseRepository {
  async findById(id: string): Promise<Workout | null> {
    const row = await this.queryOne<WorkoutRow>('SELECT * FROM workouts WHERE id = $1', [id]);
    return row ? rowToWorkout(row) : null;
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
  }): Promise<Workout> {
    const row = await this.queryOne<WorkoutRow>(
      `INSERT INTO workouts (author_id, club_id, name, description, type, difficulty, surface, blocks, target_metric, target_value, target_zone)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
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
        data.targetValue || null,
        data.targetZone || null,
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

  async hasUpcomingEvents(workoutId: string): Promise<boolean> {
    const row = await this.queryOne<{ count: string }>(
      `SELECT COUNT(*)::text AS count FROM events
       WHERE workout_id = $1
       AND COALESCE(end_date_time, start_date_time + INTERVAL '4 hours') > NOW()
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
