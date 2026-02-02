import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message_model.dart';

/// Real-time chat: WebSocket connection, subscribe to channel, stream new messages.
/// Connect with baseUrl (http/https), token, and cityId; sends subscribe city:{cityId}.
/// Incoming { type: 'message', payload: MessageViewDto } are emitted as MessageModel.
class ChatRealtimeService {
  WebSocketChannel? _channel;
  final StreamController<MessageModel> _controller = StreamController<MessageModel>.broadcast();
  bool _closed = false;

  /// Stream of new messages from the subscribed channel.
  Stream<MessageModel> get messageStream => _controller.stream;

  /// Connect to /ws, send subscribe for city:{cityId}. Token in query.
  /// baseUrl e.g. http://10.0.2.2:3000 -> ws://10.0.2.2:3000/ws
  void connect(String baseUrl, String? token, String cityId) {
    if (_closed) return;
    if (token == null || token.isEmpty) return;

    final wsUrl = _toWsUrl(baseUrl);
    final uri = Uri.parse('$wsUrl/ws?token=${Uri.encodeComponent(token)}');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (data) {
        try {
          final map = jsonDecode(data as String) as Map<String, dynamic>;
          final type = map['type'] as String?;
          if (type == 'message') {
            final payload = map['payload'] as Map<String, dynamic>?;
            if (payload != null && !_controller.isClosed) {
              _controller.add(MessageModel.fromJson(payload));
            }
          }
        } catch (_) {
          // Ignore parse errors
        }
      },
      onError: (_) {},
      onDone: () {},
      cancelOnError: false,
    );

    // Send subscribe after connect (channel is ready when first message is sent)
    Future.microtask(() {
      if (_channel != null && !_closed) {
        _channel!.sink.add(jsonEncode({
          'type': 'subscribe',
          'channel': 'city:$cityId',
        }));
      }
    });
  }

  static String _toWsUrl(String baseUrl) {
    var u = baseUrl.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    final lower = u.toLowerCase();
    if (lower.startsWith('https://')) return 'wss://${u.substring(8)}';
    if (lower.startsWith('http://')) return 'ws://${u.substring(7)}';
    return 'ws://$u';
  }

  void dispose() {
    _closed = true;
    _channel?.sink.close();
    _channel = null;
    _controller.close();
  }
}
