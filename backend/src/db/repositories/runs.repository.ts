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
  started_at: Date;
  ended_at: Date;
  duration: number;
  distance: number;
  status: string;
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
    startedAt: row.started_at,
    endedAt: row.ended_at,
    duration: row.duration,
    distance: row.distance,
    status: row.status as RunStatus,
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
    const row = await this.queryOne<RunRow>(
      'SELECT * FROM runs WHERE id = $1',
      [id]
    );
    return row ? rowToRun(row) : null;
  }

  async findByUserId(userId: string, limit = 50, offset = 0): Promise<Run[]> {
    const rows = await this.queryMany<RunRow>(
      `SELECT * FROM runs WHERE user_id = $1 
       ORDER BY started_at DESC LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
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
      errors.push(`Distance too short: ${data.distance}m, minimum: ${RunsRepository.MIN_DISTANCE_METERS}m`);
    }
    
    // Check minimum duration
    if (data.duration < RunsRepository.MIN_DURATION_SECONDS) {
      errors.push(`Duration too short: ${data.duration}s, minimum: ${RunsRepository.MIN_DURATION_SECONDS}s`);
    }
    
    // Check speed (distance in meters, duration in seconds)
    if (data.duration > 0) {
      const speedMs = data.distance / data.duration; // meters per second
      const speedKmh = speedMs * 3.6; // km/h
      
      if (speedKmh > RunsRepository.MAX_SPEED_KMH) {
        errors.push(`Speed too high: ${speedKmh.toFixed(1)} km/h, maximum: ${RunsRepository.MAX_SPEED_KMH} km/h`);
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
    if (durationDiff > 5) { // Allow 5 seconds tolerance
      errors.push(`Duration mismatch: provided ${data.duration}s, calculated ${calculatedDuration}s`);
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
  async create(data: {
    userId: string;
    activityId?: string;
    startedAt: Date;
    endedAt: Date;
    duration: number;
    distance: number;
    gpsPoints?: GpsPoint[];
  }): Promise<{ run: Run; validation: RunValidationResult }> {
    // Validate
    const validation = this.validateRun({
      duration: data.duration,
      distance: data.distance,
      startedAt: data.startedAt,
      endedAt: data.endedAt,
    });
    
    // Create run record
    const row = await this.queryOne<RunRow>(
      `INSERT INTO runs (user_id, activity_id, started_at, ended_at, duration, distance, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        data.userId,
        data.activityId || null,
        data.startedAt,
        data.endedAt,
        data.duration,
        data.distance,
        validation.status,
      ]
    );
    
    const run = rowToRun(row!);
    
    // Save GPS points if provided
    if (data.gpsPoints && data.gpsPoints.length > 0) {
      await this.saveGpsPoints(run.id, data.gpsPoints);
    }
    
    return { run, validation };
  }

  /**
   * Save GPS points for a run
   */
  private async saveGpsPoints(runId: string, points: GpsPoint[]): Promise<void> {
    if (points.length === 0) return;
    
    // Build bulk insert query
    const values: unknown[] = [];
    const placeholders: string[] = [];
    
    points.forEach((point, index) => {
      // 5 columns per row: run_id, longitude, latitude, timestamp, point_order
      const offset = index * 5;
      placeholders.push(`($${offset + 1}, $${offset + 2}, $${offset + 3}, $${offset + 4}, $${offset + 5})`);
      values.push(runId, point.longitude, point.latitude, point.timestamp || null, index);
    });
    
    await this.query(
      `INSERT INTO run_gps_points (run_id, longitude, latitude, timestamp, point_order)
       VALUES ${placeholders.join(', ')}`,
      values
    );
  }

  /**
   * Get GPS points for a run
   */
  async getGpsPoints(runId: string): Promise<GpsPoint[]> {
    const rows = await this.queryMany<GpsPointRow>(
      'SELECT * FROM run_gps_points WHERE run_id = $1 ORDER BY point_order',
      [runId]
    );
    
    return rows.map(row => ({
      longitude: row.longitude,
      latitude: row.latitude,
      timestamp: row.timestamp || undefined,
    }));
  }

  /**
   * Get user statistics
   */
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
      [userId]
    );
    
    const totalRuns = parseInt(result?.total_runs || '0', 10);
    const totalDistance = parseInt(result?.total_distance || '0', 10);
    const totalDuration = parseInt(result?.total_duration || '0', 10);
    
    // Average pace in seconds per km
    const averagePace = totalDistance > 0 
      ? Math.round((totalDuration / totalDistance) * 1000) 
      : 0;
    
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
