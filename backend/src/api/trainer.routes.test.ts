import request from 'supertest';
import { createApp } from '../app';

// Mock the repositories module
jest.mock('../db/repositories');

const app = createApp();

/**
 * Trainer profile CRUD tests
 *
 * Tests trainer profile endpoints:
 * - GET /api/trainer/profile — own profile
 * - GET /api/trainer/profile/:userId — public view
 * - POST /api/trainer/profile — create
 * - PATCH /api/trainer/profile — update
 */
describe('Trainer Routes', () => {
  const originalEnv = process.env.NODE_ENV;

  beforeAll(() => {
    process.env.NODE_ENV = 'test';
  });

  afterAll(() => {
    process.env.NODE_ENV = originalEnv;
  });

  const {
    mockUsersRepository,
    mockTrainerProfilesRepository,
    mockClubMembersRepository,
  } = require('../db/repositories');

  const mockProfile = {
    userId: 'user-1',
    bio: 'Experienced running coach',
    specialization: ['GENERAL'],
    experienceYears: 5,
    certificates: [],
    createdAt: new Date(),
  };

  beforeEach(() => {
    mockUsersRepository.findByFirebaseUid.mockClear();
    mockTrainerProfilesRepository.findByUserId.mockClear();
    mockTrainerProfilesRepository.create.mockClear();
    mockTrainerProfilesRepository.update.mockClear();
    mockClubMembersRepository.findActiveClubsByUser.mockClear();
    mockClubMembersRepository.findByClubAndUser.mockClear();

    // Default: user exists
    mockUsersRepository.findByFirebaseUid.mockResolvedValue({
      id: 'user-1',
      firebaseUid: 'uid-1',
      email: 'test@example.com',
      name: 'Test User',
    });
  });

  describe('GET /api/trainer/profile', () => {
    it('returns 200 with profile when trainer profile exists', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(mockProfile);

      const res = await request(app)
        .get('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('userId', 'user-1');
      expect(res.body).toHaveProperty('bio', 'Experienced running coach');
      expect(res.body).toHaveProperty('specialization');
      expect(res.body).toHaveProperty('experienceYears', 5);
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
        .get('/api/trainer/profile/user-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('userId', 'user-1');
      expect(res.body).toHaveProperty('specialization');
    });

    it('returns 404 when profile does not exist', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(null);

      const res = await request(app)
        .get('/api/trainer/profile/nonexistent-user')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
    });
  });

  describe('POST /api/trainer/profile', () => {
    const validBody = {
      specialization: ['GENERAL'],
      experienceYears: 5,
      bio: 'Coach bio',
    };

    it('returns 201 when trainer profile is created (user is trainer in a club)', async () => {
      // User is a trainer in at least one club
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        { clubId: 'club-1', clubName: 'Club A', clubCityId: 'spb', clubStatus: 'active', role: 'trainer', joinedAt: new Date() },
      ]);
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce(null);
      mockTrainerProfilesRepository.create.mockResolvedValueOnce(mockProfile);

      const res = await request(app)
        .post('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send(validBody);

      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('userId', 'user-1');
      expect(mockTrainerProfilesRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-1',
          specialization: ['GENERAL'],
          experienceYears: 5,
        }),
      );
    });

    it('returns 403 when user is not a trainer or leader in any club', async () => {
      // User has only member role
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        { clubId: 'club-1', clubName: 'Club A', clubCityId: 'spb', clubStatus: 'active', role: 'member', joinedAt: new Date() },
      ]);

      const res = await request(app)
        .post('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send(validBody);

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(mockTrainerProfilesRepository.create).not.toHaveBeenCalled();
    });

    it('returns 409 when trainer profile already exists', async () => {
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        { clubId: 'club-1', clubName: 'Club A', clubCityId: 'spb', clubStatus: 'active', role: 'trainer', joinedAt: new Date() },
      ]);
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
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        { clubId: 'club-1', clubName: 'Club A', clubCityId: 'spb', clubStatus: 'active', role: 'trainer', joinedAt: new Date() },
      ]);
      const updatedProfile = { ...mockProfile, bio: 'Updated bio' };
      mockTrainerProfilesRepository.update.mockResolvedValueOnce(updatedProfile);

      const res = await request(app)
        .patch('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send({ bio: 'Updated bio' });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('bio', 'Updated bio');
      expect(mockTrainerProfilesRepository.update).toHaveBeenCalledWith(
        'user-1',
        expect.objectContaining({ bio: 'Updated bio' }),
      );
    });

    it('returns 403 when user is not trainer or leader', async () => {
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        { clubId: 'club-1', clubName: 'Club A', clubCityId: 'spb', clubStatus: 'active', role: 'member', joinedAt: new Date() },
      ]);

      const res = await request(app)
        .patch('/api/trainer/profile')
        .set('Authorization', 'Bearer test-token')
        .send({ bio: 'Updated bio' });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
    });

    it('returns 404 when profile does not exist for update', async () => {
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        { clubId: 'club-1', clubName: 'Club A', clubCityId: 'spb', clubStatus: 'active', role: 'trainer', joinedAt: new Date() },
      ]);
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
