/**
 * Club members repository - membership records for user-club relation.
 */

import { BaseRepository } from './base.repository';

interface ClubMemberRow {
  id: string;
  club_id: string;
  user_id: string;
  status: string;
  role: string;
  created_at: Date;
  updated_at: Date;
}

export interface ClubMembershipRow {
  id: string;
  clubId: string;
  userId: string;
  status: 'pending' | 'active' | 'inactive' | 'suspended';
  role: 'member' | 'trainer' | 'leader';
  createdAt: Date;
  updatedAt: Date;
}

function rowToMembership(row: ClubMemberRow): ClubMembershipRow {
  return {
    id: row.id,
    clubId: row.club_id,
    userId: row.user_id,
    status: row.status as ClubMembershipRow['status'],
    role: row.role as ClubMembershipRow['role'],
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export class ClubMembersRepository extends BaseRepository {
  async findByClubAndUser(clubId: string, userId: string): Promise<ClubMembershipRow | null> {
    const row = await this.queryOne<ClubMemberRow>(
      'SELECT * FROM club_members WHERE club_id = $1 AND user_id = $2',
      [clubId, userId],
    );
    return row ? rowToMembership(row) : null;
  }

  async create(
    clubId: string,
    userId: string,
    status: 'pending' | 'active' = 'active',
    role: 'member' | 'trainer' | 'leader' = 'member'
  ): Promise<ClubMembershipRow> {
    const row = await this.queryOne<ClubMemberRow>(
      `INSERT INTO club_members (club_id, user_id, status, role)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [clubId, userId, status, role],
    );
    if (!row) throw new Error('Insert club_members failed');
    return rowToMembership(row);
  }

  async deactivate(clubId: string, userId: string): Promise<ClubMembershipRow | null> {
    const row = await this.queryOne<ClubMemberRow>(
      `UPDATE club_members
       SET status = 'inactive', updated_at = NOW()
       WHERE club_id = $1 AND user_id = $2
       RETURNING *`,
      [clubId, userId],
    );
    return row ? rowToMembership(row) : null;
  }

  async activate(clubId: string, userId: string): Promise<ClubMembershipRow | null> {
    const row = await this.queryOne<ClubMemberRow>(
      `UPDATE club_members
       SET status = 'active', updated_at = NOW()
       WHERE club_id = $1 AND user_id = $2
       RETURNING *`,
      [clubId, userId],
    );
    return row ? rowToMembership(row) : null;
  }

  async findActiveByUser(userId: string): Promise<ClubMembershipRow[]> {
    const rows = await this.queryMany<ClubMemberRow>(
      'SELECT * FROM club_members WHERE user_id = $1 AND status = $2 ORDER BY created_at ASC',
      [userId, 'active'],
    );
    return rows.map(rowToMembership);
  }

  /** Get primary (most recent) club id for user (MVP: one club). Newest membership is shown in profile. */
  async findPrimaryClubIdByUser(userId: string): Promise<string | null> {
    const row = await this.queryOne<{ club_id: string }>(
      'SELECT club_id FROM club_members WHERE user_id = $1 AND status = $2 ORDER BY created_at DESC LIMIT 1',
      [userId, 'active'],
    );
    return row?.club_id ?? null;
  }

  /** Count active members for a club */
  async countActiveMembers(clubId: string): Promise<number> {
    const row = await this.queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM club_members WHERE club_id = $1 AND status = $2',
      [clubId, 'active'],
    );
    return parseInt(row?.count ?? '0', 10);
  }
}

let instance: ClubMembersRepository | null = null;

export function getClubMembersRepository(): ClubMembersRepository {
  if (!instance) {
    instance = new ClubMembersRepository();
  }
  return instance;
}
