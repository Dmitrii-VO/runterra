-- Performance indexes for events list query
-- Covers the common filter: city_id + start_date_time + status

CREATE INDEX IF NOT EXISTS idx_events_city_status_start
  ON events(city_id, start_date_time)
  WHERE status NOT IN ('cancelled', 'completed');

CREATE INDEX IF NOT EXISTS idx_event_participants_event_user
  ON event_participants(event_id, user_id, status);
