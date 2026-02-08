/**
 * Clubs repository - database operations for clubs
 */

import { BaseRepository } from './base.repository';
import { Club, ClubStatus } from '../../modules/clubs';

interface ClubRow {
  id: string;
  name: string;
  description: string | null;
  status: string;
  city_id: string;
  creator_id: string;
  created_at: Date;
  updated_at: Date;
}

function rowToClub(row: ClubRow): Club {
  return {
    id: row.id,
    name: row.name,
    description: row.description || undefined,
    status: row.status as ClubStatus,
    cityId: row.city_id,
    creatorId: row.creator_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export class ClubsRepository extends BaseRepository {
  async findById(id: string): Promise<Club | null> {
    const row = await this.queryOne<ClubRow>(
      'SELECT * FROM clubs WHERE id = $1',
      [id]
    );
    return row ? rowToClub(row) : null;
  }

  async findByIds(ids: string[]): Promise<Club[]> {
    const uniqueIds = Array.from(new Set(ids));
    if (uniqueIds.length === 0) return [];
    const rows = await this.queryMany<ClubRow>(
      'SELECT * FROM clubs WHERE id = ANY($1)',
      [uniqueIds]
    );
    return rows.map(rowToClub);
  }

  async findByCityId(cityId: string): Promise<Club[]> {
    const rows = await this.queryMany<ClubRow>(
      'SELECT * FROM clubs WHERE city_id = $1 AND status = $2 ORDER BY created_at DESC',
      [cityId, ClubStatus.ACTIVE]
    );
    return rows.map(rowToClub);
  }

  async create(
    name: string,
    cityId: string,
    creatorId: string,
    description?: string,
    status: ClubStatus = ClubStatus.PENDING
  ): Promise<Club> {
    const row = await this.queryOne<ClubRow>(
      `INSERT INTO clubs (name, description, city_id, creator_id, status)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [name, description || null, cityId, creatorId, status]
    );
    if (!row) {
      throw new Error('Failed to create club');
    }
    return rowToClub(row);
  }

  async update(
    id: string,
    updates: { name?: string; description?: string; status?: ClubStatus }
  ): Promise<Club | null> {
    const setClauses: string[] = ['updated_at = NOW()'];
    const values: unknown[] = [];
    let paramIndex = 1;

    if (updates.name !== undefined) {
      setClauses.push(`name = $${paramIndex++}`);
      values.push(updates.name);
    }
    if (updates.description !== undefined) {
      setClauses.push(`description = $${paramIndex++}`);
      values.push(updates.description);
    }
    if (updates.status !== undefined) {
      setClauses.push(`status = $${paramIndex++}`);
      values.push(updates.status);
    }

    if (setClauses.length === 1) {
      // Only updated_at — nothing to update
      return this.findById(id);
    }

    values.push(id);
    const row = await this.queryOne<ClubRow>(
      `UPDATE clubs SET ${setClauses.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );
    return row ? rowToClub(row) : null;
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.query('DELETE FROM clubs WHERE id = $1', [id]);
    return (result.rowCount ?? 0) > 0;
  }
}

// Singleton instance
let instance: ClubsRepository | null = null;

export function getClubsRepository(): ClubsRepository {
  if (!instance) {
    instance = new ClubsRepository();
  }
  return instance;
}
