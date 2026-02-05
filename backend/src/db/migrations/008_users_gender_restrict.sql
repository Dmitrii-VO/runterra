-- Migration: 008_users_gender_restrict
-- Description: Restrict gender values to male/female
-- Created: 2026-02-05

UPDATE users
SET gender = NULL
WHERE gender IS NOT NULL AND gender NOT IN ('male', 'female');

ALTER TABLE users
  DROP CONSTRAINT IF EXISTS users_gender_check;

ALTER TABLE users
  ADD CONSTRAINT users_gender_check
  CHECK (gender IS NULL OR gender IN ('male', 'female'));

INSERT INTO migrations (name) VALUES ('008_users_gender_restrict') ON CONFLICT (name) DO NOTHING;
