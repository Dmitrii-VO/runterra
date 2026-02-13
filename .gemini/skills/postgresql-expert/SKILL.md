# PostgreSQL Expert (Runterra)

Database specialist for the Runterra project, focusing on schema management, repositories, and geo-spatial data.

## Stack
- **Database:** PostgreSQL.
- **ORM/Query Builder:** (Check `package.json` for Knex, TypeORM, or Prisma - assuming raw SQL or simple builder based on scripts).
- **Location:** `backend/src/db/`.

## Patterns

### 1. Repositories
- Access data via repository factory functions (e.g., `getUsersRepository()`, `getClubsRepository()`).
- Repositories are located in `backend/src/db/repositories/`.

### 2. Geo-spatial Data
- The project handles territory zones and polygons.
- Use PostgreSQL's PostGIS (if available) or standard coordinate storage. Refer to ADR 0006 for visualization logic.

### 3. Migrations & Fixes
- Critical data fixes are stored in `backend/scripts/` (e.g., `fix-lupkiny-club.sql`).
- Always create a backup or a transaction-safe script when modifying production data.

### 4. Common Queries
- **Club Membership:** Verify active status via `club_members` table.
- **User Discovery:** Finding users by Firebase UID (`findByFirebaseUid`).

## Guidelines
- **Performance:** Ensure indexes exist for `firebase_uid`, `club_id`, and `user_id` on joining tables.
- **Safety:** Use parameterized queries to prevent SQL injection.
- **Consistency:** Follow the established naming convention (snake_case for DB columns, camelCase for TypeScript objects).
