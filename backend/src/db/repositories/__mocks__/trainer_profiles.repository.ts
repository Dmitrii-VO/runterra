/**
 * Mock for TrainerProfilesRepository
 *
 * Provides jest.fn() stubs for all repository methods.
 * Used via jest.mock('../db/repositories') which loads __mocks__/index.ts,
 * but can also be imported directly for isolated unit tests.
 */

export const mockTrainerProfilesRepository = {
  findByUserId: jest.fn().mockResolvedValue(null),
  create: jest.fn().mockResolvedValue({
    userId: 'test-user-id',
    bio: 'Test bio',
    specialization: ['GENERAL'],
    experienceYears: 5,
    certificates: [],
    createdAt: new Date(),
  }),
  update: jest.fn().mockResolvedValue({
    userId: 'test-user-id',
    bio: 'Updated bio',
    specialization: ['GENERAL'],
    experienceYears: 5,
    certificates: [],
    createdAt: new Date(),
  }),
};

export const getTrainerProfilesRepository = jest.fn(() => mockTrainerProfilesRepository);

export class TrainerProfilesRepository {}
