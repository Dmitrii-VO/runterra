-- Add personal workout planning support:
-- 5 new workout types, template/favorite flags, scheduling, hill elevation, and sharing table

-- 1. Expand workout type CHECK constraint (keep all 4 existing + add 5 new)
ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_type_check;
ALTER TABLE workouts ADD CONSTRAINT workouts_type_check
  CHECK (type IN (
    'FUNCTIONAL', 'TEMPO', 'RECOVERY', 'ACCELERATIONS',
    'EASY_RUN', 'LONG_RUN', 'INTERVALS', 'PROGRESSION', 'HILL_RUN'
  ));

-- 2. Add new columns to workouts
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS is_template     BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS is_favorite     BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS scheduled_at   TIMESTAMPTZ;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS hill_elevation_m INTEGER;

-- 3. Create workout_shares table (friend-to-friend sharing, separate from trainer assignments)
CREATE TABLE IF NOT EXISTS workout_shares (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workout_id   UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  sender_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shared_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted     BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (workout_id, recipient_id)
);

CREATE INDEX IF NOT EXISTS idx_workout_shares_recipient ON workout_shares(recipient_id);
CREATE INDEX IF NOT EXISTS idx_workout_shares_workout   ON workout_shares(workout_id);
