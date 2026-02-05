-- Migration: 007_users_profile_fields
-- Description: Add extended profile fields for users
-- Created: 2026-02-05

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS first_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS last_name VARCHAR(100),
  ADD COLUMN IF NOT EXISTS birth_date DATE,
  ADD COLUMN IF NOT EXISTS country VARCHAR(100),
  ADD COLUMN IF NOT EXISTS gender VARCHAR(20);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_name = 'users_gender_check'
      AND table_name = 'users'
  ) THEN
    ALTER TABLE users
      ADD CONSTRAINT users_gender_check
      CHECK (gender IS NULL OR gender IN ('male', 'female', 'other', 'unknown'));
  END IF;
END $$;

UPDATE users
SET first_name = name
WHERE first_name IS NULL;

INSERT INTO migrations (name) VALUES ('007_users_profile_fields') ON CONFLICT (name) DO NOTHING;
