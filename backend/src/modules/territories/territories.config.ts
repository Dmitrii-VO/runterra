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

import { SPB_DISTRICTS_DATA } from './spb-districts.data';

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

function materialize(config: StaticTerritoryConfig): TerritoryViewDto {
  const now = new Date();
  const { coordinates, geometry: manualGeometry, color } = config;
  
  const geometry = manualGeometry || generateSquareGeometry(
    coordinates.latitude,
    coordinates.longitude,
    TERRITORY_SQUARE_SIZE_M,
  );

  return {
    ...config,
    geometry,
    color,
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

