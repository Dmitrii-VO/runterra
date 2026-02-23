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
  plan_type: string;
  created_at: Date;
  updated_at: Date;
}

interface ClubMemberDetailRow {
  user_id: string;
  display_name: string;
  role: string;
  plan_type: string;
  joined_at: Date;
  total_distance?: string | number;
}

export interface ClubMemberDetailDto {
  userId: string;
  displayName: string;
  role: 'member' | 'trainer' | 'leader';
  planType: 'club' | 'personal';
  joinedAt: Date;
  totalDistance?: number;
}

function rowToClubMemberDetail(row: ClubMemberDetailRow): ClubMemberDetailDto {
  return {
    userId: row.user_id,
    displayName: row.display_name,
    role: row.role as ClubMemberDetailDto['role'],
    planType: row.plan_type as ClubMemberDetailDto['planType'],
    joinedAt: row.joined_at,
    totalDistance: row.total_distance !== undefined ? parseInt(String(row.total_distance), 10) : 0,
  };
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
  planType: 'club' | 'personal';
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
    planType: (row.plan_type || 'club') as ClubMembershipRow['planType'],
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

  /** Set membership status to an arbitrary value */
  async setStatus(clubId: string, userId: string, status: 'pending' | 'active' | 'inactive' | 'suspended'): Promise<ClubMembershipRow | null> {
    const row = await this.queryOne<ClubMemberRow>(
      `UPDATE club_members
       SET status = $3, updated_at = NOW()
       WHERE club_id = $1 AND user_id = $2
       RETURNING *`,
      [clubId, userId, status],
    );
    return row ? rowToMembership(row) : null;
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

  /** Get all active members of a club with user display names */
  async findMembersByClub(clubId: string): Promise<ClubMemberDetailDto[]> {
    const rows = await this.queryMany<ClubMemberDetailRow>(
      `SELECT
         cm.user_id,
         COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), u.name) AS display_name,
         cm.role,
         cm.plan_type,
         cm.created_at AS joined_at,
         COALESCE(SUM(r.distance), 0) AS total_distance
       FROM club_members cm
       JOIN users u ON u.id = cm.user_id
       LEFT JOIN runs r ON r.user_id = cm.user_id AND r.status = 'completed' AND r.scoring_club_id = cm.club_id
       WHERE cm.club_id = $1 AND cm.status = 'active'
       GROUP BY cm.user_id, u.first_name, u.last_name, u.name, cm.role, cm.plan_type, cm.created_at
       ORDER BY total_distance DESC, cm.created_at ASC`,
      [clubId],
    );
    return rows.map(rowToClubMemberDetail);
  }

  /** Update plan type for a club member */
  async setPlanType(
    clubId: string,
    userId: string,
    planType: 'club' | 'personal',
  ): Promise<boolean> {
    const result = await this.query(
      `UPDATE club_members
       SET plan_type = $3, updated_at = NOW()
       WHERE club_id = $1 AND user_id = $2 AND status = 'active'`,
      [clubId, userId, planType],
    );
    return (result?.rowCount ?? 0) > 0;
  }

  /** Update role of a club member */
  async updateRole(
    clubId: string,
    userId: string,
    role: 'member' | 'trainer' | 'leader',
  ): Promise<ClubMembershipRow | null> {
    const row = await this.queryOne<ClubMemberRow>(
      `UPDATE club_members
       SET role = $3, updated_at = NOW()
       WHERE club_id = $1 AND user_id = $2 AND status = 'active'
       RETURNING *`,
      [clubId, userId, role],
    );
    return row ? rowToMembership(row) : null;
  }

  /**
   * Update role with leader transfer: when promoting to leader, demote current leader to trainer.
   * Ensures only one leader per club. Uses transaction for atomicity.
   */
  async updateRoleWithLeaderTransfer(
    clubId: string,
    newLeaderUserId: string,
    role: 'member' | 'trainer' | 'leader',
  ): Promise<ClubMembershipRow | null> {
    if (role !== 'leader') {
      return this.updateRole(clubId, newLeaderUserId, role);
    }

    const pool = this.getPool();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Find current leader (if different from new leader)
      const currentLeaderRes = await client.query<ClubMemberRow>(
        `SELECT * FROM club_members
         WHERE club_id = $1 AND role = 'leader' AND status = 'active' AND user_id != $2`,
        [clubId, newLeaderUserId],
      );
      const currentLeader = currentLeaderRes.rows[0];

      if (currentLeader) {
        await client.query(
          `UPDATE club_members SET role = 'trainer', updated_at = NOW()
           WHERE club_id = $1 AND user_id = $2`,
          [clubId, currentLeader.user_id],
        );
      }

      const newLeaderRes = await client.query<ClubMemberRow>(
        `UPDATE club_members SET role = 'leader', updated_at = NOW()
         WHERE club_id = $1 AND user_id = $2 AND status = 'active'
         RETURNING *`,
        [clubId, newLeaderUserId],
      );
      const row = newLeaderRes.rows[0];

      await client.query('COMMIT');
      return row ? rowToMembership(row) : null;
    } catch (error) {
      try {
        await client.query('ROLLBACK');
      } catch {
        // ignore rollback errors
      }
      throw error;
    } finally {
      client.release();
    }
  }

  /** Deactivate all members of a club (used when disbanding) */
  async deactivateAllMembers(clubId: string): Promise<void> {
    await this.query(
      `UPDATE club_members SET status = 'inactive', updated_at = NOW() WHERE club_id = $1 AND status = 'active'`,
      [clubId],
    );
  }

  /** Find all pending membership requests for a club */
  async findPendingByClub(clubId: string): Promise<ClubMemberDetailDto[]> {
    const rows = await this.queryMany<ClubMemberDetailRow>(
      `SELECT
         cm.user_id,
         COALESCE(NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''), u.name) AS display_name,
         cm.role,
         cm.created_at AS joined_at
       FROM club_members cm
       JOIN users u ON u.id = cm.user_id
       WHERE cm.club_id = $1 AND cm.status = 'pending'
       ORDER BY cm.created_at ASC`,
      [clubId],
    );
    return rows.map(rowToClubMemberDetail);
  }

  /** Approve a pending membership request (pending → active) */
  async approveMembership(clubId: string, userId: string): Promise<ClubMembershipRow | null> {
    const row = await this.queryOne<ClubMemberRow>(
      `UPDATE club_members
       SET status = 'active', updated_at = NOW()
       WHERE club_id = $1 AND user_id = $2 AND status = 'pending'
       RETURNING *`,
      [clubId, userId],
    );
    return row ? rowToMembership(row) : null;
  }

  /** Reject a pending membership request (delete the record) */
  async rejectMembership(clubId: string, userId: string): Promise<boolean> {
    const result = await this.query(
      `DELETE FROM club_members
       WHERE club_id = $1 AND user_id = $2 AND status = 'pending'`,
      [clubId, userId],
    );
    return (result?.rowCount ?? 0) > 0;
  }

  /** Count active members for a club */
  async countActiveMembers(clubId: string): Promise<number> {
    const row = await this.queryOne<{ count: string }>(
      'SELECT COUNT(*) as count FROM club_members WHERE club_id = $1 AND status = $2',
      [clubId, 'active'],
    );
    return parseInt(row?.count ?? '0', 10);
  }

  /** Count active leaders for a club (guardrail: club must not end up without a leader). */
  async countActiveLeaders(clubId: string): Promise<number> {
    const row = await this.queryOne<{ count: string }>(
      `SELECT COUNT(*) as count
       FROM club_members
       WHERE club_id = $1 AND status = 'active' AND role = 'leader'`,
      [clubId],
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
