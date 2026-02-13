import { TerritoryViewDto } from './territory.dto';
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

/**
 * Static territories configuration for Saint Petersburg (spb).
 * 
 * NOTE: This is a technical data source for MVP. There is no DB table
 * for territories yet; when it appears, this config can be replaced with
 * real persistence without changing API contracts.
 */

type StaticTerritoryConfig = Omit<TerritoryViewDto, 'createdAt' | 'updatedAt'>;

/** Square size in meters for MVP zone visualization */
const TERRITORY_SQUARE_SIZE_M = 1000;

const SPB_TERRITORIES_CONFIG: StaticTerritoryConfig[] = [
  {
    id: 'spb-primorsky-park-pobedy',
    name: 'Приморский парк Победы (Крестовский остров)',
    status: TerritoryStatus.CAPTURED,
    coordinates: {
      // Approximate center of Primorsky Victory Park running area
      latitude: 59.9708,
      longitude: 30.2453,
    },
    cityId: 'spb',
    clubId: 'club-1',
    capturedByUserId: undefined,
  },
  {
    id: 'spb-yalagin-island',
    name: 'ЦПКиО им. Кирова (Елагин остров)',
    status: TerritoryStatus.FREE,
    coordinates: {
      // Approximate center of Elagin Island park
      latitude: 59.9713,
      longitude: 30.2590,
    },
    cityId: 'spb',
    clubId: undefined,
    capturedByUserId: undefined,
  },
  {
    id: 'spb-park-300',
    name: 'Парк 300-летия Санкт-Петербурга',
    status: TerritoryStatus.CONTESTED,
    coordinates: {
      // Approximate center of 300th Anniversary Park
      latitude: 60.0084,
      longitude: 30.2133,
    },
    cityId: 'spb',
    clubId: 'club-2',
    capturedByUserId: undefined,
  },
];

function materialize(config: StaticTerritoryConfig): TerritoryViewDto {
  const now = new Date();
  const { coordinates } = config;
  const geometry = generateSquareGeometry(
    coordinates.latitude,
    coordinates.longitude,
    TERRITORY_SQUARE_SIZE_M,
  );
  return {
    ...config,
    geometry,
    createdAt: now,
    updatedAt: now,
  };
}

export function getTerritoriesForCity(
  cityId: string,
  clubId?: string,
): TerritoryViewDto[] {
  const source =
    cityId === 'spb'
      ? SPB_TERRITORIES_CONFIG
      : [];

  const filtered = clubId
    ? source.filter((t) => t.clubId === clubId)
    : source;

  return filtered.map(materialize);
}

export function getTerritoryById(id: string): TerritoryViewDto | null {
  const config = SPB_TERRITORIES_CONFIG.find((t) => t.id === id);
  return config ? materialize(config) : null;
}

