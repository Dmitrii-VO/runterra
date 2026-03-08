import request from 'supertest';
import { createApp } from '../app';
import { getAuthProvider } from '../modules/auth';

// Mock the repositories module
jest.mock('../modules/auth');
jest.mock('../db/repositories');

const app = createApp();

const TEST_CLUB_1 = '550e8400-e29b-41d4-a716-446655440001';
const TEST_WORKOUT_ID = '660e8400-e29b-41d4-a716-446655440001';
const TEST_TRAINER_ID = '770e8400-e29b-41d4-a716-446655440001';

/**
 * PATCH /api/events/:id tests
 *
 * Tests the trainer field update endpoint on events:
 * - 200 with workoutId
 * - 200 with trainerId (when user is leader)
 * - 403 when trainerId set by non-leader
 * - 400 when event is not club type
 * - 404 when event not found
 */
describe('PATCH /api/events/:id', () => {
  const originalEnv = process.env.NODE_ENV;

  beforeAll(() => {
    process.env.NODE_ENV = 'test';
  });

  afterAll(() => {
    process.env.NODE_ENV = originalEnv;
  });

  const {
    mockUsersRepository,
    mockEventsRepository,
    mockClubMembersRepository,
    mockWorkoutsRepository,
  } = require('../db/repositories');

  const mockClubEvent = {
    id: 'event-1',
    name: 'Club Training',
    type: 'training',
    status: 'open',
    startDateTime: new Date(),
    startLocation: { longitude: 30.3351, latitude: 59.9343 },
    locationName: 'Test Park',
    organizerId: TEST_CLUB_1,
    organizerType: 'club' as const,
    difficultyLevel: 'intermediate' as const,
    description: 'Club event',
    participantLimit: 20,
    participantCount: 5,
    territoryId: 'territory-1',
    cityId: 'spb',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockUserEvent = {
    ...mockClubEvent,
    id: 'event-user',
    organizerId: 'user-1',
    organizerType: 'trainer' as const,
  };

  beforeEach(() => {
    (getAuthProvider as jest.Mock).mockReturnValue({
      verifyToken: jest.fn().mockResolvedValue({
        valid: true,
        user: { uid: 'uid-1', email: 'test@example.com' },
      }),
    });
    mockUsersRepository.findByFirebaseUid.mockClear();
    mockEventsRepository.findById.mockClear();
    mockEventsRepository.update.mockClear();
    mockEventsRepository.updateTrainerFields.mockClear();
    mockClubMembersRepository.findByClubAndUser.mockClear();
    mockClubMembersRepository.findActiveClubsByUser.mockClear();
    mockWorkoutsRepository.findById.mockClear();

    // Default: user exists
    mockUsersRepository.findByFirebaseUid.mockResolvedValue({
      id: 'user-1',
      firebaseUid: 'uid-1',
      email: 'test@example.com',
      name: 'Test User',
    });
    mockClubMembersRepository.findActiveClubsByUser.mockResolvedValue([
      {
        clubId: TEST_CLUB_1,
        clubName: 'Club A',
        clubCityId: 'spb',
        clubStatus: 'active',
        role: 'trainer',
        joinedAt: new Date(),
      },
    ]);
  });

  it('returns 200 when workoutId is set by trainer', async () => {
    mockEventsRepository.findById.mockResolvedValueOnce(mockClubEvent);

    // User is trainer in the club
    mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
      id: 'cm-1',
      clubId: TEST_CLUB_1,
      userId: 'user-1',
      status: 'active',
      role: 'trainer',
    });

    // Workout exists and belongs to the club
    mockWorkoutsRepository.findById.mockResolvedValueOnce({
      id: TEST_WORKOUT_ID,
      authorId: 'user-1',
      clubId: TEST_CLUB_1,
      name: 'Workout',
      type: 'TEMPO',
      difficulty: 'INTERMEDIATE',
      targetMetric: 'DISTANCE',
      createdAt: new Date(),
    });

    const updatedEvent = { ...mockClubEvent, workoutId: TEST_WORKOUT_ID };
    mockEventsRepository.update.mockResolvedValueOnce(updatedEvent);

    const res = await request(app)
      .patch('/api/events/event-1')
      .set('Authorization', 'Bearer test-token')
      .send({ workoutId: TEST_WORKOUT_ID });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('workoutId', TEST_WORKOUT_ID);
    expect(mockEventsRepository.update).toHaveBeenCalledWith(
      'event-1',
      expect.objectContaining({ workoutId: TEST_WORKOUT_ID }),
    );
  });

  it('returns 200 when trainerId is set by leader', async () => {
    mockEventsRepository.findById.mockResolvedValueOnce(mockClubEvent);

    // First call: isTrainerOrLeaderInClub check — user is leader
    // Second call: isLeaderInClub check — user is leader
    // Third call: isTrainerOrLeaderInClub for the target trainer
    mockClubMembersRepository.findByClubAndUser
      .mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
        role: 'leader',
      })
      .mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
        role: 'leader',
      })
      .mockResolvedValueOnce({
        id: 'cm-2',
        clubId: TEST_CLUB_1,
        userId: TEST_TRAINER_ID,
        status: 'active',
        role: 'trainer',
      });

    const updatedEvent = { ...mockClubEvent, trainerId: TEST_TRAINER_ID };
    mockEventsRepository.update.mockResolvedValueOnce(updatedEvent);

    const res = await request(app)
      .patch('/api/events/event-1')
      .set('Authorization', 'Bearer test-token')
      .send({ trainerId: TEST_TRAINER_ID });

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('trainerId', TEST_TRAINER_ID);
  });

  it('returns 403 when trainerId is set by non-leader (trainer role)', async () => {
    mockEventsRepository.findById.mockResolvedValueOnce(mockClubEvent);

    // First call: isTrainerOrLeaderInClub — user is trainer (passes)
    // Second call: isLeaderInClub — user is trainer, not leader (fails)
    mockClubMembersRepository.findByClubAndUser
      .mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
        role: 'trainer',
      })
      .mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
        role: 'trainer',
      });

    const res = await request(app)
      .patch('/api/events/event-1')
      .set('Authorization', 'Bearer test-token')
      .send({ trainerId: TEST_TRAINER_ID });

    expect(res.status).toBe(403);
    expect(res.body).toHaveProperty('code', 'forbidden');
    expect(res.body.message).toMatch(/leader/i);
    expect(mockEventsRepository.updateTrainerFields).not.toHaveBeenCalled();
  });

  it('returns 400 when event is not a club event', async () => {
    mockEventsRepository.findById.mockResolvedValueOnce(mockUserEvent);

    const res = await request(app)
      .patch('/api/events/event-user')
      .set('Authorization', 'Bearer test-token')
      .send({ workoutId: TEST_WORKOUT_ID });

    expect(res.status).toBe(400);
    expect(res.body).toHaveProperty('code', 'validation_error');
    expect(res.body.message).toMatch(/club/i);
    expect(mockEventsRepository.updateTrainerFields).not.toHaveBeenCalled();
    expect(mockEventsRepository.update).not.toHaveBeenCalled();
  });

  it('returns 404 when event is not found', async () => {
    mockEventsRepository.findById.mockResolvedValueOnce(null);

    const res = await request(app)
      .patch('/api/events/nonexistent')
      .set('Authorization', 'Bearer test-token')
      .send({ workoutId: TEST_WORKOUT_ID });

    expect(res.status).toBe(404);
    expect(res.body).toHaveProperty('code', 'not_found');
    expect(mockEventsRepository.updateTrainerFields).not.toHaveBeenCalled();
    expect(mockEventsRepository.update).not.toHaveBeenCalled();
  });

  it('returns 403 when user is not trainer or leader in the organizing club', async () => {
    mockEventsRepository.findById.mockResolvedValueOnce(mockClubEvent);
    mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
      id: 'cm-1',
      clubId: TEST_CLUB_1,
      userId: 'user-1',
      status: 'active',
      role: 'member',
    });

    const res = await request(app)
      .patch('/api/events/event-1')
      .set('Authorization', 'Bearer test-token')
      .send({ workoutId: TEST_WORKOUT_ID });

    expect(res.status).toBe(403);
    expect(res.body).toHaveProperty('code', 'forbidden');
  });

  it('returns 403 when trainer event organizer is no longer an active approved trainer', async () => {
    mockEventsRepository.findById.mockResolvedValueOnce(mockUserEvent);
    mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([]);

    const res = await request(app)
      .patch('/api/events/event-user')
      .set('Authorization', 'Bearer test-token')
      .send({ name: 'Updated Trainer Event' });

    expect(res.status).toBe(403);
    expect(res.body).toHaveProperty('code', 'forbidden');
    expect(res.body.message).toMatch(/active approved trainer organizer/i);
    expect(mockEventsRepository.update).not.toHaveBeenCalled();
  });
});
