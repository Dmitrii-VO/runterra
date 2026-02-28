import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/my_club_model.dart';
import '../../../shared/models/direct_chat_model.dart';
import '../direct_chat_screen.dart';
import 'trainer_groups_tab.dart';

/// Tab "Тренер" — trainer messaging with sub-tabs: Groups and Personal.
class CoachTab extends StatefulWidget {
  const CoachTab({super.key});

  @override
  State<CoachTab> createState() => _CoachTabState();
}

class _CoachTabState extends State<CoachTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<TrainerGroupsTabState> _groupsKey = GlobalKey();
  List<DirectChatModel>? _trainerClients;
  DirectChatModel? _myTrainer;
  List<MyClubModel>? _myClubs;
  bool _isLoading = true;

  bool _canCreateGroups = false;
  bool _isTrainerRole = false;

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
        ServiceLocator.clubsService.getMyClubs().catchError((e) {
          debugPrint('CoachTab: Error loading my clubs: $e');
          return <MyClubModel>[];
        }),
      ]);

      if (!mounted) return;
      
      setState(() {
        _trainerClients = results[0] as List<DirectChatModel>?;
        _myTrainer = results[1] as DirectChatModel?;
        _myClubs = results[2] as List<MyClubModel>;
        
        _canCreateGroups = _myClubs?.any((c) => c.role == 'trainer' || c.role == 'leader') ?? false;
        _isTrainerRole = (_trainerClients != null && _trainerClients!.isNotEmpty) || _canCreateGroups;
        
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

    return Scaffold(
      body: Column(
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
                TrainerGroupsTab(key: _groupsKey),
                _buildPersonalTab(l10n, Theme.of(context)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _canCreateGroups
          ? FloatingActionButton(
              onPressed: _showCreateGroupDialog,
              child: const Icon(Icons.group_add),
            )
          : null,
    );
  }

  void _showCreateGroupDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final trainerClubs = _myClubs?.where((c) => c.role == 'trainer' || c.role == 'leader').toList() ?? [];

    if (trainerClubs.isEmpty) return;

    String? selectedClubId;
    if (trainerClubs.length == 1) {
      selectedClubId = trainerClubs.first.id;
    } else {
      selectedClubId = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(l10n.selectClub),
          children: trainerClubs
              .map((c) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, c.id),
                    child: Text(c.name),
                  ))
              .toList(),
        ),
      );
    }

    if (selectedClubId != null && mounted) {
      final club = trainerClubs.firstWhere((c) => c.id == selectedClubId);
      final result = await context.push<bool>(
        '/trainer/groups/create?clubId=$selectedClubId&clubName=${Uri.encodeComponent(club.name)}',
      );
      if (result == true) {
        _loadData();
        _groupsKey.currentState?.loadData();
      }
    }
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
