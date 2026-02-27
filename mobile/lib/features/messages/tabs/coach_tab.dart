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

class _CoachTabState extends State<CoachTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DirectChatModel>? _trainerClients;
  DirectChatModel? _myTrainer;
  bool _isLoading = true;

  bool _isTrainerRole = false;
  bool _hasClubs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        ServiceLocator.messagesService.getTrainerClients().catchError((e) {
          debugPrint('CoachTab: Error loading clients: $e');
          return <DirectChatModel>[];
        }),
        ServiceLocator.messagesService.getMyTrainer().catchError((e) {
          debugPrint('CoachTab: Error loading my trainer: $e');
          return null;
        }),
        ServiceLocator.messagesService.getClubChats().catchError((e) {
          debugPrint('CoachTab: Error loading clubs: $e');
          return <ClubChatModel>[];
        }),
      ]);

      if (!mounted) return;
      
      setState(() {
        _trainerClients = results[0] as List<DirectChatModel>?;
        _myTrainer = results[1] as DirectChatModel?;
        final clubs = results[2] as List<ClubChatModel>;
        _hasClubs = clubs.isNotEmpty;
        
        // Mark as trainer if they have clients OR if they have any clubs
        // (Simplified: if you are in a club, you might be a trainer/leader)
        _isTrainerRole = (_trainerClients != null && _trainerClients!.isNotEmpty) || _hasClubs;
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('CoachTab: Unexpected error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.trainerGroupsTab),
            Tab(text: l10n.trainerPersonalTab),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Groups tab
              _buildGroupsTab(l10n, theme),
              // Personal tab
              _buildPersonalTab(l10n, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab(AppLocalizations l10n, ThemeData theme) {
    if (_isLoading && !_hasClubs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_hasClubs) {
      return _buildEmptyState(l10n.noClubChats, theme);
    }
    // For now, show ClubMessagesTab but we might want a list view here later
    return const ClubMessagesTab(highlightTrainer: true);
  }

  Widget _buildPersonalTab(AppLocalizations l10n, ThemeData theme) {
    if (_isLoading && _trainerClients == null && _myTrainer == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // 1. Trainer view: show clients list
    if (_trainerClients != null && _trainerClients!.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        child: _buildClientsList(l10n, theme),
      );
    }

    // 2. Athlete view: show my trainer chat
    if (_myTrainer != null) {
      return DirectChatScreen(
        otherUser: _myTrainer!,
        isTrainer: false,
      );
    }

    // 3. Empty state
    String emptyMessage = l10n.trainerNoPersonalTrainer;
    if (_isTrainerRole) {
      emptyMessage = l10n.trainerNoPrivateClients;
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: _buildEmptyState(emptyMessage, theme),
          ),
        ],
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
