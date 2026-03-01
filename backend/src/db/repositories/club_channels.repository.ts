/**
 * Club channels repository - sub-chats within clubs.
 */

import { BaseRepository } from './base.repository';

interface ClubChannelRow {
  id: string;
  club_id: string;
  type: string;
  name: string;
  is_default: boolean;
  created_at: Date;
}

export interface ClubChannelDto {
  id: string;
  clubId: string;
  type: string;
  name: string;
  isDefault: boolean;
  createdAt: Date;
}

function rowToDto(row: ClubChannelRow): ClubChannelDto {
  return {
    id: row.id,
    clubId: row.club_id,
    type: row.type,
    name: row.name,
    isDefault: row.is_default,
    createdAt: row.created_at,
  };
}

export class ClubChannelsRepository extends BaseRepository {
  /** Find all channels for a club */
  async findByClub(clubId: string): Promise<ClubChannelDto[]> {
    const rows = await this.queryMany<ClubChannelRow>(
      `SELECT * FROM club_channels WHERE club_id = $1 ORDER BY is_default DESC, created_at ASC`,
      [clubId],
    );
    return rows.map(rowToDto);
  }

  /** Find a specific channel by ID */
  async findById(channelId: string): Promise<ClubChannelDto | null> {
    const row = await this.queryOne<ClubChannelRow>(`SELECT * FROM club_channels WHERE id = $1`, [
      channelId,
    ]);
    return row ? rowToDto(row) : null;
  }

  /** Find the default channel for a club */
  async findDefaultByClub(clubId: string): Promise<ClubChannelDto | null> {
    const row = await this.queryOne<ClubChannelRow>(
      `SELECT * FROM club_channels WHERE club_id = $1 AND is_default = true`,
      [clubId],
    );
    return row ? rowToDto(row) : null;
  }

  /** Create a new channel */
  async create(
    clubId: string,
    name: string,
    type: string = 'general',
    isDefault: boolean = false,
  ): Promise<ClubChannelDto> {
    const row = await this.queryOne<ClubChannelRow>(
      `INSERT INTO club_channels (club_id, type, name, is_default)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [clubId, type, name, isDefault],
    );
    if (!row) throw new Error('Insert club_channels failed');
    return rowToDto(row);
  }

  /** Create default channel for a new club */
  async createDefaultForClub(clubId: string): Promise<ClubChannelDto> {
    return this.create(clubId, 'General', 'general', true);
  }
}

let instance: ClubChannelsRepository | null = null;

export function getClubChannelsRepository(): ClubChannelsRepository {
  if (!instance) {
    instance = new ClubChannelsRepository();
  }
  return instance;
}
