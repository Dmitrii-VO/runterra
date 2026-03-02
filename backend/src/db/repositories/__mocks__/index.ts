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
  visibility: 'public' as const,
  startDateTime: new Date(),
  startLocation: { longitude: 30.3351, latitude: 59.9343 },
  locationName: 'Test Park',
  organizerId: 'a0000000-0000-4000-8000-000000000001',
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
  id: 'a0000000-0000-4000-8000-000000000001',
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
  leaveEvent: jest
    .fn()
    .mockResolvedValue({ participant: { ...mockParticipant, status: 'cancelled' as const } }),
  checkIn: jest
    .fn()
    .mockResolvedValue({ participant: { ...mockParticipant, status: 'checked_in' as const } }),
  getParticipant: jest.fn().mockResolvedValue(null),
  getParticipants: jest.fn().mockResolvedValue([]),
  update: jest.fn().mockResolvedValue(mockEvent),
  updateTrainerFields: jest.fn().mockResolvedValue(mockEvent),
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
  create: jest.fn().mockResolvedValue({
    id: 'cm-1',
    clubId: '1',
    userId: 'test-user-id',
    status: 'active',
    role: 'member',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  deactivate: jest.fn().mockResolvedValue({
    id: 'cm-1',
    clubId: '1',
    userId: 'test-user-id',
    status: 'inactive',
    role: 'member',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  activate: jest.fn().mockResolvedValue({
    id: 'cm-1',
    clubId: '1',
    userId: 'test-user-id',
    status: 'active',
    role: 'member',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  findPrimaryClubIdByUser: jest.fn().mockResolvedValue(null),
  countActiveMembers: jest.fn().mockResolvedValue(5),
  countActiveLeaders: jest.fn().mockResolvedValue(1),
  findActiveByUser: jest.fn().mockResolvedValue([]),
  findActiveClubsByUser: jest.fn().mockResolvedValue([]),
  updateRole: jest.fn().mockResolvedValue({
    id: 'cm-1',
    clubId: '1',
    userId: 'test-user-id',
    status: 'active',
    role: 'leader',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  updateRoleWithLeaderTransfer: jest.fn().mockResolvedValue({
    id: 'cm-1',
    clubId: '1',
    userId: 'test-user-id',
    status: 'active',
    role: 'leader',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  approveMembership: jest.fn().mockResolvedValue({
    id: 'cm-1',
    clubId: '1',
    userId: 'test-user-id',
    status: 'active',
    role: 'member',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  findMembersByClub: jest.fn().mockResolvedValue([]),
  findPendingByClub: jest.fn().mockResolvedValue([]),
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
  findByClubChannel: jest.fn().mockResolvedValue([]),
  findByClubChannelWithRole: jest.fn().mockResolvedValue([]),
  create: jest.fn().mockResolvedValue({
    id: 'msg-1',
    channelType: 'club',
    channelId: 'a0000000-0000-4000-8000-000000000001',
    userId: 'test-user-id',
    text: 'hello',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  getClubChatsForUser: jest.fn().mockResolvedValue([]),
  getTrainerClients: jest.fn().mockResolvedValue([]),
  getMyTrainer: jest.fn().mockResolvedValue(null),
  getDirectMessages: jest.fn().mockResolvedValue([]),
  insertDirectMessage: jest.fn().mockResolvedValue({
    id: 'dm-1',
    text: 'hi',
    userId: 'test-user-id',
    userName: 'Test',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }),
  hasTrainerClientRelationship: jest.fn().mockResolvedValue(false),
  getTrainerIdForPair: jest.fn().mockResolvedValue(null),
  hasDirectMessages: jest.fn().mockResolvedValue(false),
  addTrainerClient: jest.fn().mockResolvedValue(undefined),
  removeTrainerClient: jest.fn().mockResolvedValue(true),
  isTrainerClient: jest.fn().mockResolvedValue(false),
};

export const mockClubChannelsRepository = {
  findByClub: jest.fn().mockResolvedValue([]),
  findById: jest.fn().mockResolvedValue(null),
  findDefaultByClub: jest.fn().mockResolvedValue(null),
  create: jest.fn().mockResolvedValue({
    id: 'test-channel-id',
    clubId: 'a0000000-0000-4000-8000-000000000001',
    type: 'general',
    name: 'General',
    isDefault: true,
    createdAt: new Date(),
  }),
  createDefaultForClub: jest.fn().mockResolvedValue({
    id: 'test-channel-id',
    clubId: 'a0000000-0000-4000-8000-000000000001',
    type: 'general',
    name: 'General',
    isDefault: true,
    createdAt: new Date(),
  }),
};

// Mock TrainerProfilesRepository
export const mockTrainerProfilesRepository = {
  findByUserId: jest.fn().mockResolvedValue(null),
  create: jest.fn().mockResolvedValue({
    userId: 'test-user-id',
    bio: 'Test bio',
    specialization: ['GENERAL'],
    experienceYears: 5,
    certificates: [],
    acceptsPrivateClients: false,
    createdAt: new Date(),
  }),
  update: jest.fn().mockResolvedValue({
    userId: 'test-user-id',
    bio: 'Updated bio',
    specialization: ['GENERAL'],
    experienceYears: 5,
    certificates: [],
    acceptsPrivateClients: false,
    createdAt: new Date(),
  }),
  findPublicTrainers: jest.fn().mockResolvedValue([]),
};

// Mock WorkoutsRepository
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

// Mock TerritoriesRepository
export const mockTerritoriesRepository = {
  getSeasonStart: jest
    .fn()
    .mockReturnValue(new Date(Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), 1))),
  getTerritoryScores: jest.fn().mockResolvedValue([]),
  addRunContribution: jest.fn().mockResolvedValue(undefined),
};

// Getter functions
export const getUsersRepository = jest.fn(() => mockUsersRepository);
export const getEventsRepository = jest.fn(() => mockEventsRepository);
export const getRunsRepository = jest.fn(() => mockRunsRepository);
export const getClubMembersRepository = jest.fn(() => mockClubMembersRepository);
export const getClubsRepository = jest.fn(() => mockClubsRepository);
export const getMessagesRepository = jest.fn(() => mockMessagesRepository);
export const getClubChannelsRepository = jest.fn(() => mockClubChannelsRepository);
export const getTrainerProfilesRepository = jest.fn(() => mockTrainerProfilesRepository);
export const getWorkoutsRepository = jest.fn(() => mockWorkoutsRepository);
export const getTerritoriesRepository = jest.fn(() => mockTerritoriesRepository);

// Mock ActivitiesRepository (GET /api/activities uses findByUserId)
export const mockActivitiesRepository = {
  findById: jest.fn().mockResolvedValue(null),
  findByUserId: jest.fn().mockResolvedValue([]),
  create: jest.fn().mockResolvedValue({
    id: 'activity-1',
    userId: 'test-user-id',
    type: 'running',
    status: 'completed',
    name: 'Test Activity',
    description: undefined,
    scheduledItemId: undefined,
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
};
export const getActivitiesRepository = jest.fn(() => mockActivitiesRepository);

// Re-export classes (not used in mocks but needed for type compatibility)
export class BaseRepository {}
export class UsersRepository {}
export class EventsRepository {}
export class RunsRepository {}
export class ClubMembersRepository {}
export class ClubsRepository {}
export class MessagesRepository {}
export class ClubChannelsRepository {}
export class TrainerProfilesRepository {}
export class WorkoutsRepository {}
export class TerritoriesRepository {}
export class ActivitiesRepository {}
export type EventParticipant = { id: string };
export type RunValidationResult = { valid: boolean };
export type ClubMembershipRow = { id: string; clubId: string; userId: string; status: string };
export type ActiveUserClubMembershipRow = {
  clubId: string;
  clubName: string;
  clubCityId: string;
  clubStatus: string;
  role: string;
  joinedAt: Date;
};
export type ClubMemberDetailDto = {
  userId: string;
  displayName: string;
  role: string;
  joinedAt: Date;
};
