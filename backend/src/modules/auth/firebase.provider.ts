import { AuthProvider, TokenVerificationResult, AuthUser } from './auth.provider';
import crypto from 'crypto';
import admin from 'firebase-admin';

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

let firebaseAdminApp: admin.app.App | null = null;

/**
 * Lazily initializes and returns Firebase Admin app instance.
 *
 * Uses service-account style credentials from env:
 * - FIREBASE_PROJECT_ID
 * - FIREBASE_CLIENT_EMAIL
 * - FIREBASE_PRIVATE_KEY (\\n-separated, will be normalized)
 *
 * This is intentionally minimal and infrastructure-only; no product logic.
 */
function getFirebaseAdminApp(): admin.app.App {
  if (firebaseAdminApp) {
    return firebaseAdminApp;
  }

  if (admin.apps.length > 0) {
    firebaseAdminApp = admin.app();
    return firebaseAdminApp;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  let privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      'Firebase Admin SDK credentials are not fully configured. ' +
        'Expected FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY environment variables.',
    );
  }

  // Support multi-line private keys encoded with \n in env files
  privateKey = privateKey.replace(/\\n/g, '\n');

  firebaseAdminApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId,
      clientEmail,
      privateKey,
    }),
  });

  return firebaseAdminApp;
}

function mapDecodedTokenToAuthUser(decoded: admin.auth.DecodedIdToken): AuthUser {
  return {
    uid: decoded.uid,
    email: decoded.email ?? undefined,
    emailVerified: decoded.email_verified ?? undefined,
    displayName: decoded.name ?? undefined,
    photoURL: decoded.picture ?? undefined,
  };
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
   * Реализация поверх Firebase Admin SDK с fallback-заглушкой в non-production.
   *
   * В production среде ожидается корректная настройка Firebase Admin SDK
   * через переменные окружения, иначе сервер не стартует.
 */
export class FirebaseAuthProvider implements AuthProvider {
  /**
   * Проверка токена Firebase ID Token
   *
   * В non-production, если Firebase Admin не сконфигурирован, используется
   * безопасная заглушка, которая детерминированно derive-ит uid из токена.
   *
   * @param token - Firebase ID Token из заголовка Authorization
   * @returns Результат проверки
   */
  async verifyToken(token: string): Promise<TokenVerificationResult> {
    if (!token || token.trim() === '') {
      return {
        valid: false,
        error: 'Token is missing or empty',
      };
    }

    try {
      const app = getFirebaseAdminApp();
      const decoded = await app.auth().verifyIdToken(token);
      return {
        valid: true,
        user: mapDecodedTokenToAuthUser(decoded),
      };
    } catch (error) {
      const err = error as { code?: string; message?: string };

      // Для production — любая ошибка верификации считается невалидным токеном
      if (process.env.NODE_ENV === 'production') {
        return {
          valid: false,
          error: 'Firebase ID token verification failed',
          details: {
            code: err.code,
          },
        };
      }

      // В non-production, если нет конфигурации Admin SDK, используем заглушку
      const message = String(err.message || '');
      const misconfig =
        message.includes('FIREBASE_PROJECT_ID') ||
        message.includes('FIREBASE_CLIENT_EMAIL') ||
        message.includes('FIREBASE_PRIVATE_KEY');

      if (misconfig) {
        return {
          valid: true,
          user: deriveAuthUserFromToken(token),
        };
      }

      return {
        valid: false,
        error: 'Firebase ID token verification failed (non-production)',
        details: {
          code: err.code,
        },
      };
    }
  }
}

/**
 * Startup-check для модуля авторизации.
 *
 * В production окружении гарантирует наличие корректной конфигурации
 * Firebase Admin SDK (credentials через env). В non-production только
 * выполняет лёгкую проверку без падения.
 */
export function assertFirebaseAuthConfigured(): void {
  if (process.env.NODE_ENV === 'production') {
    // В production сразу проверяем, что все env для Firebase заданы.
    const projectId = process.env.FIREBASE_PROJECT_ID;
    const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
    const privateKey = process.env.FIREBASE_PRIVATE_KEY;

    if (!projectId || !clientEmail || !privateKey) {
      throw new Error(
        'SECURITY: Firebase Admin SDK is not initialized. ' +
          'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY for production.',
      );
    }

    // Пробуем лениво инициализировать Admin SDK, чтобы поймать ошибки конфигурации на старте.
    getFirebaseAdminApp();
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
