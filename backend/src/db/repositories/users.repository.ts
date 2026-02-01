/**
 * Users repository - database operations for users
 */

import { BaseRepository } from './base.repository';
import { User, UserStatus } from '../../modules/users/user.entity';

interface UserRow {
  id: string;
  firebase_uid: string;
  email: string;
  name: string;
  avatar_url: string | null;
  city_id: string | null;
  is_mercenary: boolean;
  status: string;
  created_at: Date;
  updated_at: Date;
}

function rowToUser(row: UserRow): User {
  return {
    id: row.id,
    firebaseUid: row.firebase_uid,
    email: row.email,
    name: row.name,
    avatarUrl: row.avatar_url || undefined,
    cityId: row.city_id || undefined,
    isMercenary: row.is_mercenary,
    status: row.status as UserStatus,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export class UsersRepository extends BaseRepository {
  async findById(id: string): Promise<User | null> {
    const row = await this.queryOne<UserRow>(
      'SELECT * FROM users WHERE id = $1',
      [id]
    );
    return row ? rowToUser(row) : null;
  }

  async findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    const row = await this.queryOne<UserRow>(
      'SELECT * FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    return row ? rowToUser(row) : null;
  }

  async findAll(limit = 50, offset = 0): Promise<User[]> {
    const rows = await this.queryMany<UserRow>(
      'SELECT * FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    return rows.map(rowToUser);
  }

  async create(data: {
    firebaseUid: string;
    email: string;
    name: string;
    avatarUrl?: string;
    cityId?: string;
    isMercenary?: boolean;
  }): Promise<User> {
    const row = await this.queryOne<UserRow>(
      `INSERT INTO users (firebase_uid, email, name, avatar_url, city_id, is_mercenary)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        data.firebaseUid,
        data.email,
        data.name,
        data.avatarUrl || null,
        data.cityId || null,
        data.isMercenary || false,
      ]
    );
    return rowToUser(row!);
  }

  async update(id: string, data: Partial<{
    name: string;
    avatarUrl: string;
    cityId: string;
    isMercenary: boolean;
    status: UserStatus;
  }>): Promise<User | null> {
    const fields: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    if (data.name !== undefined) {
      fields.push(`name = $${paramIndex++}`);
      values.push(data.name);
    }
    if (data.avatarUrl !== undefined) {
      fields.push(`avatar_url = $${paramIndex++}`);
      values.push(data.avatarUrl);
    }
    if (data.cityId !== undefined) {
      fields.push(`city_id = $${paramIndex++}`);
      values.push(data.cityId);
    }
    if (data.isMercenary !== undefined) {
      fields.push(`is_mercenary = $${paramIndex++}`);
      values.push(data.isMercenary);
    }
    if (data.status !== undefined) {
      fields.push(`status = $${paramIndex++}`);
      values.push(data.status);
    }

    if (fields.length === 0) {
      return this.findById(id);
    }

    fields.push(`updated_at = NOW()`);
    values.push(id);

    const row = await this.queryOne<UserRow>(
      `UPDATE users SET ${fields.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );
    return row ? rowToUser(row) : null;
  }

  /**
   * Find or create user by Firebase UID
   * Used during authentication
   */
  async findOrCreate(data: {
    firebaseUid: string;
    email: string;
    name: string;
    avatarUrl?: string;
  }): Promise<User> {
    const existing = await this.findByFirebaseUid(data.firebaseUid);
    if (existing) {
      return existing;
    }
    return this.create(data);
  }
}

// Singleton instance
let instance: UsersRepository | null = null;

export function getUsersRepository(): UsersRepository {
  if (!instance) {
    instance = new UsersRepository();
  }
  return instance;
}
