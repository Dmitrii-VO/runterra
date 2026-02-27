-- Add 'open_event' to events type CHECK constraint
--
-- The EventType enum already has OPEN_EVENT = 'open_event', but the DB
-- constraint was never updated. Inserting open_event rows fails with
-- a check_violation (code 23514).

ALTER TABLE events DROP CONSTRAINT events_type_check;

ALTER TABLE events
  ADD CONSTRAINT events_type_check
    CHECK (type IN ('group_run', 'training', 'competition', 'club_event', 'open_event'));
