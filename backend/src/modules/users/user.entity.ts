/**
 * Сущность пользователя
 * 
 * Описывает модель пользователя в системе Runterra.
 * Связана с Firebase Authentication через firebaseUid.
 * 
 * На текущей стадии (skeleton) содержит только структуру данных
 * без логики и без работы с БД.
 */

/**
 * Статус пользователя
 */
export enum UserStatus {
  /** Пользователь активен */
  ACTIVE = 'active',
  /** Пользователь неактивен */
  INACTIVE = 'inactive',
  /** Пользователь заблокирован */
  BLOCKED = 'blocked',
}

/**
 * Интерфейс пользователя
 * 
 * Представляет полную модель пользователя в системе.
 * Все поля соответствуют будущей структуре БД.
 */
export interface User {
  /** Уникальный идентификатор пользователя в системе */
  id: string;
  
  /** Уникальный идентификатор пользователя в Firebase Authentication */
  firebaseUid: string;
  
  /** Email пользователя */
  email: string;
  
  /** Имя пользователя */
  name: string;

  /** Имя (раздельно, для профиля) */
  firstName?: string;

  /** Фамилия (раздельно, для профиля) */
  lastName?: string;

  /** Дата рождения (YYYY-MM-DD) */
  birthDate?: string;

  /** Страна */
  country?: string;

  /** Пол */
  gender?: 'male' | 'female';
  
  /** URL фото профиля */
  avatarUrl?: string;
  
  /** Идентификатор города пользователя */
  cityId?: string;
  
  /**
   * Флаг меркателя (true — меркатель, false — не меркатель).
   * Правила (зафиксировать при реализации логики):
   * - Меркатель НЕ имеет ClubMembership. club === null в профиле.
   * - ClubMembership НЕ создаётся при участии в тренировке.
   * - Вклад засчитывается логикой активности, не через membership.
   * - Доступ в профиль не зависит от role === MEMBER.
   */
  isMercenary: boolean;
  
  /** Статус пользователя */
  status: UserStatus;
  
  /** Дата создания пользователя */
  createdAt: Date;
  
  /** Дата последнего обновления */
  updatedAt: Date;
}
