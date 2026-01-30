/**
 * Типы для модуля карты
 * 
 * Описывает контракты для работы с картой в системе Runterra.
 * 
 * На текущей стадии (skeleton) содержит только типы без логики,
 * без геометрии, без территорий, без интеграций с Mapbox/PostGIS.
 */

import type { GeoCoordinates } from '../../shared/types/coordinates';

/** Coordinates on map — alias for shared GeoCoordinates. */
export type MapCoordinates = GeoCoordinates;

/**
 * Интерфейс области видимости карты (viewport)
 * 
 * Описывает текущее состояние отображения карты:
 * центр карты и уровень масштабирования.
 * 
 * Не содержит границ (bounds) и геометрии - только центр и зум.
 */
export interface MapViewport {
  /** Центр карты (координаты) */
  center: MapCoordinates;
  
  /** Уровень масштабирования (zoom level) */
  zoom: number;
}
