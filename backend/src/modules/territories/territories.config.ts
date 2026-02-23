import { TerritoryViewDto, ZoneTier, LeaderboardEntryDto, ClubProgressDto } from './territory.dto';
import { TerritoryStatus } from './territory.status';
import type { GeoCoordinates } from '../../shared/types/coordinates';

/**
 * Conversion constants for coordinates to meters approximation.
 * 1 degree latitude is approximately 111.132 km.
 * 1 degree longitude at equator is approximately 111.320 km.
 */
const METERS_PER_DEGREE_LAT = 111132;
const METERS_PER_DEGREE_LON_EQUATOR = 111320;

/**
 * Generates square polygon geometry from center coordinates.
 * Used for MVP zone visualization — squares instead of overlapping circles.
 *
 * Uses equirectangular projection approximation with cos(lat) correction
 * for longitude. This is sufficient for city-scale zones (<10km).
 */
function generateSquareGeometry(
  lat: number,
  lon: number,
  sizeInMeters: number,
): GeoCoordinates[] {
  const halfSizeMeters = sizeInMeters / 2;
  const latOffset = halfSizeMeters / METERS_PER_DEGREE_LAT;

  // Correction for longitude depends on latitude: 1 deg lon = 111320 * cos(lat) meters
  const latRad = (lat * Math.PI) / 180;
  const lonOffset = halfSizeMeters / (METERS_PER_DEGREE_LON_EQUATOR * Math.cos(latRad));

  return [
    { longitude: lon - lonOffset, latitude: lat - latOffset },
    { longitude: lon + lonOffset, latitude: lat - latOffset },
    { longitude: lon + lonOffset, latitude: lat + latOffset },
    { longitude: lon - lonOffset, latitude: lat + latOffset },
  ];
}

import { SPB_DISTRICTS_DATA } from './spb-districts.data';

// --- Tier configuration ---

const TIER_CONFIG: Record<ZoneTier, { paceThreshold: string; pointMultiplier: number; color: string }> = {
  green: { paceThreshold: '7:00', pointMultiplier: 1.2, color: '#4CAF50' },
  blue:  { paceThreshold: '5:30', pointMultiplier: 1.3, color: '#2196F3' },
  red:   { paceThreshold: '4:30', pointMultiplier: 1.4, color: '#F44336' },
  black: { paceThreshold: '4:00', pointMultiplier: 1.5, color: '#212121' },
};

// --- Mock activity data per district ---

const DISTRICT_MOCK_ACTIVITY: Record<string, { totalKm: number; avgPace: string }> = {
  'spb-admiralteyskiy':    { totalKm: 320, avgPace: '5:45' },
  'spb-vasileostrovskiy':  { totalKm: 180, avgPace: '6:10' },
  'spb-vyborgskiy':        { totalKm: 45,  avgPace: '7:20' },
  'spb-kalininskiy':       { totalKm: 90,  avgPace: '6:30' },
  'spb-kirovskiy':         { totalKm: 30,  avgPace: '7:40' },
  'spb-kolpinskiy':        { totalKm: 15,  avgPace: '8:00' },
  'spb-krasnogvardeyskiy': { totalKm: 210, avgPace: '5:20' },
  'spb-krasnoselskiy':     { totalKm: 25,  avgPace: '7:10' },
  'spb-kronshtadtskiy':    { totalKm: 10,  avgPace: '7:50' },
  'spb-kurortnyy':         { totalKm: 60,  avgPace: '6:50' },
  'spb-moskovskiy':        { totalKm: 250, avgPace: '5:10' },
  'spb-nevskiy':           { totalKm: 150, avgPace: '5:40' },
  'spb-petrogradskiy':     { totalKm: 550, avgPace: '4:20' },
  'spb-petrodvorcovyy':    { totalKm: 35,  avgPace: '7:30' },
  'spb-primorskiy':        { totalKm: 480, avgPace: '4:40' },
  'spb-pushkinskiy':       { totalKm: 40,  avgPace: '7:00' },
  'spb-frunzenskiy':       { totalKm: 120, avgPace: '6:00' },
  'spb-centralnyy':        { totalKm: 600, avgPace: '4:10' },
};

// Fake club names for deterministic leaderboard generation
const FAKE_CLUBS = [
  'RunnersPro', 'NevaBears', 'PiterStride', 'NorthWind RC',
  'BalticRunners', 'FinnishLine', 'GraniteSoles', 'WhiteNights RC',
  'BridgeRunners', 'CanalCrew',
];

/**
 * Parses pace string "M:SS" to total seconds.
 */
function paceToSeconds(pace: string): number {
  const [min, sec] = pace.split(':').map(Number);
  return min * 60 + sec;
}

/**
 * Computes the volume score (0-3) based on total km.
 */
function volumeScore(totalKm: number): number {
  if (totalKm > 500) return 3;
  if (totalKm >= 200) return 2;
  if (totalKm >= 50) return 1;
  return 0;
}

/**
 * Computes the pace score (0-3) based on average pace.
 */
function paceScore(avgPace: string): number {
  const sec = paceToSeconds(avgPace);
  if (sec < paceToSeconds('4:30')) return 3;
  if (sec < paceToSeconds('5:30')) return 2;
  if (sec < paceToSeconds('7:00')) return 1;
  return 0;
}

/**
 * Computes the zone tier based on activity metrics (spec section 1.2).
 * Tier = max(volume_score, pace_score) mapped to green/blue/red/black.
 */
function computeTier(totalKm: number, avgPace: string): ZoneTier {
  const score = Math.max(volumeScore(totalKm), paceScore(avgPace));
  const tiers: ZoneTier[] = ['green', 'blue', 'red', 'black'];
  return tiers[score];
}

/**
 * Generates a deterministic mock leaderboard for a district.
 * Uses a simple hash of the district ID for stable pseudo-random selection.
 */
function generateMockLeaderboard(districtId: string): LeaderboardEntryDto[] {
  // Simple hash to get a stable seed from the district ID
  let hash = 0;
  for (let i = 0; i < districtId.length; i++) {
    hash = ((hash << 5) - hash + districtId.charCodeAt(i)) | 0;
  }
  hash = Math.abs(hash);

  // 2-5 clubs per district
  const clubCount = 2 + (hash % 4);
  const entries: LeaderboardEntryDto[] = [];

  for (let i = 0; i < clubCount; i++) {
    const clubIndex = (hash + i * 7) % FAKE_CLUBS.length;
    // Deterministic km: decreasing by position, based on hash
    const baseKm = 100 + ((hash + i * 31) % 400);
    const totalKm = Math.round((baseKm / (i + 1)) * 10) / 10;

    entries.push({
      clubId: `mock-club-${clubIndex}`,
      clubName: FAKE_CLUBS[clubIndex],
      totalKm,
      position: i + 1,
    });
  }

  // Sort by totalKm descending and reassign positions
  entries.sort((a, b) => b.totalKm - a.totalKm);
  entries.forEach((e, idx) => { e.position = idx + 1; });

  return entries;
}

/**
 * Computes the ISO 8601 date string for the 1st of next month (season end).
 */
function computeSeasonEndsAt(): string {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return nextMonth.toISOString();
}

// --- Static config ---

/**
 * Static territories configuration for Saint Petersburg (spb).
 *
 * NOTE: This is a technical data source for MVP. There is no DB table
 * for territories yet; when it appears, this config can be replaced with
 * real persistence without changing API contracts.
 */

type StaticTerritoryConfig = Omit<TerritoryViewDto, 'createdAt' | 'updatedAt' | 'geometry'> & {
  geometry?: GeoCoordinates[];
  color?: string;
};

/** Square size in meters for MVP zone visualization (fallback) */
const TERRITORY_SQUARE_SIZE_M = 1000;

/**
 * All territories use clubId: undefined (free) until capture logic is implemented.
 *
 * UPDATED 2026-02-15: Now using real administrative districts polygons.
 */
const SPB_TERRITORIES_CONFIG: StaticTerritoryConfig[] = SPB_DISTRICTS_DATA;

const ZONE_BOUNTY = 1.5;

/**
 * Resolves myClubProgress from leaderboard for the user's clubs.
 * Returns the first match found in the leaderboard, or null.
 */
export function resolveMyClubProgress(
  leaderboard: LeaderboardEntryDto[],
  userClubIds: string[],
): ClubProgressDto | null {
  if (!userClubIds.length || !leaderboard.length) return null;

  const userClubSet = new Set(userClubIds);
  const entry = leaderboard.find((e) => userClubSet.has(e.clubId));
  if (!entry) return null;

  const leaderKm = leaderboard[0].totalKm;
  const gapToLeader = entry.position === 1
    ? leaderKm - (leaderboard[1]?.totalKm ?? 0)
    : entry.totalKm - leaderKm;

  return {
    clubId: entry.clubId,
    clubName: entry.clubName,
    totalKm: entry.totalKm,
    position: entry.position,
    gapToLeader,
  };
}

/**
 * Materializes a light territory DTO for map rendering.
 * Excludes heavy fields (leaderboard, myClubProgress) to keep map payload small.
 */
function materializeLight(config: StaticTerritoryConfig): TerritoryViewDto {
  const now = new Date();
  const { coordinates, geometry: manualGeometry } = config;

  const geometry = manualGeometry || generateSquareGeometry(
    coordinates.latitude,
    coordinates.longitude,
    TERRITORY_SQUARE_SIZE_M,
  );

  const activity = DISTRICT_MOCK_ACTIVITY[config.id];
  const tier: ZoneTier = activity
    ? computeTier(activity.totalKm, activity.avgPace)
    : 'green';
  const tierCfg = TIER_CONFIG[tier];

  return {
    ...config,
    geometry,
    color: tierCfg.color,
    tier,
    paceThreshold: tierCfg.paceThreshold,
    pointMultiplier: tierCfg.pointMultiplier,
    zoneBounty: ZONE_BOUNTY,
    createdAt: now,
    updatedAt: now,
  };
}

/**
 * Materializes the full territory DTO with leaderboard and seasonEndsAt.
 * myClubProgress is set to null; callers should resolve it via resolveMyClubProgress().
 */
function materializeFull(config: StaticTerritoryConfig): TerritoryViewDto {
  const now = new Date();
  const { coordinates, geometry: manualGeometry } = config;

  const geometry = manualGeometry || generateSquareGeometry(
    coordinates.latitude,
    coordinates.longitude,
    TERRITORY_SQUARE_SIZE_M,
  );

  const activity = DISTRICT_MOCK_ACTIVITY[config.id];
  const tier: ZoneTier = activity
    ? computeTier(activity.totalKm, activity.avgPace)
    : 'green';
  const tierCfg = TIER_CONFIG[tier];

  const leaderboard = generateMockLeaderboard(config.id);
  const seasonEndsAt = computeSeasonEndsAt();

  return {
    ...config,
    geometry,
    color: tierCfg.color,
    tier,
    paceThreshold: tierCfg.paceThreshold,
    pointMultiplier: tierCfg.pointMultiplier,
    zoneBounty: ZONE_BOUNTY,
    seasonEndsAt,
    leaderboard,
    myClubProgress: null,
    createdAt: now,
    updatedAt: now,
  };
}

export function getTerritoriesForCity(
  cityId: string,
): TerritoryViewDto[] {
  const source =
    cityId === 'spb'
      ? SPB_TERRITORIES_CONFIG
      : [];

  return source.map(materializeLight);
}

export function getTerritoryById(id: string): TerritoryViewDto | null {
  const config = SPB_TERRITORIES_CONFIG.find((t) => t.id === id);
  return config ? materializeFull(config) : null;
}
