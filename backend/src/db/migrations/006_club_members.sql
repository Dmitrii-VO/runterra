-- Migration: 006_club_members
-- Description: Create club_members table for user-club membership (MVP: one club per user via application logic).
-- Created: 2026-02-04

-- club_id is VARCHAR to support mock clubs; when clubs table exists, can add FK.
CREATE TABLE IF NOT EXISTS club_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id VARCHAR(128) NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT club_members_status_check CHECK (status IN ('pending', 'active', 'inactive', 'suspended')),
    CONSTRAINT club_members_unique UNIQUE (club_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_club_members_club ON club_members(club_id);
CREATE INDEX IF NOT EXISTS idx_club_members_user ON club_members(user_id);

-- Record this migration
INSERT INTO migrations (name) VALUES ('006_club_members') ON CONFLICT (name) DO NOTHING;
