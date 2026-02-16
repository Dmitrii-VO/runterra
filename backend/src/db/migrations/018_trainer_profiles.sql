-- Trainer profiles: bio, specialization, experience, certificates
CREATE TABLE trainer_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id),
  bio TEXT,
  specialization TEXT[] NOT NULL DEFAULT '{}',
  experience_years INTEGER NOT NULL DEFAULT 0,
  certificates JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
