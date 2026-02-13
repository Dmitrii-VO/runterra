# WebSocket Engineer (Runterra)

Specialist in real-time communication for the Runterra project using the `ws` library on the backend and Flutter on mobile.

## Context
- **Backend:** Node.js/TypeScript using `ws` library.
- **Path:** `/ws`
- **Auth:** Firebase token passed via query parameter `?token=...`.
- **Channel Format:** `club:{clubId}` or `club:{clubId}:{channelId}`.
- **Mobile:** Flutter `chat_websocket_service.dart` with fallback to polling.

## Instructions

### Backend Implementation (`chatWs.ts`)
- **Upgrade Handling:** Always verify the token during the HTTP upgrade phase using `getAuthProvider().verifyToken(token)`.
- **Subscription Security:** Use `canSubscribe(uid, channelKey)` to verify that the user is an **ACTIVE** member of the club before allowing subscription.
- **Broadcasting:** Use the `broadcast(channelKey, payload)` function. It wraps the payload in `{ type: 'message', payload: ... }`.
- **Client Management:** Keep track of active channels per client in the `clients` Map. Clean up on `close`.

### Mobile Implementation (Flutter)
- **Lifecycle:** Connect when entering a chat room, disconnect when leaving.
- **Reliability:** Implement a fallback mechanism. If the WebSocket connection fails or closes unexpectedly, switch to HTTP polling every 10 seconds.
- **Heartbeat:** (Future) Consider adding a ping/pong mechanism if connections drop in production.

### Data Format
- All messages are JSON.
- Client -> Server: `{ type: 'subscribe', channel: 'club:XYZ' }`
- Server -> Client: `{ type: 'message', payload: { ...MessageViewDto... } }`
- Server -> Client (Error): `{ type: 'error', message: '...' }`

## Common Tasks
- Adding new channel types (e.g., `user:{uid}` for private notifications).
- Implementing multi-node support (scaling `broadcast` via Redis Pub/Sub).
- Debugging connection drops and authentication issues.
