import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout.dart';
import '../../shared/models/assigned_workout.dart';
import '../../shared/models/my_club_model.dart';
import '../../shared/models/direct_chat_model.dart';
import '../../shared/api/users_service.dart' show ApiException;
import 'package:go_router/go_router.dart';

/// Screen showing workout templates (personal, club, and assigned by trainer)
class WorkoutsListScreen extends StatefulWidget {
  const WorkoutsListScreen({super.key});

  @override
  State<WorkoutsListScreen> createState() => _WorkoutsListScreenState();
}

class _WorkoutsListScreenState extends State<WorkoutsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Workout>> _personalFuture;
  late Future<List<Workout>> _clubFuture;
  late Future<List<AssignedWorkout>> _assignedFuture;
  String? _currentClubId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _personalFuture = _loadPersonalWorkouts();
    _assignedFuture = ServiceLocator.workoutsService.getAssignedWorkouts();
    _currentClubId = ServiceLocator.currentClubService.currentClubId;
    _clubFuture = Future.value(<Workout>[]);
    _loadClubWithRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _personalFuture = _loadPersonalWorkouts();
      _assignedFuture = ServiceLocator.workoutsService.getAssignedWorkouts();
    });
    _loadClubWithRefresh();
  }

  Future<void> _loadClubWithRefresh() async {
    final clubId = await _resolveClubId();
    if (mounted) {
      setState(() {
        _currentClubId = clubId;
        _clubFuture = _loadClubWorkouts();
      });
    }
  }

  Future<String?> _resolveClubId() async {
    final cachedClubId = ServiceLocator.currentClubService.currentClubId;

    try {
      final myClubs = await ServiceLocator.clubsService.getMyClubs();
      if (myClubs.isEmpty) {
        return (cachedClubId != null && cachedClubId.isNotEmpty) ? cachedClubId : null;
      }

      final myClubIds = myClubs.map((club) => club.id).toSet();
      if (cachedClubId != null &&
          cachedClubId.isNotEmpty &&
          myClubIds.contains(cachedClubId)) {
        return cachedClubId;
      }

      final List<MyClubModel> activeClubs = myClubs
          .where((club) => club.status == 'active')
          .toList();
      final selectedClub = activeClubs.isNotEmpty ? activeClubs.first : myClubs.first;
      await ServiceLocator.currentClubService.setCurrentClubId(selectedClub.id);
      return selectedClub.id;
    } catch (_) {
      return (cachedClubId != null && cachedClubId.isNotEmpty) ? cachedClubId : null;
    }
  }

  Future<List<Workout>> _loadClubWorkouts() async {
    final myClubIds = await _loadMyClubIds();
    final effectiveClubId = (_currentClubId != null && _currentClubId!.isNotEmpty)
        ? _currentClubId!
        : (myClubIds.isNotEmpty ? myClubIds.first : null);

    if (effectiveClubId == null || effectiveClubId.isEmpty) {
      return <Workout>[];
    }

    final filtered = await ServiceLocator.workoutsService.getWorkouts(clubId: effectiveClubId);
    if (filtered.isNotEmpty) return filtered;

    // Fallback for environments where server-side clubId filtering may lag/misbehave.
    final all = await ServiceLocator.workoutsService.getWorkouts();
    final clubScoped = all
        .where((workout) => workout.clubId != null && workout.clubId!.isNotEmpty)
        .toList();

    if (myClubIds.isNotEmpty) {
      final myClubWorkouts = clubScoped
          .where((workout) => myClubIds.contains(workout.clubId))
          .toList();
      if (myClubWorkouts.isNotEmpty) return myClubWorkouts;
    }

    final exactClubWorkouts =
        clubScoped.where((workout) => workout.clubId == effectiveClubId).toList();
    if (exactClubWorkouts.isNotEmpty) return exactClubWorkouts;

    return clubScoped;
  }

  Future<List<Workout>> _loadPersonalWorkouts() async {
    final all = await ServiceLocator.workoutsService.getWorkouts();
    return all.where((workout) => workout.clubId == null || workout.clubId!.isEmpty).toList();
  }

  Future<Set<String>> _loadMyClubIds() async {
    try {
      final myClubs = await ServiceLocator.clubsService.getMyClubs();
      return myClubs.map((club) => club.id).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> _deleteWorkout(Workout workout) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteAccountConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ServiceLocator.workoutsService.deleteWorkout(workout.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workoutDeleted)),
        );
        _refresh();
      }
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.code == 'workout_in_use' ? l10n.workoutInUse : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  /// Show bottom sheet to pick a client and assign this workout to them
  Future<void> _showAssignDialog(Workout workout) async {
    final l10n = AppLocalizations.of(context)!;
    final List<DirectChatModel> clients;

    try {
      clients = await ServiceLocator.messagesService.getTrainerClients();
    } on ApiException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workoutAssignError)),
        );
      }
      return;
    }

    if (!mounted) return;

    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.trainerNoPrivateClients)),
      );
      return;
    }

    final selected = await showModalBottomSheet<DirectChatModel>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.workoutAssignSelectClient,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: clients.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(clients[i].userName),
                onTap: () => Navigator.of(ctx).pop(clients[i]),
              ),
            ),
          ),
        ],
      ),
    );

    if (selected == null || !mounted) return;

    try {
      await ServiceLocator.workoutsService.assignWorkout(workout.id, selected.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workoutAssigned)),
        );
      }
    } on ApiException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workoutAssignError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workouts),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.myWorkouts),
            Tab(text: l10n.workoutClub),
            Tab(text: l10n.workoutFromTrainer),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Personal workouts tab
          _buildPersonalList(l10n),
          // Club workouts tab
          _buildWorkoutsList(_clubFuture, l10n, showAssign: false),
          // Assigned-by-trainer tab
          _buildAssignedList(l10n),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push('/workouts/create');
          if (result == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Personal workouts tab — shows assign button as trailing action
  Widget _buildPersonalList(AppLocalizations l10n) {
    return FutureBuilder<List<Workout>>(
      future: _personalFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.errorLoadTitle),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _refresh, child: Text(l10n.retry)),
              ],
            ),
          );
        }

        final workouts = snapshot.data ?? [];
        if (workouts.isEmpty) {
          return Center(child: Text(l10n.workoutEmpty));
        }

        return ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final w = workouts[index];
            return Dismissible(
              key: Key(w.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                await _deleteWorkout(w);
                return false;
              },
              child: ListTile(
                title: Text(w.name),
                subtitle: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(_localizeType(l10n, w.type)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add_outlined),
                  tooltip: l10n.workoutAssignToClient,
                  onPressed: () => _showAssignDialog(w),
                ),
                onTap: () async {
                  final result = await context.push('/workouts/${w.id}/edit', extra: w);
                  if (result == true) _refresh();
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Club workouts tab (no assign button)
  Widget _buildWorkoutsList(
      Future<List<Workout>> future, AppLocalizations l10n, {required bool showAssign}) {
    return FutureBuilder<List<Workout>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.errorLoadTitle),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _refresh, child: Text(l10n.retry)),
              ],
            ),
          );
        }

        final workouts = snapshot.data ?? [];
        if (workouts.isEmpty) {
          return Center(child: Text(l10n.workoutEmpty));
        }

        return ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final w = workouts[index];
            return Dismissible(
              key: Key(w.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                await _deleteWorkout(w);
                return false;
              },
              child: ListTile(
                title: Text(w.name),
                subtitle: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(_localizeType(l10n, w.type)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                onTap: () async {
                  final result = await context.push('/workouts/${w.id}/edit', extra: w);
                  if (result == true) _refresh();
                },
              ),
            );
          },
        );
      },
    );
  }

  /// "From Trainer" tab — shows assigned workouts with trainer name
  Widget _buildAssignedList(AppLocalizations l10n) {
    return FutureBuilder<List<AssignedWorkout>>(
      future: _assignedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.errorLoadTitle),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _refresh, child: Text(l10n.retry)),
              ],
            ),
          );
        }

        final workouts = snapshot.data ?? [];
        if (workouts.isEmpty) {
          return Center(child: Text(l10n.workoutAssignedEmpty));
        }

        return ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final w = workouts[index];
            return ListTile(
              title: Text(w.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(_localizeType(l10n, w.type)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  Text(
                    l10n.workoutAssignedBy(w.trainerName),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (w.note != null && w.note!.isNotEmpty)
                    Text(
                      w.note!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              onTap: () => context.push('/workouts/${w.id}/edit', extra: w),
            );
          },
        );
      },
    );
  }

  String _localizeType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'RECOVERY':
        return l10n.typeRecovery;
      case 'TEMPO':
        return l10n.typeTempo;
      case 'FUNCTIONAL':
        return l10n.typeFunctional;
      case 'ACCELERATIONS':
        return l10n.typeAccelerations;
      default:
        return type;
    }
  }
}
