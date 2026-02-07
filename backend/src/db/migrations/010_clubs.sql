-- Migration: 010_clubs
-- Description: Create clubs table and update club_members FK
-- Created: 2026-02-08

-- ============================================
-- Clubs table
-- ============================================
CREATE TABLE IF NOT EXISTS clubs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    city_id VARCHAR(128) NOT NULL,
    creator_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT clubs_status_check CHECK (status IN ('pending', 'active', 'inactive', 'suspended'))
);

CREATE INDEX IF NOT EXISTS idx_clubs_city ON clubs(city_id);
CREATE INDEX IF NOT EXISTS idx_clubs_creator ON clubs(creator_id);
CREATE INDEX IF NOT EXISTS idx_clubs_status ON clubs(status);

-- Record this migration
INSERT INTO migrations (name) VALUES ('010_clubs') ON CONFLICT (name) DO NOTHING;
