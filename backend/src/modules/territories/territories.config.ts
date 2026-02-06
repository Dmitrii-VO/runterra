import { TerritoryViewDto } from './territory.dto';
import { TerritoryStatus } from './territory.status';

/**
 * Static territories configuration for Saint Petersburg (spb).
 * 
 * NOTE: This is a technical data source for MVP. There is no DB table
 * for territories yet; when it appears, this config can be replaced with
 * real persistence without changing API contracts.
 */

type StaticTerritoryConfig = Omit<TerritoryViewDto, 'createdAt' | 'updatedAt'>;

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
  return {
    ...config,
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

