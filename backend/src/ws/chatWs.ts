/**
 * WebSocket server for real-time chat.
 * Path: /ws. Auth via query token. Client sends { type: 'subscribe', channel: 'club:clubId' }.
 * Server broadcasts { type: 'message', payload: MessageViewDto } to subscribers of the channel.
 */

import { Server as HttpServer } from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import { parse as parseUrl } from 'url';
import { getAuthProvider } from '../modules/auth';
import { logger } from '../shared/logger';

const WS_PATH = '/ws';

interface WsClient {
  channels: Set<string>;
  uid: string;
}

/** Per-connection state: subscribed channels + authenticated uid */
const clients = new Map<WebSocket, WsClient>();

let wss: WebSocketServer | null = null;

const VALID_CHANNEL_RE = /^club:[0-9a-f-]{36}$/;

/**
 * Broadcast payload to all connections subscribed to channelKey.
 * Payload is sent as { type: 'message', payload }.
 */
export function broadcast(channelKey: string, payload: object): void {
  const message = JSON.stringify({ type: 'message', payload });
  let count = 0;
  for (const [ws, client] of clients.entries()) {
    if (ws.readyState === WebSocket.OPEN && client.channels.has(channelKey)) {
      ws.send(message);
      count += 1;
    }
  }
  if (count > 0) {
    logger.debug('Chat WS broadcast', { channelKey, subscriberCount: count });
  }
}

/**
 * Validate that the user is allowed to subscribe to the given channel.
 * club:<clubId> — allowed for now (stub), but format is validated.
 */
async function canSubscribe(_uid: string, channelKey: string): Promise<boolean> {
  return VALID_CHANNEL_RE.test(channelKey);
}

/**
 * Attach WebSocket server to HTTP server at path /ws.
 * Validates token from query (?token=...) on connect; handles subscribe messages.
 */
export function initChatWs(server: HttpServer): void {
  wss = new WebSocketServer({ noServer: true });

  server.on('upgrade', (request, socket, head) => {
    const pathname = parseUrl(request.url || '', true).pathname;
    if (pathname !== WS_PATH) {
      socket.destroy();
      return;
    }

    const query = parseUrl(request.url || '', true).query;
    const token = typeof query.token === 'string' ? query.token : undefined;

    if (!token) {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }

    getAuthProvider()
      .verifyToken(token)
      .then((result) => {
        if (!result.valid || !result.user) {
          socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
          socket.destroy();
          return;
        }
        const uid = result.user.uid;
        wss!.handleUpgrade(request, socket, head, (ws: WebSocket) => {
          wss!.emit('connection', ws, uid);
        });
      })
      .catch(() => {
        socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
        socket.destroy();
      });
  });

  wss.on('connection', (ws: WebSocket, uid: string) => {
    clients.set(ws, { channels: new Set<string>(), uid });

    ws.on('message', (data: Buffer) => {
      try {
        const msg = JSON.parse(data.toString()) as { type?: string; channel?: string };
        if (msg.type === 'subscribe' && typeof msg.channel === 'string') {
          const client = clients.get(ws);
          if (!client) return;
          canSubscribe(client.uid, msg.channel)
            .then((allowed) => {
              if (allowed) {
                client.channels.add(msg.channel!);
              } else {
                ws.send(JSON.stringify({ type: 'error', message: 'Subscribe denied' }));
              }
            })
            .catch(() => {
              ws.send(JSON.stringify({ type: 'error', message: 'Subscribe check failed' }));
            });
        }
      } catch {
        // Ignore invalid JSON
      }
    });

    ws.on('close', () => {
      clients.delete(ws);
    });
  });
}

/**
 * Close the WebSocket server and all active connections.
 */
export function closeChatWs(): void {
  if (!wss) return;
  for (const [ws] of clients.entries()) {
    ws.close(1001, 'Server shutting down');
  }
  clients.clear();
  wss.close();
  wss = null;
}
