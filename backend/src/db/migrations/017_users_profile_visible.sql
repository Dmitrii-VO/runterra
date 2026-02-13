-- Migration: 017_users_profile_visible
-- Description: Add profile_visible column for privacy (hide profile from public search)
-- Created: 2026-02-13

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS profile_visible BOOLEAN NOT NULL DEFAULT true;

COMMENT ON COLUMN users.profile_visible IS 'When false, profile is hidden from public search (product_spec §7)';

INSERT INTO migrations (name) VALUES ('017_users_profile_visible') ON CONFLICT (name) DO NOTHING;
