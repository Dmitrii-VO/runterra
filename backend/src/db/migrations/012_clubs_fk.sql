-- Migration: 012_clubs_fk
-- Description: Add Foreign Key club_members.club_id → clubs.id and convert type to UUID
-- Created: 2026-02-08
-- Priority: P0 (Critical) - Data integrity

-- Step 1: Check for orphaned club_members (memberships in non-existent clubs)
-- If any found, they will be deleted before adding FK
DO $$
DECLARE
  orphaned_count INT;
BEGIN
  SELECT COUNT(*)
  INTO orphaned_count
  FROM club_members cm
  WHERE NOT EXISTS (
    SELECT 1 FROM clubs c WHERE c.id::text = cm.club_id
  );

  IF orphaned_count > 0 THEN
    RAISE NOTICE 'Found % orphaned club_members records. They will be deleted.', orphaned_count;

    DELETE FROM club_members cm
    WHERE NOT EXISTS (
      SELECT 1 FROM clubs c WHERE c.id::text = cm.club_id
    );

    RAISE NOTICE 'Deleted % orphaned records.', orphaned_count;
  ELSE
    RAISE NOTICE 'No orphaned club_members found. Proceeding with migration.';
  END IF;
END $$;

-- Step 2: Convert club_id from VARCHAR to UUID
-- This uses id::text comparison from clubs to handle existing data
ALTER TABLE club_members
  ALTER COLUMN club_id TYPE UUID
  USING (
    SELECT c.id
    FROM clubs c
    WHERE c.id::text = club_members.club_id
  );

-- Step 3: Add Foreign Key constraint
ALTER TABLE club_members
  ADD CONSTRAINT fk_club_members_club
  FOREIGN KEY (club_id)
  REFERENCES clubs(id)
  ON DELETE CASCADE;

-- Step 4: Add index for FK (improves JOIN performance)
CREATE INDEX IF NOT EXISTS idx_club_members_club_fk ON club_members(club_id);

-- Record this migration
INSERT INTO migrations (name) VALUES ('012_clubs_fk') ON CONFLICT (name) DO NOTHING;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration 012_clubs_fk completed successfully.';
  RAISE NOTICE 'club_members.club_id is now UUID with FK to clubs.id.';
END $$;
