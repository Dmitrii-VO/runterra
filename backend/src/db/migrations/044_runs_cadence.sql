-- Migration 044: Add avg_cadence to runs table
-- avg_cadence stores average steps per minute for a run (nullable — older runs and devices without pedometer)
ALTER TABLE runs
ADD COLUMN IF NOT EXISTS avg_cadence INTEGER;
