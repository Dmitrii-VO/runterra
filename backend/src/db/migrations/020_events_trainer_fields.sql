-- Add workout and trainer references to events
ALTER TABLE events
  ADD COLUMN IF NOT EXISTS workout_id UUID REFERENCES workouts(id),
  ADD COLUMN IF NOT EXISTS trainer_id UUID REFERENCES users(id);
