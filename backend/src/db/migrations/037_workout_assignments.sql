-- Migration 037: workout_assignments table
-- Allows trainers to assign workout templates directly to private clients

CREATE TABLE workout_assignments (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_id  UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  trainer_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  note        TEXT,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (workout_id, client_id)
);

CREATE INDEX idx_workout_assignments_client  ON workout_assignments(client_id);
CREATE INDEX idx_workout_assignments_trainer ON workout_assignments(trainer_id);

INSERT INTO migrations(name) VALUES ('037_workout_assignments') ON CONFLICT (name) DO NOTHING;
