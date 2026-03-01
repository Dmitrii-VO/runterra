import { BaseRepository } from './base.repository';
import { PoolClient } from 'pg';

export class TerritoriesRepository extends BaseRepository {
  public getSeasonStart(date: Date = new Date()): Date {
    // Returns 1st day of the current month in UTC
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1));
  }

  async getTerritoryScores(seasonStart: Date): Promise<
    Array<{
      territory_id: string;
      club_id: string;
      club_name: string; // We'll join with clubs table
      total_meters: string; // BigInt returns as string
    }>
  > {
    // Join with clubs to get name
    const rows = await this.queryMany<{
      territory_id: string;
      club_id: string;
      club_name: string;
      total_meters: string;
    }>(
      `SELECT 
         tcs.territory_id, 
         tcs.club_id, 
         c.name as club_name,
         tcs.total_meters
       FROM territory_club_scores tcs
       JOIN clubs c ON tcs.club_id = c.id
       WHERE tcs.season_start = $1
       ORDER BY tcs.territory_id, tcs.total_meters DESC`,
      [seasonStart],
    );
    return rows;
  }

  /**
   * Records run contribution to territories and updates club scores.
   * MUST be executed within a transaction.
   */
  async addRunContribution(
    client: PoolClient,
    runId: string,
    clubId: string,
    contributions: Map<string, number>,
  ): Promise<void> {
    if (contributions.size === 0) return;

    const seasonStart = this.getSeasonStart();
    const seasonEnd = new Date(seasonStart);
    seasonEnd.setUTCMonth(seasonEnd.getUTCMonth() + 1);

    // 1. Insert into territory_run_contributions
    const values: unknown[] = [];
    const placeholders: string[] = [];
    let i = 1;

    for (const [territoryId, meters] of contributions) {
      if (meters <= 0) continue;
      // run_id, territory_id, club_id, meters, season_start, season_end
      placeholders.push(`($${i}, $${i + 1}, $${i + 2}, $${i + 3}, $${i + 4}, $${i + 5})`);
      values.push(runId, territoryId, clubId, meters, seasonStart, seasonEnd);
      i += 6;
    }

    if (values.length === 0) return;

    await client.query(
      `INSERT INTO territory_run_contributions (run_id, territory_id, club_id, meters, season_start, season_end)
       VALUES ${placeholders.join(', ')}
       ON CONFLICT (run_id, territory_id) DO NOTHING`,
      values,
    );

    // 2. Upsert territory_club_scores
    // We reuse the same data structure effectively.
    // values for scores: territory_id, club_id, season_start, season_end, total_meters

    const scoreValues: unknown[] = [];
    const scorePlaceholders: string[] = [];
    let j = 1;

    for (const [territoryId, meters] of contributions) {
      if (meters <= 0) continue;
      scorePlaceholders.push(`($${j}, $${j + 1}, $${j + 2}, $${j + 3}, $${j + 4})`);
      scoreValues.push(territoryId, clubId, seasonStart, seasonEnd, meters);
      j += 5;
    }

    await client.query(
      `INSERT INTO territory_club_scores (territory_id, club_id, season_start, season_end, total_meters)
         VALUES ${scorePlaceholders.join(', ')}
         ON CONFLICT (territory_id, club_id, season_start)
         DO UPDATE SET 
            total_meters = territory_club_scores.total_meters + EXCLUDED.total_meters,
            updated_at = NOW()`,
      scoreValues,
    );
  }
}

// Singleton instance
let instance: TerritoriesRepository | null = null;

export function getTerritoriesRepository(): TerritoriesRepository {
  if (!instance) {
    instance = new TerritoriesRepository();
  }
  return instance;
}
