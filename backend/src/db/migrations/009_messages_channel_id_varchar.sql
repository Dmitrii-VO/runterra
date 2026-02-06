-- Migration: 009_messages_channel_id_varchar
-- Description: Change messages.channel_id from UUID to VARCHAR(128)
--              to align with string clubId/cityId across DB/API/WS/mobile.
-- Created: 2026-02-06

ALTER TABLE messages
  ALTER COLUMN channel_id TYPE VARCHAR(128) USING channel_id::text;

-- Record this migration
INSERT INTO migrations (name) VALUES ('009_messages_channel_id_varchar') ON CONFLICT (name) DO NOTHING;

