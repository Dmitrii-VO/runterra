-- Add price field to events table
-- price: participation cost in rubles (integer >= 0), 0 means free
ALTER TABLE events ADD COLUMN IF NOT EXISTS price INTEGER NOT NULL DEFAULT 0;
