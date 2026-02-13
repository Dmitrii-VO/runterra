import request from 'supertest';
import { createApp } from '../app';
import { getAuthProvider } from '../modules/auth';
import { getUsersRepository, getClubMembersRepository } from '../db/repositories';

// Mock dependencies
jest.mock('../modules/auth');
jest.mock('../db/repositories');
jest.mock('../modules/territories/territories.config', () => ({
  ...jest.requireActual('../modules/territories/territories.config'),
  getTerritoryById: jest.fn(),
}));

import { getTerritoryById } from '../modules/territories/territories.config';

const app = createApp();

describe('Territories Routes - Capture', () => {
  const mockTerritoryId = 'spb-park-300';
  const mockClubId = '6f888888-8888-8888-8888-888888888888';
  const mockUserId = 'user-123';
  const mockFirebaseUid = 'firebase-uid-123';

  beforeEach(() => {
    jest.clearAllMocks();

    // Default mock for territory
    (getTerritoryById as jest.Mock).mockReturnValue({
      id: mockTerritoryId,
      name: 'Test Territory',
      status: 'free',
      cityId: 'spb',
    });

    // Default mock for auth provider (authenticated)
    (getAuthProvider as jest.Mock).mockReturnValue({
      verifyToken: jest.fn().mockResolvedValue({
        valid: true,
        user: { uid: mockFirebaseUid, email: 'test@example.com' },
      }),
    });

    // Default mock for users repo
    (getUsersRepository as jest.Mock).mockReturnValue({
      findByFirebaseUid: jest.fn().mockResolvedValue({ id: mockUserId }),
    });
  });

  it('allows capture for an ACTIVE club member', async () => {
    (getClubMembersRepository as jest.Mock).mockReturnValue({
      findByClubAndUser: jest.fn().mockResolvedValue({
        status: 'active',
        role: 'member',
      }),
    });

    const res = await request(app)
      .post(`/api/territories/${mockTerritoryId}/capture`)
      .set('Authorization', 'Bearer valid-token')
      .send({ clubId: mockClubId });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toBe('Contribution accepted');
  });

  it('returns 403 Forbidden for a PENDING club member', async () => {
    (getClubMembersRepository as jest.Mock).mockReturnValue({
      findByClubAndUser: jest.fn().mockResolvedValue({
        status: 'pending',
        role: 'member',
      }),
    });

    const res = await request(app)
      .post(`/api/territories/${mockTerritoryId}/capture`)
      .set('Authorization', 'Bearer valid-token')
      .send({ clubId: mockClubId });

    expect(res.status).toBe(403);
    expect(res.body.code).toBe('forbidden');
    expect(res.body.message).toContain('Only active club members');
    expect(res.body.details.status).toBe('pending');
  });

  it('returns 403 Forbidden if user is NOT a member', async () => {
    (getClubMembersRepository as jest.Mock).mockReturnValue({
      findByClubAndUser: jest.fn().mockResolvedValue(null),
    });

    const res = await request(app)
      .post(`/api/territories/${mockTerritoryId}/capture`)
      .set('Authorization', 'Bearer valid-token')
      .send({ clubId: mockClubId });

    expect(res.status).toBe(403);
    expect(res.body.code).toBe('forbidden');
    expect(res.body.message).toContain('You must be a member');
  });

  it('returns 401 Unauthorized if token is missing', async () => {
    const res = await request(app)
      .post(`/api/territories/${mockTerritoryId}/capture`)
      .send({ clubId: mockClubId });

    expect(res.status).toBe(401);
    expect(res.body.code).toBe('unauthorized');
  });

  it('returns 400 Validation Error for invalid clubId format', async () => {
    const res = await request(app)
      .post(`/api/territories/${mockTerritoryId}/capture`)
      .set('Authorization', 'Bearer valid-token')
      .send({ clubId: 'not-a-uuid' });

    expect(res.status).toBe(400);
    expect(res.body.code).toBe('validation_error');
  });

  it('returns 404 Not Found for non-existent territory', async () => {
    (getTerritoryById as jest.Mock).mockReturnValue(null);

    const res = await request(app)
      .post('/api/territories/unknown-id/capture')
      .set('Authorization', 'Bearer valid-token')
      .send({ clubId: mockClubId });

    expect(res.status).toBe(404);
    expect(res.body.code).toBe('not_found');
  });
});
