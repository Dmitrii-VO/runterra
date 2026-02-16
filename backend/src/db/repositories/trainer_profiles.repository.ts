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
    createdAt: row.created_at,
  };
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
  }): Promise<TrainerProfile> {
    const row = await this.queryOne<TrainerProfileRow>(
      `INSERT INTO trainer_profiles (user_id, bio, specialization, experience_years, certificates)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [
        data.userId,
        data.bio || null,
        data.specialization,
        data.experienceYears,
        JSON.stringify(data.certificates || []),
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
}

let instance: TrainerProfilesRepository | null = null;

export function getTrainerProfilesRepository(): TrainerProfilesRepository {
  if (!instance) {
    instance = new TrainerProfilesRepository();
  }
  return instance;
}
