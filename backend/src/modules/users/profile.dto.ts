/**
 * Data Transfer Object для личного кабинета пользователя
 * 
 * DTO используется для передачи агрегированных данных личного кабинета
 * в одном ответе API, минимизируя количество запросов.
 * 
 * На текущей стадии (skeleton) содержит только структуру данных
 * без бизнес-логики агрегации.
 * 
 * ВАЖНО:
 * - Нет логики агрегации данных
 * - Нет работы с БД
 * - Только контракты для будущей реализации
 */

import { User } from './user.entity';
import { UserStats } from './user-stats.entity';
import { ClubRole } from '../clubs';
import { UserNotification } from '../notifications';
import { ActivityStatus } from '../activities';

/**
 * Упрощенная модель активности для личного кабинета
 */
export interface ProfileActivityDto {
  /** Идентификатор активности */
  id: string;
  
  /** Название тренировки */
  name?: string;
  
  /** Дата и время (ISO string) */
  dateTime?: string;
  
  /** Статус активности */
  status: ActivityStatus;
  
  /** Результат (засчитано / не засчитано) - для последней активности */
  result?: 'counted' | 'not_counted';
  
  /** Краткое сообщение - для последней активности */
  message?: string;
}

/**
 * Информация о клубе пользователя
 */
export interface ProfileClubDto {
  /** Идентификатор клуба */
  id: string;
  
  /** Название клуба */
  name: string;
  
  /** Роль пользователя в клубе */
  role: ClubRole;
}

/**
 * DTO для личного кабинета пользователя
 * 
 * Агрегирует все данные, необходимые для отображения личного кабинета.
 * Контракт: club === null — не в клубе (меркатель или без клуба). См. isMercantile.
 */
export interface ProfileDto {
  /** Данные пользователя */
  user: {
    id: string;
    name: string;
    avatarUrl?: string;
    cityId?: string;
    cityName?: string; // Название города (для удобства)
    /** Идентификатор основного клуба пользователя (из club_members, для фильтра «Мой клуб»). */
    primaryClubId?: string;
    isMercenary: boolean;
    status: User['status'];
  };
  
  /**
   * Информация о клубе (если пользователь состоит в клубе).
   * Явный контракт: club === null — пользователь не в клубе.
   * UI обязан обрабатывать:
   * - club == null && isMercenary === true (меркатель)
   * - club == null && isMercenary === false (без клуба, edge-case)
   */
  club?: ProfileClubDto | null;
  
  /** Мини-статистика пользователя */
  stats: UserStats;
  
  /** Ближайшая активность (тренировка) */
  nextActivity?: ProfileActivityDto;
  
  /** Последняя активность */
  lastActivity?: ProfileActivityDto;
  
  /** Список последних уведомлений */
  notifications: UserNotification[];
}
