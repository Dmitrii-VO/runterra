import { BaseRepository } from './base.repository';
import { Activity, ActivityType, ActivityStatus } from '../../modules/activities';

interface ActivityRow {
  id: string;
  user_id: string;
  type: string;
  status: string;
  name: string | null;
  description: string | null;
  scheduled_item_id: string | null;
  created_at: Date;
  updated_at: Date;
}

function rowToActivity(row: ActivityRow): Activity {
  return {
    id: row.id,
    userId: row.user_id,
    type: row.type as ActivityType,
    status: row.status as ActivityStatus,
    name: row.name ?? undefined,
    description: row.description ?? undefined,
    scheduledItemId: row.scheduled_item_id ?? undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export class ActivitiesRepository extends BaseRepository {
  async findById(id: string): Promise<Activity | null> {
    const row = await this.queryOne<ActivityRow>('SELECT * FROM activities WHERE id = $1', [id]);
    return row ? rowToActivity(row) : null;
  }

  async findByUserId(userId: string, limit = 50, offset = 0): Promise<Activity[]> {
    const rows = await this.queryMany<ActivityRow>(
      'SELECT * FROM activities WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3',
      [userId, limit, offset],
    );
    return rows.map(rowToActivity);
  }

  async create(
    data: {
      userId: string;
      type: ActivityType;
      status: ActivityStatus;
      name?: string;
      description?: string;
      scheduledItemId?: string;
    },
    client?: import('pg').PoolClient,
  ): Promise<Activity> {
    const row = await this.queryOne<ActivityRow>(
      `INSERT INTO activities (user_id, type, status, name, description, scheduled_item_id)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        data.userId,
        data.type,
        data.status,
        data.name || null,
        data.description || null,
        data.scheduledItemId || null,
      ],
      client,
    );
    if (!row) throw new Error('Failed to create activity');
    return rowToActivity(row);
  }
}

let instance: ActivitiesRepository | null = null;

export function getActivitiesRepository(): ActivitiesRepository {
  if (!instance) {
    instance = new ActivitiesRepository();
  }
  return instance;
}
