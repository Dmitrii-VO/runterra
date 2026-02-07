-- Migration: 011_events_end_date_time
-- Description: Add end_date_time field to events table for time-based status transitions
-- Created: 2026-02-08

ALTER TABLE events
ADD COLUMN IF NOT EXISTS end_date_time TIMESTAMP WITH TIME ZONE;

-- For existing events, set end_date_time to start_date_time + 2 hours (default event duration)
UPDATE events
SET end_date_time = start_date_time + INTERVAL '2 hours'
WHERE end_date_time IS NULL;

-- Add index for time-based queries
CREATE INDEX IF NOT EXISTS idx_events_end_date_time ON events(end_date_time);

-- Record this migration
INSERT INTO migrations (name) VALUES ('011_events_end_date_time') ON CONFLICT (name) DO NOTHING;
