-- Add optional username field to users table
-- username: unique handle like @nickname, lowercase letters/digits/underscore, 3-30 chars
-- NULLS NOT DISTINCT keeps the UNIQUE constraint but allows multiple NULLs (PostgreSQL 15+)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(30);
CREATE UNIQUE INDEX IF NOT EXISTS users_username_unique
  ON users (username)
  WHERE username IS NOT NULL;
