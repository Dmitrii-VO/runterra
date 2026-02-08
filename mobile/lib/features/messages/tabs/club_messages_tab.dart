import 'dart:async';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/api/users_service.dart' show ApiException;
import '../../../shared/auth/auth_service.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/club_chat_model.dart';
import '../../../shared/models/message_model.dart';

/// Club tab in messages screen.
///
/// First step: list of user's clubs (from GET /api/messages/clubs).
/// Second step: chat of selected club (history + composer). Back returns to list.
/// [initialClubId] — when set (e.g. from route /messages?tab=club&clubId=...), open that club's chat directly.
class ClubMessagesTab extends StatefulWidget {
  /// If set, open chat for this club immediately (e.g. deep-link from ClubDetailsScreen).
  final String? initialClubId;

  const ClubMessagesTab({super.key, this.initialClubId});

  @override
  State<ClubMessagesTab> createState() => _ClubMessagesTabState();
}

class _ClubMessagesTabState extends State<ClubMessagesTab> {
  static const int _pageSize = 50;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ClubChatModel>? _clubChats;
  Object? _listLoadError;
  bool _isListLoading = true;

  String? _clubId;
  String? _currentUserId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMoreHistory = false;
  bool _hasMoreHistory = false;
  bool _errorOnMessagesLoad = false;
  Object? _messagesLoadError;

  int _historyOffset = 0;
  Timer? _pollTimer;
  List<MessageModel> _messages = <MessageModel>[];

  @override
  void initState() {
    super.initState();
    _loadClubList();
  }

  @override
  void didUpdateWidget(ClubMessagesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialClubId != oldWidget.initialClubId &&
        widget.initialClubId != null &&
        _clubChats != null &&
        _clubId == null) {
      _tryOpenInitialClub();
    }
  }

  void _tryOpenInitialClub() {
    final id = widget.initialClubId;
    if (id == null || _clubChats == null) return;
    if (_clubChats!.any((c) => c.clubId == id)) {
      _openClubChat(id);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadClubList() async {
    setState(() {
      _isListLoading = true;
      _listLoadError = null;
    });

    try {
      final chats = await ServiceLocator.messagesService.getClubChats();
      if (!mounted) return;
      setState(() {
        _clubChats = chats;
        _isListLoading = false;
      });
      _tryOpenInitialClub();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _listLoadError = error;
        _isListLoading = false;
      });
    }
  }

  Future<void> _openClubChat(String clubId) async {
    _stopPolling();
    setState(() {
      _clubId = clubId;
      _isLoading = true;
      _errorOnMessagesLoad = false;
    });

    try {
      final loadedMessages =
          await ServiceLocator.messagesService.getClubChatMessages(
        clubId,
        limit: _pageSize,
        offset: 0,
      );
      loadedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted || _clubId != clubId) return;
      final profile = await ServiceLocator.usersService.getProfile();
      if (!mounted || _clubId != clubId) return;
      setState(() {
        _currentUserId = profile.user.id;
        _messages = loadedMessages;
        _historyOffset = loadedMessages.length;
        _hasMoreHistory = loadedMessages.length == _pageSize;
        _isLoading = false;
      });
      _startPolling();
      _scrollToBottomDeferred(animated: false);
    } catch (error) {
      if (!mounted || _clubId != clubId) return;
      setState(() {
        _errorOnMessagesLoad = true;
        _messagesLoadError = error;
        _isLoading = false;
      });
    }
  }

  void _backToClubList() {
    _stopPolling();
    setState(() {
      _clubId = null;
      _messages = <MessageModel>[];
      _historyOffset = 0;
      _hasMoreHistory = false;
    });
  }

  void _startPolling() {
    _stopPolling();
    if (_clubId == null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshLatestMessages();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final position = _scrollController.position;
    return (position.maxScrollExtent - position.pixels) <= 80;
  }

  Future<void> _refreshLatestMessages() async {
    final clubId = _clubId;
    if (clubId == null) return;

    try {
      final wasNearBottom = _isNearBottom();
      final latest = await ServiceLocator.messagesService.getClubChatMessages(
        clubId,
        limit: _pageSize,
        offset: 0,
      );
      latest.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted || _clubId != clubId) return;
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
    final clubId = _clubId;
    if (clubId == null || !_hasMoreHistory || _isLoadingMoreHistory) return;

    final hasScroll = _scrollController.hasClients;
    final previousMaxExtent =
        hasScroll ? _scrollController.position.maxScrollExtent : 0.0;
    final previousOffset = hasScroll ? _scrollController.position.pixels : 0.0;

    setState(() => _isLoadingMoreHistory = true);

    try {
      final olderBatch =
          await ServiceLocator.messagesService.getClubChatMessages(
        clubId,
        limit: _pageSize,
        offset: _historyOffset,
      );
      olderBatch.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted || _clubId != clubId) return;
      _historyOffset += olderBatch.length;
      _hasMoreHistory = olderBatch.length == _pageSize;

      final existingIds = _messages.map((m) => m.id).toSet();
      final uniqueOlder =
          olderBatch.where((m) => !existingIds.contains(m.id)).toList();

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

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  Future<void> _sendMessage() async {
    final clubId = _clubId;
    if (clubId == null || _isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final wasNearBottom = _isNearBottom();
      final sent =
          await ServiceLocator.messagesService.sendClubMessage(clubId, text);
      if (!mounted) return;

      _messageController.clear();
      if (_messages.any((message) => message.id == sent.id)) return;

      setState(() {
        _messages = <MessageModel>[..._messages, sent];
        _historyOffset += 1;
      });
      if (wasNearBottom) {
        _scrollToBottomDeferred(animated: true);
      }
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final errorText = l10n.errorGeneric(_errorMessage(error));
      if (error is ApiException && error.code == 'forbidden') {
        _openClubChat(clubId);
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
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

  String _formatTime(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildListLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildListError(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.clubChatsLoadError(_listLoadError != null ? _errorMessage(_listLoadError!) : ''),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadClubList,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoClubs(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l10n.noClubChats,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildClubList(AppLocalizations l10n, ThemeData theme) {
    final chats = _clubChats!;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final name = chat.clubName?.trim().isNotEmpty == true
            ? chat.clubName!
            : chat.clubId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.group),
            ),
            title: Text(name),
            subtitle: chat.lastMessageText?.trim().isNotEmpty == true
                ? Text(
                    chat.lastMessageText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            onTap: () => _openClubChat(chat.clubId),
          ),
        );
      },
    );
  }

  Widget _buildChatLoadError(AppLocalizations l10n, ThemeData theme) {
    final msg = _messagesLoadError != null
        ? _errorMessage(_messagesLoadError!)
        : '';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              l10n.messagesLoadError(msg),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _clubId != null ? _openClubChat(_clubId!) : null,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(BuildContext context, MessageModel message) {
    final myUserId = _currentUserId ?? AuthService.instance.currentUser?.uid;
    final isMine = myUserId != null && message.userId == myUserId;
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
                enabled: !_isSending,
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

  Widget _buildMessagesList() {
    final topLoaderItems = _isLoadingMoreHistory ? 1 : 0;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels <= 24) {
          _loadOlderMessages();
        }
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
    );
  }

  /// Chat view: back button + club name + messages + composer.
  Widget _buildChatView(AppLocalizations l10n, ThemeData theme) {
    final chat = _clubChats?.firstWhere(
      (c) => c.clubId == _clubId,
      orElse: () => ClubChatModel(
        id: '',
        clubId: _clubId!,
        clubName: _clubId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final title = chat?.clubName?.trim().isNotEmpty == true
        ? (chat?.clubName ?? _clubId!)
        : _clubId!;

    return Column(
      children: [
        Material(
          elevation: 1,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _backToClubList,
                    tooltip: l10n.messagesBackToClubs,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _buildMessagesList()),
        _buildComposer(l10n),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_clubId != null) {
      if (_isLoading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (_errorOnMessagesLoad) {
        return _buildChatLoadError(l10n, theme);
      }
      return _buildChatView(l10n, theme);
    }

    if (_isListLoading) {
      return _buildListLoading();
    }
    if (_listLoadError != null) {
      return _buildListError(l10n, theme);
    }
    if (_clubChats == null || _clubChats!.isEmpty) {
      return _buildNoClubs(l10n, theme);
    }
    return _buildClubList(l10n, theme);
  }
}
