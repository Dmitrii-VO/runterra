# Changes: Territory Capture & Private Events (2026-02-17)

## Summary
Implemented real GPS-based territory capture scoring and private events functionality across Backend and Mobile.

## Backend Changes

### 1. Data Infrastructure
*   **Transactions:** Refactored `BaseRepository` to support `client` parameter and `transaction()` method.
*   **Migration:** Prepared `021_real_territory_scoring.sql` (to be applied).
*   **Repositories:**
    *   Updated `RunsRepository` to support transactional inserts.
    *   Created `TerritoriesRepository` for recording contributions and fetching scores.
    *   Updated `EventsRepository` to support `visibility` filtering.

### 2. Territory Capture Logic
*   **Geo Utils:** Implemented `isPointInPolygon` (Ray Casting) and `calculateRunContribution`.
*   **Scoring Flow (`POST /api/runs`):**
    *   Added `scoringClubId` to payload.
    *   Validates user membership in the scoring club.
    *   Calculates meters contributed to territories based on GPS track.
    *   Updates `territory_run_contributions` and `territory_club_scores` atomically.
*   **Territories API (`GET /api/territories`):**
    *   Merges static config (geometry) with real scores from DB.
    *   Dynamic status (CAPTURED/FREE) based on scores.

### 3. Private Events
*   **Schema:** Added `visibility` ('public'/'private') to events.
*   **Filtering:** `GET /api/events` and `GET /api/map/data` now filter private events:
    *   Visible only if user is participant or organizer.
    *   Public events visible to everyone.

## Mobile Changes

### 1. Run Tracking
*   **Club Selection:**
    *   Handle `club_required_for_scoring` (400) error.
    *   Show "Select Club" dialog if user has multiple active clubs.
    *   Retry submission with selected `scoringClubId`.

### 2. Create Event
*   **Privacy Toggle:** Added "Private Event" switch in `CreateEventScreen`.
*   **API:** Updated `EventsService` to pass `visibility` parameter.

## Verification
*   **Backend:** `npm run build` passed. `geo.test.ts` passed.
*   **Mobile:** `flutter analyze` passed (no errors, only deprecation warnings). `flutter test` passed.
