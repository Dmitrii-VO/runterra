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
/// Shows chat for the current club (MVP): history + composer.
class ClubMessagesTab extends StatefulWidget {
  const ClubMessagesTab({super.key});

  @override
  State<ClubMessagesTab> createState() => _ClubMessagesTabState();
}

class _ClubMessagesTabState extends State<ClubMessagesTab> {
  static const int _pageSize = 50;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMoreHistory = false;
  bool _hasMoreHistory = false;
  bool _errorOnMessagesLoad = false;
  bool _profileMetaLoadAttempted = false;

  Object? _loadError;
  String? _clubId;
  String? _currentUserId;
  String? _primaryClubId;
  int _historyOffset = 0;
  Timer? _pollTimer;
  List<MessageModel> _messages = <MessageModel>[];

  @override
  void initState() {
    super.initState();
    _loadClubChat();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureProfileMetaLoaded() async {
    if (_profileMetaLoadAttempted) return;
    _profileMetaLoadAttempted = true;
    try {
      final profile = await ServiceLocator.usersService.getProfile();
      _currentUserId = profile.user.id;
      _primaryClubId = profile.user.primaryClubId;
    } catch (_) {
      // Keep fallback behavior when profile is temporarily unavailable.
    }
  }

  DateTime _clubActivityTime(ClubChatModel chat) =>
      chat.lastMessageAt ?? chat.updatedAt;

  String _selectMostRelevantClubId(List<ClubChatModel> chats) {
    if (chats.length == 1) return chats.first.clubId;

    ClubChatModel best = chats.first;
    for (final chat in chats.skip(1)) {
      if (_clubActivityTime(chat).isAfter(_clubActivityTime(best))) {
        best = chat;
      }
    }
    return best.clubId;
  }

  Future<String?> _resolveClubId() async {
    await _ensureProfileMetaLoaded();

    final chats = await ServiceLocator.messagesService.getClubChats();
    if (chats.isEmpty) {
      if (ServiceLocator.currentClubService.currentClubId != null) {
        await ServiceLocator.currentClubService.setCurrentClubId(null);
      }
      return null;
    }

    final allowedClubIds = chats.map((chat) => chat.clubId).toSet();
    final currentClubId = ServiceLocator.currentClubService.currentClubId;
    if (currentClubId != null && allowedClubIds.contains(currentClubId)) {
      return currentClubId;
    }

    if (currentClubId != null && !allowedClubIds.contains(currentClubId)) {
      await ServiceLocator.currentClubService.setCurrentClubId(null);
    }

    if (_primaryClubId != null && allowedClubIds.contains(_primaryClubId)) {
      await ServiceLocator.currentClubService.setCurrentClubId(_primaryClubId);
      return _primaryClubId;
    }

    final fallbackClubId = _selectMostRelevantClubId(chats);
    await ServiceLocator.currentClubService.setCurrentClubId(fallbackClubId);
    return fallbackClubId;
  }

  Future<void> _loadClubChat() async {
    _stopPolling();
    setState(() {
      _isLoading = true;
      _loadError = null;
      _errorOnMessagesLoad = false;
    });

    bool fetchingMessagesStarted = false;

    try {
      final clubId = await _resolveClubId();
      if (clubId == null) {
        if (!mounted) return;
        setState(() {
          _clubId = null;
          _messages = <MessageModel>[];
          _historyOffset = 0;
          _hasMoreHistory = false;
          _isLoading = false;
        });
        return;
      }

      fetchingMessagesStarted = true;
      final loadedMessages =
          await ServiceLocator.messagesService.getClubChatMessages(
        clubId,
        limit: _pageSize,
        offset: 0,
      );
      loadedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      if (!mounted) return;
      setState(() {
        _clubId = clubId;
        _messages = loadedMessages;
        _historyOffset = loadedMessages.length;
        _hasMoreHistory = loadedMessages.length == _pageSize;
        _isLoading = false;
      });
      _startPolling();
      _scrollToBottomDeferred(animated: false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _errorOnMessagesLoad = fetchingMessagesStarted;
        _isLoading = false;
      });
    }
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
    } catch (_) {
      // Ignore polling failures; user can still manually retry by reopening tab.
    }
  }

  Future<void> _loadOlderMessages() async {
    final clubId = _clubId;
    if (clubId == null || !_hasMoreHistory || _isLoadingMoreHistory) return;

    final hasScroll = _scrollController.hasClients;
    final previousMaxExtent =
        hasScroll ? _scrollController.position.maxScrollExtent : 0.0;
    final previousOffset = hasScroll ? _scrollController.position.pixels : 0.0;

    setState(() {
      _isLoadingMoreHistory = true;
    });

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
    } catch (_) {
      // Ignore history loading failure to keep current messages visible.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreHistory = false;
        });
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString();
  }

  Future<void> _sendMessage() async {
    final clubId = _clubId;
    if (clubId == null || _isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
    });

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
        await _loadClubChat();
        if (!mounted) return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
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

  Widget _buildLoadErrorState(AppLocalizations l10n, ThemeData theme) {
    final error = _loadError;
    final message = error == null ? '' : _errorMessage(error);
    final text = _errorOnMessagesLoad
        ? l10n.messagesLoadError(message)
        : l10n.clubChatsLoadError(message);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              text,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadClubChat,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoClubState(AppLocalizations l10n, ThemeData theme) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return _buildLoadErrorState(l10n, theme);
    }

    if (_clubId == null) {
      return _buildNoClubState(l10n, theme);
    }

    return Column(
      children: [
        Expanded(child: _buildMessagesList()),
        _buildComposer(l10n),
      ],
    );
  }
}
