/**
 * Events repository - database operations for events
 */

import { BaseRepository } from './base.repository';
import { Event } from '../../modules/events/event.entity';
import { EventType } from '../../modules/events/event.type';
import { EventStatus } from '../../modules/events/event.status';
import { EventListItemDto, EventDetailsDto } from '../../modules/events/event.dto';
import { PoolClient } from 'pg';

interface EventRow {
  id: string;
  name: string;
  type: string;
  status: string;
  start_date_time: Date;
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
}

function rowToEvent(row: EventRow): Event {
  return {
    id: row.id,
    name: row.name,
    type: row.type as EventType,
    status: row.status as EventStatus,
    startDateTime: row.start_date_time,
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
    const row = await this.queryOne<EventRow>(
      'SELECT * FROM events WHERE id = $1',
      [id]
    );
    return row ? rowToEvent(row) : null;
  }

  async findAll(options?: {
    status?: EventStatus[];
    dateFilter?: 'today' | 'tomorrow' | 'next7days';
    clubId?: string;
    cityId?: string;
    difficultyLevel?: string;
    eventType?: EventType;
    organizerId?: string;
    limit?: number;
    offset?: number;
  }): Promise<Event[]> {
    const limit = options?.limit || 50;
    const offset = options?.offset || 0;
    
    const conditions: string[] = [];
    const params: unknown[] = [];
    let paramIndex = 1;
    
    // Status filter (default: only OPEN and FULL, exclude DRAFT)
    if (options?.status && options.status.length > 0) {
      conditions.push(`status = ANY($${paramIndex++})`);
      params.push(options.status);
    } else {
      conditions.push(`status IN ('open', 'full')`);
    }
    
    // Date filter
    if (options?.dateFilter) {
      const now = new Date();
      const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      
      if (options.dateFilter === 'today') {
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        conditions.push(`start_date_time >= $${paramIndex++} AND start_date_time < $${paramIndex++}`);
        params.push(today, tomorrow);
      } else if (options.dateFilter === 'tomorrow') {
        const tomorrow = new Date(today);
        tomorrow.setDate(tomorrow.getDate() + 1);
        const dayAfter = new Date(tomorrow);
        dayAfter.setDate(dayAfter.getDate() + 1);
        conditions.push(`start_date_time >= $${paramIndex++} AND start_date_time < $${paramIndex++}`);
        params.push(tomorrow, dayAfter);
      } else if (options.dateFilter === 'next7days') {
        const nextWeek = new Date(today);
        nextWeek.setDate(nextWeek.getDate() + 7);
        conditions.push(`start_date_time >= $${paramIndex++} AND start_date_time < $${paramIndex++}`);
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
    
    // Event type filter
    if (options?.eventType) {
      conditions.push(`type = $${paramIndex++}`);
      params.push(options.eventType);
    }
    
    // Organizer filter
    if (options?.organizerId) {
      conditions.push(`organizer_id = $${paramIndex++}`);
      params.push(options.organizerId);
    }
    
    let sql = 'SELECT * FROM events';
    if (conditions.length > 0) {
      sql += ` WHERE ${conditions.join(' AND ')}`;
    }
    sql += ` ORDER BY start_date_time ASC LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(limit, offset);
    
    const rows = await this.queryMany<EventRow>(sql, params);
    return rows.map(rowToEvent);
  }

  async create(data: {
    name: string;
    type: EventType;
    startDateTime: Date;
    startLocation: { longitude: number; latitude: number };
    locationName?: string;
    organizerId: string;
    organizerType: 'club' | 'trainer';
    difficultyLevel?: 'beginner' | 'intermediate' | 'advanced';
    description?: string;
    participantLimit?: number;
    territoryId?: string;
    cityId: string;
  }): Promise<Event> {
    const row = await this.queryOne<EventRow>(
      `INSERT INTO events (
        name, type, status, start_date_time, start_longitude, start_latitude,
        location_name, organizer_id, organizer_type, difficulty_level,
        description, participant_limit, territory_id, city_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *`,
      [
        data.name,
        data.type,
        EventStatus.OPEN,
        data.startDateTime,
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
      ]
    );
    return rowToEvent(row!);
  }

  /**
   * Join event - register user as participant
   * Returns error message if cannot join, null if success
   */
  async joinEvent(eventId: string, userId: string): Promise<{ error?: string; participant?: EventParticipant }> {
    const pool = this.getPool();
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Lock event row to make participant_limit checks and count updates atomic.
      const eventRes = await client.query<EventRow>(
        'SELECT * FROM events WHERE id = $1 FOR UPDATE',
        [eventId]
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
        [eventId, userId]
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
          [existing.id]
        );
        participantRow = updatedRes.rows[0];
      } else {
        const insertRes = await client.query<ParticipantRow>(
          `INSERT INTO event_participants (event_id, user_id, status)
           VALUES ($1, $2, 'registered')
           RETURNING *`,
          [eventId, userId]
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
        [eventId, newActiveCount]
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
    coordinates: { longitude: number; latitude: number }
  ): Promise<{ error?: string; participant?: EventParticipant }> {
    // Check if event exists
    const event = await this.findById(eventId);
    if (!event) {
      return { error: 'Event not found' };
    }
    
    // Check time window (15 minutes before to 30 minutes after start)
    const now = new Date();
    const eventStart = new Date(event.startDateTime);
    const windowStart = new Date(eventStart.getTime() - 15 * 60 * 1000); // 15 min before
    const windowEnd = new Date(eventStart.getTime() + 30 * 60 * 1000);   // 30 min after
    
    if (now < windowStart) {
      return { error: 'Check-in is not yet available. Opens 15 minutes before event start.' };
    }
    if (now > windowEnd) {
      return { error: 'Check-in window has closed.' };
    }
    
    // Check GPS distance (500 meters radius)
    const distance = this.calculateDistance(
      coordinates.latitude, coordinates.longitude,
      event.startLocation.latitude, event.startLocation.longitude
    );
    
    if (distance > 500) {
      return { error: `Too far from event location. Distance: ${Math.round(distance)}m, max: 500m` };
    }
    
    // Check if registered
    const registration = await this.queryOne<ParticipantRow>(
      'SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2',
      [eventId, userId]
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
      [coordinates.longitude, coordinates.latitude, registration.id]
    );
    
    return { participant: rowToParticipant(updated!) };
  }

  /**
   * Cancel participation in event
   */
  async leaveEvent(eventId: string, userId: string): Promise<{ error?: string; participant?: EventParticipant }> {
    const registration = await this.queryOne<ParticipantRow>(
      'SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2',
      [eventId, userId]
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
      [registration.id]
    );

    await this.updateParticipantCount(eventId);

    return { participant: rowToParticipant(updated!) };
  }

  /**
   * Calculate distance between two GPS points using Haversine formula
   * Returns distance in meters
   */
  private calculateDistance(
    lat1: number, lon1: number,
    lat2: number, lon2: number
  ): number {
    const R = 6371000; // Earth's radius in meters
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
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
      [eventId]
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
      [eventId]
    );
  }

  private async getActiveParticipantCount(client: PoolClient, eventId: string): Promise<number> {
    const result = await client.query<{ count: string }>(
      `SELECT COUNT(*)::text AS count
       FROM event_participants
       WHERE event_id = $1 AND status IN ('registered', 'checked_in')`,
      [eventId]
    );
    return parseInt(result.rows[0]?.count ?? '0', 10);
  }

  async getParticipant(eventId: string, userId: string): Promise<EventParticipant | null> {
    const row = await this.queryOne<ParticipantRow>(
      'SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2',
      [eventId, userId]
    );
    return row ? rowToParticipant(row) : null;
  }

  async getParticipants(eventId: string): Promise<EventParticipant[]> {
    const rows = await this.queryMany<ParticipantRow>(
      `SELECT * FROM event_participants 
       WHERE event_id = $1 AND status IN ('registered', 'checked_in')
       ORDER BY created_at`,
      [eventId]
    );
    return rows.map(rowToParticipant);
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
