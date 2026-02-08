-- Migration: 013_club_members_role
-- Description: Add role column to club_members table
-- Created: 2026-02-08
-- Reason: Implement club roles (leader, moderator, member) as per product_spec.md §5.3

-- Add role column with default 'member'
ALTER TABLE club_members
  ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'member';

-- Add check constraint for valid roles
ALTER TABLE club_members
  ADD CONSTRAINT club_members_role_check
  CHECK (role IN ('member', 'moderator', 'leader'));

-- Update existing club creators to be leaders
-- (based on clubs.creator_id matching club_members.user_id)
UPDATE club_members cm
SET role = 'leader'
FROM clubs c
WHERE cm.club_id = c.id
  AND cm.user_id = c.creator_id
  AND cm.role = 'member';

-- Add index for role queries
CREATE INDEX IF NOT EXISTS idx_club_members_role ON club_members(role);

-- Record this migration
INSERT INTO migrations (name) VALUES ('013_club_members_role') ON CONFLICT (name) DO NOTHING;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration 013_club_members_role completed successfully.';
  RAISE NOTICE 'Club creators updated to leader role.';
END $$;
