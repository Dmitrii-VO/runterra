/**
 * Data Transfer Objects для модуля карты
 * 
 * DTO используются для передачи данных между слоями приложения
 * и валидации данных при работе с картой.
 * 
 * На текущей стадии (skeleton) содержат только типы без валидации,
 * без геометрии, без территорий, без интеграций.
 * TODO: Добавить валидацию через class-validator или zod в будущем.
 */

import { MapViewport } from './map.types';
import { TerritoryViewDto } from '../territories/territory.dto';
import { EventListItemDto } from '../events/event.dto';

/**
 * DTO для ответа API карты
 * 
 * Используется для возврата данных о текущем состоянии карты.
 * Содержит территории и события для отображения на карте.
 */
export interface MapDataDto {
  /** Область видимости карты (viewport) */
  viewport: MapViewport;
  
  /** Список территорий для отображения на карте */
  territories: TerritoryViewDto[];
  
  /** Список событий для отображения на карте */
  events: EventListItemDto[];
  
  /** Метаданные ответа */
  meta?: {
    /** Версия API */
    version?: string;
    /** Временная метка ответа */
    timestamp?: Date;
  };
}
