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

  /** Идентификатор задания из календаря (event_id или personal_note_id) (опционально) */
  scheduledItemId?: string;
  
  /** Идентификатор клуба, в который идет зачет очков (опционально) */
  scoringClubId?: string;
  
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

  /** RPE (Rating of Perceived Exertion) 1-10 */
  rpe?: number;

  /** Заметки для тренера */
  notes?: string;
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
  activityId: z.string().uuid().optional(),
  scheduledItemId: z.string().uuid().optional(),
  scoringClubId: z.string().uuid().optional(),
  startedAt: z.string().datetime(),
  endedAt: z.string().datetime(),
  duration: z.number(),
  distance: z.number(),
  gpsPoints: z.array(GpsPointSchema).optional(),
  rpe: z.number().int().min(1).max(10).optional(),
  notes: z.string().max(2000).optional(),
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

  /** Идентификатор клуба, в который идет зачет очков (опционально) */
  scoringClubId?: string;

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

  /** RPE 1-10 */
  rpe?: number;

  /** Notes */
  notes?: string;

  /** Дата создания записи */
  createdAt: Date;

  /** Дата последнего обновления */
  updatedAt: Date;
}

/** Compact run item for history list */
export interface RunHistoryItemDto {
  id: string;
  startedAt: Date;
  duration: number;
  distance: number;
  paceSecondsPerKm: number;
}

/** Run details with GPS track */
export interface RunDetailDto extends RunViewDto {
  gpsPoints: Array<{
    latitude: number;
    longitude: number;
    timestamp?: Date;
  }>;
}

/** User running statistics */
export interface UserRunStatsDto {
  totalRuns: number;
  totalDistance: number;
  totalDuration: number;
  averagePace: number;
}
