/**
 * Data Transfer Objects для модуля событий
 *
 * DTO используются для передачи данных между слоями приложения
 * и валидации входных данных при создании и отображении событий.
 *
 * На текущей стадии (skeleton) содержат типы и техническую runtime-валидацию
 * входных данных через Zod-схемы без бизнес-логики.
 */

import { z } from 'zod';
import { GeoCoordinatesSchema } from '../../shared/types/coordinates';
import { EventType } from './event.type';
import { EventStatus } from './event.status';
import type { EventStartLocation } from './event.entity';

/**
 * DTO для создания события
 * 
 * Используется при создании нового события в системе.
 * 
 * ВАЖНО: Не содержит GPS check-in данные, расчёты участников.
 */
export interface CreateEventDto {
  /** Название события */
  name: string;
  
  /** Тип события */
  type: EventType;
  
  /** Дата и время начала события */
  startDateTime: Date;
  
  /** Координаты точки старта */
  startLocation: EventStartLocation;
  
  /** Краткое название локации (парк / район) */
  locationName?: string;
  
  /** Идентификатор организатора (клуб или тренер) */
  organizerId: string;
  
  /** Тип организатора */
  organizerType: 'club' | 'trainer';
  
  /** Уровень подготовки */
  difficultyLevel?: 'beginner' | 'intermediate' | 'advanced';
  
  /** Описание события (опционально) */
  description?: string;
  
  /** Лимит участников (опционально) */
  participantLimit?: number;
  
  /** Идентификатор территории, к которой привязано событие (если есть) */
  territoryId?: string;

  /** Идентификатор города, в котором проходит событие */
  cityId: string;
}

/**
 * Runtime schema for validating CreateEventDto payloads.
 *
 * NOTE: Only technical shape/type validation, no business rules.
 * Dates are coerced from strings to Date instances at runtime.
 */
export const CreateEventSchema = z.object({
  name: z.string(),
  type: z.nativeEnum(EventType),
  startDateTime: z.coerce.date(),
  startLocation: GeoCoordinatesSchema,
  locationName: z.string().optional(),
  organizerId: z.string(),
  organizerType: z.enum(['club', 'trainer']),
  difficultyLevel: z
    .enum(['beginner', 'intermediate', 'advanced'])
    .optional(),
  description: z.string().optional(),
  participantLimit: z.number().int().optional(),
  territoryId: z.string().optional(),
  cityId: z.string(),
});

/**
 * DTO для отображения детальной информации о событии
 * 
 * Используется для передачи полных данных события клиенту
 * при запросе детальной информации (GET /api/events/:id).
 * Содержит все необходимые поля для отображения события
 * в детальном экране приложения.
 * 
 * ВАЖНО: Не содержит GPS check-in данные, расчёты участников.
 */
export interface EventDetailsDto {
  /** Уникальный идентификатор события в системе */
  id: string;
  
  /** Название события */
  name: string;
  
  /** Тип события */
  type: EventType;
  
  /** Статус события */
  status: EventStatus;
  
  /** Дата и время начала события */
  startDateTime: Date;
  
  /** Координаты точки старта */
  startLocation: EventStartLocation;
  
  /** Краткое название локации (парк / район) */
  locationName?: string;
  
  /** Идентификатор организатора (клуб или тренер) */
  organizerId: string;
  
  /** Тип организатора */
  organizerType: 'club' | 'trainer';
  
  /** Уровень подготовки */
  difficultyLevel?: 'beginner' | 'intermediate' | 'advanced';
  
  /** Описание события (опционально) */
  description?: string;
  
  /** 
   * Лимит участников (опционально)
   * 
   * Также называется capacity - максимальное количество участников.
   * Если не указан, событие без ограничений по количеству участников.
   * Используется для определения статуса FULL (participantCount >= participantLimit).
   * 
   * Invariant: status === FULL ⇔ participantLimit != null && participantCount >= participantLimit
   */
  participantLimit?: number;
  
  /** 
   * Количество записавшихся участников
   * 
   * Также называется participantsCount - текущее количество участников.
   * Используется вместе с participantLimit для определения статуса FULL.
   * TODO: Вычислять автоматически при записи/отмене участия.
   * 
   * Invariant: status === FULL ⇔ participantLimit != null && participantCount >= participantLimit
   */
  participantCount: number;
  
  /** Идентификатор территории, к которой привязано событие (если есть) */
  territoryId?: string;
  
  /** Идентификатор города, в котором проходит событие */
  cityId: string;
  
  /** Дата создания записи */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;

  /** Является ли текущий пользователь участником события */
  isParticipant?: boolean;

  /** Статус участия текущего пользователя */
  participantStatus?: 'registered' | 'checked_in' | 'cancelled' | 'no_show';
}

/**
 * DTO для отображения события в списке
 * 
 * Упрощённая версия EventViewDto для списка событий.
 * Содержит только основные поля для карточки события.
 */
export interface EventListItemDto {
  /** Уникальный идентификатор события в системе */
  id: string;
  
  /** Название события */
  name: string;
  
  /** Тип события */
  type: EventType;
  
  /** Статус события */
  status: EventStatus;
  
  /** Дата и время начала события */
  startDateTime: Date;
  
  /** Координаты точки старта (для отображения на карте) */
  startLocation: EventStartLocation;
  
  /** Краткое название локации (парк / район) */
  locationName?: string;
  
  /** Идентификатор организатора (клуб или тренер) */
  organizerId: string;
  
  /** Тип организатора */
  organizerType: 'club' | 'trainer';
  
  /** Уровень подготовки */
  difficultyLevel?: 'beginner' | 'intermediate' | 'advanced';
  
  /** Количество записавшихся участников */
  participantCount: number;
  
  /** Идентификатор территории, к которой привязано событие (если есть) */
  territoryId?: string;

  /** Идентификатор города, в котором проходит событие */
  cityId: string;
}

/**
 * DTO для отображения участника события
 *
 * Используется в списке участников события (GET /api/events/:id/participants).
 */
export interface EventParticipantViewDto {
  /** Уникальный идентификатор записи участника */
  id: string;

  /** ID пользователя */
  userId: string;

  /** Имя пользователя (может отсутствовать, если не найден) */
  name: string | null;

  /** URL аватара (опционально) */
  avatarUrl?: string;

  /** Статус участия */
  status: 'registered' | 'checked_in' | 'cancelled' | 'no_show';

  /** Время check-in (ISO) */
  checkedInAt?: string;
}
