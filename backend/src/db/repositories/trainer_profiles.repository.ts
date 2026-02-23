/**
 * Trainer profiles repository
 */

import { BaseRepository } from './base.repository';
import { TrainerProfile, Certificate } from '../../modules/trainer/trainer.entity';

interface TrainerProfileRow {
  user_id: string;
  bio: string | null;
  specialization: string[];
  experience_years: number;
  certificates: unknown;
  accepts_private_clients: boolean;
  created_at: Date;
}

function rowToProfile(row: TrainerProfileRow): TrainerProfile {
  let certs: Certificate[] = [];
  if (row.certificates) {
    try {
      certs = (typeof row.certificates === 'string'
        ? JSON.parse(row.certificates)
        : row.certificates) as Certificate[];
    } catch {
      certs = [];
    }
  }
  return {
    userId: row.user_id,
    bio: row.bio || undefined,
    specialization: row.specialization,
    experienceYears: row.experience_years,
    certificates: certs,
    acceptsPrivateClients: row.accepts_private_clients,
    createdAt: row.created_at,
  };
}

export interface PublicTrainerEntry {
  userId: string;
  name: string;
  bio?: string;
  specialization: string[];
  experienceYears: number;
  acceptsPrivateClients: true;
}

export class TrainerProfilesRepository extends BaseRepository {
  async findByUserId(userId: string): Promise<TrainerProfile | null> {
    const row = await this.queryOne<TrainerProfileRow>(
      'SELECT * FROM trainer_profiles WHERE user_id = $1',
      [userId],
    );
    return row ? rowToProfile(row) : null;
  }

  async create(data: {
    userId: string;
    bio?: string;
    specialization: string[];
    experienceYears: number;
    certificates?: Certificate[];
    acceptsPrivateClients?: boolean;
  }): Promise<TrainerProfile> {
    const row = await this.queryOne<TrainerProfileRow>(
      `INSERT INTO trainer_profiles (user_id, bio, specialization, experience_years, certificates, accepts_private_clients)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        data.userId,
        data.bio || null,
        data.specialization,
        data.experienceYears,
        JSON.stringify(data.certificates || []),
        data.acceptsPrivateClients ?? false,
      ],
    );
    if (!row) throw new Error('Insert trainer_profiles failed');
    return rowToProfile(row);
  }

  async update(userId: string, data: {
    bio?: string;
    specialization?: string[];
    experienceYears?: number;
    certificates?: Certificate[];
    acceptsPrivateClients?: boolean;
  }): Promise<TrainerProfile | null> {
    const sets: string[] = [];
    const params: unknown[] = [];
    let idx = 1;

    if (data.bio !== undefined) {
      sets.push(`bio = $${idx++}`);
      params.push(data.bio);
    }
    if (data.specialization !== undefined) {
      sets.push(`specialization = $${idx++}`);
      params.push(data.specialization);
    }
    if (data.experienceYears !== undefined) {
      sets.push(`experience_years = $${idx++}`);
      params.push(data.experienceYears);
    }
    if (data.certificates !== undefined) {
      sets.push(`certificates = $${idx++}`);
      params.push(JSON.stringify(data.certificates));
    }
    if (data.acceptsPrivateClients !== undefined) {
      sets.push(`accepts_private_clients = $${idx++}`);
      params.push(data.acceptsPrivateClients);
    }

    if (sets.length === 0) {
      return this.findByUserId(userId);
    }

    params.push(userId);
    const row = await this.queryOne<TrainerProfileRow>(
      `UPDATE trainer_profiles SET ${sets.join(', ')} WHERE user_id = $${idx} RETURNING *`,
      params,
    );
    return row ? rowToProfile(row) : null;
  }

  /** Find public trainers for discovery (only accepts_private_clients = true) */
  async findPublicTrainers(filters: {
    cityId?: string;
    specialization?: string;
  }): Promise<PublicTrainerEntry[]> {
    const conditions: string[] = ['tp.accepts_private_clients = true'];
    const params: unknown[] = [];
    let idx = 1;

    if (filters.cityId) {
      conditions.push(`u.city_id = $${idx++}`);
      params.push(filters.cityId);
    }
    if (filters.specialization) {
      conditions.push(`$${idx++} = ANY(tp.specialization)`);
      params.push(filters.specialization.toUpperCase());
    }

    const where = conditions.join(' AND ');
    const rows = await this.queryMany<{
      user_id: string;
      name: string;
      first_name: string | null;
      last_name: string | null;
      bio: string | null;
      specialization: string[];
      experience_years: number;
    }>(
      `SELECT tp.user_id, u.name, u.first_name, u.last_name, tp.bio, tp.specialization, tp.experience_years
       FROM trainer_profiles tp
       JOIN users u ON u.id = tp.user_id
       WHERE ${where}
       ORDER BY tp.created_at DESC`,
      params,
    );

    return rows.map((row) => {
      const first = row.first_name?.trim();
      const last = row.last_name?.trim();
      const fullName = [first, last].filter(Boolean).join(' ').trim() || row.name;
      return {
        userId: row.user_id,
        name: fullName,
        bio: row.bio || undefined,
        specialization: row.specialization,
        experienceYears: row.experience_years,
        acceptsPrivateClients: true,
      };
    });
  }
}

let instance: TrainerProfilesRepository | null = null;

export function getTrainerProfilesRepository(): TrainerProfilesRepository {
  if (!instance) {
    instance = new TrainerProfilesRepository();
  }
  return instance;
}
