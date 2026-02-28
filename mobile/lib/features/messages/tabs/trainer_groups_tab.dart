import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/my_club_model.dart';
import '../../../shared/models/trainer_group_model.dart';

class TrainerGroupsTab extends StatefulWidget {
  const TrainerGroupsTab({super.key});

  @override
  State<TrainerGroupsTab> createState() => TrainerGroupsTabState();
}

class TrainerGroupsTabState extends State<TrainerGroupsTab> {
  List<MyClubModel>? _clubs;
  Map<String, List<TrainerGroupModel>> _clubGroups = {};
  String? _currentUserId;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ServiceLocator.usersService.getProfile();
      final clubs = await ServiceLocator.clubsService.getMyClubs();
      
      final Map<String, List<TrainerGroupModel>> clubGroups = {};
      
      // Load groups for each club
      await Future.wait(clubs.map((club) async {
        try {
          final groups = await ServiceLocator.trainerService.getGroups(club.id);
          if (groups.isNotEmpty) {
            clubGroups[club.id] = groups;
          }
        } catch (e) {
          debugPrint('Error loading groups for club ${club.id}: $e');
        }
      }));

      if (mounted) {
        setState(() {
          _currentUserId = profile.user.id;
          _clubs = clubs;
          _clubGroups = clubGroups;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteGroup(TrainerGroupModel group) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutDeleteConfirm),
        content: Text(group.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.workoutDeleteAction, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ServiceLocator.trainerService.deleteGroup(group.id);
        loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneric(e.toString()))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.errorGeneric(_error!)),
            ElevatedButton(
              onPressed: loadData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final allGroups = _clubGroups.values.expand((e) => e).toList();
    if (allGroups.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.6,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.trainerNoGroups,
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Sort all groups by date
    allGroups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView.builder(
        itemCount: allGroups.length,
        itemBuilder: (context, index) {
          final group = allGroups[index];
          final club = _clubs?.firstWhere(
            (c) => c.id == group.clubId,
            orElse: () => MyClubModel(
              id: group.clubId,
              name: 'Unknown',
              cityId: '',
              status: '',
              role: '',
              joinedAt: DateTime.now(),
            ),
          );
          final clubName = club?.name ?? 'Unknown';
          final isTrainer = group.trainerId == _currentUserId;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: const Icon(Icons.groups),
            ),
            title: Text(group.name),
            subtitle: Text(clubName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group.memberCount}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (isTrainer)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await context.push<bool>(
                          '/trainer/groups/create?clubId=${group.clubId}&clubName=${Uri.encodeComponent(clubName)}',
                          extra: group,
                        );
                        if (result == true) loadData();
                      } else if (value == 'delete') {
                        _deleteGroup(group);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 20),
                            const SizedBox(width: 8),
                            Text(l10n.editProfileEditAction),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(l10n.workoutDeleteAction, style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            onTap: () {
              context.push(
                '/chat/trainer_group/${group.id}?title=${Uri.encodeComponent(group.name)}',
              );
            },
          );
        },
      ),
    );
  }
}
