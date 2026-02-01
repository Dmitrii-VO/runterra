/**
 * Mock repositories for testing
 */

import { UserStatus } from '../../../modules/users';
import { EventStatus, EventType } from '../../../modules/events';

// Mock data
const mockUser = {
  id: 'test-user-id',
  firebaseUid: 'firebase-uid-1',
  email: 'test@example.com',
  name: 'Test User',
  avatarUrl: undefined,
  cityId: undefined,
  isMercenary: false,
  status: UserStatus.ACTIVE,
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockEvent = {
  id: 'test-event-id',
  name: 'Test Event',
  type: EventType.TRAINING,
  status: EventStatus.OPEN,
  startDateTime: new Date(),
  startLocation: { longitude: 30.3351, latitude: 59.9343 },
  locationName: 'Test Park',
  organizerId: 'club-1',
  organizerType: 'club' as const,
  difficultyLevel: 'intermediate' as const,
  description: 'Test description',
  participantLimit: 20,
  participantCount: 5,
  territoryId: 'territory-1',
  createdAt: new Date(),
  updatedAt: new Date(),
};

const mockParticipant = {
  id: 'p-1',
  eventId: 'test-event-id',
  userId: 'test-user-id',
  status: 'registered' as const,
  createdAt: new Date(),
};

const mockRunStats = {
  totalRuns: 10,
  totalDistance: 50000,
  totalDuration: 18000,
  avgPace: 360,
};

// Mock UsersRepository
export const mockUsersRepository = {
  findById: jest.fn().mockResolvedValue(mockUser),
  findByFirebaseUid: jest.fn().mockResolvedValue(mockUser),
  findAll: jest.fn().mockResolvedValue([mockUser]),
  create: jest.fn().mockResolvedValue(mockUser),
  update: jest.fn().mockResolvedValue(mockUser),
  findOrCreate: jest.fn().mockResolvedValue(mockUser),
  delete: jest.fn().mockResolvedValue(true),
};

// Mock EventsRepository
export const mockEventsRepository = {
  findById: jest.fn().mockResolvedValue(mockEvent),
  findAll: jest.fn().mockResolvedValue([mockEvent]),
  create: jest.fn().mockResolvedValue(mockEvent),
  joinEvent: jest.fn().mockResolvedValue({ participant: mockParticipant }),
  checkIn: jest.fn().mockResolvedValue({ participant: { ...mockParticipant, status: 'checked_in' as const } }),
  getParticipants: jest.fn().mockResolvedValue([]),
};

// Mock RunsRepository
export const mockRunsRepository = {
  findById: jest.fn().mockResolvedValue(null),
  findByUserId: jest.fn().mockResolvedValue([]),
  create: jest.fn().mockResolvedValue({ id: 'run-1' }),
  getUserStats: jest.fn().mockResolvedValue(mockRunStats),
  getGpsPoints: jest.fn().mockResolvedValue([]),
};

// Getter functions
export const getUsersRepository = jest.fn(() => mockUsersRepository);
export const getEventsRepository = jest.fn(() => mockEventsRepository);
export const getRunsRepository = jest.fn(() => mockRunsRepository);

// Re-export classes (not used in mocks but needed for type compatibility)
export class BaseRepository {}
export class UsersRepository {}
export class EventsRepository {}
export class RunsRepository {}
export type EventParticipant = { id: string };
export type RunValidationResult = { valid: boolean };
