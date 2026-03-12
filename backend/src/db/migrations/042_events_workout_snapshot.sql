-- Add workout_snapshot JSONB column to events table.
-- Stores a snapshot of the linked workout at the time of event creation,
-- so event details remain accurate even if the workout template is later edited or deleted.
ALTER TABLE events
  ADD COLUMN IF NOT EXISTS workout_snapshot JSONB;
