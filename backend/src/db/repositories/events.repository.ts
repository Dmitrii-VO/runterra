/**
 * Events repository - database operations for events
 */

import { BaseRepository } from './base.repository';
import { Event } from '../../modules/events/event.entity';
import { EventType } from '../../modules/events/event.type';
import { EventStatus } from '../../modules/events/event.status';
import { PoolClient } from 'pg';

interface EventRow {
  id: string;
  name: string;
  type: string;
  status: string;
  visibility: string;
  start_date_time: Date;
  end_date_time: Date | null;
  start_longitude: number;
  start_latitude: number;
  location_name: string | null;
  organizer_id: string;
  organizer_type: string;
  difficulty_level: string | null;
  description: string | null;
  participant_limit: number | null;
  participant_count: number;
  territory_id: string | null;
  city_id: string;
  created_at: Date;
  updated_at: Date;
  workout_id: string | null;
  trainer_id: string | null;
  workout_snapshot: Record<string, unknown> | null;
  template_id: string | null;
  generated_for_date: Date | null;
  is_manually_edited: boolean;
  price: number;
}

/**
 * Compute actual event status based on time and participant count.
 *
 * Logic:
 * - If effective end time has passed, status is COMPLETED
 * - If participant limit is reached, status is FULL
 * - Otherwise, use status from DB
 */
const DEFAULT_EVENT_DURATION_MS = 4 * 60 * 60 * 1000; // 4 hours

function computeEventStatus(row: EventRow): EventStatus {
  const dbStatus = row.status as EventStatus;

  // If event is already cancelled/completed in DB, respect that
  if (dbStatus === EventStatus.CANCELLED || dbStatus === EventStatus.COMPLETED) {
    return dbStatus;
  }

  // Check if event has ended (time-based transition to completed).
  // Some events may not have end_date_time; treat them as ended after a default duration.
  const effectiveEnd =
    row.end_date_time ?? new Date(row.start_date_time.getTime() + DEFAULT_EVENT_DURATION_MS);
  const now = new Date();
  if (effectiveEnd < now) {
    return EventStatus.COMPLETED;
  }

  // Check if event is full (participant limit reached)
  if (row.participant_limit !== null && row.participant_count >= row.participant_limit) {
    return EventStatus.FULL;
  }

  // Otherwise, use status from DB
  return dbStatus;
}

function rowToEvent(row: EventRow): Event {
  return {
    id: row.id,
    name: row.name,
    type: row.type as EventType,
    status: computeEventStatus(row),
    visibility: row.visibility as 'public' | 'private',
    startDateTime: row.start_date_time,
    endDateTime: row.end_date_time || undefined,
    startLocation: {
      longitude: row.start_longitude,
      latitude: row.start_latitude,
    },
    locationName: row.location_name || undefined,
    organizerId: row.organizer_id,
    organizerType: row.organizer_type as 'club' | 'trainer',
    difficultyLevel: row.difficulty_level as Event['difficultyLevel'],
    description: row.description || undefined,
    participantLimit: row.participant_limit ?? undefined,
    participantCount: row.participant_count,
    territoryId: row.territory_id || undefined,
    cityId: row.city_id,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    workoutId: row.workout_id || undefined,
    trainerId: row.trainer_id || undefined,
    workoutSnapshot: row.workout_snapshot ?? undefined,
    isManuallyEdited: row.is_manually_edited ?? false,
    price: row.price ?? 0,
  };
}

export interface EventParticipant {
  id: string;
  eventId: string;
  userId: string;
  status: 'registered' | 'checked_in' | 'cancelled' | 'no_show';
  checkedInAt?: Date;
  checkInLongitude?: number;
  checkInLatitude?: number;
  createdAt: Date;
}

interface ParticipantRow {
  id: string;
  event_id: string;
  user_id: string;
  status: string;
  checked_in_at: Date | null;
  check_in_longitude: number | null;
  check_in_latitude: number | null;
  created_at: Date;
}

function rowToParticipant(row: ParticipantRow): EventParticipant {
  return {
    id: row.id,
    eventId: row.event_id,
    userId: row.user_id,
    status: row.status as EventParticipant['status'],
    checkedInAt: row.checked_in_at || undefined,
    checkInLongitude: row.check_in_longitude ?? undefined,
    checkInLatitude: row.check_in_latitude ?? undefined,
    createdAt: row.created_at,
  };
}

export class EventsRepository extends BaseRepository {
  async findById(id: string): Promise<Event | null> {
    const row = await this.queryOne<EventRow>('SELECT * FROM events WHERE id = $1', [id]);
    return row ? rowToEvent(row) : null;
  }

  async findAll(options?: {
    status?: EventStatus[];
    dateFilter?: 'today' | 'tomorrow' | 'next7days';
    dateFrom?: Date;
    dateTo?: Date;
    clubId?: string;
    cityId?: string;
    difficultyLevel?: string;
    eventType?: EventType;
    eventTypes?: EventType[];
    organizerId?: string;
    participantOnly?: boolean;
    participantUserId?: string;
    onlyOpen?: boolean;
    currentUserId?: string;
    sortBy?: 'relevance' | 'date_asc' | 'date_desc' | 'price_asc' | 'price_desc';
    limit?: number;
    offset?: number;
  }): Promise<Event[]> {
    const limit = options?.limit || 50;
    const offset = options?.offset || 0;

    const conditions: string[] = [];
    const params: unknown[] = [];
    let paramIndex = 1;

    // Status filter (default: only OPEN and FULL, exclude DRAFT and COMPLETED)
    if (options?.status && options.status.length > 0) {
      conditions.push(`status = ANY($${paramIndex++})`);
      params.push(options.status);
    } else {
      // onlyOpen=true: only 'open' (exclude 'full'); otherwise open+full
      if (options?.onlyOpen) {
        conditions.push(`status = 'open'`);
      } else {
        conditions.push(`status IN ('open', 'full')`);
      }
      conditions.push(`COALESCE(end_date_time, start_date_time + INTERVAL '4 hours') > NOW()`);
    }

    // Date filter
    if (options?.dateFilter) {
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      if (options.dateFilter === 'today') {
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        conditions.push(
          `start_date_time >= $${paramIndex++} AND start_date_time < $${paramIndex++}`,
        );
        params.push(today, tomorrow);
      } else if (options.dateFilter === 'tomorrow') {
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        const dayAfter = new Date(tomorrow);
        dayAfter.setDate(dayAfter.getDate() + 1);
        conditions.push(
          `start_date_time >= $${paramIndex++} AND start_date_time < $${paramIndex++}`,
        );
        params.push(tomorrow, dayAfter);
      } else if (options.dateFilter === 'next7days') {
        const nextWeek = new Date(today);
        nextWeek.setDate(nextWeek.getDate() + 7);
        conditions.push(
          `start_date_time >= $${paramIndex++} AND start_date_time < $${paramIndex++}`,
        );
        params.push(today, nextWeek);
      }
    }

    // Club filter (organizer)
    if (options?.clubId) {
      conditions.push(`organizer_id = $${paramIndex++} AND organizer_type = 'club'`);
      params.push(options.clubId);
    }

    // City filter (required at API level, but kept optional here for flexibility)
    if (options?.cityId) {
      conditions.push(`city_id = $${paramIndex++}`);
      params.push(options.cityId);
    }

    // Difficulty level filter
    if (options?.difficultyLevel) {
      conditions.push(`difficulty_level = $${paramIndex++}`);
      params.push(options.difficultyLevel);
    }

    // Event type filter (single, legacy)
    if (options?.eventType) {
      conditions.push(`type = $${paramIndex++}`);
      params.push(options.eventType);
    }

    // Event types filter (multi-select)
    if (options?.eventTypes && options.eventTypes.length > 0) {
      conditions.push(`type = ANY($${paramIndex++})`);
      params.push(options.eventTypes);
    }

    // Specific date range filter (for calendar day tap)
    if (options?.dateFrom) {
      conditions.push(`start_date_time >= $${paramIndex++}`);
      params.push(options.dateFrom);
    }
    if (options?.dateTo) {
      conditions.push(`start_date_time < $${paramIndex++}`);
      params.push(options.dateTo);
    }

    // Organizer filter
    if (options?.organizerId) {
      conditions.push(`organizer_id = $${paramIndex++}`);
      params.push(options.organizerId);
    }

    // Participant filter: only events where user is registered
    if (options?.participantOnly) {
      if (!options.participantUserId) {
        // Defensive: never "silently ignore" participantOnly, because it can leak
        // non-participating events if a caller forgets to pass userId.
        return [];
      }
      conditions.push(`id IN (
        SELECT event_id FROM event_participants
        WHERE user_id = $${paramIndex++} AND status IN ('registered', 'checked_in')
      )`);
      params.push(options.participantUserId);
    }

    // Visibility filter
    if (options?.currentUserId) {
      // Show public + private where user is participant/organizer
      // Note: organizer check logic is separate, but usually organizer is participant?
      // For now, let's assume private events require being a participant (invited).
      // Or we can check if user is organizer.
      // Plan says: "AND (visibility = 'public' OR (visibility = 'private' AND EXISTS(participants...)))"
      conditions.push(
        `(visibility = 'public' OR (visibility = 'private' AND EXISTS (SELECT 1 FROM event_participants ep WHERE ep.event_id = events.id AND ep.user_id = $${paramIndex})))`,
      );
      params.push(options.currentUserId);
      paramIndex++;
    } else {
      // Show only public if no user context
      conditions.push(`visibility = 'public'`);
    }

    let sql = 'SELECT * FROM events';
    if (conditions.length > 0) {
      sql += ` WHERE ${conditions.join(' AND ')}`;
    }

    const orderBy = (() => {
      switch (options?.sortBy) {
        case 'date_asc': return 'start_date_time ASC';
        case 'date_desc': return 'start_date_time DESC';
        case 'price_asc': return 'price ASC, start_date_time ASC';
        case 'price_desc': return 'price DESC, start_date_time ASC';
        default: return 'start_date_time ASC'; // relevance = nearest first
      }
    })();
    sql += ` ORDER BY ${orderBy} LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(limit, offset);

    const rows = await this.queryMany<EventRow>(sql, params);
    return rows.map(rowToEvent);
  }

  async create(data: {
    name: string;
    type: EventType;
    startDateTime: Date;
    endDateTime?: Date;
    startLocation: { longitude: number; latitude: number };
    locationName?: string;
    organizerId: string;
    organizerType: 'club' | 'trainer';
    difficultyLevel?: 'beginner' | 'intermediate' | 'advanced';
    description?: string;
    participantLimit?: number;
    territoryId?: string;
    cityId: string;
    visibility?: 'public' | 'private';
    templateId?: string;
    generatedForDate?: string;
    workoutId?: string;
    trainerId?: string;
    workoutSnapshot?: Record<string, unknown>;
    price?: number;
  }): Promise<Event> {
    const row = await this.queryOne<EventRow>(
      `INSERT INTO events (
        name, type, status, start_date_time, end_date_time, start_longitude, start_latitude,
        location_name, organizer_id, organizer_type, difficulty_level,
        description, participant_limit, territory_id, city_id, visibility,
        template_id, generated_for_date, workout_id, trainer_id, workout_snapshot, price
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22)
      RETURNING *`,
      [
        data.name,
        data.type,
        EventStatus.OPEN,
        data.startDateTime,
        data.endDateTime || null,
        data.startLocation.longitude,
        data.startLocation.latitude,
        data.locationName || null,
        data.organizerId,
        data.organizerType,
        data.difficultyLevel || null,
        data.description || null,
        data.participantLimit || null,
        data.territoryId || null,
        data.cityId,
        data.visibility || 'public',
        data.templateId || null,
        data.generatedForDate || null,
        data.workoutId || null,
        data.trainerId || null,
        data.workoutSnapshot ? JSON.stringify(data.workoutSnapshot) : null,
        data.price ?? 0,
      ],
    );
    return rowToEvent(row!);
  }

  /**
   * Join event - register user as participant
   * Returns error message if cannot join, null if success
   */
  async joinEvent(
    eventId: string,
    userId: string,
  ): Promise<{ error?: string; participant?: EventParticipant }> {
    const pool = this.getPool();
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Lock event row to make participant_limit checks and count updates atomic.
      const eventRes = await client.query<EventRow>(
        'SELECT * FROM events WHERE id = $1 FOR UPDATE',
        [eventId],
      );
      const eventRow = eventRes.rows[0];
      if (!eventRow) {
        await client.query('ROLLBACK');
        return { error: 'Event not found' };
      }
      const event = rowToEvent(eventRow);

      if (event.status !== EventStatus.OPEN) {
        await client.query('ROLLBACK');
        return { error: `Cannot join event with status: ${event.status}` };
      }

      const existingRes = await client.query<ParticipantRow>(
        'SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2 FOR UPDATE',
        [eventId, userId],
      );
      const existing = existingRes.rows[0];
      if (existing && (existing.status === 'registered' || existing.status === 'checked_in')) {
        await client.query('ROLLBACK');
        return { error: 'Already registered for this event' };
      }

      const activeCount = await this.getActiveParticipantCount(client, eventId);
      if (event.participantLimit && activeCount >= event.participantLimit) {
        await client.query('ROLLBACK');
        return { error: 'Event is full' };
      }

      let participantRow: ParticipantRow;
      if (existing) {
        const updatedRes = await client.query<ParticipantRow>(
          `UPDATE event_participants
           SET status = 'registered', updated_at = NOW()
           WHERE id = $1 RETURNING *`,
          [existing.id],
        );
        participantRow = updatedRes.rows[0];
      } else {
        const insertRes = await client.query<ParticipantRow>(
          `INSERT INTO event_participants (event_id, user_id, status)
           VALUES ($1, $2, 'registered')
           RETURNING *`,
          [eventId, userId],
        );
        participantRow = insertRes.rows[0];
      }

      const newActiveCount = await this.getActiveParticipantCount(client, eventId);
      await client.query(
        `UPDATE events
         SET participant_count = $2,
             status = CASE
               WHEN status IN ('cancelled', 'completed') THEN status
               WHEN participant_limit IS NOT NULL AND $2 >= participant_limit THEN 'full'
               WHEN status = 'full' AND (participant_limit IS NULL OR $2 < participant_limit) THEN 'open'
               ELSE status
             END,
             updated_at = NOW()
         WHERE id = $1`,
        [eventId, newActiveCount],
      );

      await client.query('COMMIT');
      return { participant: rowToParticipant(participantRow) };
    } catch (error) {
      try {
        await client.query('ROLLBACK');
      } catch {
        // ignore rollback errors and rethrow original failure
      }
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Check-in to event with GPS verification
   */
  async checkIn(
    eventId: string,
    userId: string,
    coordinates: { longitude: number; latitude: number },
  ): Promise<{ error?: string; participant?: EventParticipant }> {
    // Check if event exists
    const event = await this.findById(eventId);
    if (!event) {
      return { error: 'Event not found' };
    }

    // Check time window (30 minutes before to 1 hour after start) — Z8 decisions 2026-02-13
    const now = new Date();
    const eventStart = new Date(event.startDateTime);
    const windowStart = new Date(eventStart.getTime() - 30 * 60 * 1000); // 30 min before
    const windowEnd = new Date(eventStart.getTime() + 60 * 60 * 1000); // 1 hour after

    if (now < windowStart) {
      return { error: 'Check-in is not yet available. Opens 30 minutes before event start.' };
    }
    if (now > windowEnd) {
      return { error: 'Check-in window has closed.' };
    }

    // Check GPS distance (500 meters radius)
    const distance = this.calculateDistance(
      coordinates.latitude,
      coordinates.longitude,
      event.startLocation.latitude,
      event.startLocation.longitude,
    );

    if (distance > 500) {
      return {
        error: `Too far from event location. Distance: ${Math.round(distance)}m, max: 500m`,
      };
    }

    // Check if registered
    const registration = await this.queryOne<ParticipantRow>(
      'SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2',
      [eventId, userId],
    );

    if (!registration) {
      return { error: 'Not registered for this event' };
    }

    if (registration.status === 'checked_in') {
      return { error: 'Already checked in' };
    }

    if (registration.status === 'cancelled') {
      return { error: 'Registration was cancelled' };
    }

    // Perform check-in
    const updated = await this.queryOne<ParticipantRow>(
      `UPDATE event_participants 
       SET status = 'checked_in', 
           checked_in_at = NOW(),
           check_in_longitude = $1,
           check_in_latitude = $2,
           updated_at = NOW()
       WHERE id = $3 RETURNING *`,
      [coordinates.longitude, coordinates.latitude, registration.id],
    );

    return { participant: rowToParticipant(updated!) };
  }

  /**
   * Cancel participation in event
   */
  async leaveEvent(
    eventId: string,
    userId: string,
  ): Promise<{ error?: string; participant?: EventParticipant }> {
    const registration = await this.queryOne<ParticipantRow>(
      'SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2',
      [eventId, userId],
    );

    if (!registration) {
      return { error: 'Not registered for this event' };
    }

    if (registration.status === 'cancelled') {
      return { error: 'Already cancelled participation' };
    }

    const updated = await this.queryOne<ParticipantRow>(
      `UPDATE event_participants
       SET status = 'cancelled', updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [registration.id],
    );

    await this.updateParticipantCount(eventId);

    return { participant: rowToParticipant(updated!) };
  }

  /**
   * Calculate distance between two GPS points using Haversine formula
   * Returns distance in meters
   */
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371000; // Earth's radius in meters
    const φ1 = (lat1 * Math.PI) / 180;
    const φ2 = (lat2 * Math.PI) / 180;
    const Δφ = ((lat2 - lat1) * Math.PI) / 180;
    const Δλ = ((lon2 - lon1) * Math.PI) / 180;

    const a =
      Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  /**
   * Update participant count for an event
   */
  private async updateParticipantCount(eventId: string): Promise<void> {
    await this.query(
      `UPDATE events 
       SET participant_count = (
         SELECT COUNT(*) FROM event_participants 
         WHERE event_id = $1 AND status IN ('registered', 'checked_in')
       ),
       updated_at = NOW()
       WHERE id = $1`,
      [eventId],
    );

    // Check if should update status to FULL / OPEN (keep CANCELLED/COMPLETED)
    await this.query(
      `UPDATE events 
       SET status = CASE 
         WHEN status IN ('cancelled', 'completed') THEN status
         WHEN participant_limit IS NOT NULL AND participant_count >= participant_limit THEN 'full'
         WHEN status = 'full' AND (participant_limit IS NULL OR participant_count < participant_limit) THEN 'open'
         ELSE status
       END,
       updated_at = NOW()
       WHERE id = $1`,
      [eventId],
    );
  }

  private async getActiveParticipantCount(client: PoolClient, eventId: string): Promise<number> {
    const result = await client.query<{ count: string }>(
      `SELECT COUNT(*)::text AS count
       FROM event_participants
       WHERE event_id = $1 AND status IN ('registered', 'checked_in')`,
      [eventId],
    );
    return parseInt(result.rows[0]?.count ?? '0', 10);
  }

  async getNextEventForUser(userId: string): Promise<{
    id: string; name: string; start_date_time: string; ep_status: string;
  } | null> {
    return this.queryOne<{ id: string; name: string; start_date_time: string; ep_status: string }>(
      `SELECT e.id, e.name, e.start_date_time, ep.status AS ep_status
       FROM event_participants ep
       JOIN events e ON e.id = ep.event_id
       WHERE ep.user_id = $1::uuid
         AND ep.status IN ('registered', 'checked_in')
         AND e.start_date_time > NOW()
       ORDER BY e.start_date_time ASC
       LIMIT 1`,
      [userId],
    );
  }

  async getParticipant(eventId: string, userId: string): Promise<EventParticipant | null> {
    const row = await this.queryOne<ParticipantRow>(
      'SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2',
      [eventId, userId],
    );
    return row ? rowToParticipant(row) : null;
  }

  async update(
    eventId: string,
    data: {
      name?: string;
      type?: EventType;
      startDateTime?: Date;
      startLocation?: { longitude: number; latitude: number };
      locationName?: string;
      description?: string;
      participantLimit?: number | null;
      difficultyLevel?: 'beginner' | 'intermediate' | 'advanced' | null;
      workoutId?: string | null;
      trainerId?: string | null;
      isManuallyEdited?: boolean;
      deletedAt?: Date | null;
      price?: number;
    },
  ): Promise<Event | null> {
    const sets: string[] = [];
    const params: unknown[] = [];
    let idx = 1;

    if (data.name !== undefined) {
      sets.push(`name = $${idx++}`);
      params.push(data.name);
    }
    if (data.type !== undefined) {
      sets.push(`type = $${idx++}`);
      params.push(data.type);
    }
    if (data.startDateTime !== undefined) {
      sets.push(`start_date_time = $${idx++}`);
      params.push(data.startDateTime);
    }
    if (data.startLocation !== undefined) {
      sets.push(`start_longitude = $${idx++}`);
      params.push(data.startLocation.longitude);
      sets.push(`start_latitude = $${idx++}`);
      params.push(data.startLocation.latitude);
    }
    if (data.locationName !== undefined) {
      sets.push(`location_name = $${idx++}`);
      params.push(data.locationName || null);
    }
    if (data.description !== undefined) {
      sets.push(`description = $${idx++}`);
      params.push(data.description || null);
    }
    if (data.participantLimit !== undefined) {
      sets.push(`participant_limit = $${idx++}`);
      params.push(data.participantLimit);
    }
    if (data.difficultyLevel !== undefined) {
      sets.push(`difficulty_level = $${idx++}`);
      params.push(data.difficultyLevel);
    }
    if (data.workoutId !== undefined) {
      sets.push(`workout_id = $${idx++}`);
      params.push(data.workoutId);
    }
    if (data.trainerId !== undefined) {
      sets.push(`trainer_id = $${idx++}`);
      params.push(data.trainerId);
    }
    if (data.isManuallyEdited !== undefined) {
      sets.push(`is_manually_edited = $${idx++}`);
      params.push(data.isManuallyEdited);
    }
    if (data.deletedAt !== undefined) {
      sets.push(`deleted_at = $${idx++}`);
      params.push(data.deletedAt);
    }
    if (data.price !== undefined) {
      sets.push(`price = $${idx++}`);
      params.push(data.price);
    }

    if (sets.length === 0) {
      return this.findById(eventId);
    }

    sets.push(`updated_at = NOW()`);
    params.push(eventId);
    const row = await this.queryOne<EventRow>(
      `UPDATE events SET ${sets.join(', ')} WHERE id = $${idx} RETURNING *`,
      params,
    );
    return row ? rowToEvent(row) : null;
  }

  async updateTrainerFields(
    eventId: string,
    data: { workoutId?: string | null; trainerId?: string | null },
  ): Promise<Event | null> {
    const sets: string[] = [];
    const params: unknown[] = [];
    let idx = 1;

    if (data.workoutId !== undefined) {
      sets.push(`workout_id = $${idx++}`);
      params.push(data.workoutId);
    }
    if (data.trainerId !== undefined) {
      sets.push(`trainer_id = $${idx++}`);
      params.push(data.trainerId);
    }

    if (sets.length === 0) {
      return this.findById(eventId);
    }

    sets.push(`updated_at = NOW()`);
    params.push(eventId);
    const row = await this.queryOne<EventRow>(
      `UPDATE events SET ${sets.join(', ')} WHERE id = $${idx} RETURNING *`,
      params,
    );
    return row ? rowToEvent(row) : null;
  }

  async getParticipants(eventId: string): Promise<EventParticipant[]> {
    const rows = await this.queryMany<ParticipantRow>(
      `SELECT * FROM event_participants 
       WHERE event_id = $1 AND status IN ('registered', 'checked_in')
       ORDER BY created_at`,
      [eventId],
    );
    return rows.map(rowToParticipant);
  }

  /**
   * Get events where user is registered/checked_in for a given month (UTC)
   */
  async getRegisteredEventsForMonth(
    userId: string,
    year: number,
    month: number,
  ): Promise<Array<{ id: string; date: string; name: string }>> {
    const startDate = new Date(Date.UTC(year, month - 1, 1));
    const endDate = new Date(Date.UTC(year, month, 1));
    const rows = await this.queryMany<{ id: string; name: string; start_date_time: Date }>(
      `SELECT e.id, e.name, e.start_date_time
       FROM events e
       JOIN event_participants ep ON ep.event_id = e.id
       WHERE ep.user_id = $1::uuid
         AND ep.status IN ('registered', 'checked_in')
         AND e.start_date_time >= $2
         AND e.start_date_time < $3
         AND e.type != 'training'
       ORDER BY e.start_date_time ASC`,
      [userId, startDate, endDate],
    );
    return rows.map(row => ({
      id: row.id,
      date: row.start_date_time.toISOString().slice(0, 10),
      name: row.name,
    }));
  }

  /**
   * Получить события клуба за месяц
   */
  async findByClubAndMonth(clubId: string, yearMonth: string): Promise<Event[]> {
    const startDate = `${yearMonth}-01`;
    const rows = await this.queryMany<EventRow>(
      `SELECT * FROM events 
       WHERE organizer_id = $1 
         AND organizer_type = 'club'
         AND start_date_time >= $2::timestamp
         AND start_date_time < ($2::timestamp + interval '1 month')
         AND deleted_at IS NULL
       ORDER BY start_date_time ASC`,
      [clubId, startDate],
    );
    return rows.map(rowToEvent);
  }

  /**
   * Найти событие, сгенерированное из конкретного шаблона на дату
   */
  async findByTemplateAndDate(templateId: string, date: string): Promise<Event | null> {
    const row = await this.queryOne<EventRow>(
      `SELECT * FROM events 
       WHERE template_id = $1 AND generated_for_date = $2::date AND deleted_at IS NULL`,
      [templateId, date],
    );
    return row ? rowToEvent(row) : null;
  }

  /**
   * Найти будущие события клуба, сгенерированные из шаблона
   */
  async findFutureByTemplate(templateId: string): Promise<Event[]> {
    const rows = await this.queryMany<EventRow>(
      `SELECT * FROM events 
       WHERE template_id = $1 
         AND start_date_time >= NOW() 
         AND deleted_at IS NULL`,
      [templateId],
    );
    return rows.map(rowToEvent);
  }
}

// Singleton instance
let instance: EventsRepository | null = null;

export function getEventsRepository(): EventsRepository {
  if (!instance) {
    instance = new EventsRepository();
  }
  return instance;
}
