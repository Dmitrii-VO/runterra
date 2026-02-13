# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Runterra — platform for local running communities with gamified territory capture. Active MVP development, Android-first. Pilot city: Saint Petersburg.

Core features: events (join/leave/check-in), clubs (join/leave, roles), runs (GPS tracking), chat (club-based, WebSocket), profile, interactive map (Yandex MapKit), multi-city, i18n, Firebase Auth.

## Tech Stack (FIXED — do not change)

- **Mobile:** Flutter (Dart) — Yandex MapKit, GoRouter, Firebase Auth
- **Backend:** Node.js + TypeScript — Express, PostgreSQL (pg), WebSocket (ws), Zod, Firebase Admin SDK
- **Admin:** Next.js 14 (minimal, not actively developed)
- **Auth:** Firebase Authentication (global middleware on backend)
- **Maps:** Yandex MapKit (mobile + admin)
- **CI:** GitHub Actions (`.github/workflows/ci.yml`)

## Repository Structure

Monorepo with three packages: `backend/`, `mobile/`, `admin/`. Root `package.json` has deploy and AI assistant scripts.

## Common Commands

### Backend (`backend/`)
```bash
npm run dev              # Start dev server (ts-node)
npm run build            # TypeScript compile to dist/
npm run test             # Run Jest tests
npm run test:watch       # Jest in watch mode
npm run test:coverage    # Jest with coverage
npm run migrate          # Run DB migrations (dev, ts-node)
npm run migrate:prod     # Run DB migrations (prod, compiled JS)
```

Run a single test file: `cd backend && npx jest path/to/file.test.ts`

### Mobile (`mobile/`)
```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint/analyze
flutter test             # Run all tests
flutter test test/models/some_test.dart  # Single test
flutter build apk --debug               # Build debug APK
flutter run --dart-define=API_BASE_URL=http://host:3000  # Run with custom API URL
```

### Deployment (from repo root)
```bash
npm run deploy           # Deploy backend + mobile
npm run deploy:backend   # Push + SSH + update.sh on Cloud.ru
npm run deploy:mobile    # Build APK + upload to Firebase App Distribution
```

### CI
Runs on push/PR to `main`: backend typecheck + tests + build; mobile analyze + tests + build APK.

## Architecture

### Backend

**Entry:** `server.ts` → `app.ts` (Express + WebSocket).

**Routes:** `src/api/*.routes.ts`, registered in `src/api/index.ts`. Global `authMiddleware` protects all `/api/*` routes — no per-route auth checks needed.

**Auth flow:** `Authorization: Bearer <token>` → Firebase Admin SDK verification → `req.authUser` (contains `userId` from `users` table, resolved via Firebase UID).

**Modules:** `src/modules/<domain>/` — each has `*.entity.ts`, `*.dto.ts`, `*.status.ts`. Business/domain types live here, not in routes.

**Database:** PostgreSQL via `pg` pool (`src/db/client.ts`). Repositories in `src/db/repositories/`. SQL migrations in `src/db/migrations/*.sql` (currently 14), tracked in `migrations` table.

**Validation:** Zod schemas with `validateBody` middleware. Validation errors return HTTP 400: `{ code: "validation_error", message: "...", details: { fields: [{ field, message, code }] } }`.

**Error format (all endpoints):** `{ code: string, message: string, details?: any }`. English only, no Russian error messages. Stable codes for client-side localization.

**Real-time:** WebSocket server in `src/ws/chatWs.ts` for club chat messages.

**Tests:** Jest + ts-jest + supertest. Mocks in `src/db/repositories/__mocks__/`.

### Mobile

**Entry:** `main.dart` → Firebase init, MapKit init, ServiceLocator init, error handlers → `app.dart` (MaterialApp + GoRouter).

**Feature-based structure:** `lib/features/<feature>/` — screens, widgets. `lib/shared/` — API services, models, DI, config, common UI.

**DI:** `ServiceLocator` singleton (`shared/di/service_locator.dart`). Single `ApiClient` instance via `ApiClient.getInstance()`. Access services via `ServiceLocator.eventsService`, etc.

**Navigation:** GoRouter with `ShellRoute` for bottom tabs: Map, Run, Messages, Events, Profile.

**API layer:** `shared/api/*_service.dart` — one service per domain. All use the shared `ApiClient`.

**Localization:** `AppLocalizations.of(context)!` for all UI strings. ARB files: `l10n/app_en.arb` (template), `l10n/app_ru.arb`. New keys must be added to both.

**Models:** `shared/models/*.dart` — data models with `fromJson` factories.

### Infrastructure

- **Server:** Cloud.ru (85.208.85.13), systemd service `runterra-backend.service`, port 3000
- **DB:** PostgreSQL on server (localhost:5432, database `runterra`)
- **Mobile distribution:** Firebase App Distribution

## Mandatory Rules

### Before any task
1. Read relevant `docs/` (product_spec.md, progress.md, changes/, adr/) to avoid duplicating work
2. If logic/behavior is not documented — ask the user first
3. Briefly describe approach before making code changes
4. If task touches >3 files — break into subtasks first

### Code style
- **Comments in code: English**
- **Documentation: Russian**
- Simple, readable, explicit code. No premature abstractions. No "future-proofing."

### After every task (MANDATORY — task is NOT done without this)
1. Update `docs/progress.md`
2. Update/create `docs/changes/*.md` if behavior changed
3. Create ADR in `docs/adr/` if an architectural decision was made

### Mobile-specific
- **Never** call HTTP/API in `FutureBuilder.future` — use `StatefulWidget` and cache `Future` in `initState`
- Use only `ApiClient.getInstance()` via `ServiceLocator` — never create new `ApiClient` instances
- All UI strings via `AppLocalizations.of(context)!` — add new keys to both ARB files
- **Real-time chat:** Use WebSocket (`ChatWebSocketService`) as primary for new messages; polling only as fallback when WebSocket fails. Do not use polling alone for real-time.

### Backend-specific
- Auth via shared middleware only, not per-route
- Error responses: `{ code, message, details? }` — English only, stable codes
- Validation errors: HTTP 400 with `code: "validation_error"` and `details.fields[]`

### Error log checking
1. First read `docs/errors-runbook.md`
2. Don't re-fix already fixed errors
3. After fixing — update runbook and progress

## Key ADRs

- **ADR-0001:** Sentry for backend error logging
- **ADR-0002:** Unified API error format `{ code, message, details? }` with Zod validation
- **ADR-0003:** Local logging + dev remote logs
- **ADR-0004:** Mobile ServiceLocator DI pattern — single ApiClient, no direct instantiation
