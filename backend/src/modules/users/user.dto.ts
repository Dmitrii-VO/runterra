/**
 * Data Transfer Objects для модуля пользователей
 *
 * DTO используются для передачи данных между слоями приложения
 * и валидации входных данных при создании и обновлении пользователей.
 *
 * На текущей стадии (skeleton) содержат типы и техническую runtime-валидацию
 * входных данных через Zod-схемы без бизнес-логики.
 */

import { z } from 'zod';
import { User, UserStatus } from './user.entity';

/**
 * DTO для создания пользователя
 * 
 * Используется при регистрации нового пользователя.
 * Связывает пользователя с Firebase Authentication через firebaseUid.
 */
export interface CreateUserDto {
  /** Уникальный идентификатор пользователя в Firebase Authentication */
  firebaseUid: string;
  
  /** Email пользователя */
  email: string;
  
  /** Имя пользователя */
  name: string;
  
  /** URL фото профиля */
  avatarUrl?: string;
  
  /** Идентификатор города пользователя */
  cityId?: string;
  
  /** Флаг меркателя (true - меркатель, false - участник клуба) */
  isMercenary?: boolean;
  
  /** Статус пользователя (по умолчанию ACTIVE) */
  status?: UserStatus;
}

/**
 * Runtime schema for validating CreateUserDto payloads.
 *
 * NOTE: Only technical shape/type validation, no business rules.
 */
export const CreateUserSchema = z.object({
  firebaseUid: z.string(),
  email: z.string(),
  name: z.string(),
  avatarUrl: z.string().optional(),
  cityId: z.string().optional(),
  isMercenary: z.boolean().optional(),
  status: z.nativeEnum(UserStatus).optional(),
});

/**
 * DTO для отображения пользователя в API-ответах.
 * Не содержит firebaseUid — внутренний идентификатор Firebase не утекает наружу.
 */
export interface UserViewDto {
  id: string;
  email: string;
  name: string;
  avatarUrl?: string;
  cityId?: string;
  isMercenary: boolean;
  status: UserStatus;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Maps User entity to UserViewDto (omits firebaseUid).
 */
export function userToViewDto(user: User): UserViewDto {
  const { firebaseUid: _omit, ...rest } = user;
  return rest as UserViewDto;
}

/**
 * DTO для обновления пользователя
 * 
 * Используется для частичного обновления данных пользователя.
 * Все поля опциональны - обновляются только переданные поля.
 */
export interface UpdateUserDto {
  /** Email пользователя */
  email?: string;
  
  /** Имя пользователя */
  name?: string;
  
  /** URL фото профиля */
  avatarUrl?: string;
  
  /** Идентификатор города пользователя */
  cityId?: string;
  
  /** Флаг меркателя (true - меркатель, false - участник клуба) */
  isMercenary?: boolean;
  
  /** Статус пользователя */
  status?: UserStatus;
}

/**
 * DTO для обновления профиля текущего пользователя (PATCH /me/profile).
 * Все поля опциональны.
 */
export interface UpdateProfileDto {
  /** Идентификатор текущего города пользователя (из /api/cities) */
  currentCityId?: string;
}

/**
 * Runtime schema for PATCH /me/profile body.
 */
export const UpdateProfileSchema = z.object({
  currentCityId: z.string().optional(),
});
