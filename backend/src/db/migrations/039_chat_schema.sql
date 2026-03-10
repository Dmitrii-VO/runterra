-- Migration: 039_chat_schema
-- Description: Move chat tables (messages, direct_messages) to dedicated 'chat' schema
-- Indexes and FK constraints migrate automatically with the tables.

CREATE SCHEMA IF NOT EXISTS chat;

ALTER TABLE messages SET SCHEMA chat;
ALTER TABLE direct_messages SET SCHEMA chat;

INSERT INTO migrations (name) VALUES ('039_chat_schema') ON CONFLICT (name) DO NOTHING;
