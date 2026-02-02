import type { City, CityBounds, CityCoordinates } from './city.entity';

// Санкт‑Петербург — базовый город по умолчанию.
// Координаты и bounds подобраны как разумный прямоугольник вокруг города.

const SPB_CENTER: CityCoordinates = {
  longitude: 30.315868,
  latitude: 59.939095,
};

const SPB_BOUNDS: CityBounds = {
  ne: {
    longitude: 30.6,
    latitude: 60.1,
  },
  sw: {
    longitude: 29.6,
    latitude: 59.7,
  },
};

const now = new Date('2024-01-01T00:00:00.000Z');

export const CITIES: City[] = [
  {
    id: 'spb',
    name: 'Санкт‑Петербург',
    center: SPB_CENTER,
    bounds: SPB_BOUNDS,
    coordinates: SPB_CENTER,
    createdAt: now,
    updatedAt: now,
  },
];

export function getAllCities(): City[] {
  return CITIES;
}

export function findCityById(id: string): City | undefined {
  return CITIES.find((city) => city.id === id);
}

