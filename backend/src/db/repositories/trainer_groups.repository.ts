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
    const rows = await this.queryMany<TrainerGroupViewRow>(
      `SELECT tg.*, COUNT(tgm.user_id) as member_count
       FROM trainer_groups tg
       LEFT JOIN trainer_group_members tgm ON tgm.group_id = tg.id
       WHERE tg.trainer_id = $1 AND tg.club_id = $2
       GROUP BY tg.id
       ORDER BY tg.created_at DESC`,
      [trainerId, clubId],
    );
    return rows.map(rowToTrainerGroupViewDto);
  }

  async findByMemberAndClub(userId: string, clubId: string): Promise<TrainerGroupViewDto[]> {
    const rows = await this.queryMany<TrainerGroupViewRow>(
      `SELECT tg.*, COUNT(tgm2.user_id) as member_count
       FROM trainer_groups tg
       JOIN trainer_group_members tgm ON tgm.group_id = tg.id
       LEFT JOIN trainer_group_members tgm2 ON tgm2.group_id = tg.id
       WHERE tgm.user_id = $1 AND tg.club_id = $2
       GROUP BY tg.id
       ORDER BY tg.created_at DESC`,
      [userId, clubId],
    );
    return rows.map(rowToTrainerGroupViewDto);
  }

  async findById(id: string): Promise<TrainerGroup | null> {
    const row = await this.queryOne<TrainerGroupRow>('SELECT * FROM trainer_groups WHERE id = $1', [
      id,
    ]);
    return row ? rowToTrainerGroup(row) : null;
  }

  async isMember(groupId: string, userId: string): Promise<boolean> {
    const row = await this.queryOne(
      'SELECT 1 FROM trainer_group_members WHERE group_id = $1 AND user_id = $2',
      [groupId, userId],
    );
    return !!row;
  }

  async findMemberIds(groupId: string): Promise<string[]> {
    const rows = await this.queryMany<{ user_id: string }>(
      'SELECT user_id FROM trainer_group_members WHERE group_id = $1',
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
