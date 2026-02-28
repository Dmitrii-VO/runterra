-- Workouts: add blocks (JSONB) and surface
ALTER TABLE workouts 
ADD COLUMN IF NOT EXISTS surface VARCHAR(20),
ADD COLUMN IF NOT EXISTS blocks JSONB;
