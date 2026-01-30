/**
 * Data Transfer Objects для модуля территорий
 *
 * DTO используются для передачи данных между слоями приложения
 * и валидации входных данных при создании и отображении территорий.
 *
 * На текущей стадии (skeleton) содержат типы и техническую runtime-валидацию
 * входных данных через Zod-схемы без бизнес-логики.
 */

import { z } from 'zod';
import { GeoCoordinatesSchema } from '../../shared/types/coordinates';
import { TerritoryStatus } from './territory.status';
import type { TerritoryCoordinates } from './territory.entity';

/**
 * DTO для создания территории
 * 
 * Используется при добавлении новой территории в систему.
 * 
 * ВАЖНО: Не содержит геометрию границ, только координаты центра.
 */
export interface CreateTerritoryDto {
  /** Название территории */
  name: string;
  
  /** Координаты центра территории на карте */
  coordinates: TerritoryCoordinates;
  
  /** Идентификатор города, к которому относится территория */
  cityId: string;
  
  /** Статус территории (по умолчанию FREE) */
  status?: TerritoryStatus;
}

/**
 * Runtime schema for validating CreateTerritoryDto payloads.
 *
 * NOTE: Only technical shape/type validation, no business rules.
 */
export const CreateTerritorySchema = z.object({
  name: z.string(),
  coordinates: GeoCoordinatesSchema,
  cityId: z.string(),
  status: z.nativeEnum(TerritoryStatus).optional(),
});

/**
 * DTO для отображения территории
 * 
 * Используется для передачи данных территории клиенту.
 * Содержит все необходимые поля для отображения территории на карте
 * и в интерфейсе приложения.
 * 
 * ВАЖНО: Не содержит геометрию границ, только координаты центра.
 */
export interface TerritoryViewDto {
  /** Уникальный идентификатор территории в системе */
  id: string;
  
  /** Название территории */
  name: string;
  
  /** Статус территории */
  status: TerritoryStatus;
  
  /** Координаты центра территории на карте */
  coordinates: TerritoryCoordinates;
  
  /** Идентификатор города, к которому относится территория */
  cityId: string;
  
  /** Идентификатор игрока, захватившего территорию (если захвачена) */
  capturedByUserId?: string;
  
  /** Идентификатор клуба-владельца территории (если захвачена клубом) */
  clubId?: string;
  
  /** Дата создания записи */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;
}
