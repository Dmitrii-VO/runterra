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

type StaticTerritoryConfig = Omit<TerritoryViewDto, 'createdAt' | 'updatedAt' | 'geometry'> & {
  geometry?: GeoCoordinates[];
};

/** Square size in meters for MVP zone visualization (fallback) */
const TERRITORY_SQUARE_SIZE_M = 1000;

/**
 * All territories use clubId: undefined (free) until capture logic is implemented.
 */
const SPB_TERRITORIES_CONFIG: StaticTerritoryConfig[] = [
  {
    id: 'spb-primorsky-park-pobedy',
    name: 'Приморский парк Победы (Крестовский остров)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9708, longitude: 30.2453 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9740, longitude: 30.2200 },
      { latitude: 59.9720, longitude: 30.2550 },
      { latitude: 59.9660, longitude: 30.2500 },
      { latitude: 59.9680, longitude: 30.2150 },
    ],
  },
  {
    id: 'spb-yalagin-island',
    name: 'ЦПКиО им. Кирова (Елагин остров)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9713, longitude: 30.2590 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9790, longitude: 30.2350 },
      { latitude: 59.9815, longitude: 30.2550 },
      { latitude: 59.9805, longitude: 30.2750 },
      { latitude: 59.9755, longitude: 30.2850 },
      { latitude: 59.9735, longitude: 30.2800 },
      { latitude: 59.9750, longitude: 30.2600 },
      { latitude: 59.9770, longitude: 30.2400 },
    ],
  },
  {
    id: 'spb-park-300',
    name: 'Парк 300-летия Санкт-Петербурга',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0084, longitude: 30.2133 },
    cityId: 'spb',
    geometry: [
      { latitude: 60.0115, longitude: 30.1950 },
      { latitude: 60.0135, longitude: 30.2150 },
      { latitude: 60.0090, longitude: 30.2300 },
      { latitude: 60.0045, longitude: 30.2200 },
      { latitude: 60.0065, longitude: 30.1980 },
    ],
  },
  {
    id: 'spb-sosnovka-central',
    name: 'Парк Сосновка (Центральная аллея)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0180, longitude: 30.3500 },
    cityId: 'spb',
    geometry: [
      { latitude: 60.0280, longitude: 30.3350 },
      { latitude: 60.0305, longitude: 30.3650 },
      { latitude: 60.0150, longitude: 30.3700 },
      { latitude: 60.0080, longitude: 30.3550 },
      { latitude: 60.0100, longitude: 30.3300 },
    ],
  },
  {
    id: 'spb-udely-park',
    name: 'Удельный парк (Верхняя терраса)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0050, longitude: 30.3150 },
    cityId: 'spb',
    geometry: [
      { latitude: 60.0125, longitude: 30.3050 },
      { latitude: 60.0115, longitude: 30.3250 },
      { latitude: 59.9985, longitude: 30.3300 },
      { latitude: 59.9965, longitude: 30.3150 },
      { latitude: 60.0035, longitude: 30.2950 },
    ],
  },
  {
    id: 'spb-tavrichesky',
    name: 'Таврический сад',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9440, longitude: 30.3720 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9475, longitude: 30.3680 },
      { latitude: 59.9465, longitude: 30.3780 },
      { latitude: 59.9410, longitude: 30.3750 },
      { latitude: 59.9420, longitude: 30.3650 },
    ],
  },
  {
    id: 'spb-victory-park-moscow',
    name: 'Московский парк Победы',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.8680, longitude: 30.3280 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.8745, longitude: 30.3200 },
      { latitude: 59.8735, longitude: 30.3400 },
      { latitude: 59.8625, longitude: 30.3420 },
      { latitude: 59.8615, longitude: 30.3220 },
    ],
  },
  {
    id: 'spb-murinsky',
    name: 'Муринский парк',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0250, longitude: 30.3950 },
    cityId: 'spb',
    geometry: [
      { latitude: 60.0315, longitude: 30.3750 },
      { latitude: 60.0335, longitude: 30.4150 },
      { latitude: 60.0225, longitude: 30.4200 },
      { latitude: 60.0205, longitude: 30.3800 },
    ],
  },
  {
    id: 'spb-smolny-embankment',
    name: 'Смольнинская набережная',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9480, longitude: 30.3950 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9535, longitude: 30.3850 },
      { latitude: 59.9515, longitude: 30.4100 },
      { latitude: 59.9445, longitude: 30.4150 },
      { latitude: 59.9425, longitude: 30.3900 },
    ],
  },
  {
    id: 'spb-petrovsky-island',
    name: 'Петровский парк',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9580, longitude: 30.2750 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9625, longitude: 30.2600 },
      { latitude: 59.9635, longitude: 30.2850 },
      { latitude: 59.9545, longitude: 30.2900 },
      { latitude: 59.9535, longitude: 30.2650 },
    ],
  },
  {
    id: 'spb-pulkovo-park',
    name: 'Пулковский парк (Города-Герои)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.8300, longitude: 30.3300 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.8340, longitude: 30.3220 },
      { latitude: 59.8350, longitude: 30.3380 },
      { latitude: 59.8265, longitude: 30.3400 },
      { latitude: 59.8255, longitude: 30.3240 },
    ],
  },
  {
    id: 'spb-rzhevsky-forest',
    name: 'Ржевский лесопарк',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9600, longitude: 30.5150 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9755, longitude: 30.4650 },
      { latitude: 59.9785, longitude: 30.5100 },
      { latitude: 59.9455, longitude: 30.5150 },
      { latitude: 59.9425, longitude: 30.4700 },
    ],
  },
  {
    id: 'spb-vasilyevsky-spit',
    name: 'Стрелка Васильевского острова',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9441, longitude: 30.3061 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9465, longitude: 30.3000 },
      { latitude: 59.9460, longitude: 30.3100 },
      { latitude: 59.9415, longitude: 30.3100 },
      { latitude: 59.9425, longitude: 30.2980 },
    ],
  },
  {
    id: 'spb-dvortsovaya-emb',
    name: 'Дворцовая набережная и площадь',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9405, longitude: 30.3155 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9430, longitude: 30.3120 },
      { latitude: 59.9450, longitude: 30.3250 },
      { latitude: 59.9380, longitude: 30.3280 },
      { latitude: 59.9360, longitude: 30.3120 },
    ],
  },
  {
    id: 'spb-fontanka-north',
    name: 'Набережная Фонтанки (Летний сад)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9415, longitude: 30.3400 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9460, longitude: 30.3350 },
      { latitude: 59.9445, longitude: 30.3480 },
      { latitude: 59.9380, longitude: 30.3450 },
      { latitude: 59.9395, longitude: 30.3350 },
    ],
  },
  {
    id: 'spb-petrogradka-bolshoy',
    name: 'Большой проспект П.С.',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9590, longitude: 30.3020 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9640, longitude: 30.2950 },
      { latitude: 59.9610, longitude: 30.3150 },
      { latitude: 59.9540, longitude: 30.3100 },
      { latitude: 59.9565, longitude: 30.2900 },
    ],
  },
  {
    id: 'spb-university-emb',
    name: 'Университетская набережная',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9385, longitude: 30.2950 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9415, longitude: 30.2850 },
      { latitude: 59.9405, longitude: 30.3050 },
      { latitude: 59.9355, longitude: 30.3020 },
      { latitude: 59.9365, longitude: 30.2820 },
    ],
  },
  {
    id: 'spb-griboedov-canal-spas',
    name: 'Канал Грибоедова (Спас-на-Крови)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9390, longitude: 30.3300 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9420, longitude: 30.3250 },
      { latitude: 59.9410, longitude: 30.3320 },
      { latitude: 59.9360, longitude: 30.3320 },
      { latitude: 59.9370, longitude: 30.3220 },
    ],
  },
  {
    id: 'spb-ozerki-suzdalsky',
    name: 'Суздальские озёра (Озерки)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0400, longitude: 30.3150 },
    cityId: 'spb',
    geometry: [
      { latitude: 60.0520, longitude: 30.3000 },
      { latitude: 60.0500, longitude: 30.3300 },
      { latitude: 60.0300, longitude: 30.3350 },
      { latitude: 60.0320, longitude: 30.3050 },
    ],
  },
  {
    id: 'spb-yuzhno-primorsky',
    name: 'Южно-Приморский парк (Балтийская жемчужина)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.8500, longitude: 30.1700 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.8580, longitude: 30.1550 },
      { latitude: 59.8560, longitude: 30.1850 },
      { latitude: 59.8420, longitude: 30.1800 },
      { latitude: 59.8440, longitude: 30.1500 },
    ],
  },
  {
    id: 'spb-zanevsky-park',
    name: 'Заневский парк (Малая Охта)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9250, longitude: 30.4050 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9300, longitude: 30.3950 },
      { latitude: 59.9280, longitude: 30.4150 },
      { latitude: 59.9200, longitude: 30.4120 },
      { latitude: 59.9220, longitude: 30.3920 },
    ],
  },
  {
    id: 'spb-esenin-park',
    name: 'Парк Есенина (Невский район)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.9050, longitude: 30.4750 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.9120, longitude: 30.4650 },
      { latitude: 59.9100, longitude: 30.4850 },
      { latitude: 59.8980, longitude: 30.4820 },
      { latitude: 59.9000, longitude: 30.4620 },
    ],
  },
  {
    id: 'spb-primorsky-res-komendant',
    name: 'Комендантский / Долгоозёрная',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0150, longitude: 30.2550 },
    cityId: 'spb',
    geometry: [
      { latitude: 60.0220, longitude: 30.2400 },
      { latitude: 60.0200, longitude: 30.2700 },
      { latitude: 60.0080, longitude: 30.2650 },
      { latitude: 60.0100, longitude: 30.2350 },
    ],
  },
  {
    id: 'spb-park-internatsionalistov',
    name: 'Парк Интернационалистов (Купчино)',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 59.8650, longitude: 30.3950 },
    cityId: 'spb',
    geometry: [
      { latitude: 59.8720, longitude: 30.3850 },
      { latitude: 59.8700, longitude: 30.4050 },
      { latitude: 59.8580, longitude: 30.4020 },
      { latitude: 59.8600, longitude: 30.3820 },
    ],
  },
  {
    id: 'spb-piskarevsky-park',
    name: 'Пискарёвский парк',
    status: TerritoryStatus.FREE,
    coordinates: { latitude: 60.0000, longitude: 30.4200 },
    cityId: 'spb',
    geometry: [
      { latitude: 60.0100, longitude: 30.4050 },
      { latitude: 60.0080, longitude: 30.4350 },
      { latitude: 59.9900, longitude: 30.4320 },
      { latitude: 59.9920, longitude: 30.4020 },
    ],
  },
];

function materialize(config: StaticTerritoryConfig): TerritoryViewDto {
  const now = new Date();
  const { coordinates, geometry: manualGeometry } = config;
  
  const geometry = manualGeometry || generateSquareGeometry(
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

