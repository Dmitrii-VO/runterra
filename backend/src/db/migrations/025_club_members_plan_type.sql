-- Migration: 025_club_members_plan_type
-- Description: Add plan_type to club_members to distinguish between club and personal plans.
-- Created: 2026-02-20

ALTER TABLE club_members
  ADD COLUMN plan_type VARCHAR(20) NOT NULL DEFAULT 'club'
  CONSTRAINT club_members_plan_type_check CHECK (plan_type IN ('club', 'personal'));

-- Record this migration
INSERT INTO migrations (name) VALUES ('025_club_members_plan_type') ON CONFLICT (name) DO NOTHING;
