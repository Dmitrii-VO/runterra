-- Migration: 026_cleanup_unknown_user_city_ids
-- Description: Normalize and clean legacy users.city_id values that are not present in current city config.
-- Created: 2026-02-20

-- Normalize casing/whitespace.
UPDATE users
SET city_id = LOWER(TRIM(city_id))
WHERE city_id IS NOT NULL;

-- Keep only supported city ids from current config; clear unknown/stale values.
-- Current config includes only: spb
UPDATE users
SET city_id = NULL
WHERE city_id IS NOT NULL
  AND city_id <> 'spb';

-- Record this migration
INSERT INTO migrations (name) VALUES ('026_cleanup_unknown_user_city_ids') ON CONFLICT (name) DO NOTHING;
