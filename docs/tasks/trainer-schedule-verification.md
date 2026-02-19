# Check-list: Stage 5 - Trainer Interface (Mobile)

Verification of the Trainer Schedule & Plans mobile implementation.

## 1. UI: Club Details Integration
- [x] "Manage Schedule" button is visible for leaders and trainers.
- [x] "Manage Roster" button is visible for leaders and trainers.
- [x] Regular members do NOT see these management buttons.

## 2. Weekly Schedule (Club Template)
- [x] Screen displays a list of 7 days (Monday to Sunday).
- [x] Can add a new item (Note) to a specific day.
- [x] Can delete a template item.
- [ ] Can add/edit Event (integrated with Workouts library).
- [ ] Can edit an existing template item (e.g., change time or description).
- [ ] Saving changes triggers the "Update Future Items" logic (verified via calendar check).
- [x] UI handles empty days gracefully.

## 3. Club Roster
- [x] Screen displays all active members of the club.
- [x] Each member shows their current plan type (Club or Personal).
- [x] Tapping on a member opens their personal plan management screen.

## 4. Personal Plan Management
- [x] Screen displays the current personal template for a runner.
- [x] Can replace the entire template with a new set of items.
- [x] Changes correctly switch the member's `plan_type` to 'personal'.
- [ ] Can view/edit specific personal notes (optional for Stage 5, mandatory for Stage 6).

## 5. API & Data Integrity
- [x] All schedule changes are persisted correctly on the backend.
- [ ] Error messages (e.g., network failure, unauthorized) are displayed to the user.
- [x] Loading states are shown during API calls.
- [ ] Date/time formatting follows the club's timezone context.

## 6. Edge Cases
- [ ] Adding multiple items to the same day in the template works.
- [ ] Deleting the last item of a day works.
- [ ] Switching between days in the Weekly Schedule screen is smooth.
- [ ] Pull-to-refresh works on Schedule and Roster screens.
