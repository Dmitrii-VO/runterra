-- Migration: 014_club_role_trainer
-- Description: Rename club role 'moderator' to 'trainer' (Лидер, Тренер, Участник)
-- Created: 2026-02-08

-- Replace moderator with trainer
UPDATE club_members
SET role = 'trainer'
WHERE role = 'moderator';

-- Drop old check constraint
ALTER TABLE club_members
  DROP CONSTRAINT IF EXISTS club_members_role_check;

-- Add new check constraint (member, trainer, leader)
ALTER TABLE club_members
  ADD CONSTRAINT club_members_role_check
  CHECK (role IN ('member', 'trainer', 'leader'));

-- Record this migration
INSERT INTO migrations (name) VALUES ('014_club_role_trainer') ON CONFLICT (name) DO NOTHING;

DO $$
BEGIN
  RAISE NOTICE 'Migration 014_club_role_trainer completed: roles are now member, trainer, leader.';
END $$;
