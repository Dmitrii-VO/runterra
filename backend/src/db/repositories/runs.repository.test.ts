/**
 * Unit tests for RunsRepository validation and run business rules.
 * validateRun is pure logic (no DB). Mocks: DB for create path only.
 */

import { RunStatus } from '../../modules/runs/run.type';
import { RunsRepository, getRunsRepository } from './runs.repository';

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
});
