-- Simplify workout types: replace old 5 types with 4 new ones
-- Keep legacy columns (difficulty, surface, blocks, etc.) — just not exposed in UI

-- 1. Migrate existing data to nearest new type before changing the constraint
UPDATE workouts SET type = 'ACCELERATIONS' WHERE type = 'INTERVAL';
UPDATE workouts SET type = 'TEMPO'         WHERE type = 'FARTLEK';
UPDATE workouts SET type = 'RECOVERY'      WHERE type = 'LONG_RUN';

-- 2. Update CHECK constraint
ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_type_check;
ALTER TABLE workouts ADD CONSTRAINT workouts_type_check
  CHECK (type IN ('FUNCTIONAL', 'TEMPO', 'RECOVERY', 'ACCELERATIONS'));

-- 3. Add new type-specific columns
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS distance_m        INTEGER;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS heart_rate_target INTEGER;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS pace_target       INTEGER;  -- seconds/km
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS rep_count         INTEGER;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS rep_distance_m    INTEGER;
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS exercise_name     VARCHAR(200);
ALTER TABLE workouts ADD COLUMN IF NOT EXISTS exercise_instructions TEXT;
