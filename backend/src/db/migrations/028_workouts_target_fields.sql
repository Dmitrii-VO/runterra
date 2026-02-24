-- Workouts: add target_value and target_zone
ALTER TABLE workouts 
ADD COLUMN IF NOT EXISTS target_value INTEGER,
ADD COLUMN IF NOT EXISTS target_zone VARCHAR(50);