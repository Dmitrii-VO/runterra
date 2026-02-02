import type { CityBounds, CityCoordinates } from './city.entity';
import { findCityById } from './cities.config';

/**
 * Проверяет, лежит ли точка внутри прямоугольных границ города.
 */
export function isPointWithinBounds(
  point: CityCoordinates,
  bounds: CityBounds,
): boolean {
  const { latitude, longitude } = point;
  const { ne, sw } = bounds;

  return (
    latitude >= sw.latitude &&
    latitude <= ne.latitude &&
    longitude >= sw.longitude &&
    longitude <= ne.longitude
  );
}

/**
 * Проверяет, что точка лежит внутри границ указанного города.
 * Возвращает false, если город не найден.
 */
export function isPointWithinCityBounds(
  point: CityCoordinates,
  cityId: string,
): boolean {
  const city = findCityById(cityId);
  if (!city) {
    return false;
  }

  return isPointWithinBounds(point, city.bounds);
}

