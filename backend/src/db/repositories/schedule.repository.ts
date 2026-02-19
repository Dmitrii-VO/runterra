import { BaseRepository } from './base.repository';
import { WeeklyScheduleItemDto, PersonalScheduleItemDto } from '../modules/schedule/schedule.dto';

interface WeeklyScheduleItemRow {
  id: string;
  club_id: string;
  day_of_week: number;
  start_time: string;
  activity_type: string;
  name: string;
  description: string | null;
  workout_id: string | null;
  trainer_id: string | null;
  created_at: Date;
  updated_at: Date;
}

interface PersonalScheduleItemRow {
  id: string;
  user_id: string;
  day_of_week: number;
  name: string;
  description: string | null;
  workout_id: string | null;
  trainer_id: string | null;
  created_at: Date;
  updated_at: Date;
}

interface PersonalNoteRow {
  id: string;
  user_id: string;
  template_id: string | null;
  date: Date;
  name: string;
  description: string | null;
  workout_id: string | null;
  trainer_id: string | null;
  is_manually_edited: boolean;
  created_at: Date;
  updated_at: Date;
}

function rowToWeeklyItem(row: WeeklyScheduleItemRow): WeeklyScheduleItemDto {
  return {
    id: row.id,
    clubId: row.club_id,
    dayOfWeek: row.day_of_week,
    startTime: row.start_time.substring(0, 5), // 'HH:mm:ss' -> 'HH:mm'
    activityType: row.activity_type,
    name: row.name,
    description: row.description ?? undefined,
    workoutId: row.workout_id ?? undefined,
    trainerId: row.trainer_id ?? undefined,
  };
}

function rowToPersonalItem(row: PersonalScheduleItemRow): PersonalScheduleItemDto {
  return {
    id: row.id,
    userId: row.user_id,
    dayOfWeek: row.day_of_week,
    name: row.name,
    description: row.description ?? undefined,
    workoutId: row.workout_id ?? undefined,
    trainerId: row.trainer_id ?? undefined,
  };
}

function rowToPersonalNote(row: PersonalNoteRow): import('../modules/schedule/schedule.dto').PersonalNoteDto {
  return {
    id: row.id,
    userId: row.user_id,
    templateId: row.template_id ?? undefined,
    date: row.date.toISOString().split('T')[0],
    name: row.name,
    description: row.description ?? undefined,
    workoutId: row.workout_id ?? undefined,
    trainerId: row.trainer_id ?? undefined,
    isManuallyEdited: row.is_manually_edited,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export class ScheduleRepository extends BaseRepository {
  /**
   * Получить недельное расписание клуба
   */
  async findWeeklyByClub(clubId: string): Promise<WeeklyScheduleItemDto[]> {
    const rows = await this.queryMany<WeeklyScheduleItemRow>(
      'SELECT * FROM weekly_schedule_items WHERE club_id = $1 ORDER BY day_of_week ASC, start_time ASC',
      [clubId]
    );
    return rows.map(rowToWeeklyItem);
  }

  /**
   * Добавить элемент в недельное расписание
   */
  async createWeeklyItem(clubId: string, item: Omit<WeeklyScheduleItemDto, 'id' | 'clubId'>): Promise<WeeklyScheduleItemDto> {
    const row = await this.queryOne<WeeklyScheduleItemRow>(
      `INSERT INTO weekly_schedule_items 
       (club_id, day_of_week, start_time, activity_type, name, description, workout_id, trainer_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        clubId,
        item.dayOfWeek,
        item.startTime,
        item.activityType,
        item.name,
        item.description || null,
        item.workoutId || null,
        item.trainerId || null
      ]
    );
    if (!row) throw new Error('Failed to create weekly schedule item');
    return rowToWeeklyItem(row);
  }

  /**
   * Получить конкретный элемент шаблона
   */
  async findWeeklyItemById(itemId: string): Promise<WeeklyScheduleItemDto | null> {
    const row = await this.queryOne<WeeklyScheduleItemRow>(
      'SELECT * FROM weekly_schedule_items WHERE id = $1',
      [itemId]
    );
    return row ? rowToWeeklyItem(row) : null;
  }

  /**
   * Удалить элемент из расписания
   */
  async deleteWeeklyItem(itemId: string): Promise<boolean> {
    const result = await this.query(
      'DELETE FROM weekly_schedule_items WHERE id = $1',
      [itemId]
    );
    return (result.rowCount ?? 0) > 0;
  }

  /**
   * Обновить элемент шаблона
   */
  async updateWeeklyItem(itemId: string, item: Partial<Omit<WeeklyScheduleItemDto, 'id' | 'clubId'>>): Promise<WeeklyScheduleItemDto | null> {
    const fields: string[] = [];
    const values: any[] = [];
    let i = 1;

    if (item.dayOfWeek !== undefined) { fields.push(`day_of_week = $${i++}`); values.push(item.dayOfWeek); }
    if (item.startTime !== undefined) { fields.push(`start_time = $${i++}`); values.push(item.startTime); }
    if (item.activityType !== undefined) { fields.push(`activity_type = $${i++}`); values.push(item.activityType); }
    if (item.name !== undefined) { fields.push(`name = $${i++}`); values.push(item.name); }
    if (item.description !== undefined) { fields.push(`description = $${i++}`); values.push(item.description || null); }
    if (item.workoutId !== undefined) { fields.push(`workout_id = $${i++}`); values.push(item.workoutId || null); }
    if (item.trainerId !== undefined) { fields.push(`trainer_id = $${i++}`); values.push(item.trainerId || null); }

    if (fields.length === 0) return this.findWeeklyItemById(itemId);

    values.push(itemId);
    const row = await this.queryOne<WeeklyScheduleItemRow>(
      `UPDATE weekly_schedule_items SET ${fields.join(', ')}, updated_at = NOW() WHERE id = $${i} RETURNING *`,
      values
    );
    return row ? rowToWeeklyItem(row) : null;
  }

  /**
   * Получить личный шаблон расписания пользователя
   */
  async findPersonalByUser(userId: string): Promise<PersonalScheduleItemDto[]> {
    const rows = await this.queryMany<PersonalScheduleItemRow>(
      'SELECT * FROM personal_schedule_items WHERE user_id = $1 ORDER BY day_of_week ASC',
      [userId]
    );
    return rows.map(rowToPersonalItem);
  }

  /**
   * Получить конкретный элемент личного шаблона
   */
  async findPersonalItemById(itemId: string): Promise<PersonalScheduleItemDto | null> {
    const row = await this.queryOne<PersonalScheduleItemRow>(
      'SELECT * FROM personal_schedule_items WHERE id = $1',
      [itemId]
    );
    return row ? rowToPersonalItem(row) : null;
  }

  /**
   * Полностью заменить личное расписание пользователя (транзакция)
   */
  async replacePersonalSchedule(userId: string, items: Omit<PersonalScheduleItemDto, 'id' | 'userId'>[]): Promise<PersonalScheduleItemDto[]> {
    const pool = this.getPool();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Удаляем старые
      await client.query('DELETE FROM personal_schedule_items WHERE user_id = $1', [userId]);

      // 2. Вставляем новые
      const createdItems: PersonalScheduleItemDto[] = [];
      for (const item of items) {
        const res = await client.query<PersonalScheduleItemRow>(
          `INSERT INTO personal_schedule_items 
           (user_id, day_of_week, name, description, workout_id, trainer_id)
           VALUES ($1, $2, $3, $4, $5, $6)
           RETURNING *`,
          [
            userId,
            item.dayOfWeek,
            item.name,
            item.description || null,
            item.workoutId || null,
            item.trainerId || null
          ]
        );
        if (res.rows[0]) {
          createdItems.push(rowToPersonalItem(res.rows[0]));
        }
      }

      await client.query('COMMIT');
      return createdItems;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Получить заметки пользователя за месяц
   */
  async findNotesByUserAndMonth(userId: string, yearMonth: string): Promise<import('../modules/schedule/schedule.dto').PersonalNoteDto[]> {
    const startDate = `${yearMonth}-01`;
    // Last day of month logic simplified for query
    const rows = await this.queryMany<PersonalNoteRow>(
      `SELECT * FROM personal_notes 
       WHERE user_id = $1 
         AND date >= $2::date 
         AND date <= ($2::date + interval '1 month' - interval '1 day')::date
         AND deleted_at IS NULL
       ORDER BY date ASC`,
      [userId, startDate]
    );
    return rows.map(rowToPersonalNote);
  }

  /**
   * Получить ВСЕ недельные шаблоны всех клубов (для крона)
   */
  async getAllWeeklyTemplates(): Promise<WeeklyScheduleItemDto[]> {
    const rows = await this.queryMany<WeeklyScheduleItemRow>('SELECT * FROM weekly_schedule_items');
    return rows.map(rowToWeeklyItem);
  }

  /**
   * Получить ВСЕ личные шаблоны всех пользователей (для крона)
   */
  async getAllPersonalTemplates(): Promise<PersonalScheduleItemDto[]> {
    const rows = await this.queryMany<PersonalScheduleItemRow>('SELECT * FROM personal_schedule_items');
    return rows.map(rowToPersonalItem);
  }

  /**
   * Найти личную заметку, сгенерированную из шаблона на дату
   */
  async findNoteByTemplateAndDate(templateId: string, date: string): Promise<import('../modules/schedule/schedule.dto').PersonalNoteDto | null> {
    const row = await this.queryOne<PersonalNoteRow>(
      `SELECT * FROM personal_notes 
       WHERE template_id = $1 AND date = $2::date AND deleted_at IS NULL`,
      [templateId, date]
    );
    return row ? rowToPersonalNote(row) : null;
  }

  /**
   * Создать личную заметку
   */
  async createPersonalNote(data: {
    userId: string;
    templateId?: string;
    date: string;
    name: string;
    description?: string;
    workoutId?: string;
    trainerId?: string;
  }): Promise<import('../modules/schedule/schedule.dto').PersonalNoteDto> {
    const row = await this.queryOne<PersonalNoteRow>(
      `INSERT INTO personal_notes 
       (user_id, template_id, date, name, description, workout_id, trainer_id)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [
        data.userId,
        data.templateId || null,
        data.date,
        data.name,
        data.description || null,
        data.workoutId || null,
        data.trainerId || null
      ]
    );
    if (!row) throw new Error('Failed to create personal note');
    return rowToPersonalNote(row);
  }

  /**
   * Обновить личную заметку
   */
  async updateNote(noteId: string, data: Partial<Omit<import('../modules/schedule/schedule.dto').PersonalNoteDto, 'id' | 'userId' | 'createdAt' | 'updatedAt'>>): Promise<import('../modules/schedule/schedule.dto').PersonalNoteDto | null> {
    const fields: string[] = [];
    const values: any[] = [];
    let i = 1;

    if (data.name !== undefined) { fields.push(`name = $${i++}`); values.push(data.name); }
    if (data.description !== undefined) { fields.push(`description = $${i++}`); values.push(data.description || null); }
    if (data.date !== undefined) { fields.push(`date = $${i++}`); values.push(data.date); }
    if (data.workoutId !== undefined) { fields.push(`workout_id = $${i++}`); values.push(data.workoutId || null); }
    if (data.trainerId !== undefined) { fields.push(`trainer_id = $${i++}`); values.push(data.trainerId || null); }
    if (data.isManuallyEdited !== undefined) { fields.push(`is_manually_edited = $${i++}`); values.push(data.isManuallyEdited); }

    if (fields.length === 0) {
      const row = await this.queryOne<PersonalNoteRow>('SELECT * FROM personal_notes WHERE id = $1', [noteId]);
      return row ? rowToPersonalNote(row) : null;
    }

    values.push(noteId);
    const row = await this.queryOne<PersonalNoteRow>(
      `UPDATE personal_notes SET ${fields.join(', ')}, updated_at = NOW() WHERE id = $${i} RETURNING *`,
      values
    );
    return row ? rowToPersonalNote(row) : null;
  }

  /**
   * Мягкое удаление заметки
   */
  async deleteNote(noteId: string): Promise<boolean> {
    const result = await this.query(
      'UPDATE personal_notes SET deleted_at = NOW(), updated_at = NOW() WHERE id = $1',
      [noteId]
    );
    return (result.rowCount ?? 0) > 0;
  }

  /**
   * Найти будущие заметки, сгенерированные из шаблона
   */
  async findFutureByTemplate(templateId: string): Promise<import('../modules/schedule/schedule.dto').PersonalNoteDto[]> {
    const rows = await this.queryMany<PersonalNoteRow>(
      `SELECT * FROM personal_notes 
       WHERE template_id = $1 
         AND date >= CURRENT_DATE 
         AND deleted_at IS NULL`,
      [templateId]
    );
    return rows.map(rowToPersonalNote);
  }

  /**
   * Найти будущие события, сгенерированные из шаблона
   * (Добавлено здесь для удобства, хотя относится к EventsRepository)
   */
}

let instance: ScheduleRepository | null = null;

export function getScheduleRepository(): ScheduleRepository {
  if (!instance) {
    instance = new ScheduleRepository();
  }
  return instance;
}
