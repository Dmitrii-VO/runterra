# Software Architecture (Runterra)

Architectural guide for the Runterra project, focusing on Clean Architecture, modularity, and cross-platform consistency.

## Project Structure
- `backend/`: Node.js/TypeScript. Follows a modular approach (`src/modules`) with clear separation of `api`, `db`, `shared`, and `ws`.
- `mobile/`: Flutter. Uses `shared/services`, `modules/`, and a service locator for DI.
- `admin/`: Next.js/React. Shared logic with backend/mobile via API contracts.

## Architecture Principles

### 1. Dependency Management (Flutter)
- **Service Locator:** Follow ADR 0004. Use `GetIt` (or similar) to register and retrieve services.
- **Interfaces:** Define abstract classes for services to allow easy mocking in tests.

### 2. API Design & Errors
- **Standard Format:** Follow ADR 0002. All API errors must use the standardized format (Code, Message, Details).
- **Validation:** Use `Zod` (backend) or similar for strict input validation.

### 3. Data Consistency
- **Geodata:** Use the `isValidClubId` and shared coordinate logic. Follow ADR 0006 for territory polygon visualization.
- **DB Repositories:** Always use repository patterns (`getUsersRepository()`, etc.) instead of direct DB access in controllers.

### 4. Logging & Observability
- **Sentry:** Follow ADR 0001. All critical errors (backend & mobile) must be logged to Sentry.
- **Local Logs:** Use the shared `logger` in `backend/src/shared/logger.ts`.

## Decision Records (ADRs)
Refer to `docs/adr/*.md` for specific architectural decisions:
- `0004`: Service Locator DI on Mobile.
- `0002`: API Error Format.
- `0006`: Territory Polygons.
- `0007`: Territory Capture Rules (Active Club Only).
