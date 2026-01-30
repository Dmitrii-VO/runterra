/**
 * Auth module — re-exports from modules/auth (single abstraction).
 * Middleware uses getAuthProvider() from modules/auth.
 */

export type { AuthUser, TokenVerificationResult, AuthProvider, FirebaseUser } from './types';
export { authMiddleware } from './authMiddleware';
