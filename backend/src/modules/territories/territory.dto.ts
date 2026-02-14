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
import { GeoCoordinatesSchema, type GeoCoordinates } from '../../shared/types/coordinates';
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
 * DTO for capturing a territory.
 * User must be an ACTIVE member of the club specified by clubId.
 */
export interface CaptureTerritoryDto {
  /** The club ID claiming the territory */
  clubId: string;
}

/**
 * Runtime schema for validating CaptureTerritoryDto payloads.
 */
export const CaptureTerritorySchema = z.object({
  clubId: z.string().uuid(),
});

/**
 * DTO для отображения территории
 * 
 * Используется для передачи данных территории клиенту.
 * Содержит все необходимые поля для отображения территории на карте
 * и в интерфейсе приложения.
 * 
 * geometry — опциональный массив точек полигона границ.
 * Если задан, клиент рисует PolygonMapObject; иначе — CircleMapObject (fallback).
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
  
  /** Опциональная геометрия границ — массив точек полигона (latitude, longitude) */
  geometry?: GeoCoordinates[];
  
  /** Идентификатор города, к которому относится территория */
  cityId: string;
  
  /** Идентификатор игрока, захватившего территорию (если захвачена) */
  capturedByUserId?: string;
  
  /** Идентификатор клуба-владельца территории (если захвачена клубом) */
  clubId?: string;
  
  /** Цвет территории (hex string, e.g. '#FF0000') для отображения границ */
  color?: string;

  /** Дата создания записи */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;
}
