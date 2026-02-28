-- Runs: add RPE and notes for trainer feedback
ALTER TABLE runs 
ADD COLUMN IF NOT EXISTS rpe INTEGER,
ADD COLUMN IF NOT EXISTS notes TEXT;
