import request from 'supertest';
import { createApp } from './app';

const app = createApp();

describe('App', () => {
  describe('GET /health', () => {
    it('returns 200 with status ok', async () => {
      const res = await request(app).get('/health');
      
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ status: 'ok' });
    });
  });

  describe('Unknown routes', () => {
    it('returns 404 with code and message for unknown routes', async () => {
      const res = await request(app).get('/unknown-route');

      expect(res.status).toBe(404);
      expect(res.body.code).toBe('not_found');
      expect(res.body.message).toContain('Route not found');
    });

    it('returns 404 for POST to root', async () => {
      const res = await request(app)
        .post('/')
        .send({ foo: 'bar' })
        .set('Content-Type', 'application/json');

      expect(res.status).toBe(404);
      expect(res.body.code).toBe('not_found');
    });
  });

  describe('JSON body limit', () => {
    it('accepts valid JSON body', async () => {
      const res = await request(app)
        .post('/api/users')
        .send({ email: 'test@example.com' })
        .set('Content-Type', 'application/json');
      
      // Should not fail due to body parsing (may fail auth, that's ok)
      expect(res.status).not.toBe(413);
    });
  });
});
