import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/my_club_model.dart';
import '../../../shared/models/direct_chat_model.dart';
import '../../../shared/models/trainer_assignment_model.dart';
import '../../../shared/models/profile_model.dart';
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
  List<DirectChatModel>? _trainerClients;
  DirectChatModel? _myTrainer;
  bool _isLoading = true;

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
        ServiceLocator.usersService.getProfile(),
        ServiceLocator.clubsService.getMyClubs().catchError((e) {
          debugPrint('CoachTab: Error loading my clubs: $e');
          return <MyClubModel>[];
        }),
        ServiceLocator.messagesService.getTrainerClients().catchError((e) {
          debugPrint('CoachTab: Error loading clients: $e');
          return <DirectChatModel>[];
        }),
        ServiceLocator.messagesService.getMyTrainer().catchError((e) {
          debugPrint('CoachTab: Error loading my trainer: $e');
          return null;
        }),
      ]);

      if (!mounted) return;

      final profile = results[0] as ProfileModel;
      final currentUserId = profile.user.id;
      final clubs = results[1] as List<MyClubModel>;
      final apiTrainerClients = results[2] as List<DirectChatModel>;
      final apiMyTrainer = results[3] as DirectChatModel?;

      final trainerClubs = clubs
          .where((c) => c.role == 'trainer' || c.role == 'leader')
          .toList();
      final fallbackAssignments = await _loadAssignmentsForClubs(clubs);
      final rosterTrainerClients = _extractOwnTrainerClients(
        currentUserId,
        fallbackAssignments,
      );
      final mergedTrainerClients = _mergeClients(
        primary: apiTrainerClients,
        fallback: rosterTrainerClients,
      );
      final resolvedMyTrainer =
          apiMyTrainer ?? _extractMyTrainer(currentUserId, fallbackAssignments);
      
      setState(() {
        _trainerClients = mergedTrainerClients;
        _myTrainer = resolvedMyTrainer;
        
        _isTrainerRole = trainerClubs.isNotEmpty;
        
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('CoachTab: Unexpected error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, TrainerAssignmentsModel>> _loadAssignmentsForClubs(
    List<MyClubModel> clubs,
  ) async {
    final Map<String, TrainerAssignmentsModel> map = {};
    await Future.wait(clubs.map((club) async {
      try {
        final assignments =
            await ServiceLocator.clubsService.getTrainerAssignments(club.id);
        map[club.id] = assignments;
      } catch (e) {
        debugPrint('CoachTab: Error loading assignments for club ${club.id}: $e');
      }
    }));
    return map;
  }

  List<DirectChatModel> _extractOwnTrainerClients(
    String currentUserId,
    Map<String, TrainerAssignmentsModel> assignmentsByClub,
  ) {
    final Map<String, DirectChatModel> byUserId = {};

    for (final assignments in assignmentsByClub.values) {
      for (final trainer in assignments.trainers) {
        if (trainer.trainerId != currentUserId) continue;
        for (final member in trainer.personalClients) {
          byUserId[member.userId] = DirectChatModel(
            userId: member.userId,
            userName: member.displayName,
          );
        }
      }
    }

    return byUserId.values.toList();
  }

  DirectChatModel? _extractMyTrainer(
    String currentUserId,
    Map<String, TrainerAssignmentsModel> assignmentsByClub,
  ) {
    for (final assignments in assignmentsByClub.values) {
      for (final trainer in assignments.trainers) {
        final isMePersonalClient =
            trainer.personalClients.any((m) => m.userId == currentUserId);
        if (isMePersonalClient) {
          return DirectChatModel(
            userId: trainer.trainerId,
            userName: trainer.trainerName,
          );
        }
      }
    }
    return null;
  }

  List<DirectChatModel> _mergeClients({
    required List<DirectChatModel> primary,
    required List<DirectChatModel> fallback,
  }) {
    final Map<String, DirectChatModel> byUserId = {
      for (final client in fallback) client.userId: client,
    };

    for (final client in primary) {
      byUserId[client.userId] = client;
    }

    final merged = byUserId.values.toList();
    merged.sort((a, b) => a.userName.toLowerCase().compareTo(b.userName.toLowerCase()));
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: l10n.trainerGroupsTab),
                    Tab(text: l10n.trainerPersonalTab),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: l10n.findTrainers,
                onPressed: () => context.push('/trainers'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const TrainerGroupsTab(),
                _buildPersonalTab(l10n, Theme.of(context)),
              ],
            ),
          ),
        ],
      ),
    );
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
    Widget? action;

    if (_isTrainerRole) {
      emptyMessage = l10n.trainerNoPrivateClients;
    } else {
      action = ElevatedButton.icon(
        onPressed: () => context.push('/trainers'),
        icon: const Icon(Icons.search),
        label: Text(l10n.findTrainers),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: _buildEmptyState(emptyMessage, theme, action: action),
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

  Widget _buildEmptyState(String text, ThemeData theme, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
