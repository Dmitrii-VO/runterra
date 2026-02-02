-- Migration: 004_users_city_id_varchar
-- Description: Change users.city_id from UUID to VARCHAR(64) to store city slugs (e.g. spb) from cities config
-- Created: 2026-02-02

ALTER TABLE users
ALTER COLUMN city_id TYPE VARCHAR(64) USING (city_id::text);

-- Record this migration
INSERT INTO migrations (name) VALUES ('004_users_city_id_varchar') ON CONFLICT (name) DO NOTHING;
