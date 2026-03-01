/**
 * Helper to check if a user is a trainer or leader in any club
 */

import { getClubMembersRepository } from '../../db/repositories';

export async function isTrainerInAnyClub(userId: string): Promise<boolean> {
  const repo = getClubMembersRepository();
  const clubs = await repo.findActiveClubsByUser(userId);
  return clubs.some(c => c.role === 'trainer' || c.role === 'leader');
}

export async function isTrainerOrLeaderInClub(userId: string, clubId: string): Promise<boolean> {
  const repo = getClubMembersRepository();
  const membership = await repo.findByClubAndUser(clubId, userId);
  if (!membership || membership.status !== 'active') return false;
  return membership.role === 'trainer' || membership.role === 'leader';
}

export async function isLeaderInClub(userId: string, clubId: string): Promise<boolean> {
  const repo = getClubMembersRepository();
  const membership = await repo.findByClubAndUser(clubId, userId);
  if (!membership || membership.status !== 'active') return false;
  return membership.role === 'leader';
}
