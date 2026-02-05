import { AuthProvider, TokenVerificationResult, AuthUser } from './auth.provider';
import crypto from 'crypto';

function decodeJwtPayload(token: string): Record<string, unknown> | null {
  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const payload = parts[1];
  try {
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
    const padded = normalized + '='.repeat((4 - (normalized.length % 4)) % 4);
    const json = Buffer.from(padded, 'base64').toString('utf8');
    return JSON.parse(json) as Record<string, unknown>;
  } catch {
    return null;
  }
}

function getString(payload: Record<string, unknown> | null, key: string): string | undefined {
  if (!payload) return undefined;
  const value = payload[key];
  return typeof value === 'string' && value.trim() !== '' ? value : undefined;
}

function getBoolean(payload: Record<string, unknown> | null, key: string): boolean | undefined {
  if (!payload) return undefined;
  const value = payload[key];
  if (typeof value === 'boolean') return value;
  if (typeof value === 'string') {
    if (value.toLowerCase() === 'true') return true;
    if (value.toLowerCase() === 'false') return false;
  }
  return undefined;
}

function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex').slice(0, 32);
}

function deriveAuthUserFromToken(token: string): AuthUser {
  const payload = decodeJwtPayload(token);
  const uid =
    getString(payload, 'user_id') ||
    getString(payload, 'uid') ||
    getString(payload, 'sub') ||
    `stub-${hashToken(token)}`;
  const email = getString(payload, 'email');
  const displayName =
    getString(payload, 'name') ||
    getString(payload, 'displayName') ||
    getString(payload, 'preferred_username') ||
    email;
  const emailVerified =
    getBoolean(payload, 'email_verified') ??
    getBoolean(payload, 'emailVerified');
  const photoURL = getString(payload, 'picture') || getString(payload, 'photoURL');

  return {
    uid,
    email,
    emailVerified,
    displayName,
    photoURL,
  };
}

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

    return {
      valid: true,
      user: deriveAuthUserFromToken(token),
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
