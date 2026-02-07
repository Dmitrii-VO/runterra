/**
 * Unit tests for EventsRepository business logic.
 * Mocks: DB (pg pool). Time is mocked for check-in window tests.
 *
 * TODO: No-show policy — participant status 'no_show' exists in type but
 * no logic yet that sets/checks it (e.g. registered without check-in after event end).
 */

import { EventStatus } from '../../modules/events/event.status';
import { EventType } from '../../modules/events/event.type';
import { EventsRepository, getEventsRepository } from './events.repository';

// Mock DB client so repository uses fake pool
const mockQuery = jest.fn();
jest.mock('../client', () => ({
  getDbPool: () => null,
  createDbPool: () => ({
    query: mockQuery,
    connect: async () => ({
      query: mockQuery,
      release: () => {},
    }),
    on: () => {},
  }),
}));

function eventRow(overrides: Partial<{
  id: string; status: string; participant_limit: number | null; participant_count: number;
  start_date_time: Date; start_longitude: number; start_latitude: number;
}> = {}) {
  return {
    id: 'ev-1',
    name: 'Test Run',
    type: EventType.TRAINING,
    status: EventStatus.OPEN,
    start_date_time: new Date(),
    start_longitude: 30.3351,
    start_latitude: 59.9343,
    location_name: 'Park',
    organizer_id: 'org-1',
    organizer_type: 'club',
    difficulty_level: 'intermediate',
    description: null,
    participant_limit: 20,
    participant_count: 5,
    territory_id: null,
    created_at: new Date(),
    updated_at: new Date(),
    ...overrides,
  };
}

function participantRow(overrides: Partial<{
  id: string; event_id: string; user_id: string; status: string;
  checked_in_at: Date | null; check_in_longitude: number | null; check_in_latitude: number | null;
}> = {}) {
  return {
    id: 'p-1',
    event_id: 'ev-1',
    user_id: 'user-1',
    status: 'registered',
    checked_in_at: null,
    check_in_longitude: null,
    check_in_latitude: null,
    created_at: new Date(),
    ...overrides,
  };
}

describe('EventsRepository', () => {
  let repo: EventsRepository;

  beforeAll(() => {
    repo = getEventsRepository();
  });

  beforeEach(() => {
    mockQuery.mockReset();
  });

  describe('joinEvent', () => {
    it('should return error when event does not exist', async () => {
      mockQuery.mockImplementation(async (sql: string) => {
        if (sql.includes('SELECT * FROM events WHERE id = $1 FOR UPDATE')) {
          return { rows: [], rowCount: 0 };
        }
        return { rows: [], rowCount: 0 };
      });

      const result = await repo.joinEvent('non-existent', 'user-1');

      expect(result.error).toBe('Event not found');
      expect(result.participant).toBeUndefined();
    });

    it('should return error when event status is not open', async () => {
      mockQuery.mockImplementation(async (sql: string) => {
        if (sql.includes('SELECT * FROM events WHERE id = $1 FOR UPDATE')) {
          return {
            rows: [eventRow({ status: EventStatus.FULL })],
            rowCount: 1,
          };
        }
        return { rows: [], rowCount: 0 };
      });

      const result = await repo.joinEvent('ev-1', 'user-1');

      expect(result.error).toContain('Cannot join event with status');
      expect(result.participant).toBeUndefined();
    });

    it('should return error when event is full (participantCount >= limit)', async () => {
      mockQuery.mockImplementation(async (sql: string) => {
        if (sql.includes('SELECT * FROM events WHERE id = $1 FOR UPDATE')) {
          return {
            rows: [eventRow({ participant_limit: 10, participant_count: 10 })],
            rowCount: 1,
          };
        }
        if (sql.includes('SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2 FOR UPDATE')) {
          return { rows: [], rowCount: 0 };
        }
        if (sql.includes('SELECT COUNT(*)::text AS count')) {
          return { rows: [{ count: '10' }], rowCount: 1 };
        }
        return { rows: [], rowCount: 0 };
      });

      const result = await repo.joinEvent('ev-1', 'user-1');

      expect(result.error).toBe('Cannot join event with status: full');
      expect(result.participant).toBeUndefined();
    });

    it('should return error when user already registered', async () => {
      mockQuery.mockImplementation(async (sql: string) => {
        if (sql.includes('SELECT * FROM events WHERE id = $1 FOR UPDATE')) {
          return {
            rows: [eventRow()],
            rowCount: 1,
          };
        }
        if (sql.includes('SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2 FOR UPDATE')) {
          return {
            rows: [participantRow({ status: 'registered' })],
            rowCount: 1,
          };
        }
        return { rows: [], rowCount: 0 };
      });

      const result = await repo.joinEvent('ev-1', 'user-1');

      expect(result.error).toBe('Already registered for this event');
      expect(result.participant).toBeUndefined();
    });

    it('should return participant when join succeeds for open event', async () => {
      let activeCountCalls = 0;
      mockQuery.mockImplementation(async (sql: string) => {
        if (sql.includes('SELECT * FROM events WHERE id = $1 FOR UPDATE')) {
          return {
            rows: [eventRow()],
            rowCount: 1,
          };
        }
        if (sql.includes('SELECT * FROM event_participants WHERE event_id = $1 AND user_id = $2 FOR UPDATE')) {
          return { rows: [], rowCount: 0 };
        }
        if (sql.includes('SELECT COUNT(*)::text AS count')) {
          activeCountCalls += 1;
          return {
            rows: [{ count: activeCountCalls === 1 ? '5' : '6' }],
            rowCount: 1,
          };
        }
        if (sql.includes('INSERT INTO event_participants')) {
          return {
            rows: [participantRow()],
            rowCount: 1,
          };
        }
        return { rows: [], rowCount: 0 };
      });

      const result = await repo.joinEvent('ev-1', 'user-1');

      expect(result.error).toBeUndefined();
      expect(result.participant).toBeDefined();
      expect(result.participant!.eventId).toBe('ev-1');
      expect(result.participant!.userId).toBe('user-1');
      expect(result.participant!.status).toBe('registered');
    });
  });

  describe('checkIn', () => {
    const eventStart = new Date('2025-06-15T10:00:00Z');
    const eventRowForCheckIn = () =>
      eventRow({
        start_date_time: eventStart,
        start_longitude: 30.3351,
        start_latitude: 59.9343,
      });

    it('should return error when event does not exist', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const result = await repo.checkIn('non-existent', 'user-1', {
        longitude: 30.3351,
        latitude: 59.9343,
      });

      expect(result.error).toBe('Event not found');
      expect(result.participant).toBeUndefined();
    });

    it('should return error when check-in is before window (15 min before start)', async () => {
      const now = new Date(eventStart.getTime() - 20 * 60 * 1000);
      jest.useFakeTimers().setSystemTime(now);
      mockQuery.mockResolvedValueOnce({
        rows: [eventRowForCheckIn()],
        rowCount: 1,
      });

      const result = await repo.checkIn('ev-1', 'user-1', {
        longitude: 30.3351,
        latitude: 59.9343,
      });

      expect(result.error).toContain('Check-in is not yet available');
      jest.useRealTimers();
    });

    it('should return error when check-in is after window (30 min after start)', async () => {
      const now = new Date(eventStart.getTime() + 35 * 60 * 1000);
      jest.useFakeTimers().setSystemTime(now);
      mockQuery.mockResolvedValueOnce({
        rows: [eventRowForCheckIn()],
        rowCount: 1,
      });

      const result = await repo.checkIn('ev-1', 'user-1', {
        longitude: 30.3351,
        latitude: 59.9343,
      });

      expect(result.error).toContain('Check-in window has closed');
      jest.useRealTimers();
    });

    it('should return error when user is too far from event location (>500m)', async () => {
      const now = new Date(eventStart.getTime() - 5 * 60 * 1000);
      jest.useFakeTimers().setSystemTime(now);
      mockQuery.mockResolvedValueOnce({
        rows: [eventRowForCheckIn()],
        rowCount: 1,
      });

      // ~6km away (e.g. another city)
      const result = await repo.checkIn('ev-1', 'user-1', {
        longitude: 30.45,
        latitude: 59.99,
      });

      expect(result.error).toContain('Too far from event location');
      expect(result.error).toContain('500');
      jest.useRealTimers();
    });

    it('should return error when user is not registered', async () => {
      const now = new Date(eventStart.getTime() - 5 * 60 * 1000);
      jest.useFakeTimers().setSystemTime(now);
      mockQuery
        .mockResolvedValueOnce({
          rows: [eventRowForCheckIn()],
          rowCount: 1,
        })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const result = await repo.checkIn('ev-1', 'user-1', {
        longitude: 30.3351,
        latitude: 59.9343,
      });

      expect(result.error).toBe('Not registered for this event');
      jest.useRealTimers();
    });

    it('should return error when registration was cancelled', async () => {
      const now = new Date(eventStart.getTime() - 5 * 60 * 1000);
      jest.useFakeTimers().setSystemTime(now);
      mockQuery
        .mockResolvedValueOnce({
          rows: [eventRowForCheckIn()],
          rowCount: 1,
        })
        .mockResolvedValueOnce({
          rows: [participantRow({ status: 'cancelled' })],
          rowCount: 1,
        });

      const result = await repo.checkIn('ev-1', 'user-1', {
        longitude: 30.3351,
        latitude: 59.9343,
      });

      expect(result.error).toBe('Registration was cancelled');
      jest.useRealTimers();
    });

    it('should return error when user already checked in', async () => {
      const now = new Date(eventStart.getTime() - 5 * 60 * 1000);
      jest.useFakeTimers().setSystemTime(now);
      mockQuery
        .mockResolvedValueOnce({
          rows: [eventRowForCheckIn()],
          rowCount: 1,
        })
        .mockResolvedValueOnce({
          rows: [participantRow({ status: 'checked_in' })],
          rowCount: 1,
        });

      const result = await repo.checkIn('ev-1', 'user-1', {
        longitude: 30.3351,
        latitude: 59.9343,
      });

      expect(result.error).toBe('Already checked in');
      jest.useRealTimers();
    });

    it('should return participant when check-in succeeds within window and radius', async () => {
      const now = new Date(eventStart.getTime() - 5 * 60 * 1000);
      jest.useFakeTimers().setSystemTime(now);
      mockQuery
        .mockResolvedValueOnce({
          rows: [eventRowForCheckIn()],
          rowCount: 1,
        })
        .mockResolvedValueOnce({
          rows: [participantRow({ status: 'registered' })],
          rowCount: 1,
        })
        .mockResolvedValueOnce({
          rows: [
            participantRow({
              status: 'checked_in',
              checked_in_at: now,
              check_in_longitude: 30.3351,
              check_in_latitude: 59.9343,
            }),
          ],
          rowCount: 1,
        });

      const result = await repo.checkIn('ev-1', 'user-1', {
        longitude: 30.3351,
        latitude: 59.9343,
      });

      expect(result.error).toBeUndefined();
      expect(result.participant).toBeDefined();
      expect(result.participant!.status).toBe('checked_in');
      jest.useRealTimers();
    });
  });

  describe('leaveEvent', () => {
    it('should return error when user is not registered', async () => {
      mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const result = await repo.leaveEvent('ev-1', 'user-1');

      expect(result.error).toBe('Not registered for this event');
      expect(result.participant).toBeUndefined();
    });

    it('should return error when participation already cancelled', async () => {
      mockQuery.mockResolvedValueOnce({
        rows: [participantRow({ status: 'cancelled' })],
        rowCount: 1,
      });

      const result = await repo.leaveEvent('ev-1', 'user-1');

      expect(result.error).toBe('Already cancelled participation');
      expect(result.participant).toBeUndefined();
    });

    it('should cancel participation and update participant count', async () => {
      mockQuery
        .mockResolvedValueOnce({
          rows: [participantRow({ status: 'registered' })],
          rowCount: 1,
        })
        .mockResolvedValueOnce({
          rows: [participantRow({ status: 'cancelled' })],
          rowCount: 1,
        })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 })
        .mockResolvedValueOnce({ rows: [], rowCount: 0 });

      const result = await repo.leaveEvent('ev-1', 'user-1');

      expect(result.error).toBeUndefined();
      expect(result.participant).toBeDefined();
      expect(result.participant!.status).toBe('cancelled');
    });
  });
});
