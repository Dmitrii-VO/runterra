/**
 * Модуль авторизации
 *
 * Экспортирует интерфейсы, типы и провайдеры для работы с авторизацией.
 * На текущей стадии содержит только заглушки без реального подключения к системам авторизации.
 */

export * from './auth.provider';
export {
  FirebaseAuthProvider,
  assertFirebaseAuthConfigured,
  getAuthProvider,
} from './firebase.provider';
