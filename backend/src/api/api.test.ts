import request from 'supertest';
import { createApp } from '../app';
import { getAuthProvider } from '../modules/auth';

// Mock the repositories module
jest.mock('../modules/auth');
jest.mock('../db/repositories');

const app = createApp();

// Test UUIDs for clubs (after migration 012_clubs_fk, clubId must be UUID)
const TEST_CLUB_1 = '550e8400-e29b-41d4-a716-446655440001';
const _TEST_CLUB_2 = '550e8400-e29b-41d4-a716-446655440002';
const TEST_CLUB_NEW = '550e8400-e29b-41d4-a716-446655440003';

/**
 * API smoke tests
 *
 * Tests basic API behavior:
 * - Auth middleware blocks unauthenticated requests
 * - Endpoints exist and respond correctly
 *
 * NOTE: Auth is mocked explicitly in these tests.
 */
describe('API Routes', () => {
  // Store original NODE_ENV
  const originalEnv = process.env.NODE_ENV;

  beforeAll(() => {
    process.env.NODE_ENV = 'test';
  });

  afterAll(() => {
    process.env.NODE_ENV = originalEnv;
  });

  beforeEach(() => {
    (getAuthProvider as jest.Mock).mockReturnValue({
      verifyToken: jest.fn().mockResolvedValue({
        valid: true,
        user: {
          uid: 'uid-1',
          email: 'test@example.com',
          displayName: 'Test User',
        },
      }),
    });
  });

  describe('Auth middleware', () => {
    it('returns 401 without Authorization header', async () => {
      const res = await request(app).get('/api/users');

      expect(res.status).toBe(401);
      expect(res.body).toHaveProperty('code', 'unauthorized');
    });

    it('returns 401 with invalid Authorization format', async () => {
      const res = await request(app).get('/api/users').set('Authorization', 'InvalidFormat');

      expect(res.status).toBe(401);
    });

    it('accepts Bearer token when auth provider validates it', async () => {
      const res = await request(app).get('/api/users').set('Authorization', 'Bearer test-token');

      expect(res.status).not.toBe(401);
    });
  });

  describe('GET /api/users', () => {
    it('returns 200 with array', async () => {
      const res = await request(app).get('/api/users').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('GET /api/cities', () => {
    it('returns 200 with array', async () => {
      const res = await request(app).get('/api/cities').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('GET /api/clubs', () => {
    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/clubs?cityId=spb')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });

    it('returns 400 for unknown cityId', async () => {
      const res = await request(app)
        .get('/api/clubs?cityId=unknown-city')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body?.details?.fields?.[0]?.code).toBe('city_not_found');
    });
  });

  describe('GET /api/clubs/my', () => {
    const { mockUsersRepository, mockClubMembersRepository } = require('../db/repositories');

    beforeEach(() => {
      mockUsersRepository.findByFirebaseUid.mockClear();
      mockClubMembersRepository.findActiveClubsByUser.mockClear();
    });

    it('returns active clubs of current user with role and joinedAt', async () => {
      const joinedAt = new Date('2026-02-08T10:00:00.000Z');
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
      });
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        {
          clubId: TEST_CLUB_1,
          clubName: 'Runterra Club',
          clubDescription: 'Morning runs',
          clubCityId: 'spb',
          clubStatus: 'active',
          role: 'leader',
          joinedAt,
        },
      ]);

      const res = await request(app).get('/api/clubs/my').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body).toHaveLength(1);
      expect(res.body[0]).toMatchObject({
        id: TEST_CLUB_1,
        name: 'Runterra Club',
        cityId: 'spb',
        role: 'leader',
        status: 'active',
      });
      expect(typeof res.body[0].cityName).toBe('string');
      expect(res.body[0].joinedAt).toBe(joinedAt.toISOString());
    });

    it('returns 401 when user record is not found', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce(null);

      const res = await request(app).get('/api/clubs/my').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(401);
      expect(res.body).toHaveProperty('code', 'unauthorized');
    });
  });

  describe('GET /api/clubs/leaderboard/:cityId', () => {
    const {
      mockClubsRepository,
      mockTerritoriesRepository,
      mockClubMembersRepository,
    } = require('../db/repositories');

    beforeEach(() => {
      mockClubsRepository.findByCityId.mockClear();
      mockTerritoriesRepository.getTerritoryScores.mockClear();
      mockClubMembersRepository.countActiveMembers.mockClear();
    });

    it('returns 200 with leaderboard array and optional myClub', async () => {
      mockClubsRepository.findByCityId.mockResolvedValueOnce([
        { id: 'club-1', name: 'Club 1', cityId: 'spb' },
        { id: 'club-2', name: 'Club 2', cityId: 'spb' },
      ]);
      mockTerritoriesRepository.getTerritoryScores.mockResolvedValueOnce([
        { territory_id: 't-1', club_id: 'club-1', club_name: 'Club 1', total_meters: '1000' },
      ]);
      mockClubMembersRepository.countActiveMembers.mockResolvedValue(5);

      const res = await request(app)
        .get('/api/clubs/leaderboard/spb?clubId=club-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('leaderboard');
      expect(Array.isArray(res.body.leaderboard)).toBe(true);
      expect(res.body).toHaveProperty('myClub');
      expect(res.body.myClub).toMatchObject({ id: 'club-1', points: 15 }); // 5 members + 10 pts for territory
    });
  });

  describe('GET /api/territories', () => {
    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/territories?cityId=spb')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('GET /api/events', () => {
    const {
      mockEventsRepository,
      mockWorkoutsRepository,
      mockUsersRepository,
    } = require('../db/repositories');

    beforeEach(() => {
      mockEventsRepository.findAll.mockClear();
      mockWorkoutsRepository.findById.mockClear();
      mockWorkoutsRepository.findByIds.mockClear();
      mockUsersRepository.findByIds.mockClear();
    });

    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/events?cityId=spb')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(mockEventsRepository.findAll).toHaveBeenCalled();
      expect(mockEventsRepository.findAll).toHaveBeenCalledWith(
        expect.objectContaining({ cityId: 'spb' }),
      );
    });

    it('passes sortBy to repository', async () => {
      const res = await request(app)
        .get('/api/events?cityId=spb&sortBy=price_asc')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(mockEventsRepository.findAll).toHaveBeenCalledWith(
        expect.objectContaining({ sortBy: 'price_asc' }),
      );
    });

    it('passes eventTypes as array to repository', async () => {
      const res = await request(app)
        .get('/api/events?cityId=spb&eventTypes=group_run,open_event')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(mockEventsRepository.findAll).toHaveBeenCalledWith(
        expect.objectContaining({ eventTypes: ['group_run', 'open_event'] }),
      );
    });

    it('passes limit and offset to repository', async () => {
      const res = await request(app)
        .get('/api/events?cityId=spb&limit=20&offset=40')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(mockEventsRepository.findAll).toHaveBeenCalledWith(
        expect.objectContaining({ limit: 20, offset: 40 }),
      );
    });

    it('returns events with organizerDisplayName when organizer exists', async () => {
      const res = await request(app)
        .get('/api/events?cityId=spb')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.length).toBeGreaterThan(0);
      const first = res.body[0];
      expect(first).toHaveProperty('organizerId');
      expect(first).toHaveProperty('organizerType');
      expect(first).toHaveProperty('organizerDisplayName');
      // Mock returns club with name 'Test Club' for organizerId 'a0000000-0000-4000-8000-000000000001'
      if (
        first.organizerType === 'club' &&
        first.organizerId === 'a0000000-0000-4000-8000-000000000001'
      ) {
        expect(first.organizerDisplayName).toBe('Test Club');
      }
    });

    it('returns workout/trainer integration fields for list items', async () => {
      mockEventsRepository.findAll.mockResolvedValueOnce([
        {
          id: 'event-with-integration',
          name: 'Tempo Training',
          type: 'training',
          status: 'open',
          startDateTime: new Date(),
          startLocation: { longitude: 30.3351, latitude: 59.9343 },
          organizerId: TEST_CLUB_1,
          organizerType: 'club',
          participantCount: 10,
          cityId: 'spb',
          createdAt: new Date(),
          updatedAt: new Date(),
          workoutId: 'workout-1',
          trainerId: 'trainer-1',
          price: 0,
        },
      ]);
      mockWorkoutsRepository.findByIds.mockResolvedValueOnce(
        new Map([
          [
            'workout-1',
            {
              id: 'workout-1',
              authorId: 'trainer-1',
              clubId: TEST_CLUB_1,
              name: 'Intervals 8x400',
              description: 'Warm-up and intervals',
              type: 'INTERVAL',
              difficulty: 'INTERMEDIATE',
              targetMetric: 'DISTANCE',
              createdAt: new Date(),
            },
          ],
        ]),
      );
      mockUsersRepository.findByIds.mockResolvedValueOnce([
        {
          id: 'trainer-1',
          firebaseUid: 'uid-trainer',
          email: 'trainer@example.com',
          name: 'Trainer One',
          firstName: 'Trainer',
          lastName: 'One',
          status: 'active',
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ]);

      const res = await request(app)
        .get('/api/events?cityId=spb')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveLength(1);
      expect(res.body[0]).toMatchObject({
        workoutId: 'workout-1',
        trainerId: 'trainer-1',
        workoutName: 'Intervals 8x400',
        workoutType: 'INTERVAL',
        workoutDifficulty: 'INTERMEDIATE',
        trainerName: 'Trainer One',
      });
    });

    it('returns 404 for private participant list when requester is not participant or organizer', async () => {
      mockEventsRepository.findById.mockResolvedValueOnce({
        id: 'private-event-1',
        visibility: 'private',
        organizerId: TEST_CLUB_1,
        organizerType: 'club',
      });
      mockEventsRepository.getParticipant.mockResolvedValueOnce(null);
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        email: 'u@example.com',
        name: 'User One',
      });

      const res = await request(app)
        .get('/api/events/private-event-1/participants')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(mockEventsRepository.getParticipants).not.toHaveBeenCalled();
    });
  });

  describe('GET /api/activities', () => {
    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/activities')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('GET /api/map/data', () => {
    it('returns 200 with territories and events', async () => {
      const res = await request(app)
        .get('/api/map/data?cityId=spb')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('territories');
      expect(res.body).toHaveProperty('events');
      expect(Array.isArray(res.body.territories)).toBe(true);
      expect(Array.isArray(res.body.events)).toBe(true);
    });

    it('returns territories with valid geometry polygons', async () => {
      const res = await request(app)
        .get('/api/map/data?cityId=spb')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      const territories = res.body.territories;
      expect(territories.length).toBeGreaterThan(0);

      for (const t of territories) {
        expect(t).toHaveProperty('geometry');
        expect(Array.isArray(t.geometry)).toBe(true);
        // Polygons must have at least 3 points
        expect(t.geometry.length).toBeGreaterThanOrEqual(3);

        for (const pt of t.geometry) {
          expect(pt).toHaveProperty('latitude');
          expect(pt).toHaveProperty('longitude');
          expect(typeof pt.latitude).toBe('number');
          expect(typeof pt.longitude).toBe('number');
        }
      }
    });
  });

  describe('Messages clubId validation', () => {
    it('GET /api/messages/clubs/:clubId returns 400 for invalid clubId format', async () => {
      const res = await request(app)
        .get('/api/messages/clubs/club:invalid')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body?.details?.fields?.[0]?.field).toBe('clubId');
    });

    it('POST /api/messages/clubs/:clubId returns 400 for invalid clubId format', async () => {
      const res = await request(app)
        .post('/api/messages/clubs/club:invalid')
        .set('Authorization', 'Bearer test-token')
        .send({ text: 'hello' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body?.details?.fields?.[0]?.field).toBe('clubId');
    });
  });

  describe('Messages default channel behavior', () => {
    const {
      mockUsersRepository,
      mockClubMembersRepository,
      mockMessagesRepository,
      mockClubChannelsRepository,
    } = require('../db/repositories');

    beforeEach(() => {
      // Clear call history but keep default mock implementations for other suites.
      mockUsersRepository.findByFirebaseUid.mockClear();
      mockClubMembersRepository.findByClubAndUser.mockClear();
      mockMessagesRepository.findByClubChannelWithRole.mockClear();
      mockMessagesRepository.create.mockClear();
      mockClubChannelsRepository.findDefaultByClub.mockClear();
      mockClubChannelsRepository.createDefaultForClub.mockClear();
      mockClubChannelsRepository.findById.mockClear();
    });

    it('GET /api/messages/clubs/:clubId without channelId uses default channel', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        name: 'U',
      });
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
      });
      mockClubChannelsRepository.findDefaultByClub.mockResolvedValueOnce({
        id: 'chan-1',
        clubId: TEST_CLUB_1,
        type: 'general',
        name: 'General',
        isDefault: true,
        createdAt: new Date(),
      });
      mockMessagesRepository.findByClubChannelWithRole.mockResolvedValueOnce([
        {
          id: 'm-1',
          text: 'hello',
          userId: 'user-1',
          userName: 'U',
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      ]);

      const res = await request(app)
        .get(`/api/messages/clubs/${TEST_CLUB_1}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(mockMessagesRepository.findByClubChannelWithRole).toHaveBeenCalledWith(
        TEST_CLUB_1,
        'chan-1',
        expect.any(Number),
        expect.any(Number),
      );
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body[0]).toHaveProperty('id', 'm-1');
    });

    it('POST /api/messages/clubs/:clubId without channelId writes to default channel', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        name: 'U',
      });
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
      });
      mockClubChannelsRepository.findDefaultByClub.mockResolvedValueOnce({
        id: 'chan-1',
        clubId: TEST_CLUB_1,
        type: 'general',
        name: 'General',
        isDefault: true,
        createdAt: new Date(),
      });
      mockMessagesRepository.create.mockResolvedValueOnce({
        id: 'm-1',
        channelType: 'club',
        channelId: TEST_CLUB_1,
        userId: 'user-1',
        text: 'hello',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .post(`/api/messages/clubs/${TEST_CLUB_1}`)
        .set('Authorization', 'Bearer test-token')
        .send({ text: 'hello' });

      expect(res.status).toBe(201);
      expect(mockMessagesRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          channelType: 'club',
          channelId: TEST_CLUB_1,
          clubChannelId: 'chan-1',
        }),
      );
      expect(res.body).toHaveProperty('id', 'm-1');
    });
  });

  describe('Clubs clubId validation', () => {
    it('GET /api/clubs/:id returns 400 for invalid clubId format', async () => {
      const res = await request(app)
        .get('/api/clubs/club:invalid')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body?.details?.fields?.[0]?.field).toBe('clubId');
    });

    it('POST /api/clubs/:id/join returns 400 for invalid clubId format', async () => {
      const res = await request(app)
        .post('/api/clubs/club:invalid/join')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body?.details?.fields?.[0]?.field).toBe('clubId');
    });
  });

  describe('POST validation', () => {
    it('returns 400 for invalid POST /api/users body', async () => {
      const res = await request(app)
        .post('/api/users')
        .set('Authorization', 'Bearer test-token')
        .send({ invalid: 'data' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
    });

    it('returns 400 for invalid POST /api/events body', async () => {
      const res = await request(app)
        .post('/api/events')
        .set('Authorization', 'Bearer test-token')
        .send({ name: 'Test' }); // Missing required fields

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
    });

    it('returns 403 for trainer event creation when organizer is not an active approved trainer', async () => {
      const {
        mockUsersRepository,
        mockTrainerProfilesRepository,
        mockClubMembersRepository,
        mockEventsRepository,
      } = require('../db/repositories');

      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        email: 'test@example.com',
        name: 'Test User',
      });
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce({
        userId: 'user-1',
        bio: 'Coach bio',
        specialization: ['GENERAL'],
        experienceYears: 5,
        certificates: [],
        acceptsPrivateClients: true,
        createdAt: new Date(),
      });
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([]);
      mockEventsRepository.create.mockClear();

      const res = await request(app)
        .post('/api/events')
        .set('Authorization', 'Bearer test-token')
        .send({
          name: 'Private Coach Session',
          type: 'training',
          startDateTime: '2026-03-10T10:00:00.000Z',
          startLocation: { longitude: 30.3351, latitude: 59.9343 },
          organizerId: 'user-1',
          organizerType: 'trainer',
          cityId: 'spb',
        });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(res.body.message).toMatch(/active approved trainers/i);
      expect(mockEventsRepository.create).not.toHaveBeenCalled();
    });

    it('returns 400 when trainer fields are set on trainer events', async () => {
      const {
        mockUsersRepository,
        mockTrainerProfilesRepository,
        mockClubMembersRepository,
        mockEventsRepository,
      } = require('../db/repositories');

      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        email: 'test@example.com',
        name: 'Test User',
      });
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce({
        userId: 'user-1',
        bio: 'Coach bio',
        specialization: ['GENERAL'],
        experienceYears: 5,
        certificates: [],
        acceptsPrivateClients: true,
        createdAt: new Date(),
      });
      mockClubMembersRepository.findActiveClubsByUser.mockResolvedValueOnce([
        {
          clubId: TEST_CLUB_1,
          clubName: 'Test Club',
          clubCityId: 'spb',
          clubStatus: 'active',
          role: 'trainer',
          joinedAt: new Date(),
        },
      ]);
      mockEventsRepository.create.mockClear();

      const res = await request(app)
        .post('/api/events')
        .set('Authorization', 'Bearer test-token')
        .send({
          name: 'Private Coach Session',
          type: 'training',
          startDateTime: '2026-03-10T10:00:00.000Z',
          startLocation: { longitude: 30.3351, latitude: 59.9343 },
          organizerId: 'user-1',
          organizerType: 'trainer',
          cityId: 'spb',
          workoutId: '550e8400-e29b-41d4-a716-446655440099',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body.message).toMatch(/club events/i);
      expect(mockEventsRepository.create).not.toHaveBeenCalled();
    });

    it('returns 403 when non-leader tries to assign trainerId on club event creation', async () => {
      const {
        mockUsersRepository,
        mockClubMembersRepository,
        mockEventsRepository,
      } = require('../db/repositories');

      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        email: 'test@example.com',
        name: 'Test User',
      });
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
        role: 'trainer',
      });
      mockEventsRepository.create.mockClear();

      const res = await request(app)
        .post('/api/events')
        .set('Authorization', 'Bearer test-token')
        .send({
          name: 'Club Session',
          type: 'training',
          startDateTime: '2026-03-10T10:00:00.000Z',
          startLocation: { longitude: 30.3351, latitude: 59.9343 },
          organizerId: TEST_CLUB_1,
          organizerType: 'club',
          cityId: 'spb',
          trainerId: '550e8400-e29b-41d4-a716-446655440098',
        });

      expect(res.status).toBe(403);
      expect(res.body).toHaveProperty('code', 'forbidden');
      expect(res.body.message).toMatch(/only club leader/i);
      expect(mockEventsRepository.create).not.toHaveBeenCalled();
    });

    it('returns 400 when workout does not belong to club or author on club event creation', async () => {
      const {
        mockUsersRepository,
        mockClubMembersRepository,
        mockWorkoutsRepository,
        mockEventsRepository,
      } = require('../db/repositories');

      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        email: 'test@example.com',
        name: 'Test User',
      });
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'user-1',
        status: 'active',
        role: 'leader',
      });
      mockWorkoutsRepository.findById.mockResolvedValueOnce({
        id: 'workout-foreign',
        authorId: 'other-user',
        clubId: '550e8400-e29b-41d4-a716-446655440077',
        name: 'Foreign Workout',
        type: 'TEMPO',
        difficulty: 'INTERMEDIATE',
        targetMetric: 'DISTANCE',
        createdAt: new Date(),
      });
      mockEventsRepository.create.mockClear();

      const res = await request(app)
        .post('/api/events')
        .set('Authorization', 'Bearer test-token')
        .send({
          name: 'Club Session',
          type: 'training',
          startDateTime: '2026-03-10T10:00:00.000Z',
          startLocation: { longitude: 30.3351, latitude: 59.9343 },
          organizerId: TEST_CLUB_1,
          organizerType: 'club',
          cityId: 'spb',
          workoutId: '550e8400-e29b-41d4-a716-446655440097',
        });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body.message).toMatch(/does not belong to this club or author/i);
      expect(mockEventsRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('GET by ID', () => {
    const {
      mockEventsRepository,
      mockWorkoutsRepository,
      mockUsersRepository,
    } = require('../db/repositories');

    beforeEach(() => {
      mockEventsRepository.findById.mockClear();
      mockWorkoutsRepository.findById.mockClear();
      mockWorkoutsRepository.findByIds.mockClear();
      mockUsersRepository.findByIds.mockClear();
    });

    // NOTE: Stubs return 200 with mock data for any ID.
    // TODO: Update tests when real DB integration is added.

    it('GET /api/users/:id returns 200', async () => {
      const res = await request(app)
        .get('/api/users/any-id')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
    });

    it('GET /api/users/:id returns 404 for hidden profile of another user', async () => {
      mockUsersRepository.findById.mockResolvedValueOnce({
        id: 'hidden-user-id',
        firebaseUid: 'hidden-uid',
        email: 'hidden@example.com',
        name: 'Hidden User',
        profileVisible: false,
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'requester-id',
        firebaseUid: 'uid-1',
        email: 'test@example.com',
        name: 'Requester',
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .get('/api/users/hidden-user-id')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
    });

    it('GET /api/events/:id returns 200 with organizerDisplayName', async () => {
      const res = await request(app)
        .get('/api/events/any-id')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('organizerDisplayName');
      // Mock event has organizerId 'a0000000-0000-4000-8000-000000000001', mock club name is 'Test Club'
      if (res.body.organizerType === 'club') {
        expect(res.body.organizerDisplayName).toBe('Test Club');
      }
    });

    it('GET /api/events/:id returns workout/trainer integration fields', async () => {
      mockEventsRepository.findById.mockResolvedValueOnce({
        id: 'event-details-1',
        name: 'Club Workout',
        type: 'training',
        status: 'open',
        startDateTime: new Date(),
        startLocation: { longitude: 30.3351, latitude: 59.9343 },
        locationName: 'Park',
        organizerId: TEST_CLUB_1,
        organizerType: 'club',
        participantCount: 12,
        cityId: 'spb',
        createdAt: new Date(),
        updatedAt: new Date(),
        workoutId: 'workout-2',
        trainerId: 'trainer-2',
      });
      mockWorkoutsRepository.findByIds.mockResolvedValueOnce(
        new Map([
          [
            'workout-2',
            {
              id: 'workout-2',
              authorId: 'trainer-2',
              clubId: TEST_CLUB_1,
              name: 'Long Tempo',
              description: '15 min warm-up + tempo blocks',
              type: 'TEMPO',
              difficulty: 'ADVANCED',
              targetMetric: 'TIME',
              createdAt: new Date(),
            },
          ],
        ]),
      );
      mockUsersRepository.findByIds.mockResolvedValueOnce([
        {
          id: 'trainer-2',
          firebaseUid: 'uid-trainer-2',
          email: 'trainer2@example.com',
          name: 'Coach Anna',
          firstName: 'Anna',
          lastName: 'Petrova',
          status: 'active',
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ]);

      const res = await request(app)
        .get('/api/events/event-details-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({
        workoutId: 'workout-2',
        trainerId: 'trainer-2',
        workoutName: 'Long Tempo',
        workoutDescription: '15 min warm-up + tempo blocks',
        workoutType: 'TEMPO',
        workoutDifficulty: 'ADVANCED',
        trainerName: 'Anna Petrova',
      });
    });

    it('GET /api/clubs/:id returns 200', async () => {
      const res = await request(app)
        .get(`/api/clubs/${TEST_CLUB_1}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
    });
  });

  describe('GET /api/events/:id participant status', () => {
    const { mockEventsRepository } = require('../db/repositories');

    beforeEach(() => {
      mockEventsRepository.getParticipant.mockReset();
    });

    it('includes participant flags when user is registered', async () => {
      mockEventsRepository.getParticipant.mockResolvedValueOnce({
        id: 'p-1',
        eventId: 'test-event-id',
        userId: 'test-user-id',
        status: 'registered',
        createdAt: new Date(),
      });

      const res = await request(app)
        .get('/api/events/test-event-id')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.isParticipant).toBe(true);
      expect(res.body.participantStatus).toBe('registered');
    });

    it('omits participant flags when no participation found', async () => {
      mockEventsRepository.getParticipant.mockResolvedValueOnce(null);

      const res = await request(app)
        .get('/api/events/test-event-id')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body).not.toHaveProperty('isParticipant');
      expect(res.body).not.toHaveProperty('participantStatus');
    });
  });

  describe('GET /api/clubs/:id membership flags', () => {
    const { mockClubMembersRepository } = require('../db/repositories');

    beforeEach(() => {
      mockClubMembersRepository.findByClubAndUser.mockReset();
    });

    it('sets isMember=false for inactive membership and keeps status', async () => {
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'test-user-id',
        status: 'inactive',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .get(`/api/clubs/${TEST_CLUB_1}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.isMember).toBe(false);
      expect(res.body.membershipStatus).toBe('inactive');
    });
  });

  describe('GET /api/users/me/profile club consistency', () => {
    const { mockClubMembersRepository, mockClubsRepository } = require('../db/repositories');

    beforeEach(() => {
      mockClubMembersRepository.findPrimaryClubIdByUser.mockReset();
      mockClubsRepository.findById.mockReset();
    });

    it('returns club=null when primaryClubId points to missing club', async () => {
      mockClubMembersRepository.findPrimaryClubIdByUser.mockResolvedValueOnce(TEST_CLUB_NEW);
      mockClubsRepository.findById.mockResolvedValueOnce(null);

      const res = await request(app)
        .get('/api/users/me/profile')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.club).toBeNull();
      expect(res.body.user?.primaryClubId).toBeUndefined();
    });
  });

  describe('GET /api/users/me/profile profileVisible', () => {
    const { mockUsersRepository } = require('../db/repositories');

    beforeEach(() => {
      // Keep default mock implementations for other suites; just clear call history.
      mockUsersRepository.findByFirebaseUid.mockClear();
    });

    it('returns profileVisible=false when user.profileVisible=false', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        email: 'u@example.com',
        name: 'U',
        firstName: 'U',
        lastName: undefined,
        birthDate: undefined,
        country: undefined,
        gender: undefined,
        avatarUrl: undefined,
        cityId: undefined,
        isMercenary: false,
        status: 'active',
        profileVisible: false,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .get('/api/users/me/profile')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body?.user?.profileVisible).toBe(false);
    });

    it('defaults profileVisible=true when user.profileVisible is missing', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        email: 'u@example.com',
        name: 'U',
        firstName: 'U',
        lastName: undefined,
        birthDate: undefined,
        country: undefined,
        gender: undefined,
        avatarUrl: undefined,
        cityId: undefined,
        isMercenary: false,
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .get('/api/users/me/profile')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body?.user?.profileVisible).toBe(true);
    });
  });

  describe('PATCH /api/users/me/profile profileVisible', () => {
    const { mockUsersRepository } = require('../db/repositories');

    beforeEach(() => {
      // Keep default mock implementations for other suites; just clear call history.
      mockUsersRepository.findByFirebaseUid.mockClear();
      mockUsersRepository.update.mockClear();
    });

    it('passes profileVisible to repository update', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        name: 'U',
      });

      const res = await request(app)
        .patch('/api/users/me/profile')
        .set('Authorization', 'Bearer test-token')
        .send({ profileVisible: false });

      expect(res.status).toBe(200);
      expect(mockUsersRepository.update).toHaveBeenCalledWith('user-1', { profileVisible: false });
    });
  });

  describe('POST /api/events/:id/join', () => {
    const { mockEventsRepository, mockUsersRepository, mockClubMembersRepository } =
      require('../db/repositories');

    beforeEach(() => {
      mockUsersRepository.findByFirebaseUid.mockClear();
      mockClubMembersRepository.findByClubAndUser.mockClear();
      mockEventsRepository.findById.mockClear();
      mockEventsRepository.getParticipant.mockClear();
      mockEventsRepository.joinEvent.mockResolvedValue({
        participant: {
          id: 'p-1',
          eventId: 'ev-1',
          userId: 'user-1',
          status: 'registered',
          createdAt: new Date(),
        },
      });
    });

    it('should return 200 with participant when join succeeds', async () => {
      const res = await request(app)
        .post('/api/events/ev-1/join')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.participant).toBeDefined();
      expect(res.body.participant.status).toBe('registered');
    });

    it('should return 400 with ADR-0002 envelope when repo returns business error', async () => {
      mockEventsRepository.joinEvent.mockResolvedValueOnce({ error: 'Event is full' });

      const res = await request(app)
        .post('/api/events/ev-1/join')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('event_full');
      expect(res.body.message).toBe('Event is full');
      expect(res.body.details).toEqual({ eventId: 'ev-1' });
    });

    it('returns 404 and does not join hidden private event for outsider', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
        email: 'test@example.com',
        name: 'Test User',
      });
      mockEventsRepository.findById.mockResolvedValueOnce({
        id: 'ev-private',
        name: 'Private Event',
        type: 'training',
        status: 'open',
        visibility: 'private',
        startDateTime: new Date(),
        startLocation: { longitude: 30.3351, latitude: 59.9343 },
        organizerId: TEST_CLUB_1,
        organizerType: 'club',
        participantCount: 0,
        cityId: 'spb',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockEventsRepository.getParticipant.mockResolvedValueOnce(null);
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce(null);
      mockEventsRepository.joinEvent.mockClear();

      const res = await request(app)
        .post('/api/events/ev-private/join')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body).toHaveProperty('code', 'not_found');
      expect(mockEventsRepository.joinEvent).not.toHaveBeenCalled();
    });
  });

  describe('POST /api/events/:id/check-in', () => {
    const { mockEventsRepository } = require('../db/repositories');

    beforeEach(() => {
      mockEventsRepository.checkIn.mockResolvedValue({
        participant: {
          id: 'p-1',
          eventId: 'ev-1',
          userId: 'user-1',
          status: 'checked_in',
          createdAt: new Date(),
        },
      });
    });

    it('should return 400 with ADR-0002 when longitude or latitude is missing', async () => {
      const res = await request(app)
        .post('/api/events/ev-1/check-in')
        .set('Authorization', 'Bearer test-token')
        .send({ latitude: 59.93 });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('validation_error');
      expect(res.body.message).toMatch(/validation/i);
    });

    it('should return 400 with ADR-0002 when coordinates are not numbers', async () => {
      const res = await request(app)
        .post('/api/events/ev-1/check-in')
        .set('Authorization', 'Bearer test-token')
        .send({ longitude: '30.33', latitude: '59.93' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('validation_error');
    });

    it('should return 200 with participant when check-in succeeds', async () => {
      const res = await request(app)
        .post('/api/events/ev-1/check-in')
        .set('Authorization', 'Bearer test-token')
        .send({ longitude: 30.3351, latitude: 59.9343 });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.participant).toBeDefined();
      expect(res.body.participant.status).toBe('checked_in');
    });

    it('should return 400 with ADR-0002 when repo returns error (e.g. too far)', async () => {
      mockEventsRepository.checkIn.mockResolvedValueOnce({
        error: 'Too far from event location. Distance: 600m, max: 500m',
      });

      const res = await request(app)
        .post('/api/events/ev-1/check-in')
        .set('Authorization', 'Bearer test-token')
        .send({ longitude: 30.3351, latitude: 59.9343 });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('check_in_too_far');
      expect(res.body.message).toMatch(/Too far/i);
    });
  });

  describe('POST /api/events/:id/leave', () => {
    const { mockEventsRepository } = require('../db/repositories');

    beforeEach(() => {
      mockEventsRepository.leaveEvent.mockReset();
    });

    it('returns 200 with participant when leave succeeds', async () => {
      mockEventsRepository.leaveEvent.mockResolvedValueOnce({
        participant: {
          id: 'p-1',
          eventId: 'ev-1',
          userId: 'user-1',
          status: 'cancelled',
          createdAt: new Date(),
        },
      });

      const res = await request(app)
        .post('/api/events/ev-1/leave')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.participant).toBeDefined();
      expect(res.body.participant.status).toBe('cancelled');
    });

    it('maps not registered error to not_registered code', async () => {
      mockEventsRepository.leaveEvent.mockResolvedValueOnce({
        error: 'Not registered for this event',
      });

      const res = await request(app)
        .post('/api/events/ev-1/leave')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('not_registered');
    });

    it('maps already cancelled error to already_cancelled code', async () => {
      mockEventsRepository.leaveEvent.mockResolvedValueOnce({
        error: 'Already cancelled participation',
      });

      const res = await request(app)
        .post('/api/events/ev-1/leave')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('already_cancelled');
    });
  });

  describe('POST /api/clubs/:id/leave', () => {
    const { mockClubMembersRepository, mockClubsRepository } = require('../db/repositories');

    beforeEach(() => {
      mockClubMembersRepository.findByClubAndUser.mockReset();
      mockClubMembersRepository.deactivate.mockReset();
      mockClubsRepository.findById.mockReset();
    });

    it('returns 200 when active membership is deactivated', async () => {
      // Mock club exists
      mockClubsRepository.findById.mockResolvedValueOnce({
        id: TEST_CLUB_1,
        name: 'Test Club',
        status: 'active',
        cityId: 'spb',
        creatorId: 'creator-id',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'test-user-id',
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockClubMembersRepository.deactivate.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'test-user-id',
        status: 'inactive',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .post(`/api/clubs/${TEST_CLUB_1}/leave`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('inactive');
    });

    it('returns 400 when user is not a member', async () => {
      // Mock club exists
      mockClubsRepository.findById.mockResolvedValueOnce({
        id: TEST_CLUB_1,
        name: 'Test Club',
        status: 'active',
        cityId: 'spb',
        creatorId: 'creator-id',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce(null);

      const res = await request(app)
        .post(`/api/clubs/${TEST_CLUB_1}/leave`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('not_member');
    });

    it('returns 400 when membership already inactive', async () => {
      // Mock club exists
      mockClubsRepository.findById.mockResolvedValueOnce({
        id: TEST_CLUB_1,
        name: 'Test Club',
        status: 'active',
        cityId: 'spb',
        creatorId: 'creator-id',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: TEST_CLUB_1,
        userId: 'test-user-id',
        status: 'inactive',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .post(`/api/clubs/${TEST_CLUB_1}/leave`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('already_left');
    });
  });

  describe('PATCH /api/clubs/:id/members/:userId/role leader guardrail', () => {
    const {
      mockUsersRepository,
      mockClubMembersRepository,
      mockClubsRepository,
    } = require('../db/repositories');

    beforeEach(() => {
      mockUsersRepository.findByFirebaseUid.mockReset();
      mockClubMembersRepository.findByClubAndUser.mockReset();
      mockClubMembersRepository.countActiveLeaders.mockReset();
      mockClubMembersRepository.updateRoleWithLeaderTransfer.mockReset();
      mockClubsRepository.findById.mockReset();
    });

    it('returns 400 when attempting to demote the last active leader', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
      });
      mockClubsRepository.findById.mockResolvedValueOnce({
        id: TEST_CLUB_1,
        name: 'Test Club',
        status: 'active',
        cityId: 'spb',
        creatorId: 'creator-id',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // requesterMembership (leader) then targetMembership (same leader)
      mockClubMembersRepository.findByClubAndUser
        .mockResolvedValueOnce({
          id: 'cm-req',
          clubId: TEST_CLUB_1,
          userId: 'user-1',
          status: 'active',
          role: 'leader',
        })
        .mockResolvedValueOnce({
          id: 'cm-target',
          clubId: TEST_CLUB_1,
          userId: 'user-1',
          status: 'active',
          role: 'leader',
        });

      mockClubMembersRepository.countActiveLeaders.mockResolvedValueOnce(1);

      const res = await request(app)
        .patch(`/api/clubs/${TEST_CLUB_1}/members/user-1/role`)
        .set('Authorization', 'Bearer test-token')
        .send({ role: 'trainer' });

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'leader_transfer_required');
      expect(mockClubMembersRepository.updateRoleWithLeaderTransfer).not.toHaveBeenCalled();
    });
  });

  describe('POST /api/users', () => {
    const { mockUsersRepository } = require('../db/repositories');

    beforeEach(() => {
      (getAuthProvider as jest.Mock).mockReturnValue({
        verifyToken: jest.fn().mockResolvedValue({
          valid: true,
          user: {
            uid: 'auth-uid-1',
            email: 'auth@example.com',
            displayName: 'Auth User',
          },
        }),
      });
    });

    it('returns existing self user when record already exists', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'existing-id',
        firebaseUid: 'auth-uid-1',
        email: 'existing@example.com',
        name: 'Existing',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockUsersRepository.create.mockClear();

      const res = await request(app)
        .post('/api/users')
        .set('Authorization', 'Bearer test-token')
        .send({
          email: 'existing@example.com',
          name: 'Existing',
        });

      expect(res.status).toBe(200);
      expect(res.body.name).toBe('Existing');
      expect(mockUsersRepository.create).not.toHaveBeenCalled();
    });

    it('creates self user with firebase uid from verified token, ignoring client-supplied uid', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce(null);
      mockUsersRepository.create.mockResolvedValueOnce({
        id: 'created-id',
        firebaseUid: 'auth-uid-1',
        email: 'auth@example.com',
        name: 'Created User',
        isMercenary: false,
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .post('/api/users')
        .set('Authorization', 'Bearer test-token')
        .send({
          firebaseUid: 'attacker-controlled-uid',
          email: 'existing@example.com',
          name: 'Created User',
        });

      expect(res.status).toBe(201);
      expect(mockUsersRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          firebaseUid: 'auth-uid-1',
          email: 'auth@example.com',
          name: 'Created User',
        }),
      );
    });
  });

  describe('DELETE /api/users/me', () => {
    const { mockUsersRepository } = require('../db/repositories');

    beforeEach(() => {
      // Keep default mock implementations for other suites; just clear call history.
      mockUsersRepository.findByFirebaseUid.mockClear();
      mockUsersRepository.delete.mockClear();
    });

    it('should return 404 when user not found by firebase uid', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce(null);

      const res = await request(app)
        .delete('/api/users/me')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body.message).toMatch(/not found/i);
      expect(mockUsersRepository.delete).not.toHaveBeenCalled();
    });

    it('should delete user and return 200 when user exists', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'user-1',
        firebaseUid: 'uid-1',
      });
      mockUsersRepository.delete.mockResolvedValueOnce(true);

      const res = await request(app)
        .delete('/api/users/me')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body?.success).toBe(true);
      expect(mockUsersRepository.delete).toHaveBeenCalledWith('user-1');
    });
  });

  describe('GET /api/map/data filters', () => {
    it('should return territories and events with onlyActive filter', async () => {
      const res = await request(app)
        .get('/api/map/data?cityId=spb&onlyActive=true')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.territories).toBeDefined();
      expect(res.body.events).toBeDefined();
      // onlyActive=true filters to CAPTURED and CONTESTED only; with all FREE territories, result is empty
      const statuses = res.body.territories.map((t: { status: string }) => t.status);
      expect(statuses.every((s: string) => s === 'captured' || s === 'contested')).toBe(true);
    });

    it('should return filtered territories when clubId is provided', async () => {
      const res = await request(app)
        .get(`/api/map/data?cityId=spb&clubId=${TEST_CLUB_1}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.territories).toBeDefined();
      // With all territories free (clubId undefined), filter by clubId returns empty array
      expect(res.body.territories.every((t: { clubId?: string }) => t.clubId === TEST_CLUB_1)).toBe(
        true,
      );
    });
  });

  describe('cityId validation and filtering', () => {
    it('GET /api/events without cityId returns 400 with validation_error', async () => {
      const res = await request(app).get('/api/events').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body.details?.fields?.some((f: { field: string }) => f.field === 'cityId')).toBe(
        true,
      );
    });

    it('GET /api/map/data without cityId returns 400 with validation_error', async () => {
      const res = await request(app).get('/api/map/data').set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body.details?.fields?.some((f: { field: string }) => f.field === 'cityId')).toBe(
        true,
      );
    });

    it('GET /api/territories returns territories only for requested city', async () => {
      const res = await request(app)
        .get(`/api/territories?cityId=spb&clubId=${TEST_CLUB_1}`)
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.every((t: { cityId: string }) => t.cityId === 'spb')).toBe(true);
    });
  });

  describe('GET /api/users/me/calendar', () => {
    const { mockUsersRepository, mockRunsRepository, mockEventsRepository } =
      require('../db/repositories');

    beforeEach(() => {
      mockUsersRepository.findByFirebaseUid.mockClear();
      mockRunsRepository.getRunsForMonth.mockClear();
      mockEventsRepository.getRegisteredEventsForMonth.mockClear();
    });

    it('returns 401 without Authorization', async () => {
      const res = await request(app).get('/api/users/me/calendar?year=2026&month=3');
      expect(res.status).toBe(401);
    });

    it('returns 200 with days array on happy path', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'test-user-id',
        firebaseUid: 'firebase-uid-1',
        email: 'test@example.com',
        name: 'Test User',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockRunsRepository.getRunsForMonth.mockResolvedValueOnce([
        { id: 'run-1', date: '2026-03-09', distanceM: 5000, durationS: 1800 },
      ]);
      mockEventsRepository.getRegisteredEventsForMonth.mockResolvedValueOnce([
        { id: 'evt-1', date: '2026-03-09', name: 'Park Run' },
      ]);

      const res = await request(app)
        .get('/api/users/me/calendar?year=2026&month=3')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.days).toBeDefined();
      expect(res.body.days).toHaveLength(1);
      expect(res.body.days[0].date).toBe('2026-03-09');
      expect(res.body.days[0].runs).toHaveLength(1);
      expect(res.body.days[0].runs[0].distanceM).toBe(5000);
      expect(res.body.days[0].events).toHaveLength(1);
      expect(res.body.days[0].events[0].name).toBe('Park Run');
    });

    it('returns 400 for invalid month', async () => {
      const res = await request(app)
        .get('/api/users/me/calendar?year=2026&month=13')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('validation_error');
    });

    it('returns 400 for invalid year', async () => {
      const res = await request(app)
        .get('/api/users/me/calendar?year=1999&month=3')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('validation_error');
    });
  });
});
