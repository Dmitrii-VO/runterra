import request from 'supertest';
import { createApp } from '../app';

// Mock the repositories module
jest.mock('../db/repositories');

const app = createApp();

const TEST_CLUB_1 = '550e8400-e29b-41d4-a716-446655440001';
const TEST_CLUB_2 = '550e8400-e29b-41d4-a716-446655440002';

describe('Clubs Routes - One Club Rule', () => {
  const {
    mockUsersRepository,
    mockClubMembersRepository,
    mockClubsRepository,
    mockClubChannelsRepository: _mockClubChannelsRepository,
  } = require('../db/repositories');

  // Store original NODE_ENV
  const originalEnv = process.env.NODE_ENV;

  beforeAll(() => {
    process.env.NODE_ENV = 'test';
  });

  afterAll(() => {
    process.env.NODE_ENV = originalEnv;
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/clubs', () => {
    it('returns 400 if user already has an active membership', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
      });
      mockClubMembersRepository.findActiveByUser.mockResolvedValueOnce([
        { clubId: TEST_CLUB_1, status: 'active' },
      ]);

      const res = await request(app)
        .post('/api/clubs')
        .set('Authorization', 'Bearer test-token')
        .send({
          name: 'New Club',
          cityId: 'spb',
          description: 'Test description',
        });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('validation_error');
      expect(res.body.details.fields[0].code).toBe('already_in_another_club');
    });

    it('creates club if user has no active memberships', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
      });
      mockClubMembersRepository.findActiveByUser.mockResolvedValueOnce([]);
      mockClubsRepository.create.mockResolvedValueOnce({
        id: TEST_CLUB_2,
        name: 'New Club',
        cityId: 'spb',
        creatorId: 'user-1',
        description: 'Test',
        status: 'pending',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockClubMembersRepository.create.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_2,
        userId: 'user-1',
        status: 'active',
        role: 'leader',
      });

      const res = await request(app)
        .post('/api/clubs')
        .set('Authorization', 'Bearer test-token')
        .send({
          name: 'New Club',
          cityId: 'spb',
          description: 'Test',
        });

      expect(res.status).toBe(201);
      expect(mockClubsRepository.create).toHaveBeenCalled();
      expect(mockClubMembersRepository.create).toHaveBeenCalledWith(
        TEST_CLUB_2,
        'user-1',
        'active',
        'leader',
      );
    });
  });

  describe('POST /api/clubs/:id/join', () => {
    it('returns 400 if user already in another club', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
      });
      mockClubsRepository.findById.mockResolvedValueOnce({ id: TEST_CLUB_2 });
      mockClubMembersRepository.findActiveByUser.mockResolvedValueOnce([
        { clubId: TEST_CLUB_1, status: 'active' },
      ]);

      const res = await request(app)
        .post(`/api/clubs/${TEST_CLUB_2}/join`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('already_in_another_club');
    });

    it('returns 400 if user already in THIS club (active)', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
      });
      mockClubsRepository.findById.mockResolvedValueOnce({ id: TEST_CLUB_1 });
      mockClubMembersRepository.findActiveByUser.mockResolvedValueOnce([
        { clubId: TEST_CLUB_1, status: 'active' },
      ]);
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        clubId: TEST_CLUB_1,
        status: 'active',
      });

      const res = await request(app)
        .post(`/api/clubs/${TEST_CLUB_1}/join`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      // Current implementation for "this club" returns already_member
      expect(res.body.code).toBe('already_member');
    });

    it('allows joining if user has no active memberships', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
      });
      mockClubsRepository.findById.mockResolvedValueOnce({ id: TEST_CLUB_2 });
      mockClubMembersRepository.findActiveByUser.mockResolvedValueOnce([]);
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce(null);
      mockClubMembersRepository.create.mockResolvedValueOnce({
        id: 'cm-2',
        clubId: TEST_CLUB_2,
        userId: 'user-1',
        status: 'pending',
      });

      const res = await request(app)
        .post(`/api/clubs/${TEST_CLUB_2}/join`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(201);
      expect(res.body.status).toBe('pending');
    });
  });
});
