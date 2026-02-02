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
 * Прямоугольные границы города на карте.
 *
 * Используются для:
 * - ограничения области просмотра карты;
 * - проверки попадания координат (событий, территорий и т.п.) в город.
 */
export interface CityBounds {
  /** Северо-восточная точка (max latitude, max longitude) */
  ne: CityCoordinates;
  /** Юго-западная точка (min latitude, min longitude) */
  sw: CityCoordinates;
}

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

  /**
   * Координаты центра города на карте.
   *
   * Используются как стартовая позиция камеры карты.
   */
  center: CityCoordinates;

  /**
   * Прямоугольные границы города на карте.
   *
   * Используются для:
   * - ограничения области просмотра карты;
   * - проверки принадлежности объектов городу.
   */
  bounds: CityBounds;

  /**
   * @deprecated Техническое поле для обратной совместимости c ранним skeleton.
   * Использует те же координаты, что и `center`.
   */
  coordinates: CityCoordinates;
  
  /** Дата создания записи */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;
}
