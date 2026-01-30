/**
 * Типы уведомлений
 * 
 * Определяет типы уведомлений в системе Runterra.
 * 
 * На текущей стадии (skeleton) содержит только enum без логики отправки.
 */

/**
 * Тип уведомления
 */
export enum NotificationType {
  /** Территория клуба под угрозой */
  TERRITORY_THREAT = 'territory_threat',
  
  /** Новая тренировка от моего клуба */
  NEW_TRAINING = 'new_training',
  
  /** Успешный захват территории */
  TERRITORY_CAPTURED = 'territory_captured',
  
  /** Напоминание о тренировке */
  TRAINING_REMINDER = 'training_reminder',
}
