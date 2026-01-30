/**
 * Модуль авторизации администраторов.
 * 
 * Содержит типы, интерфейсы и контракты для работы с авторизацией
 * в административной панели Runterra.
 * 
 * На текущем этапе содержит только определения без реализации.
 * Реализация будет добавлена на следующих этапах разработки.
 */

export { AdminRole, hasRequiredRole } from './admin.roles';
export type { AdminUser, AdminLoginCredentials } from './admin-user.type';
export type { AdminAuthProvider } from './admin-auth.provider';
