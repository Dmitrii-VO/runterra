import { AuthProvider, TokenVerificationResult, AuthUser } from './auth.provider';

/**
 * Провайдер авторизации через Firebase Authentication
 *
 * ЗАГЛУШКА: На текущей стадии не выполняет реальных проверок токенов.
 * TODO: Подключить firebase-admin для проверки ID токенов
 * TODO: Инициализировать Firebase Admin SDK с credentials из env
 * TODO: Реализовать verifyToken с использованием admin.auth().verifyIdToken()
 *
 * SECURITY: STUB — MUST BE REPLACED
 * ВАЖНО: Эта реализация не должна использоваться в production без реальной проверки токенов.
 */
export class FirebaseAuthProvider implements AuthProvider {
  /**
   * Проверка токена Firebase ID Token
   *
   * ЗАГЛУШКА: Всегда возвращает успешный результат с mock-данными.
   *
   * TODO: Реальная реализация:
   * 1. Получить Firebase Admin SDK instance
   * 2. Вызвать admin.auth().verifyIdToken(token)
   * 3. Извлечь данные пользователя из DecodedIdToken
   * 4. Вернуть AuthUser с реальными данными
   * 5. Обработать ошибки (expired, invalid, revoked токены)
   *
   * @param token - Firebase ID Token из заголовка Authorization
   * @returns Результат проверки (всегда успешный в заглушке)
   */
  async verifyToken(token: string): Promise<TokenVerificationResult> {
    // TODO: Реальная проверка токена через firebase-admin
    // const admin = getFirebaseAdmin();
    // const decodedToken = await admin.auth().verifyIdToken(token);
    // return { valid: true, user: mapDecodedTokenToUser(decodedToken) };

    // SECURITY: STUB — MUST BE REPLACED
    // В production это поведение недопустимо — должны использоваться реальные проверки через Firebase Admin SDK.
    if (process.env.NODE_ENV === 'production') {
      throw new Error(
        'SECURITY: FirebaseAuthProvider stub verifyToken() called in production. Replace stub with real Firebase Admin SDK integration before deploying.',
      );
    }

    // ЗАГЛУШКА: возвращаем mock-данные для non-production окружений
    if (!token || token.trim() === '') {
      return {
        valid: false,
        error: 'Token is missing or empty',
      };
    }

    // TODO: Удалить mock-данные после реализации реальной проверки
    const mockUser: AuthUser = {
      uid: 'mock-uid-123',
      email: 'mock@example.com',
      emailVerified: true,
      displayName: 'Mock User',
    };

    return {
      valid: true,
      user: mockUser,
    };
  }
}

/**
 * Startup-check для модуля авторизации.
 *
 * SECURITY: STUB — MUST BE REPLACED
 * В production сервер не должен запускаться, пока Firebase Admin SDK не будет
 * корректно инициализирован и заглушка не будет заменена реальной реализацией.
 */
export function assertFirebaseAuthConfigured(): void {
  if (process.env.NODE_ENV === 'production') {
    throw new Error(
      'SECURITY: Firebase Admin SDK is not initialized. FirebaseAuthProvider stub must be replaced with real firebase-admin integration before running in production.',
    );
  }
}

let authProviderInstance: AuthProvider | null = null;

/** Single auth provider instance for the process (used by auth middleware). */
export function getAuthProvider(): AuthProvider {
  if (!authProviderInstance) {
    authProviderInstance = new FirebaseAuthProvider();
  }
  return authProviderInstance;
}
