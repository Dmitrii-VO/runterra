-- Trainer-client relationships and direct messages

CREATE TABLE trainer_clients (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  trainer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (trainer_id, client_id)
);
CREATE INDEX idx_trainer_clients_trainer ON trainer_clients(trainer_id);
CREATE INDEX idx_trainer_clients_client  ON trainer_clients(client_id);

CREATE TABLE direct_messages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id   UUID NOT NULL REFERENCES users(id),
  receiver_id UUID NOT NULL REFERENCES users(id),
  text        VARCHAR(500) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_direct_messages_pair ON direct_messages(
  LEAST(sender_id::text, receiver_id::text),
  GREATEST(sender_id::text, receiver_id::text),
  created_at DESC
);

INSERT INTO migrations(name) VALUES ('030_trainer_direct') ON CONFLICT DO NOTHING;
