/**
 * Shared club id format used across API, DB-bound logic and WebSocket channels.
 *
 * After migration 012_clubs_fk, club_id is UUID only (no slug-based IDs).
 * Format: standard UUID v4 (8-4-4-4-12 hex digits).
 *
 * Examples:
 * - Valid: "550e8400-e29b-41d4-a716-446655440000"
 * - Invalid: "new-club-id" (old slug format, no longer supported)
 */
export const CLUB_ID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function isValidClubId(clubId: string): boolean {
  return CLUB_ID_RE.test(clubId);
}

