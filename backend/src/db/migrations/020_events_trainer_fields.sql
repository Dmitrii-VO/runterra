-- Add workout and trainer references to events
ALTER TABLE events
  ADD COLUMN workout_id UUID REFERENCES workouts(id),
  ADD COLUMN trainer_id UUID REFERENCES users(id);
