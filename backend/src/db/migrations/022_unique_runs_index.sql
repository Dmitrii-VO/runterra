-- Fix: make idx_runs_user_started UNIQUE for idempotent run creation.
-- The original migration 021 created a non-unique index, which means
-- duplicate runs can be inserted. The catch block in runs.routes.ts
-- relies on unique constraint violation to return 409 Conflict.

DROP INDEX IF EXISTS idx_runs_user_started;
CREATE UNIQUE INDEX idx_runs_user_started ON runs(user_id, started_at);
