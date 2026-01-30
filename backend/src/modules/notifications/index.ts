/**
 * Модуль уведомлений
 * 
 * Экспортирует интерфейсы и типы для работы с уведомлениями.
 * На текущей стадии (skeleton) содержит только типы без бизнес-логики,
 * без репозиториев, сервисов и контроллеров.
 * 
 * ВАЖНО:
 * - Нет логики отправки уведомлений
 * - Нет работы с БД
 * - Только контракты (interfaces, enums)
 * 
 * TODO для будущей реализации:
 * - Репозиторий для работы с БД
 * - Сервис с бизнес-логикой отправки уведомлений
 * - Контроллеры для API endpoints
 * - Валидация через class-validator или zod
 * - Миграции БД для таблицы уведомлений
 */

export * from './notification.type';
export { UserNotification } from './notification.entity';
// Export as Notification alias for backward compatibility (avoiding Web API Notification shadowing)
export type { UserNotification as Notification } from './notification.entity';
