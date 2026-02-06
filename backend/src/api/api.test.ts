import request from 'supertest';
import { createApp } from '../app';

// Mock the repositories module
jest.mock('../db/repositories');

const app = createApp();

/**
 * API smoke tests
 * 
 * Tests basic API behavior:
 * - Auth middleware blocks unauthenticated requests
 * - Endpoints exist and respond correctly
 * 
 * NOTE: These tests use stub auth. In dev mode, any Bearer token is accepted.
 * Set NODE_ENV=test to allow stub auth.
 */
describe('API Routes', () => {
  // Store original NODE_ENV
  const originalEnv = process.env.NODE_ENV;
  
  beforeAll(() => {
    // Allow stub auth for tests
    process.env.NODE_ENV = 'test';
  });
  
  afterAll(() => {
    process.env.NODE_ENV = originalEnv;
  });

  describe('Auth middleware', () => {
    it('returns 401 without Authorization header', async () => {
      const res = await request(app).get('/api/users');
      
      expect(res.status).toBe(401);
      expect(res.body).toHaveProperty('code', 'unauthorized');
    });

    it('returns 401 with invalid Authorization format', async () => {
      const res = await request(app)
        .get('/api/users')
        .set('Authorization', 'InvalidFormat');
      
      expect(res.status).toBe(401);
    });

    it('accepts Bearer token (stub mode)', async () => {
      const res = await request(app)
        .get('/api/users')
        .set('Authorization', 'Bearer test-token');
      
      // Should pass auth (stub accepts any token in non-production)
      expect(res.status).not.toBe(401);
    });
  });

  describe('GET /api/users', () => {
    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/users')
        .set('Authorization', 'Bearer test-token');
      
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('GET /api/cities', () => {
    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/cities')
        .set('Authorization', 'Bearer test-token');
      
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
    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/events?cityId=spb')
        .set('Authorization', 'Bearer test-token');
      
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
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
  });

  describe('GET by ID', () => {
    // NOTE: Stubs return 200 with mock data for any ID.
    // TODO: Update tests when real DB integration is added.
    
    it('GET /api/users/:id returns 200 (stub)', async () => {
      const res = await request(app)
        .get('/api/users/any-id')
        .set('Authorization', 'Bearer test-token');
      
      expect(res.status).toBe(200);
    });

    it('GET /api/events/:id returns 200 (stub)', async () => {
      const res = await request(app)
        .get('/api/events/any-id')
        .set('Authorization', 'Bearer test-token');
      
      expect(res.status).toBe(200);
    });

    it('GET /api/clubs/:id returns 200 (stub)', async () => {
      const res = await request(app)
        .get('/api/clubs/any-id')
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
        clubId: 'club-1',
        userId: 'test-user-id',
        status: 'inactive',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .get('/api/clubs/club-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.isMember).toBe(false);
      expect(res.body.membershipStatus).toBe('inactive');
    });
  });

  describe('POST /api/events/:id/join', () => {
    const { mockEventsRepository } = require('../db/repositories');

    beforeEach(() => {
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
    const { mockClubMembersRepository } = require('../db/repositories');

    beforeEach(() => {
      mockClubMembersRepository.findByClubAndUser.mockReset();
      mockClubMembersRepository.deactivate.mockReset();
    });

    it('returns 200 when active membership is deactivated', async () => {
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: 'club-1',
        userId: 'test-user-id',
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
      });
      mockClubMembersRepository.deactivate.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: 'club-1',
        userId: 'test-user-id',
        status: 'inactive',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .post('/api/clubs/club-1/leave')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.status).toBe('inactive');
    });

    it('returns 400 when user is not a member', async () => {
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce(null);

      const res = await request(app)
        .post('/api/clubs/club-1/leave')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('not_member');
    });

    it('returns 400 when membership already inactive', async () => {
      mockClubMembersRepository.findByClubAndUser.mockResolvedValueOnce({
        id: 'cm-1',
        clubId: 'club-1',
        userId: 'test-user-id',
        status: 'inactive',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const res = await request(app)
        .post('/api/clubs/club-1/leave')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body.code).toBe('already_left');
    });
  });

  describe('POST /api/users', () => {
    const { mockUsersRepository } = require('../db/repositories');

    it('should return 409 when user with firebaseUid already exists', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({
        id: 'existing-id',
        firebaseUid: 'existing-uid',
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
          firebaseUid: 'existing-uid',
          email: 'existing@example.com',
          name: 'Existing',
        });

      expect(res.status).toBe(409);
      expect(res.body.message).toMatch(/already exists/i);
      expect(mockUsersRepository.create).not.toHaveBeenCalled();
    });
  });

  describe('DELETE /api/users/me', () => {
    const { mockUsersRepository } = require('../db/repositories');

    it('should return 404 when user not found by firebase uid', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce(null);

      const res = await request(app)
        .delete('/api/users/me')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(404);
      expect(res.body.message).toMatch(/not found/i);
      expect(mockUsersRepository.delete).not.toHaveBeenCalled();
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
      // onlyActive=true filters to CAPTURED and CONTESTED only
      const statuses = res.body.territories.map((t: { status: string }) => t.status);
      expect(statuses.every((s: string) => s === 'captured' || s === 'contested')).toBe(true);
    });

    it('should return filtered territories when clubId is provided', async () => {
      const res = await request(app)
        .get('/api/map/data?cityId=spb&clubId=club-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(res.body.territories).toBeDefined();
      expect(res.body.territories.every((t: { clubId: string }) => t.clubId === 'club-1')).toBe(true);
    });
  });

  describe('cityId validation and filtering', () => {
    it('GET /api/events without cityId returns 400 with validation_error', async () => {
      const res = await request(app)
        .get('/api/events')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body.details?.fields?.some((f: { field: string }) => f.field === 'cityId')).toBe(true);
    });

    it('GET /api/map/data without cityId returns 400 with validation_error', async () => {
      const res = await request(app)
        .get('/api/map/data')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('code', 'validation_error');
      expect(res.body.details?.fields?.some((f: { field: string }) => f.field === 'cityId')).toBe(true);
    });

    it('GET /api/territories returns territories only for requested city', async () => {
      const res = await request(app)
        .get('/api/territories?cityId=spb&clubId=club-1')
        .set('Authorization', 'Bearer test-token');

      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
      expect(res.body.every((t: { cityId: string }) => t.cityId === 'spb')).toBe(true);
    });
  });
});
