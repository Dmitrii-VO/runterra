/**
 * Data Transfer Objects для модуля клубов
 *
 * DTO используются для передачи данных между слоями приложения
 * и валидации входных данных при создании и отображении клубов.
 *
 * На текущей стадии (skeleton) содержат типы и техническую runtime-валидацию
 * входных данных через Zod-схемы без бизнес-логики.
 */

import { z } from 'zod';
import { ClubStatus } from './club.status';

/**
 * DTO для создания клуба
 * 
 * Используется при создании нового клуба в системе.
 */
export interface CreateClubDto {
  /** Название клуба */
  name: string;
  
  /** Описание клуба (опционально) */
  description?: string;
  
  /** Статус клуба (по умолчанию PENDING) */
  status?: ClubStatus;
}

/**
 * Runtime schema for validating CreateClubDto payloads.
 *
 * NOTE: Only technical shape/type validation, no business rules.
 */
export const CreateClubSchema = z.object({
  name: z.string(),
  description: z.string().optional(),
  status: z.nativeEnum(ClubStatus).optional(),
});

/**
 * DTO для отображения клуба
 * 
 * Используется для передачи данных клуба клиенту.
 * Содержит все необходимые поля для отображения клуба
 * в интерфейсе приложения.
 */
export interface ClubViewDto {
  /** Уникальный идентификатор клуба в системе */
  id: string;
  
  /** Название клуба */
  name: string;
  
  /** Описание клуба (опционально) */
  description?: string;
  
  /** Статус клуба */
  status: ClubStatus;
  
  /** Дата создания записи */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;
}
