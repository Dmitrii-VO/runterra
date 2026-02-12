-- Club channels: sub-chats within clubs (general, events, training, etc.)

CREATE TABLE club_channels (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL DEFAULT 'general',
  name VARCHAR(100) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_club_channels_club_id ON club_channels(club_id);

-- Create default 'general' channel for all existing active clubs
INSERT INTO club_channels (club_id, type, name, is_default)
  SELECT id, 'general', 'General', true FROM clubs WHERE status = 'active';

-- Add optional channel reference to messages (nullable for backward compatibility)
ALTER TABLE messages ADD COLUMN club_channel_id UUID REFERENCES club_channels(id);
