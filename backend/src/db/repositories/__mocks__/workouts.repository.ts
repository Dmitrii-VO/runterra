/**
 * Mock for WorkoutsRepository
 *
 * Provides jest.fn() stubs for all repository methods.
 * Used via jest.mock('../db/repositories') which loads __mocks__/index.ts,
 * but can also be imported directly for isolated unit tests.
 */

export const mockWorkoutsRepository = {
  findById: jest.fn().mockResolvedValue(null),
  findByIds: jest.fn().mockResolvedValue(new Map()),
  findByAuthor: jest.fn().mockResolvedValue([]),
  findByClub: jest.fn().mockResolvedValue([]),
  create: jest.fn().mockResolvedValue({
    id: 'workout-1',
    authorId: 'test-user-id',
    clubId: undefined,
    name: 'Test Workout',
    description: 'Test description',
    type: 'TEMPO',
    difficulty: 'INTERMEDIATE',
    targetMetric: 'DISTANCE',
    createdAt: new Date(),
  }),
  update: jest.fn().mockResolvedValue({
    id: 'workout-1',
    authorId: 'test-user-id',
    clubId: undefined,
    name: 'Updated Workout',
    description: 'Updated description',
    type: 'TEMPO',
    difficulty: 'INTERMEDIATE',
    targetMetric: 'DISTANCE',
    createdAt: new Date(),
  }),
  delete: jest.fn().mockResolvedValue(true),
  hasUpcomingEvents: jest.fn().mockResolvedValue(false),
};

export const getWorkoutsRepository = jest.fn(() => mockWorkoutsRepository);

export class WorkoutsRepository {}
