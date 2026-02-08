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

interface ActiveUserClubRow {
  club_id: string;
  club_name: string;
  club_description: string | null;
  club_city_id: string;
  club_status: string;
  membership_role: string;
  joined_at: Date;
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

export interface ActiveUserClubMembershipRow {
  clubId: string;
  clubName: string;
  clubDescription?: string;
  clubCityId: string;
  clubStatus: string;
  role: 'member' | 'trainer' | 'leader';
  joinedAt: Date;
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

function rowToActiveUserClubMembership(
  row: ActiveUserClubRow,
): ActiveUserClubMembershipRow {
  return {
    clubId: row.club_id,
    clubName: row.club_name,
    clubDescription: row.club_description ?? undefined,
    clubCityId: row.club_city_id,
    clubStatus: row.club_status,
    role: row.membership_role as ActiveUserClubMembershipRow['role'],
    joinedAt: row.joined_at,
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

  async findActiveClubsByUser(
    userId: string,
  ): Promise<ActiveUserClubMembershipRow[]> {
    const rows = await this.queryMany<ActiveUserClubRow>(
      `SELECT
         cm.club_id,
         c.name AS club_name,
         c.description AS club_description,
         c.city_id AS club_city_id,
         c.status AS club_status,
         cm.role AS membership_role,
         cm.created_at AS joined_at
       FROM club_members cm
       JOIN clubs c ON c.id = cm.club_id
       WHERE cm.user_id = $1 AND cm.status = $2
       ORDER BY cm.created_at DESC`,
      [userId, 'active'],
    );
    return rows.map(rowToActiveUserClubMembership);
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
