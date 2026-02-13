-- Club channels: sub-chats within clubs (general, events, training, etc.)

CREATE TABLE IF NOT EXISTS club_channels (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL DEFAULT 'general',
  name VARCHAR(100) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_club_channels_club_id ON club_channels(club_id);

-- Create default 'general' channel for all existing active clubs
INSERT INTO club_channels (club_id, type, name, is_default)
  SELECT c.id, 'general', 'General', true
  FROM clubs c
  WHERE c.status = 'active'
    AND NOT EXISTS (
      SELECT 1
      FROM club_channels cc
      WHERE cc.club_id = c.id
        AND cc.type = 'general'
        AND cc.is_default = true
    );

-- Add optional channel reference to messages (nullable for backward compatibility)
ALTER TABLE messages
  ADD COLUMN IF NOT EXISTS club_channel_id UUID;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'messages_club_channel_id_fkey'
  ) THEN
    ALTER TABLE messages
      ADD CONSTRAINT messages_club_channel_id_fkey
      FOREIGN KEY (club_channel_id) REFERENCES club_channels(id);
  END IF;
END $$;

-- Record this migration
INSERT INTO migrations (name) VALUES ('015_club_channels') ON CONFLICT (name) DO NOTHING;
