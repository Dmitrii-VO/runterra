/**
 * Trainer-client relationship repository
 */

import { BaseRepository } from './base.repository';
import { TrainerClient, TrainerClientStatus } from '../../modules/trainer/trainer.entity';

interface TrainerClientRow {
  id: string;
  trainer_id: string;
  client_id: string;
  status: TrainerClientStatus;
  created_at: Date;
}

function rowToEntity(row: TrainerClientRow): TrainerClient {
  return {
    id: row.id,
    trainerId: row.trainer_id,
    clientId: row.client_id,
    status: row.status,
    createdAt: row.created_at,
  };
}

export interface TrainerClientWithUser {
  id: string;
  trainerId: string;
  clientId: string;
  clientName: string;
  clientAvatarUrl?: string;
  status: TrainerClientStatus;
  createdAt: Date;
  lastRunAt?: Date;
}

export interface MyTrainerEntry {
  id: string;
  trainerId: string;
  clientId: string;
  trainerName: string;
  trainerAvatarUrl?: string;
  status: TrainerClientStatus;
  createdAt: Date;
}

export class TrainerClientsRepository extends BaseRepository {
  async findByTrainerAndClient(
    trainerId: string,
    clientId: string,
  ): Promise<TrainerClient | null> {
    const row = await this.queryOne<TrainerClientRow>(
      'SELECT * FROM trainer_clients WHERE trainer_id = $1 AND client_id = $2',
      [trainerId, clientId],
    );
    return row ? rowToEntity(row) : null;
  }

  async findById(id: string): Promise<TrainerClient | null> {
    const row = await this.queryOne<TrainerClientRow>(
      'SELECT * FROM trainer_clients WHERE id = $1',
      [id],
    );
    return row ? rowToEntity(row) : null;
  }

  async updateStatus(id: string, status: TrainerClientStatus): Promise<TrainerClient | null> {
    const row = await this.queryOne<TrainerClientRow>(
      'UPDATE trainer_clients SET status = $1 WHERE id = $2 RETURNING *',
      [status, id],
    );
    return row ? rowToEntity(row) : null;
  }

  /** Compare-and-swap: only updates if current status is 'pending' */
  async updateStatusIfPending(id: string, status: TrainerClientStatus): Promise<TrainerClient | null> {
    const row = await this.queryOne<TrainerClientRow>(
      "UPDATE trainer_clients SET status = $1 WHERE id = $2 AND status = 'pending' RETURNING *",
      [status, id],
    );
    return row ? rowToEntity(row) : null;
  }

  /** Re-apply after rejection: update existing rejected record back to pending */
  async upsertPending(trainerId: string, clientId: string): Promise<TrainerClient> {
    const row = await this.queryOne<TrainerClientRow>(
      `INSERT INTO trainer_clients (trainer_id, client_id, status)
       VALUES ($1, $2, 'pending')
       ON CONFLICT (trainer_id, client_id) DO UPDATE SET status = 'pending'
       RETURNING *`,
      [trainerId, clientId],
    );
    if (!row) throw new Error('Upsert trainer_clients failed');
    return rowToEntity(row);
  }

  async delete(trainerId: string, clientId: string): Promise<boolean> {
    const result = await this.queryOne<{ id: string }>(
      'DELETE FROM trainer_clients WHERE trainer_id = $1 AND client_id = $2 AND status = $3 RETURNING id',
      [trainerId, clientId, 'pending'],
    );
    return result !== null;
  }

  async findPendingByTrainer(trainerId: string): Promise<TrainerClientWithUser[]> {
    const rows = await this.queryMany<{
      id: string;
      trainer_id: string;
      client_id: string;
      status: TrainerClientStatus;
      created_at: Date;
      client_name: string;
      first_name: string | null;
      last_name: string | null;
      avatar_url: string | null;
    }>(
      `SELECT tc.*, u.name AS client_name, u.first_name, u.last_name, u.avatar_url
       FROM trainer_clients tc
       JOIN users u ON u.id = tc.client_id
       WHERE tc.trainer_id = $1 AND tc.status = 'pending'
       ORDER BY tc.created_at DESC`,
      [trainerId],
    );
    return rows.map(row => ({
      id: row.id,
      trainerId: row.trainer_id,
      clientId: row.client_id,
      clientName: [row.first_name, row.last_name].filter(Boolean).join(' ').trim() || row.client_name,
      clientAvatarUrl: row.avatar_url || undefined,
      status: row.status,
      createdAt: row.created_at,
    }));
  }

  async findActiveClientsByTrainer(trainerId: string): Promise<TrainerClientWithUser[]> {
    const rows = await this.queryMany<{
      id: string;
      trainer_id: string;
      client_id: string;
      status: TrainerClientStatus;
      created_at: Date;
      client_name: string;
      first_name: string | null;
      last_name: string | null;
      avatar_url: string | null;
      last_run_at: Date | null;
    }>(
      `SELECT tc.*, u.name AS client_name, u.first_name, u.last_name, u.avatar_url,
              (SELECT MAX(r.created_at) FROM runs r WHERE r.user_id = tc.client_id) AS last_run_at
       FROM trainer_clients tc
       JOIN users u ON u.id = tc.client_id
       WHERE tc.trainer_id = $1 AND tc.status = 'active'
       ORDER BY last_run_at DESC NULLS LAST`,
      [trainerId],
    );
    return rows.map(row => ({
      id: row.id,
      trainerId: row.trainer_id,
      clientId: row.client_id,
      clientName: [row.first_name, row.last_name].filter(Boolean).join(' ').trim() || row.client_name,
      clientAvatarUrl: row.avatar_url || undefined,
      status: row.status,
      createdAt: row.created_at,
      lastRunAt: row.last_run_at || undefined,
    }));
  }

  async findActiveTrainersByClient(clientId: string): Promise<MyTrainerEntry[]> {
    const rows = await this.queryMany<{
      id: string;
      trainer_id: string;
      client_id: string;
      status: TrainerClientStatus;
      created_at: Date;
      trainer_name: string;
      first_name: string | null;
      last_name: string | null;
      avatar_url: string | null;
    }>(
      `SELECT tc.*, u.name AS trainer_name, u.first_name, u.last_name, u.avatar_url
       FROM trainer_clients tc
       JOIN users u ON u.id = tc.trainer_id
       WHERE tc.client_id = $1 AND tc.status = 'active'
       ORDER BY tc.created_at DESC`,
      [clientId],
    );
    return rows.map(row => ({
      id: row.id,
      trainerId: row.trainer_id,
      clientId: row.client_id,
      trainerName: [row.first_name, row.last_name].filter(Boolean).join(' ').trim() || row.trainer_name,
      trainerAvatarUrl: row.avatar_url || undefined,
      status: row.status,
      createdAt: row.created_at,
    }));
  }

  async countActiveClientsByTrainer(trainerId: string): Promise<number> {
    const row = await this.queryOne<{ count: string }>(
      'SELECT COUNT(*) AS count FROM trainer_clients WHERE trainer_id = $1 AND status = $2',
      [trainerId, 'active'],
    );
    return parseInt(row?.count ?? '0', 10);
  }
}

let instance: TrainerClientsRepository | null = null;

export function getTrainerClientsRepository(): TrainerClientsRepository {
  if (!instance) {
    instance = new TrainerClientsRepository();
  }
  return instance;
}
