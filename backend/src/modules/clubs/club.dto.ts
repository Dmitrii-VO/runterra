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
import { ClubRole } from './club-role';

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
  
  /** Идентификатор города, в котором базируется клуб */
  cityId: string;
  
  /** Статус клуба (по умолчанию PENDING) */
  status?: ClubStatus;
}

/**
 * Runtime schema for validating CreateClubDto payloads.
 *
 * NOTE: Only technical shape/type validation, no business rules.
 */
export const CreateClubSchema = z.object({
  name: z.string().min(3).max(50),
  description: z.string().optional(),
  cityId: z.string(),
  status: z.nativeEnum(ClubStatus).optional(),
});

/**
 * DTO для обновления клуба
 *
 * Используется при редактировании существующего клуба.
 * Все поля опциональны - обновляются только переданные.
 */
export interface UpdateClubDto {
  /** Название клуба (3-50 символов) */
  name?: string;

  /** Описание клуба (до 500 символов) */
  description?: string;
}

/**
 * Runtime schema for validating UpdateClubDto payloads.
 *
 * Validates name length (3-50 chars) and description length (max 500 chars).
 */
export const UpdateClubSchema = z.object({
  name: z.string().min(3).max(50).optional(),
  description: z.string().max(500).optional(),
}).strict();

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

  /** Идентификатор города, в котором базируется клуб */
  cityId: string;

  /** Статус клуба */
  status: ClubStatus;

  /** Дата создания записи */
  createdAt: Date;

  /** Дата последнего обновления */
  updatedAt: Date;
}

/**
 * DTO for "my clubs" endpoint.
 *
 * Represents active clubs where current user is a member.
 */
export interface MyClubViewDto {
  /** Club identifier */
  id: string;

  /** Club name */
  name: string;

  /** Club description (optional) */
  description?: string;

  /** City identifier */
  cityId: string;

  /** City display name (optional, from config) */
  cityName?: string;

  /** Club status */
  status: ClubStatus;

  /** Current user role in this club */
  role: ClubRole;

  /** Date when user joined this club */
  joinedAt: Date;
}
