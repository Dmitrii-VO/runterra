-- Migration 038: link runs to workout_assignments
-- Allows tracking which run fulfilled a trainer's assignment

ALTER TABLE runs
ADD COLUMN IF NOT EXISTS assignment_id UUID REFERENCES workout_assignments(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_runs_assignment_id ON runs(assignment_id);

INSERT INTO migrations(name) VALUES ('038_runs_assignment_id') ON CONFLICT (name) DO NOTHING;
