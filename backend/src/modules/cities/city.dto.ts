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
import type { CityCoordinates } from './city.entity';

/**
 * DTO для создания города
 * 
 * Используется при добавлении нового города в систему.
 */
export interface CreateCityDto {
  /** Название города */
  name: string;
  
  /** Координаты города на карте */
  coordinates: CityCoordinates;
}

/**
 * Runtime schema for validating CreateCityDto payloads.
 *
 * NOTE: Only technical shape/type validation, no business rules.
 */
export const CreateCitySchema = z.object({
  name: z.string(),
  coordinates: GeoCoordinatesSchema,
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
  
  /** Координаты города на карте */
  coordinates?: CityCoordinates;
}
