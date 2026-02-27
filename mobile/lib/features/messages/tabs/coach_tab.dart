import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/direct_chat_model.dart';
import '../direct_chat_screen.dart';
import 'club_messages_tab.dart';

/// Tab "Тренер" — trainer messaging with sub-tabs: Groups and Personal.
///
/// Groups: ClubMessagesTab with highlightTrainer enabled.
/// Personal: trainer sees client list, client sees trainer chat.
class CoachTab extends StatefulWidget {
  const CoachTab({super.key});

  @override
  State<CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends State<CoachTab> {
  List<DirectChatModel>? _trainerClients;
  DirectChatModel? _myTrainer;
  bool _isLoading = true;

  // Whether current user has any clubs (for Groups tab)
  bool _hasClubs = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ServiceLocator.messagesService.getTrainerClients(),
        ServiceLocator.messagesService.getMyTrainer(),
        ServiceLocator.messagesService.getClubChats(),
      ]);

      if (!mounted) return;
      setState(() {
        _trainerClients = results[0] as List<DirectChatModel>;
        _myTrainer = results[1] as DirectChatModel?;
        final clubs = results[2] as List;
        _hasClubs = clubs.isNotEmpty;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  bool get _hasPersonalContent =>
      (_trainerClients != null && _trainerClients!.isNotEmpty) || _myTrainer != null;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Text(
                  l10n.trainerGroupsTab,
                  style: TextStyle(
                    color: _hasClubs ? null : Colors.grey,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  l10n.trainerPersonalTab,
                  style: TextStyle(
                    color: _hasPersonalContent ? null : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Groups tab
                _hasClubs
                    ? const ClubMessagesTab(highlightTrainer: true)
                    : _buildEmptyState(l10n.noClubChats, theme),
                // Personal tab
                _buildPersonalTab(l10n, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab(AppLocalizations l10n, ThemeData theme) {
    // Trainer with clients
    if (_trainerClients != null && _trainerClients!.isNotEmpty) {
      return _buildClientsList(l10n, theme);
    }

    // Athlete with trainer — open chat directly
    if (_myTrainer != null) {
      return DirectChatScreen(
        otherUser: _myTrainer!,
        isTrainer: false,
      );
    }

    // No personal content
    return _buildEmptyState(
      _trainerClients != null
          ? l10n.trainerNoPrivateClients
          : l10n.trainerNoPersonalTrainer,
      theme,
    );
  }

  Widget _buildClientsList(AppLocalizations l10n, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _trainerClients!.length,
      itemBuilder: (context, index) {
        final client = _trainerClients![index];
        return ListTile(
          leading: CircleAvatar(
            child: Text(
              client.userName.isNotEmpty
                  ? client.userName[0].toUpperCase()
                  : '?',
            ),
          ),
          title: Text(client.userName),
          subtitle: client.lastMessageText != null
              ? Text(
                  client.lastMessageText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: client.lastMessageAt != null
              ? Text(
                  _formatTime(client.lastMessageAt!.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                )
              : null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DirectChatScreen(
                  otherUser: client,
                  isTrainer: true,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String text, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
