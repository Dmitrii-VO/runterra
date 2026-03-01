import request from 'supertest';
import { createApp } from '../app';

// Mock the repositories module
jest.mock('../db/repositories');

const app = createApp();

/**
 * Trainer profile CRUD tests
 *
 * Tests trainer profile endpoints:
 * - GET /api/trainer             — public trainer discovery
 * - GET /api/trainer/profile     — own profile
 * - GET /api/trainer/profile/:userId — public view
 * - POST /api/trainer/profile    — create (any auth user with bio+specialization)
 * - PATCH /api/trainer/profile   — update own profile
 */
describe('Trainer Routes', () => {
  const originalEnv = process.env.NODE_ENV;
  const userId = '11111111-1111-1111-1111-111111111111';
  const otherUserId = '22222222-2222-2222-2222-222222222222';

  beforeAll(() => {
    process.env.NODE_ENV = 'test';
  });

  afterAll(() => {
    process.env.NODE_ENV = originalEnv;
  });

  const { mockUsersRepository, mockTrainerProfilesRepository } = require('../db/repositories');

  const mockProfile = {
    userId,
    bio: 'Experienced running coach',
    specialization: ['GENERAL'],
    experienceYears: 5,
    certificates: [],
    acceptsPrivateClients: false,
    createdAt: new Date(),
  };

  beforeEach(() => {
    mockUsersRepository.findByFirebaseUid.mockClear();
    mockTrainerProfilesRepository.findByUserId.mockClear();
    mockTrainerProfilesRepository.create.mockClear();
    mockTrainerProfilesRepository.update.mockClear();
    mockTrainerProfilesRepository.findPublicTrainers.mockClear();

    // Default: user exists
    mockUsersRepository.findByFirebaseUid.mockResolvedValue({
      id: userId,
      firebaseUid: 'uid-1',
      email: 'test@example.com',
      name: 'Test User',
    });
  });

  describe('GET /api/trainer', () => {
    it('returns 200 with array of public trainers', async () => {
      const publicTrainer = {
        userId,
        name: 'Test User',
        bio: 'Coach bio',
        specialization: ['GENERAL'],
        experienceYears: 5,
        acceptsPrivateClients: true,
      };
      mockTrainerProfilesRepository.findPublicTrainers.mockResolvedValueOnce([publicTrainer]);

      const res = await request(app).get('/api/trainer').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('userId', userId);
      expect(res.body[0]).toHaveProperty('acceptsPrivateClients', true);
    });

    it('returns 200 with empty array when no public trainers', async () => {
      mockTrainerProfilesRepository.findPublicTrainers.mockResolvedValueOnce([]);

      const res = await request(app).get('/api/trainer').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toEqual([]);
    });
  });

  describe('GET /api/trainer/profile', () => {
    it('returns 200 with profile when trainer profile exists', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(mockProfile);

      const res = await request(app)
        .get('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('userId', userId);
      expect(res.body).toHaveProperty('bio', 'Experienced running coach');
      expect(res.body).toHaveProperty('specialization');
      expect(res.body).toHaveProperty('experienceYears', 5);
      expect(res.body).toHaveProperty('acceptsPrivateClients', false);
    });

    it('returns 404 when no trainer profile exists', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(null);

      const res = await request(app)
        .get('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
      expect(res.body).toHaveProperty('message');
    });
  });

  describe('GET /api/trainer/profile/:userId', () => {
    it('returns 200 with public profile', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(mockProfile);

      const res = await request(app)
        .get(`/api/trainer/profile/${userId}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('userId', userId);
      expect(res.body).toHaveProperty('specialization');
    });

    it('returns 404 when profile does not exist', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(null);

      const res = await request(app)
        .get(`/api/trainer/profile/${otherUserId}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });

    it('returns 400 when userId is not a UUID', async () => {
      const res = await request(app)
        .get('/api/trainer/profile/edit')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(mockTrainerProfilesRepository.findByUserId).not.toHaveBeenCalled();
    });
  });

  describe('POST /api/trainer/profile', () => {
    const validBody = {
      specialization: ['GENERAL'],
      experienceYears: 5,
      bio: 'Coach bio',
    };

    it('returns 201 when trainer profile is created', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(null);
      mockTrainerProfilesRepository.create.mockResolvedValueOnce(mockProfile);

      const res = await request(app)
        .post('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send(validBody);

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('userId', userId);
      expect(mockTrainerProfilesRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          userId,
          specialization: ['GENERAL'],
          experienceYears: 5,
        }),
      );
    });

    it('returns 201 with acceptsPrivateClients when specified', async () => {
      const profileWithPrivate = { ...mockProfile, acceptsPrivateClients: true };
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(null);
      mockTrainerProfilesRepository.create.mockResolvedValueOnce(profileWithPrivate);

      const res = await request(app)
        .post('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send({ ...validBody, acceptsPrivateClients: true });

      expect(res.status).toBe(201);
      expect(mockTrainerProfilesRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({ acceptsPrivateClients: true }),
      );
    });

    it('returns 409 when trainer profile already exists', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(mockProfile);

      const res = await request(app)
        .post('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send(validBody);

      expect(res.status).toBe(409);
      expect(res.body).toHaveProperty('code', 'conflict');
      expect(mockTrainerProfilesRepository.create).not.toHaveBeenCalled();
    });

    it('returns 400 when body validation fails (missing required fields)', async () => {
      const res = await request(app)
        .post('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send({});

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
    });
  });

  describe('PATCH /api/trainer/profile', () => {
    it('returns 200 with updated profile', async () => {
      const updatedProfile = { ...mockProfile, bio: 'Updated bio' };
      mockTrainerProfilesRepository.update.mockResolvedValueOnce(updatedProfile);

      const res = await request(app)
        .patch('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send({ bio: 'Updated bio' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('bio', 'Updated bio');
      expect(mockTrainerProfilesRepository.update).toHaveBeenCalledWith(
        userId,
        expect.objectContaining({ bio: 'Updated bio' }),
      );
    });

    it('returns 200 when updating acceptsPrivateClients', async () => {
      const updatedProfile = { ...mockProfile, acceptsPrivateClients: true };
      mockTrainerProfilesRepository.update.mockResolvedValueOnce(updatedProfile);

      const res = await request(app)
        .patch('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send({ acceptsPrivateClients: true });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('acceptsPrivateClients', true);
    });

    it('returns 404 when profile does not exist for update', async () => {
      mockTrainerProfilesRepository.update.mockResolvedValueOnce(null);

      const res = await request(app)
        .patch('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send({ bio: 'Updated bio' });

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });
  });
});
