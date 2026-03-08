/**
 * WebSocket server for real-time chat.
 * Path: /ws. Auth via Authorization header. Client sends
 * { type: 'subscribe', channel: 'club:clubId' }.
 * Server broadcasts { type: 'message', payload: MessageViewDto } to subscribers of the channel.
 */

import { Server as HttpServer } from 'http';
import { WebSocketServer, WebSocket } from 'ws';
import { parse as parseUrl } from 'url';
import { getAuthProvider } from '../modules/auth';
import {
  getUsersRepository,
  getClubMembersRepository,
  getMessagesRepository,
  getTrainerGroupsRepository,
} from '../db/repositories';
import { logger } from '../shared/logger';
import { isValidClubId } from '../shared/clubId';
import { isValidUuid } from '../shared/validation';

const WS_PATH = '/ws';

interface WsClient {
  channels: Set<string>;
  uid: string;
}

/** Per-connection state: subscribed channels + authenticated uid */
const clients = new Map<WebSocket, WsClient>();

let wss: WebSocketServer | null = null;

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
 *
 * Supported channels:
 * - "club:<clubId>" or "club:<clubId>:<channelId>" — user must be active club member
 * - "direct:<id1>:<id2>" — user must be one of the two IDs and trainer_clients must exist
 */
async function canSubscribe(uid: string, channelKey: string): Promise<boolean> {
  try {
    const usersRepo = getUsersRepository();
    const user = await usersRepo.findByFirebaseUid(uid);
    if (!user) return false;

    if (channelKey.startsWith('club:')) {
      const parts = channelKey.slice('club:'.length).split(':');
      const clubId = parts[0];
      if (!isValidClubId(clubId)) return false;

      const clubMembersRepo = getClubMembersRepository();
      const membership = await clubMembersRepo.findByClubAndUser(clubId, user.id);
      return !!membership && membership.status === 'active';
    }

    if (channelKey.startsWith('direct:')) {
      const parts = channelKey.slice('direct:'.length).split(':');
      if (parts.length !== 2) return false;
      const [id1, id2] = parts;
      if (!isValidUuid(id1) || !isValidUuid(id2)) return false;

      // User must be one of the two participants
      if (user.id !== id1 && user.id !== id2) return false;

      // Trainer-client relationship must exist
      const messagesRepo = getMessagesRepository();
      return messagesRepo.hasTrainerClientRelationship(id1, id2);
    }

    if (channelKey.startsWith('trainer_group:')) {
      const groupId = channelKey.slice('trainer_group:'.length);
      if (!isValidUuid(groupId)) return false;

      const trainerGroupsRepo = getTrainerGroupsRepository();
      const group = await trainerGroupsRepo.findById(groupId);
      if (!group) return false;

      // Access check: must be the trainer or a member of the group
      const isMember = await trainerGroupsRepo.isMember(groupId, user.id);
      const isTrainer = group.trainerId === user.id;
      return isMember || isTrainer;
    }

    return false;
  } catch (error) {
    logger.error('Error checking WS subscribe permission', {
      uid,
      channelKey,
      error,
    });
    return false;
  }
}

/**
 * Attach WebSocket server to HTTP server at path /ws.
 * Validates bearer token from Authorization header on connect; handles subscribe messages.
 */
export function initChatWs(server: HttpServer): void {
  wss = new WebSocketServer({ noServer: true });

  server.on('upgrade', (request, socket, head) => {
    const pathname = parseUrl(request.url || '', true).pathname;
    if (pathname !== WS_PATH) {
      socket.destroy();
      return;
    }

    const authHeader = request.headers.authorization;
    const [scheme, token] =
      typeof authHeader === 'string' ? authHeader.split(' ') : [undefined, undefined];

    if (scheme !== 'Bearer' || !token) {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }

    getAuthProvider()
      .verifyToken(token)
      .then(result => {
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
            .then(allowed => {
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
