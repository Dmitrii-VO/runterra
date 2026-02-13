import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../auth/auth_service.dart';
import '../config/api_config.dart';

enum WsStatus { disconnected, connecting, connected, error }

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
  final _statusController = StreamController<WsStatus>.broadcast();

  WsStatus _status = WsStatus.disconnected;
  String? _currentChannelKey;

  /// Stream of incoming message payloads (MessageViewDto from backend).
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Stream of connection status changes.
  Stream<WsStatus> get statusStream => _statusController.stream;

  /// Current connection status.
  WsStatus get status => _status;

  /// Whether currently connected.
  bool get isConnected => _status == WsStatus.connected;

  void _updateStatus(WsStatus newStatus) {
    if (_status == newStatus) return;
    _status = newStatus;
    _statusController.add(newStatus);
  }

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
  /// Returns true if connection attempt started successfully.
  Future<bool> connectAndSubscribe(String channelKey) async {
    if (_currentChannelKey == channelKey && isConnected) return true;

    await disconnect();
    _currentChannelKey = channelKey;
    _updateStatus(WsStatus.connecting);

    return _reconnect();
  }

  Future<bool> _reconnect() async {
    final channelKey = _currentChannelKey;
    if (channelKey == null) return false;

    final token = await AuthService.instance.getIdToken();
    if (token == null || token.isEmpty) {
      _updateStatus(WsStatus.error);
      return false;
    }

    try {
      final url = _buildWsUrl(token);
      _channel = WebSocketChannel.connect(Uri.parse(url));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // Wait for connection (first frame or short delay)
      await Future.delayed(const Duration(milliseconds: 500));

      if (_channel == null) {
        _updateStatus(WsStatus.error);
        return false;
      }

      // Send subscribe message
      _channel!.sink.add(jsonEncode({
        'type': 'subscribe',
        'channel': channelKey,
      }));

      _updateStatus(WsStatus.connected);
      return true;
    } catch (_) {
      _updateStatus(WsStatus.error);
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
      } else if (type == 'error') {
        // e.g. Subscribe denied
        if (decoded['message'] == 'Subscribe denied') {
          // Could update status to forbidden if we had such state
        }
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  void _onError(Object error) {
    _updateStatus(WsStatus.error);
    _scheduleReconnect();
  }

  void _onDone() {
    if (_status != WsStatus.disconnected) {
      _updateStatus(WsStatus.disconnected);
      _scheduleReconnect();
    }
  }

  Timer? _reconnectTimer;
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_currentChannelKey == null) return;

    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_currentChannelKey != null && _status != WsStatus.connected) {
        _reconnect();
      }
    });
  }

  /// Disconnect and cleanup.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _currentChannelKey = null;
    _updateStatus(WsStatus.disconnected);

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
