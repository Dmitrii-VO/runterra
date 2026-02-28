# Plan: Relocate "Find Trainer" functionality

Objective: Move the "Find Trainer" entry point from Profile Screen to Messages -> Coach Tab for better UX.

## Phase 1: Research
- [x] Identified entry point in `ProfileScreen`.
- [x] Identified implementation in `TrainersListScreen` and `/trainers` route.
- [x] Identified target location in `CoachTab` (Personal sub-tab).

## Phase 2: Execution
- [ ] **Step 1: Remove from Profile.** 
    - Modify `mobile/lib/features/profile/profile_screen.dart`.
    - Remove the `Card` containing `l10n.findTrainers`.
    - Verification: Run app, check Profile tab.

- [ ] **Step 2: Add to CoachTab (Empty State).**
    - Modify `mobile/lib/features/messages/tabs/coach_tab.dart`.
    - Update `_buildPersonalTab` to include an action button in the empty state.
    - Verification: Check Coach -> Personal tab when no trainer is assigned.

- [ ] **Step 3: Add persistent search button.**
    - Add a search icon button to the `CoachTab` UI so users can find new trainers even if they already have one.
    - Verification: Ensure the button is visible and works.

- [ ] **Step 4: Cleanup & Validation.**
    - Run `flutter analyze`.
    - Verification: 0 errors.
