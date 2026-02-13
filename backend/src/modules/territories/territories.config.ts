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

/**
 * All territories use clubId: undefined (free) until capture logic is implemented.
 * Legacy club-1/club-2 removed to avoid UUID validation conflicts.
 */
const SPB_TERRITORIES_CONFIG: StaticTerritoryConfig[] = [
  {
    id: 'spb-primorsky-park-pobedy',
    name: 'Приморский парк Победы (Крестовский остров)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9708, longitude: 30.2453 },
    cityId: 'spb',
  },
  {
    id: 'spb-yalagin-island',
    name: 'ЦПКиО им. Кирова (Елагин остров)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9713, longitude: 30.2590 },
    cityId: 'spb',
  },
  {
    id: 'spb-park-300',
    name: 'Парк 300-летия Санкт-Петербурга',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0084, longitude: 30.2133 },
    cityId: 'spb',
  },
  {
    id: 'spb-sosnovka-central',
    name: 'Парк Сосновка (Центральная аллея)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0180, longitude: 30.3500 },
    cityId: 'spb',
  },
  {
    id: 'spb-udely-park',
    name: 'Удельный парк (Верхняя терраса)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0050, longitude: 30.3150 },
    cityId: 'spb',
  },
  {
    id: 'spb-tavrichesky',
    name: 'Таврический сад',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9440, longitude: 30.3720 },
    cityId: 'spb',
  },
  {
    id: 'spb-victory-park-moscow',
    name: 'Московский парк Победы',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.8680, longitude: 30.3280 },
    cityId: 'spb',
  },
  {
    id: 'spb-murinsky',
    name: 'Муринский парк',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0250, longitude: 30.3950 },
    cityId: 'spb',
  },
  {
    id: 'spb-smolny-embankment',
    name: 'Смольнинская набережная',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9480, longitude: 30.3950 },
    cityId: 'spb',
  },
  {
    id: 'spb-petrovsky-island',
    name: 'Петровский парк',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9580, longitude: 30.2750 },
    cityId: 'spb',
  },
  {
    id: 'spb-pulkovo-park',
    name: 'Пулковский парк (Города-Герои)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.8300, longitude: 30.3300 },
    cityId: 'spb',
  },
  {
    id: 'spb-rzhevsky-forest',
    name: 'Ржевский лесопарк',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9600, longitude: 30.4850 },
    cityId: 'spb',
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

