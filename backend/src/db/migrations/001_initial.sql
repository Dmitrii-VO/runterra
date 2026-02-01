-- Migration: 001_initial
-- Description: Create initial tables for Runterra
-- Created: 2026-02-01

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- Users table
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    city_id UUID,
    is_mercenary BOOLEAN NOT NULL DEFAULT false,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT users_status_check CHECK (status IN ('active', 'inactive', 'blocked'))
);

CREATE INDEX IF NOT EXISTS idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ============================================
-- Events table
-- ============================================
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft',
    start_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
    start_longitude DOUBLE PRECISION NOT NULL,
    start_latitude DOUBLE PRECISION NOT NULL,
    location_name VARCHAR(255),
    organizer_id VARCHAR(128) NOT NULL,
    organizer_type VARCHAR(20) NOT NULL,
    difficulty_level VARCHAR(20),
    description TEXT,
    participant_limit INTEGER,
    participant_count INTEGER NOT NULL DEFAULT 0,
    territory_id UUID,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT events_type_check CHECK (type IN ('group_run', 'training', 'competition', 'club_event')),
    CONSTRAINT events_status_check CHECK (status IN ('draft', 'open', 'full', 'cancelled', 'completed')),
    CONSTRAINT events_organizer_type_check CHECK (organizer_type IN ('club', 'trainer')),
    CONSTRAINT events_difficulty_check CHECK (difficulty_level IS NULL OR difficulty_level IN ('beginner', 'intermediate', 'advanced'))
);

CREATE INDEX IF NOT EXISTS idx_events_status ON events(status);
CREATE INDEX IF NOT EXISTS idx_events_start_date_time ON events(start_date_time);
CREATE INDEX IF NOT EXISTS idx_events_organizer ON events(organizer_id, organizer_type);

-- ============================================
-- Event participants table (many-to-many)
-- ============================================
CREATE TABLE IF NOT EXISTS event_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'registered',
    checked_in_at TIMESTAMP WITH TIME ZONE,
    check_in_longitude DOUBLE PRECISION,
    check_in_latitude DOUBLE PRECISION,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT event_participants_status_check CHECK (status IN ('registered', 'checked_in', 'cancelled', 'no_show')),
    CONSTRAINT event_participants_unique UNIQUE (event_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_event_participants_event ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_user ON event_participants(user_id);

-- ============================================
-- Runs table
-- ============================================
CREATE TABLE IF NOT EXISTS runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_id UUID,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL, -- seconds
    distance INTEGER NOT NULL, -- meters
    status VARCHAR(20) NOT NULL DEFAULT 'completed',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    
    CONSTRAINT runs_status_check CHECK (status IN ('completed', 'invalid')),
    CONSTRAINT runs_duration_positive CHECK (duration > 0),
    CONSTRAINT runs_distance_positive CHECK (distance >= 0)
);

CREATE INDEX IF NOT EXISTS idx_runs_user ON runs(user_id);
CREATE INDEX IF NOT EXISTS idx_runs_started_at ON runs(started_at);

-- ============================================
-- Run GPS points table
-- ============================================
CREATE TABLE IF NOT EXISTS run_gps_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    run_id UUID NOT NULL REFERENCES runs(id) ON DELETE CASCADE,
    longitude DOUBLE PRECISION NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE,
    point_order INTEGER NOT NULL,
    
    CONSTRAINT run_gps_points_order_positive CHECK (point_order >= 0)
);

CREATE INDEX IF NOT EXISTS idx_run_gps_points_run ON run_gps_points(run_id);

-- ============================================
-- Migrations tracking table
-- ============================================
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Record this migration
INSERT INTO migrations (name) VALUES ('001_initial') ON CONFLICT (name) DO NOTHING;
