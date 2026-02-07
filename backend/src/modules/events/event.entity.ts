/**
 * Сущность события
 * 
 * Описывает модель события в системе Runterra.
 * Событие представляет собой групповую активность (тренировку, совместный бег, клубное событие).
 * 
 * На текущей стадии (skeleton) содержит только структуру данных
 * без логики, без GPS check-in, без расчётов, без работы с БД.
 * 
 * ВАЖНО:
 * - Нет GPS check-in логики
 * - Нет расчётов участников
 * - Нет валидации
 * - Только контракты и структура данных
 */

import type { GeoCoordinates } from '../../shared/types/coordinates';
import { EventType } from './event.type';
import { EventStatus } from './event.status';

/** Event start point on map — alias for shared GeoCoordinates. */
export type EventStartLocation = GeoCoordinates;

/**
 * Интерфейс события
 * 
 * Представляет полную модель события в системе.
 * Все поля соответствуют будущей структуре БД.
 * 
 * ВАЖНО: Не содержит GPS check-in данные, расчёты участников.
 * Это будет добавлено позже.
 */
export interface Event {
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

  /** Дата и время окончания события (опционально) */
  endDateTime?: Date;

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
}
