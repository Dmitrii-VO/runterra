import request from 'supertest';
import { createApp } from '../app';

// Mock the repositories module
jest.mock('../db/repositories');

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
  } = require('../db/repositories');

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
    mockUsersRepository.findByFirebaseUid.mockClear();
    mockWorkoutsRepository.findById.mockClear();
    mockWorkoutsRepository.findByAuthor.mockClear();
    mockWorkoutsRepository.findByClub.mockClear();
    mockWorkoutsRepository.create.mockClear();
    mockWorkoutsRepository.update.mockClear();
    mockWorkoutsRepository.delete.mockClear();
    mockWorkoutsRepository.hasUpcomingEvents.mockClear();
    mockClubMembersRepository.findByClubAndUser.mockClear();
    mockClubMembersRepository.findActiveClubsByUser.mockClear();

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

    it('returns 403 for personal workouts when user has only member role', async () => {
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

      const res = await request(app).get('/api/workouts').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(mockWorkoutsRepository.findByAuthor).not.toHaveBeenCalled();
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

    it('returns 403 for author personal workout when user has only member role', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
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

      const res = await request(app)
        .get('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
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

    it('returns 403 when user is not a trainer or leader', async () => {
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

      const res = await request(app)
        .post('/api/workouts')
        .set('Authorization', 'Bearer test-token')
        .send(validBody);

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

    it('returns 403 when author has only member role', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
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

      const res = await request(app)
        .patch('/api/workouts/workout-1')
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

    it('returns 403 when author has only member role', async () => {
      mockWorkoutsRepository.findById.mockResolvedValueOnce(mockWorkout);
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

      const res = await request(app)
        .delete('/api/workouts/workout-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(mockWorkoutsRepository.delete).not.toHaveBeenCalled();
    });
  });
});
