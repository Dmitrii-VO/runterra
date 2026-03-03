-- Change events.workout_id FK from NO ACTION to SET NULL
-- so that deleting a workout nullifies the reference in past events
-- instead of blocking the delete with a FK violation.

ALTER TABLE events DROP CONSTRAINT IF EXISTS events_workout_id_fkey;

ALTER TABLE events
  ADD CONSTRAINT events_workout_id_fkey
  FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE SET NULL;
