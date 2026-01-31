import request from 'supertest';
import { createApp } from '../app';

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
        .get('/api/clubs')
        .set('Authorization', 'Bearer test-token');
      
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('GET /api/territories', () => {
    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/territories')
        .set('Authorization', 'Bearer test-token');
      
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body)).toBe(true);
    });
  });

  describe('GET /api/events', () => {
    it('returns 200 with array', async () => {
      const res = await request(app)
        .get('/api/events')
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
        .get('/api/map/data')
        .set('Authorization', 'Bearer test-token');
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('territories');
      expect(res.body).toHaveProperty('events');
      expect(Array.isArray(res.body.territories)).toBe(true);
      expect(Array.isArray(res.body.events)).toBe(true);
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
});
