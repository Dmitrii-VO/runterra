import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/api/chat_realtime_service.dart';
import '../../../shared/config/api_config.dart';
import '../../../shared/models/message_model.dart';
import '../../../shared/models/profile_model.dart';
import '../../../shared/ui/list_items/message_list_item.dart';

/// Tab "Город" — общий (городской) чат.
///
/// Загружает сообщения по REST, подписывается на новые по WebSocket,
/// отображает список и поле ввода для отправки.
class GlobalChatTab extends StatefulWidget {
  const GlobalChatTab({super.key});

  @override
  State<GlobalChatTab> createState() => _GlobalChatTabState();
}

class _GlobalChatTabState extends State<GlobalChatTab> {
  /// Future: (messages, cityId for real-time). cityId from profile.
  late Future<(List<MessageModel>, String?)> _dataFuture;
  /// Current list: initial + new messages from WebSocket (newest at end for reverse ListView).
  List<MessageModel> _messages = [];
  /// Whether initial future has completed with success (so we have _messages from REST).
  bool _initialLoaded = false;
  /// Real-time: subscribe to city channel when we have cityId.
  ChatRealtimeService? _realtimeService;
  StreamSubscription<MessageModel>? _realtimeSubscription;
  bool _realtimeStarted = false;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;
  String? _sendError;

  Future<(List<MessageModel>, String?)> _fetchData() async {
    final messages = await ServiceLocator.messagesService.getGlobalChatMessages();
    ProfileModel profile;
    try {
      profile = await ServiceLocator.usersService.getProfile();
    } catch (_) {
      return (messages, null);
    }
    final cityId = profile.user.cityId;
    return (messages, cityId);
  }

  void _retry() {
    setState(() {
      _initialLoaded = false;
      _messages = [];
      _realtimeStarted = false;
      _realtimeSubscription?.cancel();
      _realtimeService?.dispose();
      _realtimeService = null;
      _dataFuture = _fetchData();
    });
  }

  void _startRealtime(String cityId) {
    if (_realtimeStarted || !mounted) return;
    _realtimeStarted = true;
    final baseUrl = ApiConfig.getBaseUrl();
    final token = ServiceLocator.apiClient.authToken;
    if (token == null || token.isEmpty) return;
    _realtimeService = ChatRealtimeService();
    _realtimeService!.connect(baseUrl, token, cityId);
    _realtimeSubscription = _realtimeService!.messageStream.listen((message) {
      if (!mounted) return;
      setState(() {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages = [..._messages, message];
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sendError = null;
      _sending = true;
    });
    try {
      final sent = await ServiceLocator.messagesService.sendGlobalMessage(text);
      if (!mounted) return;
      setState(() {
        _textController.clear();
        _sending = false;
        if (!_messages.any((m) => m.id == sent.id)) {
          _messages = [..._messages, sent];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sendError = e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _realtimeService?.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(List<MessageModel>, String?)>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_initialLoaded) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Ошибка загрузки сообщений: ${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final (initialMessages, cityId) = snapshot.data!;
          if (!_initialLoaded) {
            _initialLoaded = true;
            _messages = List.from(initialMessages.reversed);
            if (cityId != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startRealtime(cityId);
              });
            }
          }

          return Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Пока тихо. Напиши первое сообщение и задай ритм городу 🏃‍♂️',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[_messages.length - 1 - index];
                          return MessageListItem(
                            messageText: message.text,
                            userName: message.userName,
                            createdAt: message.createdAt,
                          );
                        },
                      ),
              ),
              if (_sendError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Text(
                    _sendError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Сообщение...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: 2,
                        maxLength: 500,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _sendMessage,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
