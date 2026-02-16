/**
 * Workouts repository
 */

import { BaseRepository } from './base.repository';
import { Workout } from '../../modules/workout/workout.entity';

interface WorkoutRow {
  id: string;
  author_id: string;
  club_id: string | null;
  name: string;
  description: string | null;
  type: string;
  difficulty: string;
  target_metric: string;
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
    targetMetric: row.target_metric,
    createdAt: row.created_at,
  };
}

export class WorkoutsRepository extends BaseRepository {
  async findById(id: string): Promise<Workout | null> {
    const row = await this.queryOne<WorkoutRow>(
      'SELECT * FROM workouts WHERE id = $1',
      [id],
    );
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
    targetMetric: string;
  }): Promise<Workout> {
    const row = await this.queryOne<WorkoutRow>(
      `INSERT INTO workouts (author_id, club_id, name, description, type, difficulty, target_metric)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        data.authorId,
        data.clubId || null,
        data.name,
        data.description || null,
        data.type,
        data.difficulty,
        data.targetMetric,
      ],
    );
    if (!row) throw new Error('Insert workouts failed');
    return rowToWorkout(row);
  }

  async update(id: string, data: {
    name?: string;
    description?: string;
    type?: string;
    difficulty?: string;
    targetMetric?: string;
  }): Promise<Workout | null> {
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
    if (data.targetMetric !== undefined) {
      sets.push(`target_metric = $${idx++}`);
      params.push(data.targetMetric);
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
    const result = await this.query(
      'DELETE FROM workouts WHERE id = $1',
      [id],
    );
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
