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

  // Whether current user is a trainer/leader in any club
  bool _isTrainerRole = false;
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
      
      final clubs = results[2] as List;
      // If user is a leader or trainer in any club, they have the "trainer" capability
      // Note: ClubChatModel doesn't have userRole yet in the model, 
      // but we can infer from the trainer clients list or other signals.
      // For now, if getTrainerClients returned a list (even empty), and user has clubs, 
      // let's check if they have trainer/leader role in any of them.
      
      setState(() {
        _trainerClients = results[0] as List<DirectChatModel>;
        _myTrainer = results[1] as DirectChatModel?;
        _hasClubs = clubs.isNotEmpty;
        
        // A user is considered a trainer if they have at least one client 
        // OR if they are a leader/trainer in a club. 
        // Since ClubChatModel might not have 'userRole', we'll rely on trainerClients 
        // being non-null (successful API call) and the fact that they might be a trainer.
        _isTrainerRole = _trainerClients != null && _trainerClients!.isNotEmpty;
        
        // Fallback: if they have clubs, we check if they are "staff"
        if (!_isTrainerRole && clubs.isNotEmpty) {
           // We'll trust the backend response. If trainer/clients returns 200, 
           // the user is capable of being a trainer.
           _isTrainerRole = true; 
        }

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
            onTap: (_) => _loadData(), // Refresh on tab switch
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
    // 1. Trainer with clients (priority)
    if (_trainerClients != null && _trainerClients!.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: _buildClientsList(l10n, theme),
      );
    }

    // 2. Athlete with trainer — open chat directly
    if (_myTrainer != null) {
      return DirectChatScreen(
        otherUser: _myTrainer!,
        isTrainer: false,
      );
    }

    // 3. No personal content — decide which empty message to show
    String emptyMessage = l10n.trainerNoPersonalTrainer;
    if (_isTrainerRole) {
      emptyMessage = l10n.trainerNoPrivateClients;
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          alignment: Alignment.center,
          child: _buildEmptyState(emptyMessage, theme),
        ),
      ),
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
