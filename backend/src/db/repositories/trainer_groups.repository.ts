/**
 * Trainer groups repository - database operations for groups created by trainers
 */

import { BaseRepository } from './base.repository';
import { TrainerGroup, TrainerGroupViewDto } from '../../modules/trainer';

interface TrainerGroupRow {
  id: string;
  club_id: string;
  trainer_id: string;
  name: string;
  created_at: Date;
}

interface TrainerGroupViewRow extends TrainerGroupRow {
  member_count: string | number;
}

function rowToTrainerGroup(row: TrainerGroupRow): TrainerGroup {
  return {
    id: row.id,
    clubId: row.club_id,
    trainerId: row.trainer_id,
    name: row.name,
    createdAt: row.created_at,
  };
}

function rowToTrainerGroupViewDto(row: TrainerGroupViewRow): TrainerGroupViewDto {
  return {
    id: row.id,
    clubId: row.club_id,
    trainerId: row.trainer_id,
    name: row.name,
    createdAt: row.created_at.toISOString(),
    memberCount:
      typeof row.member_count === 'string'
        ? parseInt(row.member_count, 10)
        : Number(row.member_count),
  };
}

export class TrainerGroupsRepository extends BaseRepository {
  private getActiveGroupTrainerExistsSql(groupAlias = 'tg'): string {
    return `EXISTS (
      SELECT 1
      FROM club_members trainer_cm
      WHERE trainer_cm.club_id = ${groupAlias}.club_id
        AND trainer_cm.user_id = ${groupAlias}.trainer_id
        AND trainer_cm.status = 'active'
        AND trainer_cm.role IN ('trainer', 'leader')
    )`;
  }

  async create(data: {
    clubId: string;
    trainerId: string;
    name: string;
    memberIds: string[];
  }): Promise<TrainerGroup> {
    return this.transaction(async client => {
      const groupRow = await this.queryOne<TrainerGroupRow>(
        `INSERT INTO trainer_groups (club_id, trainer_id, name)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [data.clubId, data.trainerId, data.name],
        client,
      );

      const groupId = groupRow!.id;

      // Automatically add trainer as a member
      const allMemberIds = Array.from(new Set([data.trainerId, ...data.memberIds]));

      if (allMemberIds.length > 0) {
        // Bulk insert members
        const values: unknown[] = [];
        const placeholders = allMemberIds
          .map((userId, i) => {
            values.push(groupId, userId);
            return `($${i * 2 + 1}, $${i * 2 + 2})`;
          })
          .join(', ');

        await this.query(
          `INSERT INTO trainer_group_members (group_id, user_id) VALUES ${placeholders}`,
          values,
          client,
        );
      }

      return rowToTrainerGroup(groupRow!);
    });
  }

  async updateName(id: string, name: string): Promise<boolean> {
    const result = await this.query('UPDATE trainer_groups SET name = $1 WHERE id = $2', [
      name,
      id,
    ]);
    return (result.rowCount ?? 0) > 0;
  }

  async updateMembers(groupId: string, memberIds: string[]): Promise<void> {
    await this.transaction(async client => {
      // Get the trainerId to ensure they are NOT removed
      const group = await this.queryOne<TrainerGroupRow>(
        'SELECT trainer_id FROM trainer_groups WHERE id = $1',
        [groupId],
        client,
      );
      if (!group) return;

      const trainerId = group.trainer_id;
      const allMemberIds = Array.from(new Set([trainerId, ...memberIds]));

      // Clear existing members
      await this.query('DELETE FROM trainer_group_members WHERE group_id = $1', [groupId], client);

      // Insert new members
      const values: unknown[] = [];
      const placeholders = allMemberIds
        .map((userId, i) => {
          values.push(groupId, userId);
          return `($${i * 2 + 1}, $${i * 2 + 2})`;
        })
        .join(', ');

      await this.query(
        `INSERT INTO trainer_group_members (group_id, user_id) VALUES ${placeholders}`,
        values,
        client,
      );
    });
  }

  async findByTrainerAndClub(trainerId: string, clubId: string): Promise<TrainerGroupViewDto[]> {
    const activeGroupTrainerSql = this.getActiveGroupTrainerExistsSql('tg');
    const rows = await this.queryMany<TrainerGroupViewRow>(
      `SELECT tg.*, COUNT(member_cm.user_id) as member_count
       FROM trainer_groups tg
       LEFT JOIN trainer_group_members tgm ON tgm.group_id = tg.id
       LEFT JOIN club_members member_cm
         ON member_cm.club_id = tg.club_id
        AND member_cm.user_id = tgm.user_id
        AND member_cm.status = 'active'
       WHERE tg.trainer_id = $1 AND tg.club_id = $2
         AND ${activeGroupTrainerSql}
       GROUP BY tg.id
       ORDER BY tg.created_at DESC`,
      [trainerId, clubId],
    );
    return rows.map(rowToTrainerGroupViewDto);
  }

  async findByMemberAndClub(userId: string, clubId: string): Promise<TrainerGroupViewDto[]> {
    const activeGroupTrainerSql = this.getActiveGroupTrainerExistsSql('tg');
    const rows = await this.queryMany<TrainerGroupViewRow>(
      `SELECT tg.*, COUNT(member_cm2.user_id) as member_count
       FROM trainer_groups tg
       JOIN trainer_group_members tgm ON tgm.group_id = tg.id
       JOIN club_members requester_cm
         ON requester_cm.club_id = tg.club_id
        AND requester_cm.user_id = $1
        AND requester_cm.status = 'active'
       LEFT JOIN trainer_group_members tgm2 ON tgm2.group_id = tg.id
       LEFT JOIN club_members member_cm2
         ON member_cm2.club_id = tg.club_id
        AND member_cm2.user_id = tgm2.user_id
        AND member_cm2.status = 'active'
       WHERE tgm.user_id = $1 AND tg.club_id = $2
         AND ${activeGroupTrainerSql}
       GROUP BY tg.id
       ORDER BY tg.created_at DESC`,
      [userId, clubId],
    );
    return rows.map(rowToTrainerGroupViewDto);
  }

  async findById(id: string): Promise<TrainerGroup | null> {
    const activeGroupTrainerSql = this.getActiveGroupTrainerExistsSql('tg');
    const row = await this.queryOne<TrainerGroupRow>(
      `SELECT tg.*
       FROM trainer_groups tg
       WHERE tg.id = $1
         AND ${activeGroupTrainerSql}`,
      [id],
    );
    return row ? rowToTrainerGroup(row) : null;
  }

  async isMember(groupId: string, userId: string): Promise<boolean> {
    const row = await this.queryOne(
      `SELECT 1
       FROM trainer_group_members tgm
       JOIN trainer_groups tg ON tg.id = tgm.group_id
       JOIN club_members member_cm
         ON member_cm.club_id = tg.club_id
        AND member_cm.user_id = tgm.user_id
        AND member_cm.status = 'active'
       WHERE tgm.group_id = $1
         AND tgm.user_id = $2
         AND ${this.getActiveGroupTrainerExistsSql('tg')}`,
      [groupId, userId],
    );
    return !!row;
  }

  async findMemberIds(groupId: string): Promise<string[]> {
    const rows = await this.queryMany<{ user_id: string }>(
      `SELECT tgm.user_id
       FROM trainer_group_members tgm
       JOIN trainer_groups tg ON tg.id = tgm.group_id
       JOIN club_members member_cm
         ON member_cm.club_id = tg.club_id
        AND member_cm.user_id = tgm.user_id
        AND member_cm.status = 'active'
       WHERE tgm.group_id = $1
         AND ${this.getActiveGroupTrainerExistsSql('tg')}`,
      [groupId],
    );
    return rows.map(r => r.user_id);
  }

  async delete(id: string): Promise<boolean> {
    const result = await this.query('DELETE FROM trainer_groups WHERE id = $1', [id]);
    return (result.rowCount ?? 0) > 0;
  }
}

let instance: TrainerGroupsRepository | null = null;

export function getTrainerGroupsRepository(): TrainerGroupsRepository {
  if (!instance) {
    instance = new TrainerGroupsRepository();
  }
  return instance;
}
