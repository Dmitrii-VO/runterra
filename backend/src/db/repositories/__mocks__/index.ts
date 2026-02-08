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
  firstName: 'Test',
  lastName: 'User',
  birthDate: '1994-02-03',
  country: 'RU',
  gender: 'male' as const,
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
  cityId: 'spb',
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

const mockClub = {
  id: 'club-1',
  name: 'Test Club',
  description: 'Test club description',
  status: 'active',
  cityId: 'spb',
  creatorId: 'test-user-id',
  createdAt: new Date(),
  updatedAt: new Date(),
};

// Mock UsersRepository
export const mockUsersRepository = {
  findById: jest.fn().mockResolvedValue(mockUser),
  findByIds: jest.fn().mockResolvedValue([mockUser]),
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
  leaveEvent: jest.fn().mockResolvedValue({ participant: { ...mockParticipant, status: 'cancelled' as const } }),
  checkIn: jest.fn().mockResolvedValue({ participant: { ...mockParticipant, status: 'checked_in' as const } }),
  getParticipant: jest.fn().mockResolvedValue(null),
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

export const mockClubMembersRepository = {
  findByClubAndUser: jest.fn().mockResolvedValue(null),
  create: jest.fn().mockResolvedValue({ id: 'cm-1', clubId: '1', userId: 'test-user-id', status: 'active', role: 'member', createdAt: new Date(), updatedAt: new Date() }),
  deactivate: jest.fn().mockResolvedValue({ id: 'cm-1', clubId: '1', userId: 'test-user-id', status: 'inactive', role: 'member', createdAt: new Date(), updatedAt: new Date() }),
  activate: jest.fn().mockResolvedValue({ id: 'cm-1', clubId: '1', userId: 'test-user-id', status: 'active', role: 'member', createdAt: new Date(), updatedAt: new Date() }),
  findPrimaryClubIdByUser: jest.fn().mockResolvedValue(null),
  countActiveMembers: jest.fn().mockResolvedValue(5),
  findActiveByUser: jest.fn().mockResolvedValue([]),
  findActiveClubsByUser: jest.fn().mockResolvedValue([]),
};

export const mockClubsRepository = {
  findById: jest.fn().mockResolvedValue(mockClub),
  findByIds: jest.fn().mockResolvedValue([mockClub]),
  findByCityId: jest.fn().mockResolvedValue([mockClub]),
  create: jest.fn().mockResolvedValue(mockClub),
  update: jest.fn().mockResolvedValue(mockClub),
  delete: jest.fn().mockResolvedValue(true),
};

export const mockMessagesRepository = {
  findByChannel: jest.fn().mockResolvedValue([]),
  create: jest.fn().mockResolvedValue({ id: 'msg-1', channelType: 'club', channelId: 'club-1', userId: 'test-user-id', text: 'hello', createdAt: new Date(), updatedAt: new Date() }),
  getClubChatsForUser: jest.fn().mockResolvedValue([]),
};

// Getter functions
export const getUsersRepository = jest.fn(() => mockUsersRepository);
export const getEventsRepository = jest.fn(() => mockEventsRepository);
export const getRunsRepository = jest.fn(() => mockRunsRepository);
export const getClubMembersRepository = jest.fn(() => mockClubMembersRepository);
export const getClubsRepository = jest.fn(() => mockClubsRepository);
export const getMessagesRepository = jest.fn(() => mockMessagesRepository);

// Re-export classes (not used in mocks but needed for type compatibility)
export class BaseRepository {}
export class UsersRepository {}
export class EventsRepository {}
export class RunsRepository {}
export class ClubMembersRepository {}
export class ClubsRepository {}
export class MessagesRepository {}
export type EventParticipant = { id: string };
export type RunValidationResult = { valid: boolean };
export type ClubMembershipRow = { id: string; clubId: string; userId: string; status: string };
export type ActiveUserClubMembershipRow = { clubId: string; clubName: string; clubCityId: string; clubStatus: string; role: string; joinedAt: Date };
