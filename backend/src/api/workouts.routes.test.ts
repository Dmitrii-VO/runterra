import request from 'supertest';
import { createApp } from '../app';
import { getAuthProvider } from '../modules/auth';

// Mock the repositories module
jest.mock('../modules/auth');
jest.mock('../db/repositories');
jest.mock('../db/repositories/workout_shares.repository');

const app = createApp();

const TEST_CLUB_1 = '550e8400-e29b-41d4-a716-446655440001';

/**
 * Workout CRUD tests
 *
 * Tests workout endpoints:
 * - GET /api/workouts — personal workouts
 * - GET /api/workouts?clubId=X — club workouts
 * - GET /api/workouts/:id — single workout
 * - POST /api/workouts — create
 * - PATCH /api/workouts/:id — update (author only)
 * - DELETE /api/workouts/:id — delete (no upcoming events)
 */
describe('Workouts Routes', () => {
  const originalEnv = process.env.NODE_ENV;

  beforeAll(() => {
    process.env.NODE_ENV = 'test';
  });

  afterAll(() => {
    process.env.NODE_ENV = originalEnv;
  });

  const {
    mockUsersRepository,
    mockWorkoutsRepository,
    mockClubMembersRepository,
    mockTrainerGroupsRepository,
  } = require('../db/repositories');

  const {
    mockWorkoutSharesRepository,
  } = require('../db/repositories/workout_shares.repository');

  const mockWorkout = {
    id: 'workout-1',
    authorId: 'user-1',
    clubId: undefined,
    name: 'Morning Tempo',
    description: 'A tempo run',
    type: 'TEMPO',
    difficulty: 'INTERMEDIATE',
    targetMetric: 'DISTANCE',
    createdAt: new Date(),
  };

  const mockClubWorkout = {
    ...mockWorkout,
    id: 'workout-club-1',
    clubId: TEST_CLUB_1,
  };

  beforeEach(() => {
    (getAuthProvider as jest.Mock).mockReturnValue({
      verifyToken: jest.fn().mockResolvedValue({
        valid: true,
        user: { uid: 'uid-1', email: 'test@example.com' },
      }),
    });
    mockUsersRepository.findByFirebaseUid.mockClear();
    mockWorkoutsRepository.findById.mockClear();
    mockWorkoutsRepository.findByAuthor.mockClear();
    mockWorkoutsRepository.findByClub.mockClear();
    mockWorkoutsRepository.create.mockClear();
    mockWorkoutsRepository.update.mockClear();
    mockWorkoutsRepository.delete.mockClear();
    mockWorkoutsRepository.hasUpcomingEvents.mockClear();
    mockWorkoutsRepository.assignToClients.mockClear();
    mockWorkoutsRepository.findPersonalByAuthor.mockClear();
    mockWorkoutsRepository.findTemplatesByAuthor.mockClear();
    mockWorkoutsRepository.toggleFavorite.mockClear();
    mockClubMembersRepository.findByClubAndUser.mockClear();
    mockClubMembersRepository.findActiveClubsByUser.mockClear();
    mockTrainerGroupsRepository.findById.mockClear();
    mockTrainerGroupsRepository.findMemberIds.mockClear();
    mockWorkoutSharesRepository.share.mockClear();
    mockWorkoutSharesRepository.findReceivedByUser.mockClear();
    mockWorkoutSharesRepository.accept.mockClear();

    // Default: user exists
    mockUsersRepository.findByFirebaseUid.mockResolvedValue({
      id: 'user-1',
      firebaseUid: 'uid-1',
      email: 'test@example.com',
      name: 'Test User',
    });
    // Default: user has trainer role in an active club.
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

  describe('GET /api/workouts', () => {
    it('returns personal workouts when no clubId query', async () => {
      mockWorkoutsRepository.findByAuthor.mockResolvedValueOnce([mockWorkout]);

      const res = await request(app).get('/api/workouts').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toHaveLength(1);
      expect(res.body[0]).toHaveProperty('id', 'workout-1');
      expect(mockWorkoutsRepository.findByAuthor).toHaveBeenCalledWith('user-1');
    });

    it('returns club workouts when clubId is provided and user is member', async () => {
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
        role: 'member',
      });
      mockWorkoutsRepository.findByClub.mockResolvedValueOnce([mockClubWorkout]);

      const res = await request(app)
        .get(`/api/workouts?clubId=${TEST_CLUB_1}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toHaveLength(1);
      expect(res.body[0]).toHaveProperty('clubId', TEST_CLUB_1);
      expect(mockWorkoutsRepository.findByClub).toHaveBeenCalledWith(TEST_CLUB_1);
    });

    it('returns 403 when user is not a member of the club', async () => {
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce(null);

      const res = await request(app)
        .get(`/api/workouts?clubId=${TEST_CLUB_1}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
    });

    it('returns personal workouts for any authenticated user regardless of role', async () => {
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        {
          clubId: TEST_CLUB_1,
          clubName: 'Club A',
          clubCityId: 'spb',
          clubStatus: 'active',
          role: 'member',
          joinedAt: new Date(),
        },
      ]);
      mockWorkoutsRepository.findByAuthor.mockResolvedValueOnce([mockWorkout]);

      const res = await request(app).get('/api/workouts').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(mockWorkoutsRepository.findByAuthor).toHaveBeenCalledWith('user-1');
    });
  });

  describe('GET /api/workouts/:id', () => {
    it('returns single workout when user is author', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);

      const res = await request(app)
        .get('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('id', 'workout-1');
      expect(res.body).toHaveProperty('name', 'Morning Tempo');
    });

    it('returns 404 when workout does not exist', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(null);

      const res = await request(app)
        .get('/api/workouts/nonexistent')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });

    it('returns 403 when user is not author and not club member', async () => {
      const otherUserWorkout = { ...mockWorkout, authorId: 'other-user' };
      mockWorkoutsRepository.findById.mockResolvedValueOnce(otherUserWorkout);

      const res = await request(app)
        .get('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
    });

    it('returns personal workout for author regardless of club role', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);

      const res = await request(app)
        .get('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('id', 'workout-1');
    });
  });

  describe('POST /api/workouts', () => {
    const validBody = {
      name: 'New Workout',
      type: 'TEMPO',
      difficulty: 'INTERMEDIATE',
      targetMetric: 'DISTANCE',
    };

    it('returns 201 when workout is created', async () => {
      // User is trainer in a club
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        {
          clubId: 'club-1',
          clubName: 'Club A',
          clubCityId: 'spb',
          clubStatus: 'active',
          role: 'trainer',
          joinedAt: new Date(),
        },
      ]);
      mockWorkoutsRepository.create.mockResolvedValueOnce({
        ...mockWorkout,
        name: 'New Workout',
        targetValue: 5000,
        targetZone: 'Z2',
      });

      const res = await request(app)
        .post('/api/workouts')
        .set('Authorization', 'Bearer test-token')
        .send({ ...validBody, targetValue: 5000, targetZone: 'Z2' });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('name', 'New Workout');
      expect(res.body).toHaveProperty('targetValue', 5000);
      expect(res.body).toHaveProperty('targetZone', 'Z2');
      expect(mockWorkoutsRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          authorId: 'user-1',
          name: 'New Workout',
          type: 'TEMPO',
          difficulty: 'INTERMEDIATE',
          targetMetric: 'DISTANCE',
          targetValue: 5000,
          targetZone: 'Z2',
        }),
      );
    });

    it('returns 201 when any authenticated user creates a personal workout', async () => {
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        {
          clubId: 'club-1',
          clubName: 'Club A',
          clubCityId: 'spb',
          clubStatus: 'active',
          role: 'member',
          joinedAt: new Date(),
        },
      ]);
      mockWorkoutsRepository.create.mockResolvedValueOnce({ ...mockWorkout, name: 'New Workout' });

      const res = await request(app)
        .post('/api/workouts')
        .set('Authorization', 'Bearer test-token')
        .send(validBody);

      expect(res.status).toBe(201);
      expect(mockWorkoutsRepository.create).toHaveBeenCalled();
    });

    it('returns 403 when non-trainer creates a club workout', async () => {
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
        role: 'member',
      });

      const res = await request(app)
        .post('/api/workouts')
        .set('Authorization', 'Bearer test-token')
        .send({ ...validBody, clubId: TEST_CLUB_1 });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(mockWorkoutsRepository.create).not.toHaveBeenCalled();
    });

    it('returns 400 when body validation fails', async () => {
      const res = await request(app)
        .post('/api/workouts')
        .set('Authorization', 'Bearer test-token')
        .send({ name: 'Missing fields' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
    });

    it('returns 201 when creating INTERVALS workout with interval_config block', async () => {
      mockWorkoutsRepository.create.mockResolvedValueOnce({
        ...mockWorkout,
        type: 'INTERVALS',
        blocks: [{ type: 'interval_config', reps: 5, distanceM: 400, restDistanceM: 100 }],
      });

      const res = await request(app)
        .post('/api/workouts')
        .set('Authorization', 'Bearer test-token')
        .send({
          name: 'Intervals 5x400m',
          type: 'INTERVALS',
          difficulty: 'INTERMEDIATE',
          targetMetric: 'DISTANCE',
          blocks: [{ type: 'interval_config', reps: 5, distanceM: 400, restDistanceM: 100 }],
        });

      expect(res.status).toBe(201);
      expect(mockWorkoutsRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'INTERVALS' }),
      );
    });
  });

  describe('PATCH /api/workouts/:id', () => {
    it('returns 200 when author updates workout', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
      mockWorkoutsRepository.update.mockResolvedValueOnce({
        ...mockWorkout,
        name: 'Updated Name',
        targetValue: 6000,
      });

      const res = await request(app)
        .patch('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token')
        .send({ name: 'Updated Name', targetValue: 6000 });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('name', 'Updated Name');
      expect(res.body).toHaveProperty('targetValue', 6000);
      expect(mockWorkoutsRepository.update).toHaveBeenCalledWith(
        'workout-1',
        expect.objectContaining({ name: 'Updated Name', targetValue: 6000 }),
      );
    });

    it('returns 403 when non-author tries to update', async () => {
      const otherUserWorkout = { ...mockWorkout, authorId: 'other-user' };
      mockWorkoutsRepository.findById.mockResolvedValueOnce(otherUserWorkout);

      const res = await request(app)
        .patch('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token')
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(mockWorkoutsRepository.update).not.toHaveBeenCalled();
    });

    it('returns 404 when workout does not exist', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(null);

      const res = await request(app)
        .patch('/api/workouts/nonexistent')
        .set('Authorization', 'Bearer test-token')
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });

    it('returns 200 when author updates personal workout regardless of club role', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
      mockWorkoutsRepository.update.mockResolvedValueOnce({ ...mockWorkout, name: 'Updated Name' });

      const res = await request(app)
        .patch('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token')
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('name', 'Updated Name');
      expect(mockWorkoutsRepository.update).toHaveBeenCalled();
    });

    it('returns 403 when author is trainer in another club but not in the workout club', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockClubWorkout);
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce(null);

      const res = await request(app)
        .patch('/api/workouts/workout-club-1')
        .set('Authorization', 'Bearer test-token')
        .send({ name: 'Updated Name' });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(mockWorkoutsRepository.update).not.toHaveBeenCalled();
    });
  });

  describe('DELETE /api/workouts/:id', () => {
    it('returns 200 when workout is deleted', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
      mockWorkoutsRepository.hasUpcomingEvents.mockResolvedValueOnce(false);
      mockWorkoutsRepository.delete.mockResolvedValueOnce(true);

      const res = await request(app)
        .delete('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('success', true);
      expect(mockWorkoutsRepository.delete).toHaveBeenCalledWith('workout-1');
    });

    it('returns 409 when workout has upcoming events', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
      mockWorkoutsRepository.hasUpcomingEvents.mockResolvedValueOnce(true);

      const res = await request(app)
        .delete('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(409);
      expect(res.body).toHaveProperty('code', 'workout_in_use');
      expect(res.body).toHaveProperty('message', 'Workout is linked to upcoming events');
      expect(mockWorkoutsRepository.delete).not.toHaveBeenCalled();
    });

    it('returns 403 when non-author tries to delete', async () => {
      const otherUserWorkout = { ...mockWorkout, authorId: 'other-user' };
      mockWorkoutsRepository.findById.mockResolvedValueOnce(otherUserWorkout);

      const res = await request(app)
        .delete('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(mockWorkoutsRepository.delete).not.toHaveBeenCalled();
    });

    it('returns 404 when workout does not exist', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(null);

      const res = await request(app)
        .delete('/api/workouts/nonexistent')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });

    it('returns 200 when author deletes personal workout regardless of club role', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
      mockWorkoutsRepository.hasUpcomingEvents.mockResolvedValueOnce(false);
      mockWorkoutsRepository.delete.mockResolvedValueOnce(true);

      const res = await request(app)
        .delete('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('success', true);
      expect(mockWorkoutsRepository.delete).toHaveBeenCalledWith('workout-1');
    });

    it('returns 403 when author is trainer elsewhere but not in the workout club', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockClubWorkout);
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce(null);

      const res = await request(app)
        .delete('/api/workouts/workout-club-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(mockWorkoutsRepository.delete).not.toHaveBeenCalled();
    });
  });

  describe('POST /api/workouts/:id/assign-group', () => {
    it('returns 404 when trainer group is stale or inactive', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
      mockTrainerGroupsRepository.findById.mockResolvedValueOnce(null);

      const res = await request(app)
        .post('/api/workouts/workout-1/assign-group')
        .set('Authorization', 'Bearer test-token')
        .send({ groupId: '770e8400-e29b-41d4-a716-446655440001' });

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
      expect(mockWorkoutsRepository.assignToClients).not.toHaveBeenCalled();
    });
  });

  describe('GET /api/workouts/my', () => {
    it('returns personal workouts for authenticated user', async () => {
      const personalWorkout = { ...mockWorkout, isTemplate: false, isFavorite: false };
      mockWorkoutsRepository.findPersonalByAuthor.mockResolvedValueOnce([personalWorkout]);

      const res = await request(app)
        .get('/api/workouts/my')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toHaveLength(1);
      expect(mockWorkoutsRepository.findPersonalByAuthor).toHaveBeenCalledWith('user-1');
    });

    it('returns 401 without token', async () => {
      const res = await request(app).get('/api/workouts/my');
      expect(res.status).toBe(401);
    });
  });

  describe('GET /api/workouts/templates', () => {
    it('returns templates for authenticated user', async () => {
      const template = { ...mockWorkout, isTemplate: true, isFavorite: false };
      mockWorkoutsRepository.findTemplatesByAuthor.mockResolvedValueOnce([template]);

      const res = await request(app)
        .get('/api/workouts/templates')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(mockWorkoutsRepository.findTemplatesByAuthor).toHaveBeenCalledWith('user-1');
    });
  });

  describe('GET /api/workouts/shares/received', () => {
    it('returns received shares for authenticated user', async () => {
      mockWorkoutSharesRepository.findReceivedByUser.mockResolvedValueOnce([
        {
          id: 'share-1',
          workoutId: 'workout-1',
          senderId: 'user-2',
          recipientId: 'user-1',
          sharedAt: new Date(),
          accepted: false,
          senderName: 'Sender',
          workout: { ...mockWorkout },
        },
      ]);

      const res = await request(app)
        .get('/api/workouts/shares/received')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(mockWorkoutSharesRepository.findReceivedByUser).toHaveBeenCalledWith('user-1');
    });
  });

  describe('PATCH /api/workouts/:id/favorite', () => {
    it('returns updated workout when favorite toggled', async () => {
      const favWorkout = { ...mockWorkout, isTemplate: false, isFavorite: true };
      mockWorkoutsRepository.toggleFavorite.mockResolvedValueOnce(favWorkout);

      const res = await request(app)
        .patch('/api/workouts/workout-1/favorite')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('isFavorite', true);
      expect(mockWorkoutsRepository.toggleFavorite).toHaveBeenCalledWith('workout-1', 'user-1');
    });

    it('returns 404 when workout not found or not owned', async () => {
      mockWorkoutsRepository.toggleFavorite.mockResolvedValueOnce(null);

      const res = await request(app)
        .patch('/api/workouts/nonexistent/favorite')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });
  });

  describe('POST /api/workouts/:id/share', () => {
    it('shares workout with recipients', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
      mockWorkoutSharesRepository.share
        .mockResolvedValueOnce({ id: 'share-1', workoutId: 'workout-1', senderId: 'user-1', recipientId: 'user-2', sharedAt: new Date(), accepted: false });

      const res = await request(app)
        .post('/api/workouts/workout-1/share')
        .set('Authorization', 'Bearer test-token')
        .send({ recipientIds: ['550e8400-e29b-41d4-a716-446655440010'] });

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('ok', true);
      expect(mockWorkoutSharesRepository.share).toHaveBeenCalled();
    });

    it('returns 400 when recipientIds is missing', async () => {
      const res = await request(app)
        .post('/api/workouts/workout-1/share')
        .set('Authorization', 'Bearer test-token')
        .send({});

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
    });

    it('returns 403 when user is not the author', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce({ ...mockWorkout, authorId: 'other-user' });

      const res = await request(app)
        .post('/api/workouts/workout-1/share')
        .set('Authorization', 'Bearer test-token')
        .send({ recipientIds: ['550e8400-e29b-41d4-a716-446655440010'] });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
    });
  });

  describe('POST /api/workouts/shares/:shareId/accept', () => {
    it('accepts share and returns copied workout', async () => {
      const copiedWorkout = { ...mockWorkout, id: 'workout-copy-1', isTemplate: false, isFavorite: false };
      mockWorkoutSharesRepository.accept.mockResolvedValueOnce(copiedWorkout);

      const res = await request(app)
        .post('/api/workouts/shares/share-1/accept')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id', 'workout-copy-1');
      expect(mockWorkoutSharesRepository.accept).toHaveBeenCalledWith('share-1', 'user-1');
    });

    it('returns 404 when share not found', async () => {
      mockWorkoutSharesRepository.accept.mockRejectedValueOnce(new Error('Share not found'));

      const res = await request(app)
        .post('/api/workouts/shares/nonexistent/accept')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });

    it('returns 404 when share already accepted (idempotency)', async () => {
      mockWorkoutSharesRepository.accept.mockRejectedValueOnce(new Error('Share not found'));

      const res = await request(app)
        .post('/api/workouts/shares/share-already-accepted/accept')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });
  });
});
