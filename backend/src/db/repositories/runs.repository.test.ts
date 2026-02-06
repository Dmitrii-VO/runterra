/**
 * Unit tests for RunsRepository validation and run business rules.
 * validateRun is pure logic (no DB). Mocks: DB for create path only.
 */

import { RunStatus } from '../../modules/runs/run.type';
import { RunsRepository, getRunsRepository } from './runs.repository';
import type { GpsPoint } from '../../modules/runs/run.entity';

const mockQuery = jest.fn();
jest.mock('../client', () => ({
  getDbPool: () => null,
  createDbPool: () => ({ query: mockQuery, on: () => {} }),
}));

describe('RunsRepository', () => {
  let repo: RunsRepository;

  beforeAll(() => {
    repo = getRunsRepository();
  });

  beforeEach(() => {
    mockQuery.mockReset();
  });

  describe('validateRun', () => {
    const baseData = {
      startedAt: new Date('2025-06-01T10:00:00Z'),
      endedAt: new Date('2025-06-01T10:05:00Z'),
      duration: 300,
      distance: 1000,
    };

    it('should return valid when distance >= 100m, duration >= 30s, speed <= 30 km/h', () => {
      const result = repo.validateRun(baseData);

      expect(result.valid).toBe(true);
      expect(result.status).toBe(RunStatus.COMPLETED);
      expect(result.errors).toHaveLength(0);
    });

    it('should return invalid when distance is too short (< 100m)', () => {
      const result = repo.validateRun({
        ...baseData,
        distance: 50,
      });

      expect(result.valid).toBe(false);
      expect(result.status).toBe(RunStatus.INVALID);
      expect(result.errors.some((e) => e.includes('Distance too short'))).toBe(true);
      expect(result.errors.some((e) => e.includes('100'))).toBe(true);
    });

    it('should return invalid when duration is too short (< 30s)', () => {
      const result = repo.validateRun({
        ...baseData,
        duration: 20,
        endedAt: new Date('2025-06-01T10:00:20Z'),
      });

      expect(result.valid).toBe(false);
      expect(result.status).toBe(RunStatus.INVALID);
      expect(result.errors.some((e) => e.includes('Duration too short'))).toBe(true);
    });

    it('should return invalid when speed is too high (> 30 km/h)', () => {
      // 10 km in 300 s = 120 km/h
      const result = repo.validateRun({
        ...baseData,
        distance: 10000,
      });

      expect(result.valid).toBe(false);
      expect(result.status).toBe(RunStatus.INVALID);
      expect(result.errors.some((e) => e.includes('Speed too high'))).toBe(true);
      expect(result.errors.some((e) => e.includes('30'))).toBe(true);
    });

    it('should return invalid when end time is not after start time', () => {
      const result = repo.validateRun({
        ...baseData,
        endedAt: baseData.startedAt,
      });

      expect(result.valid).toBe(false);
      expect(result.errors.some((e) => e.includes('End time must be after start time'))).toBe(true);
    });

    it('should return invalid when duration does not match start/end diff (tolerance 5s)', () => {
      const result = repo.validateRun({
        startedAt: new Date('2025-06-01T10:00:00Z'),
        endedAt: new Date('2025-06-01T10:05:00Z'),
        duration: 200,
        distance: 1000,
      });

      expect(result.valid).toBe(false);
      expect(result.errors.some((e) => e.includes('Duration mismatch'))).toBe(true);
    });

    it('should return valid when speed is just under 30 km/h', () => {
      // ~29.9 km/h: 2490m in 300s to avoid float boundary (code uses > 30)
      const result = repo.validateRun({
        ...baseData,
        distance: 2490,
      });

      expect(result.valid).toBe(true);
      expect(result.status).toBe(RunStatus.COMPLETED);
    });
  });

  describe('create with gpsPoints (bulk insert)', () => {
    it('should build correct bulk-insert query for 2 GPS points', async () => {
      const startedAt = new Date('2025-06-01T10:00:00Z');
      const endedAt = new Date('2025-06-01T10:05:00Z');
      const runId = 'run-123';

      // Mock DB responses: first call returns inserted run row, subsequent calls return empty result
      mockQuery
        .mockResolvedValueOnce({
          rows: [
            {
              id: runId,
              user_id: 'user-1',
              activity_id: null,
              started_at: startedAt,
              ended_at: endedAt,
              duration: 300,
              distance: 1000,
              status: RunStatus.COMPLETED,
              created_at: startedAt,
              updated_at: startedAt,
            },
          ],
        } as any)
        .mockResolvedValue({
          rows: [],
        } as any);

      const gpsPoints: GpsPoint[] = [
        {
          longitude: 30.0,
          latitude: 59.0,
          timestamp: new Date('2025-06-01T10:00:01Z'),
        },
        {
          longitude: 30.1,
          latitude: 59.1,
          timestamp: new Date('2025-06-01T10:00:02Z'),
        },
      ];

      await repo.create({
        userId: 'user-1',
        startedAt,
        endedAt,
        duration: 300,
        distance: 1000,
        gpsPoints,
      });

      // First call: INSERT INTO runs, second call: INSERT INTO run_gps_points
      expect(mockQuery).toHaveBeenCalledTimes(2);

      const [sql, params] = mockQuery.mock.calls[1] as [string, unknown[]];
      expect(sql).toContain('INSERT INTO run_gps_points');
      // 2 points * 5 columns each
      expect(params).toHaveLength(10);

      // Expected params: [runId, lon1, lat1, ts1, 0, runId, lon2, lat2, ts2, 1]
      expect(params[0]).toBe(runId);
      expect(params[1]).toBe(30.0);
      expect(params[2]).toBe(59.0);
      expect(params[4]).toBe(0);

      expect(params[5]).toBe(runId);
      expect(params[6]).toBe(30.1);
      expect(params[7]).toBe(59.1);
      expect(params[9]).toBe(1);
    });
  });
});
