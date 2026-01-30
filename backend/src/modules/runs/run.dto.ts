/**
 * Data Transfer Objects для модуля пробежек
 *
 * DTO используются для передачи данных между слоями приложения
 * и валидации входных данных при создании и отображении пробежек.
 *
 * На текущей стадии (skeleton) содержат типы и техническую runtime-валидацию
 * входных данных через Zod-схемы без бизнес-логики.
 */

import { z } from 'zod';
import { GeoCoordinatesSchema } from '../../shared/types/coordinates';
import { RunStatus } from './run.type';

/**
 * DTO для создания пробежки
 * 
 * Используется при создании новой пробежки в системе.
 */
export interface CreateRunDto {
  /** Идентификатор тренировки, к которой привязана пробежка (опционально) */
  activityId?: string;
  
  /** Время начала пробежки (ISO 8601 строка) */
  startedAt: string;
  
  /** Время окончания пробежки (ISO 8601 строка) */
  endedAt: string;
  
  /** Длительность пробежки в секундах */
  duration: number;
  
  /** Пройденное расстояние в метрах */
  distance: number;
  
  /** GPS точки маршрута (опционально, TODO для будущего) */
  gpsPoints?: Array<{
    latitude: number;
    longitude: number;
    timestamp?: string;
  }>;
}

/**
 * Runtime schema for validating CreateRunDto payloads.
 *
 * NOTE: Only technical shape/type validation, no business rules.
 */
export const GpsPointSchema = GeoCoordinatesSchema.extend({
  timestamp: z.string().optional(),
});

export const CreateRunSchema = z.object({
  activityId: z.string().optional(),
  startedAt: z.string().datetime(),
  endedAt: z.string().datetime(),
  duration: z.number(),
  distance: z.number(),
  gpsPoints: z.array(GpsPointSchema).optional(),
});

/**
 * DTO для отображения пробежки
 * 
 * Используется для передачи данных пробежки клиенту.
 * Содержит все необходимые поля для отображения пробежки
 * в интерфейсе приложения.
 */
export interface RunViewDto {
  /** Уникальный идентификатор пробежки в системе */
  id: string;
  
  /** Идентификатор пользователя, выполнившего пробежку */
  userId: string;
  
  /** Идентификатор тренировки, к которой привязана пробежка (опционально) */
  activityId?: string;
  
  /** Время начала пробежки */
  startedAt: Date;
  
  /** Время окончания пробежки */
  endedAt: Date;
  
  /** Длительность пробежки в секундах */
  duration: number;
  
  /** Пройденное расстояние в метрах */
  distance: number;
  
  /** Статус пробежки */
  status: RunStatus;
  
  /** Дата создания записи */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;
}
