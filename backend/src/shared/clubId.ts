/**
 * Shared club id format used across API, DB-bound logic and WebSocket channels.
 *
 * Allowed characters:
 * - latin letters
 * - digits
 * - underscore
 * - hyphen
 *
 * Length: 1..128 characters (aligned with VARCHAR(128) in DB).
 */
export const CLUB_ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

export function isValidClubId(clubId: string): boolean {
  return CLUB_ID_RE.test(clubId);
}

