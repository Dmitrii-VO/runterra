/**
 * Trainer groups repository - database operations for groups created by trainers
 */

import { BaseRepository } from './base.repository';
import { TrainerGroup, TrainerGroupMember, TrainerGroupViewDto } from '../../modules/trainer';

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
    memberCount: typeof row.member_count === 'string' ? parseInt(row.member_count, 10) : Number(row.member_count),
  };
}

export class TrainerGroupsRepository extends BaseRepository {
  async create(data: {
    clubId: string;
    trainerId: string;
    name: string;
    memberIds: string[];
  }): Promise<TrainerGroup> {
    return this.transaction(async (client) => {
      const groupRow = await this.queryOne<TrainerGroupRow>(
        `INSERT INTO trainer_groups (club_id, trainer_id, name)
         VALUES ($1, $2, $3)
         RETURNING *`,
        [data.clubId, data.trainerId, data.name],
        client
      );

      const groupId = groupRow!.id;

      if (data.memberIds.length > 0) {
        // Bulk insert members
        const values: any[] = [];
        const placeholders = data.memberIds
          .map((userId, i) => {
            values.push(groupId, userId);
            return `($${i * 2 + 1}, $${i * 2 + 2})`;
          })
          .join(', ');

        await this.query(
          `INSERT INTO trainer_group_members (group_id, user_id) VALUES ${placeholders}`,
          values,
          client
        );
      }

      return rowToTrainerGroup(groupRow!);
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
      [trainerId, clubId]
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
      [userId, clubId]
    );
    return rows.map(rowToTrainerGroupViewDto);
  }

  async findById(id: string): Promise<TrainerGroup | null> {
    const row = await this.queryOne<TrainerGroupRow>(
      'SELECT * FROM trainer_groups WHERE id = $1',
      [id]
    );
    return row ? rowToTrainerGroup(row) : null;
  }

  async isMember(groupId: string, userId: string): Promise<boolean> {
    const row = await this.queryOne(
      'SELECT 1 FROM trainer_group_members WHERE group_id = $1 AND user_id = $2',
      [groupId, userId]
    );
    return !!row;
  }
}

let instance: TrainerGroupsRepository | null = null;

export function getTrainerGroupsRepository(): TrainerGroupsRepository {
  if (!instance) {
    instance = new TrainerGroupsRepository();
  }
  return instance;
}
