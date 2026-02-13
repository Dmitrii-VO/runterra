# 2026-02-13: Chat WebSocket — real-time сообщения

## Цель
Заменить polling на WebSocket для real-time доставки сообщений в клубном чате.

## Изменения

### Mobile
- **Новый сервис:** `lib/shared/services/chat_websocket_service.dart`
  - Подключение к backend `/ws` с auth token в query (`?token=...`)
  - Методы: `connectAndSubscribe(channelKey)`, `disconnect()`
  - Stream входящих сообщений (`messageStream`)
  - Формат канала: `club:clubId` или `club:clubId:channelId`
- **ClubMessagesTab:**
  - При открытии чата: попытка подключиться к WebSocket и подписаться на канал
  - При успешном подключении: polling отключён
  - При неудаче WebSocket: fallback на polling (каждые 10 сек)
  - При выходе из чата: отключение WebSocket
  - Входящие сообщения добавляются в список в реальном времени

### Backend
- Без изменений. WebSocket-сервер (`chatWs.ts`) уже поддерживает каналы `club:{clubId}` и `club:{clubId}:{channelId}`.

## Как проверить
1. Открыть чат клуба на двух устройствах/вкладках.
2. Отправить сообщение с одного — оно должно появиться на другом мгновенно (без ожидания polling).
3. При отсутствии сети или ошибке WS — сообщения должны подгружаться через polling.

## Примечания
- Polling остаётся fallback при сбое WebSocket.
- URL WebSocket: `ws://` или `wss://` в зависимости от схемы API base URL.
