-- Migration: 002_messages
-- Description: Create messages table for city and club chats
-- Created: 2026-02-02

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    channel_type VARCHAR(20) NOT NULL,
    channel_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text VARCHAR(500) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT messages_channel_type_check CHECK (channel_type IN ('city', 'club'))
);

CREATE INDEX IF NOT EXISTS idx_messages_channel ON messages(channel_type, channel_id, created_at DESC);

-- Record this migration
INSERT INTO migrations (name) VALUES ('002_messages') ON CONFLICT (name) DO NOTHING;
