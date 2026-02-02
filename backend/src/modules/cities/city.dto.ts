/**
 * Data Transfer Objects для модуля городов
 *
 * DTO используются для передачи данных между слоями приложения
 * и валидации входных данных при создании и обновлении городов.
 *
 * На текущей стадии (skeleton) содержат типы и техническую runtime-валидацию
 * входных данных через Zod-схемы без бизнес-логики.
 */

import { z } from 'zod';
import { GeoCoordinatesSchema } from '../../shared/types/coordinates';
import type { CityBounds, CityCoordinates } from './city.entity';

/**
 * DTO для создания города
 * 
 * Используется при добавлении нового города в систему.
 */
export interface CreateCityDto {
  /** Название города */
  name: string;

  /**
   * Координаты центра города на карте.
   *
   * Используются как стартовая позиция камеры.
   */
  center: CityCoordinates;

  /**
   * Прямоугольные границы города на карте.
   *
   * Используются для ограничения области карты и
   * валидации координат сущностей.
   */
  bounds: CityBounds;
}

/**
 * Runtime schema for validating CreateCityDto payloads.
 *
 * NOTE: Only technical shape/type validation, no business rules.
 */
export const CreateCitySchema = z.object({
  name: z.string(),
  center: GeoCoordinatesSchema,
  bounds: z.object({
    ne: GeoCoordinatesSchema,
    sw: GeoCoordinatesSchema,
  }),
});

/**
 * DTO для обновления города
 * 
 * Используется для частичного обновления данных города.
 * Все поля опциональны - обновляются только переданные поля.
 */
export interface UpdateCityDto {
  /** Название города */
  name?: string;

  /**
   * Координаты центра города на карте.
   */
  center?: CityCoordinates;

  /**
   * Прямоугольные границы города на карте.
   */
  bounds?: CityBounds;
}
