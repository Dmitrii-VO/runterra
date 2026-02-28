# Plan: Trainer Groups Implementation

Objective: Add the ability for trainers to create groups within a club and message them.

## Phase 1: Backend Infrastructure
- [x] **Step 1.1: Database Migration.** Create `trainer_groups` and `trainer_group_members` tables.
- [x] **Step 1.2: Repository & Entity.** Implement `TrainerGroupRepository` for CRUD operations.
- [x] **Step 1.3: API Endpoints.** Add routes to `trainer.routes.ts`.
- [x] **Step 1.4: Messaging Integration.** Support `trainer_group` as a message channel type.

## Phase 2: Mobile Implementation
- [x] **Step 2.1: Localization.** Add strings to `app_en.arb` and `app_ru.arb`.
- [x] **Step 2.2: Models & API Service.** Create `TrainerGroupModel` and update `TrainerService`.
- [x] **Step 2.3: Create Group UI.** Implement `CreateTrainerGroupScreen`.
- [x] **Step 2.4: Integration.** Add FAB (+) to `CoachTab` and implement the Groups list.

## Phase 3: Validation
- [x] **Final Check.** Full end-to-end flow: Create group -> Send message -> Verify receipt.
- [x] **Bugfixes & Management.** 
    - [x] Creator is automatically added to the group members in DB.
    - [x] Creator is filtered out from the selection list in Mobile UI.
    - [x] Added Group Management (Edit, Delete, Manage Members).
    - [x] Fixed UI refresh after creation/edit.
