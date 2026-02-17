-- Migration: 021_real_territory_scoring
-- Description: Add tables and columns for real territory scoring and private events
-- Created: 2026-02-17

-- ============================================
-- 1. Runs Table Updates
-- ============================================

-- Add scoring_club_id to link runs to specific clubs for territory capture
ALTER TABLE runs 
ADD COLUMN IF NOT EXISTS scoring_club_id UUID REFERENCES clubs(id);

-- Optional performance index for user run history ordering/filtering.
-- NOTE: Do not enforce uniqueness here; two runs can legitimately share the same start time.
CREATE INDEX IF NOT EXISTS idx_runs_user_started ON runs(user_id, started_at);

-- ============================================
-- 2. Events Table Updates
-- ============================================

-- Add visibility column for private group runs
ALTER TABLE events 
ADD COLUMN IF NOT EXISTS visibility VARCHAR(20) NOT NULL DEFAULT 'public';

-- Add check constraint for visibility values
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'events_visibility_check') THEN
        ALTER TABLE events 
        ADD CONSTRAINT events_visibility_check CHECK (visibility IN ('public', 'private'));
    END IF;
END $$;

-- Add index for filtering by visibility
CREATE INDEX IF NOT EXISTS idx_events_visibility ON events(visibility);

-- ============================================
-- 3. Territory Scoring Tables
-- ============================================

-- Granular contributions: Records how much each run contributed to a territory
CREATE TABLE IF NOT EXISTS territory_run_contributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID NOT NULL REFERENCES runs(id) ON DELETE CASCADE,
    territory_id VARCHAR(128) NOT NULL, -- Matches ID in territories.config.ts
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    meters INTEGER NOT NULL DEFAULT 0,
    season_start TIMESTAMP WITH TIME ZONE NOT NULL, -- First day of the month
    season_end TIMESTAMP WITH TIME ZONE NOT NULL,   -- First day of the next month
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure a run is only counted once per territory
    CONSTRAINT territory_run_contributions_unique UNIQUE(run_id, territory_id)
);

CREATE INDEX IF NOT EXISTS idx_territory_run_contrib_season ON territory_run_contributions(season_start);
CREATE INDEX IF NOT EXISTS idx_territory_run_contrib_club ON territory_run_contributions(club_id);

-- Aggregated Scores: Fast read source for leaderboards
CREATE TABLE IF NOT EXISTS territory_club_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    territory_id VARCHAR(128) NOT NULL,
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    season_start TIMESTAMP WITH TIME ZONE NOT NULL,
    season_end TIMESTAMP WITH TIME ZONE NOT NULL,
    total_meters BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Unique key for UPSERT operations (one score record per club per territory per season)
    CONSTRAINT territory_club_scores_unique UNIQUE(territory_id, club_id, season_start)
);

CREATE INDEX IF NOT EXISTS idx_territory_scores_season ON territory_club_scores(territory_id, season_start);
CREATE INDEX IF NOT EXISTS idx_territory_scores_ranking ON territory_club_scores(territory_id, season_start, total_meters DESC);

-- ============================================
-- 4. Record Migration
-- ============================================
INSERT INTO migrations (name) VALUES ('021_real_territory_scoring') ON CONFLICT (name) DO NOTHING;
