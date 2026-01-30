/**
 * Auth types — re-export from modules/auth (single abstraction).
 * FirebaseUser kept as alias for backward compatibility (e.g. req.authUser).
 */

import type { AuthUser } from '../modules/auth';

export type { AuthUser, TokenVerificationResult, AuthProvider } from '../modules/auth';

/** @deprecated Use AuthUser. Kept for req.authUser typing. */
export type FirebaseUser = AuthUser;
