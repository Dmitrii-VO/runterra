import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/auth_service.dart';
import '../config/api_config.dart';

/// WebSocket service for real-time club chat messages.
///
/// Connects to backend /ws with auth token. Subscribes to club channel
/// and streams incoming messages. Used by ClubMessagesTab instead of polling.
class ChatWebSocketService {
  ChatWebSocketService._();

  static final ChatWebSocketService instance = ChatWebSocketService._();

  static const String _wsPath = '/ws';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of incoming message payloads (MessageViewDto from backend).
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Whether currently connected.
  bool get isConnected => _channel != null;

  /// Build WebSocket URL from API base URL.
  /// http://host:port -> ws://host:port/ws
  /// https://host:port -> wss://host:port/ws
  static String _buildWsUrl(String token) {
    final base = ApiConfig.getBaseUrl();
    final uri = Uri.parse(base);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final host = uri.host;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '$scheme://$host$port$_wsPath?token=${Uri.encodeComponent(token)}';
  }

  /// Connect and subscribe to a club chat channel.
  ///
  /// [channelKey] format: "club:clubId" or "club:clubId:channelId"
  /// Returns true if connected and subscribed successfully.
  Future<bool> connectAndSubscribe(String channelKey) async {
    await disconnect();

    final token = await AuthService.instance.getIdToken();
    if (token == null || token.isEmpty) return false;

    try {
      final url = _buildWsUrl(token);
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Wait for connection (first frame or error)
      await Future.delayed(const Duration(milliseconds: 300));

      if (_channel == null) return false;

      // Send subscribe message
      _channel!.sink.add(jsonEncode({
        'type': 'subscribe',
        'channel': channelKey,
      }));

      return true;
    } catch (_) {
      await disconnect();
      return false;
    }
  }

  void _onMessage(dynamic data) {
    try {
      final decoded = jsonDecode(data as String) as Map<String, dynamic>;
      final type = decoded['type'] as String?;
      if (type == 'message') {
        final payload = decoded['payload'] as Map<String, dynamic>?;
        if (payload != null) {
          _messageController.add(payload);
        }
      }
      // Ignore 'error' type — subscribe denied, etc.
    } catch (_) {
      // Ignore malformed messages
    }
  }

  void _onError(Object error) {
    // Connection error — caller can reconnect if needed
  }

  void _onDone() {
    _channel = null;
    _subscription = null;
  }

  /// Disconnect and cleanup.
  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  /// Build channel key for subscription.
  /// Use channel-specific when channelId is known for real-time in that channel.
  static String channelKey(String clubId, {String? channelId}) {
    if (channelId != null && channelId.isNotEmpty) {
      return 'club:$clubId:$channelId';
    }
    return 'club:$clubId';
  }
}
