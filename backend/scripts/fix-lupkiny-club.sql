-- One-off: set club "Лупкины" to active so it appears in GET /api/clubs and profile.
-- Run on server (runterra): psql "$DATABASE_URL" -f scripts/fix-lupkiny-club.sql
-- Or: psql -h localhost -U postgres -d runterra -f scripts/fix-lupkiny-club.sql

-- Show current state
SELECT id, name, status, city_id, created_at FROM clubs WHERE name = 'Лупкины';

-- Update
UPDATE clubs SET status = 'active', updated_at = NOW() WHERE name = 'Лупкины';

-- Verify
SELECT id, name, status FROM clubs WHERE name = 'Лупкины';
