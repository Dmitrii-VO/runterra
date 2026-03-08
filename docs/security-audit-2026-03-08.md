# Security Audit 2026-03-08

## Scope

Manual code review of `backend`, selected `mobile` auth/WS client code, and local secret handling.

## Top 5 Findings

### 1. Critical: authentication bypass in non-production

- Severity: Critical
- Area: backend auth
- Files:
  - [backend/src/modules/auth/firebase.provider.ts](/D:/myprojects/Runterra/backend/src/modules/auth/firebase.provider.ts#L149)
  - [backend/src/server.ts](/D:/myprojects/Runterra/backend/src/server.ts#L12)

#### Evidence

`FirebaseAuthProvider.verifyToken()` falls back to:

- `valid: true`
- `user: deriveAuthUserFromToken(token)`

when Firebase Admin credentials are missing and `NODE_ENV !== 'production'`.

Relevant lines:

- [backend/src/modules/auth/firebase.provider.ts](/D:/myprojects/Runterra/backend/src/modules/auth/firebase.provider.ts#L160)
- [backend/src/modules/auth/firebase.provider.ts](/D:/myprojects/Runterra/backend/src/modules/auth/firebase.provider.ts#L177)
- [backend/src/modules/auth/firebase.provider.ts](/D:/myprojects/Runterra/backend/src/modules/auth/firebase.provider.ts#L179)
- [backend/src/modules/auth/firebase.provider.ts](/D:/myprojects/Runterra/backend/src/modules/auth/firebase.provider.ts#L180)

#### Exploit scenario

An attacker sends any arbitrary `Authorization: Bearer <anything>` header, or any arbitrary `?token=` value to `/ws`, against a dev/staging environment that is not running with `NODE_ENV=production` and lacks Firebase Admin credentials. The backend accepts the token and builds an authenticated user context from unverified token contents.

#### Impact

Full compromise of protected API and WebSocket endpoints in affected environments.

#### Remediation

- Remove the fallback that returns `valid: true`.
- Fail closed in every environment when token verification cannot be performed.
- If tests need fake auth, inject a dedicated test auth provider instead of overloading runtime auth logic.
- Add an integration test that confirms arbitrary bearer tokens are rejected in dev/staging.

## 2. Critical: exposed private keys and credentials in workspace

- Severity: Critical
- Area: secrets management
- Files:
  - [.env.local](/D:/myprojects/Runterra/.env.local#L17)
  - [firebase-service-account.json](/D:/myprojects/Runterra/firebase-service-account.json#L5)

#### Evidence

The workspace contains real private key material:

- `RUSTORE_PRIVATE_KEY` in [.env.local](/D:/myprojects/Runterra/.env.local#L17)
- Google service-account `private_key` in [firebase-service-account.json](/D:/myprojects/Runterra/firebase-service-account.json#L5)

#### Exploit scenario

If these files are committed, uploaded to CI, copied to logs, backed up, or accessed on a shared machine, an attacker can authenticate as the corresponding external service account or integration.

#### Impact

Potential compromise of Firebase Admin capabilities and third-party deployment/publishing flows.

#### Remediation

- Rotate all exposed secrets immediately.
- Remove secrets from git history if they were ever committed.
- Move secrets to CI secret storage or a proper secret manager.
- Add repository secret scanning and pre-commit hooks.
- Keep only example files such as `.env.local.example` in version control.

## 3. High: arbitrary user creation for чужой Firebase UID

- Severity: High
- Area: backend identity binding
- Files:
  - [backend/src/api/users.routes.ts](/D:/myprojects/Runterra/backend/src/api/users.routes.ts#L479)
  - [backend/src/api/users.routes.ts](/D:/myprojects/Runterra/backend/src/api/users.routes.ts#L515)
  - [backend/src/api/users.routes.ts](/D:/myprojects/Runterra/backend/src/api/users.routes.ts#L69)

#### Evidence

`POST /api/users` accepts `firebaseUid` from the request body and persists it directly:

- [backend/src/api/users.routes.ts](/D:/myprojects/Runterra/backend/src/api/users.routes.ts#L507)
- [backend/src/api/users.routes.ts](/D:/myprojects/Runterra/backend/src/api/users.routes.ts#L516)

At the same time, the rest of the backend resolves the current user by token UID:

- [backend/src/api/users.routes.ts](/D:/myprojects/Runterra/backend/src/api/users.routes.ts#L69)

#### Exploit scenario

An authenticated attacker creates a backend user row for a victim’s Firebase UID before the victim first uses the app. When the victim later authenticates, the backend resolves the victim to the attacker-created row.

#### Impact

Account pre-claim / profile hijack at the application data layer.

#### Remediation

- Do not accept `firebaseUid` from clients.
- Bind user creation strictly to `req.authUser.uid`.
- Convert `POST /api/users` into a self-only create-or-return endpoint.
- Add tests proving one user cannot create a row for another Firebase UID.

## 4. High: self-service trainer escalation and victim attachment

- Severity: High
- Area: trainer messaging / access control
- Files:
  - [backend/src/api/trainer.routes.ts](/D:/myprojects/Runterra/backend/src/api/trainer.routes.ts#L109)
  - [backend/src/api/trainer.routes.ts](/D:/myprojects/Runterra/backend/src/api/trainer.routes.ts#L167)
  - [backend/src/api/trainer.routes.ts](/D:/myprojects/Runterra/backend/src/api/trainer.routes.ts#L490)
  - [backend/src/api/messages.routes.ts](/D:/myprojects/Runterra/backend/src/api/messages.routes.ts#L396)
  - [backend/src/ws/chatWs.ts](/D:/myprojects/Runterra/backend/src/ws/chatWs.ts#L74)

#### Evidence

Any authenticated user can:

- create a trainer profile: [backend/src/api/trainer.routes.ts](/D:/myprojects/Runterra/backend/src/api/trainer.routes.ts#L109)
- enable `acceptsPrivateClients`: [backend/src/api/trainer.routes.ts](/D:/myprojects/Runterra/backend/src/api/trainer.routes.ts#L132)
- attach any target user as a client without consent: [backend/src/api/trainer.routes.ts](/D:/myprojects/Runterra/backend/src/api/trainer.routes.ts#L188)

That relationship is then trusted for:

- direct chat history access: [backend/src/api/messages.routes.ts](/D:/myprojects/Runterra/backend/src/api/messages.routes.ts#L396)
- direct message sending: [backend/src/api/messages.routes.ts](/D:/myprojects/Runterra/backend/src/api/messages.routes.ts#L434)
- WebSocket direct channel subscription: [backend/src/ws/chatWs.ts](/D:/myprojects/Runterra/backend/src/ws/chatWs.ts#L74)
- client run access: [backend/src/api/trainer.routes.ts](/D:/myprojects/Runterra/backend/src/api/trainer.routes.ts#L490)

#### Exploit scenario

An attacker creates a trainer profile, marks themselves as accepting private clients, attaches a victim by known `userId`, then reads the victim’s completed runs and gains direct chat access.

#### Impact

Unauthorized access to victim activity data and communication channels.

#### Remediation

- Require an explicit server-enforced trainer approval state.
- Require client consent before creating `trainer_clients` relationships.
- Record relationship origin and status (`pending`, `accepted`, `revoked`).
- Gate direct chat and client run access on accepted relationships only.

## 5. High: stale privileged roles after leaving a club

- Severity: High
- Area: club authorization
- Files:
  - [backend/src/api/clubs.routes.ts](/D:/myprojects/Runterra/backend/src/api/clubs.routes.ts)
  - [backend/src/db/repositories/club_members.repository.ts](/D:/myprojects/Runterra/backend/src/db/repositories/club_members.repository.ts#L144)

#### Evidence

When a member leaves, status becomes inactive but role is preserved. Multiple admin endpoints authorize on role without consistently requiring `status === 'active'`.

Confirmed examples from review:

- role/status bypass summary came from `leave` flow plus admin routes in [backend/src/api/clubs.routes.ts](/D:/myprojects/Runterra/backend/src/api/clubs.routes.ts)
- membership status update in [backend/src/db/repositories/club_members.repository.ts](/D:/myprojects/Runterra/backend/src/db/repositories/club_members.repository.ts#L144)

#### Exploit scenario

A former `leader` or `trainer` leaves a club, remains `inactive`, but still passes role-only checks in management endpoints and continues to administer club resources.

#### Impact

Broken access control for club administration after role revocation or membership exit.

#### Remediation

- Centralize authorization checks into one helper that requires both role and active status.
- Reset privileged roles when membership becomes inactive, unless there is a documented reason not to.
- Add regression tests for former leaders/trainers attempting privileged operations.

## Additional Serious Findings

### A. High: private event participant list disclosure

- Files:
  - [backend/src/api/events.routes.ts](/D:/myprojects/Runterra/backend/src/api/events.routes.ts#L309)
  - [backend/src/api/events.routes.ts](/D:/myprojects/Runterra/backend/src/api/events.routes.ts#L374)

`GET /api/events/:id` correctly blocks access to private events for non-participants/non-organizers, but `GET /api/events/:id/participants` only checks that the event exists and then returns the participant list.

Fix:

- Apply the same private-event authorization logic to the participants endpoint.
- Add tests for unauthorized access to private participant lists.

### B. High: IDOR in club schedule item update/delete

- Files:
  - [backend/src/api/clubs.routes.ts](/D:/myprojects/Runterra/backend/src/api/clubs.routes.ts#L1892)
  - [backend/src/api/clubs.routes.ts](/D:/myprojects/Runterra/backend/src/api/clubs.routes.ts#L1961)
  - [backend/src/db/repositories/schedule.repository.ts](/D:/myprojects/Runterra/backend/src/db/repositories/schedule.repository.ts#L144)
  - [backend/src/db/repositories/schedule.repository.ts](/D:/myprojects/Runterra/backend/src/db/repositories/schedule.repository.ts#L152)

Routes authorize against `clubId` from the URL, but the repository mutates records by `itemId` only. A trainer/leader of club A can potentially update or delete a schedule item belonging to club B if they know its `itemId`.

Fix:

- Resolve the schedule item first.
- Verify `item.clubId === req.params.id`.
- Execute update/delete with both `itemId` and `clubId` in the `WHERE` clause.

### C. High: WebSocket bearer token in query string

- Files:
  - [backend/src/ws/chatWs.ts](/D:/myprojects/Runterra/backend/src/ws/chatWs.ts#L115)
  - [mobile/lib/shared/services/chat_websocket_service.dart](/D:/myprojects/Runterra/mobile/lib/shared/services/chat_websocket_service.dart#L57)

The mobile client sends the auth token in the WebSocket URL query string. This increases the chance of token leakage through logs and telemetry.

Fix:

- Move auth to a header during upgrade where possible, or use a short-lived WS session ticket fetched over HTTPS.
- Strip query strings from any reverse-proxy logging immediately if migration takes time.

## Priority Order

1. Remove auth bypass fallback.
2. Rotate and remove exposed secrets.
3. Fix user identity binding in `POST /api/users`.
4. Add consent and approval gates to trainer/client relationships.
5. Fix stale-role authorization and IDOR cases.

## Recommended Next Step

Create remediation tasks with owners and tests for each of the five top findings before shipping any new backend features.
