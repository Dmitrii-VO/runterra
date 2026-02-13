-- Migration: 016_messages_backfill_club_channel_id
-- Description: Backfill legacy club messages to default club channel; enforce club_channel_id for club messages.
-- Created: 2026-02-13

-- Ensure each club referenced by legacy club messages has a default 'general' channel.
INSERT INTO club_channels (club_id, type, name, is_default)
  SELECT DISTINCT m.channel_id::uuid, 'general', 'General', true
  FROM messages m
  WHERE m.channel_type = 'club'
    AND m.club_channel_id IS NULL
    AND NOT EXISTS (
      SELECT 1
      FROM club_channels cc
      WHERE cc.club_id = m.channel_id::uuid
        AND cc.is_default = true
    );

-- Backfill legacy club messages to the default channel of the corresponding club.
UPDATE messages m
SET club_channel_id = cc.id
FROM club_channels cc
WHERE m.channel_type = 'club'
  AND m.club_channel_id IS NULL
  AND cc.club_id = m.channel_id::uuid
  AND cc.is_default = true;

-- Enforce: club messages must always have club_channel_id (other channel types may keep NULL).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'messages_club_channel_required_chk'
  ) THEN
    ALTER TABLE messages
      ADD CONSTRAINT messages_club_channel_required_chk
      CHECK (channel_type <> 'club' OR club_channel_id IS NOT NULL);
  END IF;
END $$;

-- Index for fast channel message listing (used by /api/messages/clubs/:clubId?channelId=...).
CREATE INDEX IF NOT EXISTS idx_messages_club_channel_created_at
  ON messages (club_channel_id, created_at DESC);

-- Record this migration
INSERT INTO migrations (name) VALUES ('016_messages_backfill_club_channel_id') ON CONFLICT (name) DO NOTHING;

