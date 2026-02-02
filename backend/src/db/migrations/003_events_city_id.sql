-- Migration: 003_events_city_id
-- Description: Add city_id column to events for city-based filtering
-- Created: 2026-02-02

ALTER TABLE events
ADD COLUMN IF NOT EXISTS city_id VARCHAR(64) NOT NULL DEFAULT 'spb';

CREATE INDEX IF NOT EXISTS idx_events_city_id ON events(city_id);

-- Record this migration
INSERT INTO migrations (name) VALUES ('003_events_city_id') ON CONFLICT (name) DO NOTHING;

