/**
 * Runs repository - database operations for runs with validation
 */

import { BaseRepository } from './base.repository';
import { Run, GpsPoint } from '../../modules/runs/run.entity';
import { RunStatus } from '../../modules/runs/run.type';

interface RunRow {
  id: string;
  user_id: string;
  activity_id: string | null;
  scoring_club_id: string | null;
  assignment_id: string | null;
  started_at: Date;
  ended_at: Date;
  duration: number;
  distance: number;
  status: string;
  rpe: number | null;
  notes: string | null;
  created_at: Date;
  updated_at: Date;
}

interface GpsPointRow {
  id: string;
  run_id: string;
  longitude: number;
  latitude: number;
  timestamp: Date | null;
  point_order: number;
}

function rowToRun(row: RunRow): Run {
  return {
    id: row.id,
    userId: row.user_id,
    activityId: row.activity_id || undefined,
    scoringClubId: row.scoring_club_id || undefined,
    assignmentId: row.assignment_id ?? undefined,
    startedAt: row.started_at,
    endedAt: row.ended_at,
    duration: row.duration,
    distance: row.distance,
    status: row.status as RunStatus,
    rpe: row.rpe ?? undefined,
    notes: row.notes ?? undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export interface RunValidationResult {
  valid: boolean;
  status: RunStatus;
  errors: string[];
}

export class RunsRepository extends BaseRepository {
  // Validation constants
  private static readonly MIN_DISTANCE_METERS = 100;
  private static readonly MAX_SPEED_KMH = 30;
  private static readonly MIN_DURATION_SECONDS = 30;

  async findById(id: string): Promise<Run | null> {
    const row = await this.queryOne<RunRow>('SELECT * FROM runs WHERE id = $1', [id]);
    return row ? rowToRun(row) : null;
  }

  async findByUserId(userId: string, limit = 50, offset = 0): Promise<Run[]> {
    const rows = await this.queryMany<RunRow>(
      `SELECT * FROM runs WHERE user_id = $1 
       ORDER BY started_at DESC LIMIT $2 OFFSET $3`,
      [userId, limit, offset],
    );
    return rows.map(rowToRun);
  }

  /**
   * Validate run data before saving
   */
  validateRun(data: {
    duration: number;
    distance: number;
    startedAt: Date;
    endedAt: Date;
  }): RunValidationResult {
    const errors: string[] = [];

    // Check minimum distance
    if (data.distance < RunsRepository.MIN_DISTANCE_METERS) {
      errors.push(
        `Distance too short: ${data.distance}m, minimum: ${RunsRepository.MIN_DISTANCE_METERS}m`,
      );
    }

    // Check minimum duration
    if (data.duration < RunsRepository.MIN_DURATION_SECONDS) {
      errors.push(
        `Duration too short: ${data.duration}s, minimum: ${RunsRepository.MIN_DURATION_SECONDS}s`,
      );
    }

    // Check speed (distance in meters, duration in seconds)
    if (data.duration > 0) {
      const speedMs = data.distance / data.duration; // meters per second
      const speedKmh = speedMs * 3.6; // km/h

      if (speedKmh > RunsRepository.MAX_SPEED_KMH) {
        errors.push(
          `Speed too high: ${speedKmh.toFixed(1)} km/h, maximum: ${RunsRepository.MAX_SPEED_KMH} km/h`,
        );
      }
    }

    // Check dates consistency
    const start = new Date(data.startedAt);
    const end = new Date(data.endedAt);
    if (end <= start) {
      errors.push('End time must be after start time');
    }

    // Check duration matches dates
    const calculatedDuration = Math.round((end.getTime() - start.getTime()) / 1000);
    const durationDiff = Math.abs(calculatedDuration - data.duration);
    if (durationDiff > 5) {
      // Allow 5 seconds tolerance
      errors.push(
        `Duration mismatch: provided ${data.duration}s, calculated ${calculatedDuration}s`,
      );
    }

    return {
      valid: errors.length === 0,
      status: errors.length === 0 ? RunStatus.COMPLETED : RunStatus.INVALID,
      errors,
    };
  }

  /**
   * Create a new run with validation
   */
  async create(
    data: {
      userId: string;
      activityId?: string;
      scoringClubId?: string;
      assignmentId?: string;
      startedAt: Date;
      endedAt: Date;
      duration: number;
      distance: number;
      gpsPoints?: GpsPoint[];
      rpe?: number;
      notes?: string;
    },
    client?: import('pg').PoolClient,
  ): Promise<{ run: Run; validation: RunValidationResult }> {
    // Validate
    const validation = this.validateRun({
      duration: data.duration,
      distance: data.distance,
      startedAt: data.startedAt,
      endedAt: data.endedAt,
    });

    // Create run record
    const row = await this.queryOne<RunRow>(
      `INSERT INTO runs (user_id, activity_id, scoring_club_id, assignment_id, started_at, ended_at, duration, distance, status, rpe, notes)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING *`,
      [
        data.userId,
        data.activityId || null,
        data.scoringClubId || null,
        data.assignmentId || null,
        data.startedAt,
        data.endedAt,
        data.duration,
        data.distance,
        validation.status,
        data.rpe || null,
        data.notes || null,
      ],
      client,
    );

    const run = rowToRun(row!);

    // Save GPS points if provided
    if (data.gpsPoints && data.gpsPoints.length > 0) {
      await this.saveGpsPoints(run.id, data.gpsPoints, client);
    }

    return { run, validation };
  }

  /**
   * Save GPS points for a run
   */
  private async saveGpsPoints(
    runId: string,
    points: GpsPoint[],
    client?: import('pg').PoolClient,
  ): Promise<void> {
    if (points.length === 0) return;

    // Build bulk insert query
    const values: unknown[] = [];
    const placeholders: string[] = [];

    points.forEach((point, index) => {
      // 5 columns per row: run_id, longitude, latitude, timestamp, point_order
      const offset = index * 5;
      placeholders.push(
        `($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5})`,
      );
      values.push(runId, point.longitude, point.latitude, point.timestamp || null, index);
    });

    await this.query(
      `INSERT INTO run_gps_points (run_id, longitude, latitude, timestamp, point_order)
       VALUES ${placeholders.join(', ')}`,
      values,
      client,
    );
  }

  /**
   * Get GPS points for a run
   */
  async getGpsPoints(runId: string): Promise<GpsPoint[]> {
    const rows = await this.queryMany<GpsPointRow>(
      'SELECT * FROM run_gps_points WHERE run_id = $1 ORDER BY point_order',
      [runId],
    );

    return rows.map(row => ({
      longitude: row.longitude,
      latitude: row.latitude,
      timestamp: row.timestamp || undefined,
    }));
  }

  /**
   * Get runs for a client, accessible by their trainer
   * Returns runs with assignment info if linked
   */
  async findByClientForTrainer(
    trainerId: string,
    clientId: string,
    limit = 50,
    offset = 0,
  ): Promise<Array<Run & { assignmentId?: string; workoutTitle?: string }>> {
    const rows = await this.queryMany<
      RunRow & { assignment_id: string | null; workout_title: string | null }
    >(
      `SELECT r.*, r.assignment_id, w.name AS workout_title
       FROM runs r
       LEFT JOIN workout_assignments wa ON wa.id = r.assignment_id AND wa.trainer_id = $1
       LEFT JOIN workouts w ON w.id = wa.workout_id
       WHERE r.user_id = $2 AND r.status = 'completed'
       ORDER BY r.started_at DESC
       LIMIT $3 OFFSET $4`,
      [trainerId, clientId, limit, offset],
    );
    return rows.map(row => ({
      ...rowToRun(row),
      assignmentId: row.assignment_id ?? undefined,
      workoutTitle: row.workout_title ?? undefined,
    }));
  }

  /**
   * Get user statistics
   */
  async getLastRun(userId: string): Promise<{
    id: string; started_at: string; status: string; distance: number;
  } | null> {
    return this.queryOne<{ id: string; started_at: string; status: string; distance: number }>(
      `SELECT id, started_at, status, distance FROM runs WHERE user_id = $1 ORDER BY started_at DESC LIMIT 1`,
      [userId],
    );
  }

  /**
   * Get completed runs for a user in a given month (UTC)
   */
  async getRunsForMonth(
    userId: string,
    year: number,
    month: number,
  ): Promise<Array<{ id: string; date: string; distanceM: number; durationS: number }>> {
    const startDate = new Date(Date.UTC(year, month - 1, 1));
    const endDate = new Date(Date.UTC(year, month, 1));
    const rows = await this.queryMany<{
      id: string;
      started_at: Date;
      distance: number;
      duration: number;
    }>(
      `SELECT id, started_at, distance, duration
       FROM runs
       WHERE user_id = $1
         AND status = 'completed'
         AND started_at >= $2
         AND started_at < $3
       ORDER BY started_at ASC`,
      [userId, startDate, endDate],
    );
    return rows.map(row => ({
      id: row.id,
      date: row.started_at.toISOString().slice(0, 10),
      distanceM: row.distance,
      durationS: row.duration,
    }));
  }

  async getUserStats(userId: string): Promise<{
    totalRuns: number;
    totalDistance: number;
    totalDuration: number;
    averagePace: number; // seconds per km
  }> {
    const result = await this.queryOne<{
      total_runs: string;
      total_distance: string;
      total_duration: string;
    }>(
      `SELECT 
        COUNT(*) as total_runs,
        COALESCE(SUM(distance), 0) as total_distance,
        COALESCE(SUM(duration), 0) as total_duration
       FROM runs 
       WHERE user_id = $1 AND status = 'completed'`,
      [userId],
    );

    const totalRuns = parseInt(result?.total_runs || '0', 10);
    const totalDistance = parseInt(result?.total_distance || '0', 10);
    const totalDuration = parseInt(result?.total_duration || '0', 10);

    // Average pace in seconds per km
    const averagePace = totalDistance > 0 ? Math.round((totalDuration / totalDistance) * 1000) : 0;

    return {
      totalRuns,
      totalDistance,
      totalDuration,
      averagePace,
    };
  }
}

// Singleton instance
let instance: RunsRepository | null = null;

export function getRunsRepository(): RunsRepository {
  if (!instance) {
    instance = new RunsRepository();
  }
  return instance;
}
