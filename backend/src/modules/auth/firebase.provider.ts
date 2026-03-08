import { AuthProvider, TokenVerificationResult, AuthUser } from './auth.provider';
import admin from 'firebase-admin';

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

/**
 * Провайдер авторизации через Firebase Authentication
 *
 * Реализация поверх Firebase Admin SDK без каких-либо runtime fallback'ов.
 * Если Firebase Admin не сконфигурирован, сервер должен fail closed.
 */
export class FirebaseAuthProvider implements AuthProvider {
  /**
   * Проверка токена Firebase ID Token
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
      return {
        valid: false,
        error: 'Firebase ID token verification failed',
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
 * Во всех runtime окружениях гарантирует наличие корректной конфигурации
 * Firebase Admin SDK (credentials через env).
 */
export function assertFirebaseAuthConfigured(): void {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
      'SECURITY: Firebase Admin SDK is not initialized. ' +
        'Set FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL and FIREBASE_PRIVATE_KEY.',
    );
  }

  // Пробуем лениво инициализировать Admin SDK, чтобы поймать ошибки конфигурации на старте.
  getFirebaseAdminApp();
}

let authProviderInstance: AuthProvider | null = null;

/** Single auth provider instance for the process (used by auth middleware). */
export function getAuthProvider(): AuthProvider {
  if (!authProviderInstance) {
    authProviderInstance = new FirebaseAuthProvider();
  }
  return authProviderInstance;
}
