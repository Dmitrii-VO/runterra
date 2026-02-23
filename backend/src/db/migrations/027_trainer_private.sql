-- Migration 027: add accepts_private_clients to trainer_profiles
-- Allows trainers to mark themselves as available for private clients (discovery)

ALTER TABLE trainer_profiles
  ADD COLUMN IF NOT EXISTS accepts_private_clients BOOLEAN NOT NULL DEFAULT false;
