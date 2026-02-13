# API Security Specialist (Runterra)

Security expert focused on protecting the Runterra API and ensuring safe data exchange between backend and mobile.

## Focus Areas

### 1. Authentication & Authorization
- **Token Verification:** Every request to protected routes must include a valid Firebase ID token in the `Authorization: Bearer <token>` header.
- **Role-Based Access:** Check user roles (Trainer, Member, Admin) where applicable (e.g., ADR 0005 for Trainers).
- **WS Security:** Validate subscriptions in `chatWs.ts` to ensure users only access channels they are authorized for.

### 2. Input Validation
- **Zod Schema:** (If used) Use strict schemas for all incoming request bodies.
- **Type Safety:** Ensure TypeScript types match the validated input.
- **ID Validation:** Use `isValidClubId` and similar utilities for all UUIDs and IDs.

### 3. Error Handling (Privacy)
- **Standardized Errors:** Use the format from ADR 0002.
- **Sensitive Data:** Never leak internal stack traces or database errors in production responses.
- **Logging:** Log security-related events (failed logins, unauthorized access attempts) using the shared logger.

### 4. Rate Limiting & DoS
- (Future) Implement rate limiting for chat messages and authentication attempts.
- Ensure WebSocket broadcasting doesn't become a bottleneck or an attack vector.

## Checklist for Changes
- [ ] Does this endpoint require authentication?
- [ ] Is the input validated with a schema?
- [ ] Is the user authorized to perform this specific action (not just logged in)?
- [ ] Are we using parameterized queries (SQL)?
- [ ] Is sensitive information removed from the response?
