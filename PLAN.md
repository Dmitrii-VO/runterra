# Plan: Trainer Groups Implementation

Objective: Add the ability for trainers to create groups within a club and message them.

## Phase 1: Backend Infrastructure
- [x] **Step 1.1: Database Migration.** Create `trainer_groups` and `trainer_group_members` tables.
    - Verification: Run migrations and check DB schema.
- [x] **Step 1.2: Repository & Entity.** Implement `TrainerGroupRepository` for CRUD operations.
    - Verification: Unit tests for group creation.
- [x] **Step 1.3: API Endpoints.** Add routes to `trainer.routes.ts`:
    - `POST /api/trainer/groups` (create)
    - `GET /api/trainer/groups` (list)
    - Verification: Manual API testing via curl/Postman.
- [x] **Step 1.4: Messaging Integration.** Support `trainer_group` as a message channel type.
    - Verification: Ensure messages can be sent to group IDs.

## Phase 2: Mobile Implementation
- [x] **Step 2.1: Localization.** Add strings to `app_en.arb` and `app_ru.arb`.
    - Verification: `flutter gen-l10n`.
- [x] **Step 2.2: Models & API Service.** Create `TrainerGroupModel` and update `TrainerService`.
    - Verification: Code compiles.
- [x] **Step 2.3: Create Group UI.** Implement `CreateTrainerGroupScreen`.
    - Features: Name field, Club member list with selection icons (+ and checkmark).
    - Verification: Manual UI interaction check.
- [x] **Step 2.4: Integration.** Add FAB (+) to `CoachTab` and implement the Groups list.
    - Verification: Groups are visible and navigable after creation.

## Phase 3: Validation
- [ ] **Final Check.** Full end-to-end flow: Create group -> Send message -> Verify receipt.
