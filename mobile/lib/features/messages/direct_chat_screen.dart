import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/direct_chat_model.dart';
import '../../shared/models/message_model.dart';
import '../../shared/services/chat_websocket_service.dart';

/// Screen for 1:1 direct chat between trainer and client.
///
/// [otherUser] — the other participant in the conversation.
/// [isTrainer] — whether current user is the trainer in this pair.
class DirectChatScreen extends StatefulWidget {
  final DirectChatModel otherUser;
  final bool isTrainer;

  const DirectChatScreen({
    super.key,
    required this.otherUser,
    required this.isTrainer,
  });

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  static const int _pageSize = 50;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMoreHistory = false;
  bool _hasMoreHistory = false;
  int _historyOffset = 0;
  String? _currentUserId;

  Timer? _pollTimer;
  StreamSubscription? _wsSubscription;
  StreamSubscription? _wsStatusSubscription;

  bool _userScrolledAway = false;
  bool _showScrollToBottom = false;

  /// Whether chat is empty (no messages) — used to block client from sending first
  bool get _chatIsEmpty => _messages.isEmpty;

  /// Whether input should be blocked (client can't write first)
  bool get _inputBlocked => !widget.isTrainer && _chatIsEmpty;

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
    _wsSubscription?.cancel();
    _wsStatusSubscription?.cancel();
    _stopPolling();
    ChatWebSocketService.instance.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _directChannelKey() {
    final myId = _currentUserId ?? '';
    final otherId = widget.otherUser.userId;
    final ids = [myId, otherId]..sort();
    return 'direct:${ids[0]}:${ids[1]}';
  }

  Future<void> _loadInitialMessages() async {
    try {
      // Resolve current user ID
      final profile = await ServiceLocator.usersService.getProfile();
      _currentUserId = profile.user.id;

      final messages = await ServiceLocator.messagesService.getDirectMessages(
        widget.otherUser.userId,
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted) return;
      setState(() {
        _messages = messages.reversed.toList();
        _historyOffset = messages.length;
        _hasMoreHistory = messages.length >= _pageSize;
        _isLoading = false;
      });

      _connectWebSocket();
      _scrollToBottomDeferred();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _connectWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = ChatWebSocketService.instance.messageStream.listen((payload) {
      if (!mounted) return;
      try {
        final msg = MessageModel.fromJson(payload);
        // Only add if it belongs to this conversation
        final otherId = widget.otherUser.userId;
        if (msg.userId == otherId || msg.userId == _currentUserId) {
          // Deduplicate
          if (_messages.any((m) => m.id == msg.id)) return;
          setState(() {
            _messages.add(msg);
          });
          if (!_userScrolledAway) {
            _scrollToBottomDeferred();
          }
        }
      } catch (_) {}
    });

    ChatWebSocketService.instance.connectAndSubscribe(_directChannelKey());
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshLatestMessages();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refreshLatestMessages() async {
    try {
      final messages = await ServiceLocator.messagesService.getDirectMessages(
        widget.otherUser.userId,
        limit: _pageSize,
        offset: 0,
      );
      if (!mounted) return;

      final reversed = messages.reversed.toList();
      // Merge: keep existing messages, add new ones
      final existingIds = _messages.map((m) => m.id).toSet();
      final newMessages = reversed.where((m) => !existingIds.contains(m.id)).toList();
      if (newMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(newMessages);
        });
        if (!_userScrolledAway) {
          _scrollToBottomDeferred();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadOlderMessages() async {
    if (_isLoadingMoreHistory || !_hasMoreHistory) return;

    final hasScroll = _scrollController.hasClients;
    final previousMaxExtent = hasScroll ? _scrollController.position.maxScrollExtent : 0.0;
    final previousOffset = hasScroll ? _scrollController.position.pixels : 0.0;

    setState(() => _isLoadingMoreHistory = true);

    try {
      final older = await ServiceLocator.messagesService.getDirectMessages(
        widget.otherUser.userId,
        limit: _pageSize,
        offset: _historyOffset,
      );
      if (!mounted) return;

      final existingIds = _messages.map((m) => m.id).toSet();
      final unique = older.reversed.where((m) => !existingIds.contains(m.id)).toList();

      setState(() {
        _messages.insertAll(0, unique);
        _historyOffset += older.length;
        _hasMoreHistory = older.length >= _pageSize;
        _isLoadingMoreHistory = false;
      });

      if (hasScroll && unique.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final newMaxExtent = _scrollController.position.maxScrollExtent;
          final delta = newMaxExtent - previousMaxExtent;
          _scrollController.jumpTo(previousOffset + delta);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMoreHistory = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      final msg = await ServiceLocator.messagesService.sendDirectMessage(
        widget.otherUser.userId,
        text,
      );
      _messageController.clear();
      if (!mounted) return;
      // Deduplicate (WS may have already delivered it)
      if (!_messages.any((m) => m.id == msg.id)) {
        setState(() {
          _messages.add(msg);
        });
      }
      if (!_userScrolledAway) _scrollToBottomDeferred();
    } catch (_) {
      // Error is shown via snackbar if needed
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottomDeferred({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(target,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      } else {
        _scrollController.jumpTo(target);
      }
    });
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

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              child: Text(
                widget.otherUser.userName.isNotEmpty
                    ? widget.otherUser.userName[0].toUpperCase()
                    : '?',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.otherUser.userName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.isTrainer)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: AppLocalizations.of(context)!.clientRunsViewResults,
              onPressed: () => context.push(
                '/trainer/clients/${widget.otherUser.userId}/runs',
                extra: <String, String>{'clientName': widget.otherUser.userName},
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildMessagesList(l10n, theme)),
                if (_inputBlocked)
                  _buildBlockedHint(l10n, theme)
                else
                  _buildComposer(l10n),
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
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _inputBlocked
                          ? l10n.directChatWaitForTrainer
                          : l10n.messageHint,
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _messages.length + topLoaderItems,
                  itemBuilder: (context, index) {
                    if (_isLoadingMoreHistory && index == 0) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
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
              tooltip: l10n.messagesScrollToBottom,
              child: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageTile(BuildContext context, MessageModel message) {
    final isMine = _currentUserId != null && message.userId == _currentUserId;
    final theme = Theme.of(context);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.userName!,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              Text(message.text),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt.toLocal()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: l10n.messageHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedHint(AppLocalizations l10n, ThemeData theme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Text(
          l10n.directChatWaitForTrainer,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
