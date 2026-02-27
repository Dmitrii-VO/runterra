-- Migration: 031_trainer_groups
-- Description: Create trainer_groups and trainer_group_members tables,
--              and add 'trainer_group' to messages channel types.
-- Created: 2026-02-28

CREATE TABLE IF NOT EXISTS trainer_groups (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  club_id     UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
  trainer_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name        VARCHAR(100) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trainer_groups_club_id ON trainer_groups(club_id);
CREATE INDEX IF NOT EXISTS idx_trainer_groups_trainer_id ON trainer_groups(trainer_id);

CREATE TABLE IF NOT EXISTS trainer_group_members (
  group_id    UUID NOT NULL REFERENCES trainer_groups(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_trainer_group_members_user_id ON trainer_group_members(user_id);

-- Update messages channel type check constraint
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_channel_type_check;
ALTER TABLE messages ADD CONSTRAINT messages_channel_type_check CHECK (channel_type IN ('city', 'club', 'trainer_group'));

-- Record this migration
INSERT INTO migrations (name) VALUES ('031_trainer_groups') ON CONFLICT (name) DO NOTHING;
