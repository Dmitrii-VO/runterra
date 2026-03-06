import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/auth/auth_service.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/message_model.dart';
import '../../shared/services/chat_websocket_service.dart';

class ChatScreen extends StatefulWidget {
  final String channelType; // 'trainer_group', 'club', etc.
  final String channelId;
  final String title;

  const ChatScreen({
    super.key,
    required this.channelType,
    required this.channelId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const int _pageSize = 50;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _currentUserId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMoreHistory = false;
  bool _hasMoreHistory = false;
  Object? _error;

  int _historyOffset = 0;
  Timer? _pollTimer;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _wsStatusSubscription;
  List<MessageModel> _messages = <MessageModel>[];

  bool _userScrolledAway = false;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();

    _wsStatusSubscription = ChatWebSocketService.instance.statusStream.listen((status) {
      if (!mounted) return;
      if (status == WsStatus.connected) {
        _stopPolling();
      } else if (status == WsStatus.error || status == WsStatus.disconnected) {
        _startPolling();
      }
    });
  }

  @override
  void dispose() {
    _stopPolling();
    _disconnectWebSocket();
    _wsStatusSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ServiceLocator.usersService.getProfile();
      final List<MessageModel> loadedMessages;
      
      if (widget.channelType == 'trainer_group') {
        loadedMessages = await ServiceLocator.messagesService.getTrainerGroupMessages(
          widget.channelId,
          limit: _pageSize,
          offset: 0,
        );
      } else {
        // Fallback for club or other types if needed
        loadedMessages = [];
      }

      loadedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      setState(() {
        _currentUserId = profile.user.id;
        _messages = loadedMessages;
        _historyOffset = loadedMessages.length;
        _hasMoreHistory = loadedMessages.length == _pageSize;
        _isLoading = false;
      });
      
      await _connectWebSocket();
      _scrollToBottomDeferred(animated: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshLatestMessages();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<bool> _connectWebSocket() async {
    _disconnectWebSocket();
    String key;
    if (widget.channelType == 'trainer_group') {
      key = ChatWebSocketService.trainerGroupChannelKey(widget.channelId);
    } else {
      return false;
    }

    final connected = await ChatWebSocketService.instance.connectAndSubscribe(key);
    if (!connected || !mounted) return false;

    _wsSubscription = ChatWebSocketService.instance.messageStream.listen((payload) {
      if (!mounted) return;
      try {
        final msg = MessageModel.fromJson(Map<String, dynamic>.from(payload as Map));
        if (_messages.any((m) => m.id == msg.id)) return;
        
        final wasNearBottom = _isNearBottom();
        setState(() {
          _messages = [..._messages, msg]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          _historyOffset += 1;
        });
        if (wasNearBottom) _scrollToBottomDeferred(animated: true);
      } catch (_) {}
    });
    return true;
  }

  void _disconnectWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    ChatWebSocketService.instance.disconnect();
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    if (_userScrolledAway) return false;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) <= 80;
  }

  void _onScrollNotification(ScrollNotification notification) {
    // Only react to user-initiated scrolls, not programmatic jumpTo/animateTo
    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails == null) return;
    } else if (notification is! ScrollEndNotification) {
      return;
    }

    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final distFromBottom = position.maxScrollExtent - position.pixels;
    final scrolledAway = distFromBottom > 200;
    if (_userScrolledAway != scrolledAway || _showScrollToBottom != scrolledAway) {
      setState(() {
        _userScrolledAway = scrolledAway;
        _showScrollToBottom = scrolledAway;
      });
    }
  }

  Future<void> _refreshLatestMessages() async {
    try {
      final wasNearBottom = _isNearBottom();
      final List<MessageModel> latest;
      
      if (widget.channelType == 'trainer_group') {
        latest = await ServiceLocator.messagesService.getTrainerGroupMessages(
          widget.channelId,
          limit: _pageSize,
          offset: 0,
        );
      } else {
        return;
      }
      
      latest.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      final mapById = <String, MessageModel>{
        for (final message in _messages) message.id: message,
      };
      final previousCount = mapById.length;
      for (final message in latest) {
        mapById[message.id] = message;
      }
      final merged = mapById.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final newCount = merged.length - previousCount;
      if (newCount <= 0) return;

      setState(() {
        _messages = merged;
        _historyOffset += newCount;
      });

      if (wasNearBottom) {
        _scrollToBottomDeferred(animated: true);
      }
    } catch (_) {}
  }

  Future<void> _loadOlderMessages() async {
    if (!_hasMoreHistory || _isLoadingMoreHistory) return;

    final hasScroll = _scrollController.hasClients;
    final previousMaxExtent = hasScroll ? _scrollController.position.maxScrollExtent : 0.0;
    final previousOffset = hasScroll ? _scrollController.position.pixels : 0.0;

    setState(() => _isLoadingMoreHistory = true);

    try {
      final List<MessageModel> olderBatch;
      if (widget.channelType == 'trainer_group') {
        olderBatch = await ServiceLocator.messagesService.getTrainerGroupMessages(
          widget.channelId,
          limit: _pageSize,
          offset: _historyOffset,
        );
      } else {
        return;
      }
      
      olderBatch.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      _historyOffset += olderBatch.length;
      _hasMoreHistory = olderBatch.length == _pageSize;

      final existingIds = _messages.map((m) => m.id).toSet();
      final uniqueOlder = olderBatch.where((m) => !existingIds.contains(m.id)).toList();

      if (uniqueOlder.isNotEmpty) {
        setState(() {
          _messages = <MessageModel>[...uniqueOlder, ..._messages];
        });

        if (hasScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients) return;
            final newMaxExtent = _scrollController.position.maxScrollExtent;
            final delta = newMaxExtent - previousMaxExtent;
            _scrollController.jumpTo(previousOffset + delta);
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingMoreHistory = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final MessageModel sent;
      if (widget.channelType == 'trainer_group') {
        sent = await ServiceLocator.messagesService.sendTrainerGroupMessage(widget.channelId, text);
      } else {
        throw UnimplementedError();
      }

      // Логируем отправку сообщения
      FirebaseAnalytics.instance.logEvent(
        name: 'message_send',
        parameters: {
          'channel_type': widget.channelType,
          'channel_id': widget.channelId,
        },
      );
      
      if (!mounted) return;

      _messageController.clear();
      _focusNode.requestFocus();
      if (_messages.any((message) => message.id == sent.id)) return;

      setState(() {
        _messages = <MessageModel>[..._messages, sent];
        _historyOffset += 1;
      });
      if (!_userScrolledAway) _scrollToBottomDeferred(animated: true);
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric(error.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottomDeferred({required bool animated}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(l10n, theme)
                    : _buildMessagesList(l10n, theme),
          ),
          _buildComposer(l10n),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(l10n.errorGeneric(_error.toString())),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialMessages,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AppLocalizations l10n, ThemeData theme) {
    final topLoaderItems = _isLoadingMoreHistory ? 1 : 0;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels <= 24) {
              _loadOlderMessages();
            }
            _onScrollNotification(notification);
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _messages.length + topLoaderItems,
            itemBuilder: (context, index) {
              if (_isLoadingMoreHistory && index == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final messageIndex = index - topLoaderItems;
              return _buildMessageTile(context, _messages[messageIndex]);
            },
          ),
        ),
        if (_showScrollToBottom)
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _userScrolledAway = false;
                  _showScrollToBottom = false;
                });
                _scrollToBottomDeferred(animated: true);
              },
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageTile(BuildContext context, MessageModel message) {
    final myUserId = _currentUserId ?? AuthService.instance.currentUser?.uid;
    final isMine = myUserId != null && message.userId == myUserId;
    final theme = Theme.of(context);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMine
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine && (message.userName?.isNotEmpty ?? false))
              Text(
                message.userName!,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.primaryColor),
              ),
            Text(message.text),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt.toLocal()),
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(AppLocalizations l10n) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: l10n.messageHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
