# 2026-02-13: Messages Channels Optimization

## Goal
Remove temporary "legacy history mixing" for club chat channels and make message storage/querying deterministic and fast.

## Changes
- DB:
  - `backend/src/db/migrations/016_messages_backfill_club_channel_id.sql`
    - Ensures each club has a default channel.
    - Backfills legacy club messages (`messages.club_channel_id IS NULL`) into the default club channel.
    - Adds a DB CHECK constraint: club messages must have `club_channel_id`.
    - Adds index `idx_messages_club_channel_created_at (club_channel_id, created_at DESC)`.
  - `backend/src/db/migrations/015_club_channels.sql`
    - Now records itself into `migrations` table (so it stops re-running on every deploy).
- Backend:
  - `backend/src/api/messages.routes.ts`
    - `channelId` is optional; if missing, API uses the club default channel.
    - Removed "include legacy messages into general channel" logic.
    - Writes always set `club_channel_id` for club messages.
    - WS broadcasts go to `club:{clubId}:{channelId}` and also to `club:{clubId}` for compatibility.
  - `backend/src/db/repositories/messages.repository.ts`
    - Enforces `clubChannelId` presence for club messages.
    - `findByClubChannel` now strictly filters by `club_channel_id`.
- Events:
  - `backend/src/db/repositories/events.repository.ts`
    - If `end_date_time` is NULL, event is treated as ended after a default duration (4 hours).
    - Default listing excludes past open/full events using `COALESCE(end_date_time, start_date_time + interval '4 hours') > NOW()`.

## How To Verify
1. Open a club chat "general" channel, send a message.
2. Switch tabs away from Messages and back.
3. Ensure the message history persists (server-side) and new messages appear after reload.
4. For events with missing `end_date_time`, verify they disappear from "open" once they are clearly in the past.

## Notes
- This is dev-stage safe: even if some legacy rows cannot be backfilled (unexpected bad `channel_id`), they may become unreachable after the backfill/constraint rollout.

