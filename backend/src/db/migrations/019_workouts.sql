-- Workout templates: simple training plans for trainers
CREATE TABLE IF NOT EXISTS workouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES users(id),
  club_id UUID REFERENCES clubs(id),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  type VARCHAR(20) NOT NULL,
  difficulty VARCHAR(20) NOT NULL,
  target_metric VARCHAR(20) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_workouts_author ON workouts(author_id);
CREATE INDEX IF NOT EXISTS idx_workouts_club ON workouts(club_id) WHERE club_id IS NOT NULL;
