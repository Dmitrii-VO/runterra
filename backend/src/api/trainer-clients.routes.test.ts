import request from 'supertest';
import { createApp } from '../app';
import { getAuthProvider } from '../modules/auth';

jest.mock('../modules/auth');
jest.mock('../db/repositories');

const app = createApp();

describe('Trainer Clients Routes', () => {
  const trainerId = '11111111-1111-1111-1111-111111111111';
  const clientId = '22222222-2222-2222-2222-222222222222';
  const requestId = '33333333-3333-3333-3333-333333333333';

  const {
    mockUsersRepository,
    mockTrainerProfilesRepository,
    mockTrainerClientsRepository,
  } = require('../db/repositories');

  const mockProfile = {
    userId: trainerId,
    bio: 'Coach',
    specialization: ['GENERAL'],
    experienceYears: 5,
    certificates: [],
    acceptsPrivateClients: true,
    createdAt: new Date(),
  };

  const mockPendingRequest = {
    id: requestId,
    trainerId,
    clientId,
    status: 'pending',
    createdAt: new Date(),
  };

  beforeEach(() => {
    (getAuthProvider as jest.Mock).mockReturnValue({
      verifyToken: jest.fn().mockResolvedValue({
        valid: true,
        user: { uid: 'uid-client', email: 'client@example.com' },
      }),
    });
    mockUsersRepository.findByFirebaseUid.mockResolvedValue({ id: clientId, firebaseUid: 'uid-client' });
    mockTrainerProfilesRepository.findByUserId.mockResolvedValue(mockProfile);
    mockTrainerClientsRepository.findByTrainerAndClient.mockResolvedValue(null);
    mockTrainerClientsRepository.findById.mockResolvedValue(null);
    mockTrainerClientsRepository.upsertPending.mockResolvedValue(mockPendingRequest);
    mockTrainerClientsRepository.delete.mockResolvedValue(true);
    mockTrainerClientsRepository.findPendingByTrainer.mockResolvedValue([]);
    mockTrainerClientsRepository.findActiveClientsByTrainer.mockResolvedValue([]);
    mockTrainerClientsRepository.findActiveTrainersByClient.mockResolvedValue([]);
    mockTrainerClientsRepository.updateStatus.mockResolvedValue({ ...mockPendingRequest, status: 'active' });
  });

  describe('GET /api/trainer/:userId/request-status', () => {
    it('returns none when no relationship exists', async () => {
      const res = await request(app)
        .get(`/api/trainer/${trainerId}/request-status`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ status: 'none' });
    });

    it('returns pending when request exists', async () => {
      mockTrainerClientsRepository.findByTrainerAndClient.mockResolvedValueOnce(mockPendingRequest);
      const res = await request(app)
        .get(`/api/trainer/${trainerId}/request-status`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('pending');
    });
  });

  describe('POST /api/trainer/:userId/request', () => {
    it('returns 201 when request is created', async () => {
      const res = await request(app)
        .post(`/api/trainer/${trainerId}/request`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('status', 'pending');
      expect(mockTrainerClientsRepository.upsertPending).toHaveBeenCalledWith(trainerId, clientId);
    });

    it('returns 400 when trainer and client are the same user', async () => {
      mockUsersRepository.findByFirebaseUid.mockResolvedValueOnce({ id: trainerId, firebaseUid: 'uid-client' });
      const res = await request(app)
        .post(`/api/trainer/${trainerId}/request`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(400);
      expect(res.body.code).toBe('bad_request');
    });

    it('returns 404 when trainer does not accept private clients', async () => {
      mockTrainerProfilesRepository.findByUserId.mockResolvedValueOnce({
        ...mockProfile,
        acceptsPrivateClients: false,
      });
      const res = await request(app)
        .post(`/api/trainer/${trainerId}/request`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(404);
    });

    it('returns 409 already_client when active relationship exists', async () => {
      mockTrainerClientsRepository.findByTrainerAndClient.mockResolvedValueOnce({
        ...mockPendingRequest,
        status: 'active',
      });
      const res = await request(app)
        .post(`/api/trainer/${trainerId}/request`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(409);
      expect(res.body.code).toBe('already_client');
    });

    it('returns 409 request_exists when pending request exists', async () => {
      mockTrainerClientsRepository.findByTrainerAndClient.mockResolvedValueOnce(mockPendingRequest);
      const res = await request(app)
        .post(`/api/trainer/${trainerId}/request`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(409);
      expect(res.body.code).toBe('request_exists');
    });
  });

  describe('DELETE /api/trainer/:userId/request', () => {
    it('returns 200 when pending request is withdrawn', async () => {
      const res = await request(app)
        .delete(`/api/trainer/${trainerId}/request`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ ok: true });
    });

    it('returns 404 when no pending request exists', async () => {
      mockTrainerClientsRepository.delete.mockResolvedValueOnce(false);
      const res = await request(app)
        .delete(`/api/trainer/${trainerId}/request`)
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/trainer/requests', () => {
    it('returns pending requests list', async () => {
      mockTrainerClientsRepository.findPendingByTrainer.mockResolvedValueOnce([
        { id: requestId, trainerId, clientId, clientName: 'Alice', status: 'pending', createdAt: new Date() },
      ]);
      const res = await request(app)
        .get('/api/trainer/requests')
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(200);
      expect(res.body).toHaveLength(1);
    });
  });

  describe('PATCH /api/trainer/requests/:id', () => {
    it('returns 200 when owner accepts request', async () => {
      mockTrainerClientsRepository.findById.mockResolvedValueOnce({
        ...mockPendingRequest,
        trainerId: clientId,
      });
      const res = await request(app)
        .patch(`/api/trainer/requests/${requestId}`)
        .set('Authorization', 'Bearer token')
        .send({ action: 'accept' });
      expect(res.status).toBe(200);
    });

    it('returns 403 when request belongs to another trainer', async () => {
      mockTrainerClientsRepository.findById.mockResolvedValueOnce({
        ...mockPendingRequest,
        trainerId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      });
      const res = await request(app)
        .patch(`/api/trainer/requests/${requestId}`)
        .set('Authorization', 'Bearer token')
        .send({ action: 'accept' });
      expect(res.status).toBe(403);
    });

    it('returns 400 when action is invalid', async () => {
      const res = await request(app)
        .patch(`/api/trainer/requests/${requestId}`)
        .set('Authorization', 'Bearer token')
        .send({ action: 'invalid' });
      expect(res.status).toBe(400);
    });

    it('returns 404 when request not found', async () => {
      const res = await request(app)
        .patch(`/api/trainer/requests/${requestId}`)
        .set('Authorization', 'Bearer token')
        .send({ action: 'reject' });
      expect(res.status).toBe(404);
    });
  });

  describe('GET /api/trainer/clients', () => {
    it('returns active clients list', async () => {
      mockTrainerClientsRepository.findActiveClientsByTrainer.mockResolvedValueOnce([
        { id: requestId, trainerId, clientId, clientName: 'Alice', status: 'active', createdAt: new Date() },
      ]);
      const res = await request(app)
        .get('/api/trainer/clients')
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(200);
      expect(res.body).toHaveLength(1);
    });
  });

  describe('GET /api/trainer/my-trainers', () => {
    it('returns active trainers for client', async () => {
      mockTrainerClientsRepository.findActiveTrainersByClient.mockResolvedValueOnce([
        { id: requestId, trainerId, clientId, trainerName: 'Bob', status: 'active', createdAt: new Date() },
      ]);
      const res = await request(app)
        .get('/api/trainer/my-trainers')
        .set('Authorization', 'Bearer token');
      expect(res.status).toBe(200);
      expect(res.body).toHaveLength(1);
    });
  });
});
