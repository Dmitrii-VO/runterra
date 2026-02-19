-- Migration: 024_schedule_tables
-- Description: Create tables for weekly and personal schedule, personal notes, update events and activities.
-- Created: 2026-02-20

-- 1. Create weekly_schedule_items (Club Templates)
CREATE TABLE IF NOT EXISTS weekly_schedule_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    club_id UUID NOT NULL REFERENCES clubs(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    activity_type VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_weekly_schedule_club ON weekly_schedule_items(club_id);

-- 2. Create personal_schedule_items (Personal Templates)
CREATE TABLE IF NOT EXISTS personal_schedule_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_personal_schedule_user ON personal_schedule_items(user_id);

-- 3. Create personal_notes (Personal Plan Instances / One-offs)
CREATE TABLE IF NOT EXISTS personal_notes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    template_id UUID REFERENCES personal_schedule_items(id) ON DELETE SET NULL,
    date DATE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    workout_id UUID REFERENCES workouts(id) ON DELETE SET NULL,
    trainer_id UUID REFERENCES users(id) ON DELETE SET NULL,
    is_manually_edited BOOLEAN NOT NULL DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_personal_notes_user_date ON personal_notes(user_id, date);
CREATE UNIQUE INDEX IF NOT EXISTS idx_personal_notes_template_date_unique 
    ON personal_notes(template_id, date) 
    WHERE template_id IS NOT NULL AND deleted_at IS NULL;

-- 4. Create activities table (Facts / Recording sessions)
CREATE TABLE IF NOT EXISTS activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'completed',
    name VARCHAR(255),
    description TEXT,
    scheduled_item_id UUID, -- Polymorphic reference (event_id or personal_note_id)
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_activities_user ON activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_scheduled_item ON activities(scheduled_item_id);

-- 5. Update events table
ALTER TABLE events 
    ADD COLUMN IF NOT EXISTS template_id UUID,
    ADD COLUMN IF NOT EXISTS generated_for_date DATE,
    ADD COLUMN IF NOT EXISTS is_manually_edited BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Add Unique Constraint for protection against duplicates in generated events
CREATE UNIQUE INDEX IF NOT EXISTS idx_events_template_date_unique 
    ON events(template_id, generated_for_date) 
    WHERE template_id IS NOT NULL AND deleted_at IS NULL;

-- 6. Link runs to activities
-- Note: runs.activity_id already exists in 001_initial.sql
ALTER TABLE runs
    ADD CONSTRAINT runs_activity_id_fk FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE SET NULL;

-- Record this migration
INSERT INTO migrations (name) VALUES ('024_schedule_tables') ON CONFLICT (name) DO NOTHING;
