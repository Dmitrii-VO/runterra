/**
 * Data Transfer Objects для модуля активностей
 *
 * DTO используются для передачи данных между слоями приложения
 * и валидации входных данных при создании и отображении активностей.
 *
 * На текущей стадии (skeleton) содержат типы и техническую runtime-валидацию
 * входных данных через Zod-схемы без бизнес-логики.
 */

import { z } from 'zod';
import { ActivityType } from './activity.type';
import { ActivityStatus } from './activity.status';

/**
 * DTO для создания активности
 * 
 * Используется при создании новой активности/тренировки в системе.
 * 
 * ВАЖНО: Не содержит GPS данные, check-in, расчёты.
 */
export interface CreateActivityDto {
  /** Тип активности */
  type: ActivityType;
  
  /** Название активности (опционально) */
  name?: string;
  
  /** Описание активности (опционально) */
  description?: string;
  
  /** Статус активности (по умолчанию PLANNED) */
  status?: ActivityStatus;
}

/**
 * Runtime schema for validating CreateActivityDto payloads.
 * 
 * NOTE: Only technical shape/type validation, no business rules.
 */
export const CreateActivitySchema = z.object({
  type: z.nativeEnum(ActivityType),
  name: z.string().optional(),
  description: z.string().optional(),
  status: z.nativeEnum(ActivityStatus).optional(),
});

/**
 * DTO для отображения активности
 * 
 * Используется для передачи данных активности клиенту.
 * Содержит все необходимые поля для отображения активности
 * в интерфейсе приложения.
 * 
 * ВАЖНО: Не содержит GPS данные, check-in, расчёты.
 */
export interface ActivityViewDto {
  /** Уникальный идентификатор активности в системе */
  id: string;
  
  /** Идентификатор пользователя, создавшего активность */
  userId: string;
  
  /** Тип активности */
  type: ActivityType;
  
  /** Статус активности */
  status: ActivityStatus;
  
  /** Название активности (опционально) */
  name?: string;
  
  /** Описание активности (опционально) */
  description?: string;
  
  /** Дата создания записи */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;
}
