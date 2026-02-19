-- Migration: 023_cleanup_memberships
-- Description: Ensure "One Club" rule by deactivating all but the oldest active membership for each user.
-- Created: 2026-02-20

UPDATE club_members
SET status = 'inactive', updated_at = NOW()
WHERE id IN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at ASC) as rn
    FROM club_members
    WHERE status = 'active'
  ) t
  WHERE rn > 1
);

-- Record this migration
INSERT INTO migrations (name) VALUES ('023_cleanup_memberships') ON CONFLICT (name) DO NOTHING;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Migration 023_cleanup_memberships completed successfully.';
  RAISE NOTICE 'Users with multiple active memberships have been cleaned up (kept only the oldest one).';
END $$;
