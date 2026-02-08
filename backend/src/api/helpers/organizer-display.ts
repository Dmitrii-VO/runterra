/**
 * Resolves organizer display name (club name or user name) for event DTOs.
 * Used by events and map routes when building event responses.
 */

import { getClubsRepository, getUsersRepository } from '../../db/repositories';
import { logger } from '../../shared/logger';

const key = (organizerId: string, organizerType: 'club' | 'trainer') =>
  `${organizerType}:${organizerId}`;

/** Single organizer: one DB lookup. Use for GET /api/events/:id. */
export async function getOrganizerDisplayName(
  organizerId: string,
  organizerType: 'club' | 'trainer',
): Promise<string | undefined> {
  if (!organizerId?.trim()) return undefined;
  try {
    if (organizerType === 'club') {
      const club = await getClubsRepository().findById(organizerId);
      return club?.name;
    }
    const user = await getUsersRepository().findById(organizerId);
    return user?.name;
  } catch (error) {
    logger.warn('Failed to resolve organizer display name', { organizerId, organizerType, error });
    return undefined;
  }
}

/**
 * Batch resolve organizer display names. Two DB queries total (clubs + users).
 * Use for GET /api/events and GET /api/map/data to avoid N+1.
 */
export async function getOrganizerDisplayNamesBatch(
  pairs: ReadonlyArray<{ organizerId: string; organizerType: 'club' | 'trainer' }>,
): Promise<Map<string, string | undefined>> {
  const result = new Map<string, string | undefined>();
  if (pairs.length === 0) return result;

  const nonEmpty = (id: string) => id.trim().length > 0;
  const clubIds = Array.from(
    new Set(
      pairs.filter((p) => p.organizerType === 'club' && nonEmpty(p.organizerId)).map((p) => p.organizerId),
    ),
  );
  const trainerIds = Array.from(
    new Set(
      pairs.filter((p) => p.organizerType === 'trainer' && nonEmpty(p.organizerId)).map((p) => p.organizerId),
    ),
  );

  try {
    const [clubs, users] = await Promise.all([
      clubIds.length > 0 ? getClubsRepository().findByIds(clubIds) : Promise.resolve([]),
      trainerIds.length > 0 ? getUsersRepository().findByIds(trainerIds) : Promise.resolve([]),
    ]);

    for (const club of clubs) {
      result.set(key(club.id, 'club'), club.name);
    }
    for (const user of users) {
      result.set(key(user.id, 'trainer'), user.name);
    }
  } catch (error) {
    logger.warn('Failed to batch resolve organizer display names', { error });
  }

  return result;
}
