/**
 * Сущность города
 * 
 * Описывает модель города в системе Runterra.
 * Используется для работы с картами через Mapbox.
 * 
 * На текущей стадии (skeleton) содержит только структуру данных
 * без логики и без работы с БД.
 */

import type { GeoCoordinates } from '../../shared/types/coordinates';

/** Coordinates of city on map — alias for shared GeoCoordinates. */
export type CityCoordinates = GeoCoordinates;

/**
 * Интерфейс города
 * 
 * Представляет полную модель города в системе.
 * Все поля соответствуют будущей структуре БД.
 */
export interface City {
  /** Уникальный идентификатор города в системе */
  id: string;
  
  /** Название города */
  name: string;
  
  /** Координаты города на карте */
  coordinates: CityCoordinates;
  
  /** Дата создания записи */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;
}
