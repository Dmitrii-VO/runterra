-- Add status column to trainer_clients (table exists since migration 030)
-- Existing rows are established relationships, backfilled as 'active'
ALTER TABLE trainer_clients
  ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'active'
    CHECK (status IN ('pending', 'active', 'rejected'));

-- New CTA requests should default to 'pending'
ALTER TABLE trainer_clients
  ALTER COLUMN status SET DEFAULT 'pending';
