import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout.dart';
import '../../shared/models/my_club_model.dart';
import '../../shared/api/users_service.dart' show ApiException;
import 'package:go_router/go_router.dart';

/// Screen showing workout templates (personal and club)
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
  String? _currentClubId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _personalFuture = _loadPersonalWorkouts();
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

    // Last-resort fallback: show any club-scoped templates authored/visible to user.
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Personal workouts tab
          _buildWorkoutsList(_personalFuture, l10n),
          // Club workouts tab
          _buildWorkoutsList(_clubFuture, l10n),
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

  Widget _buildWorkoutsList(
      Future<List<Workout>> future, AppLocalizations l10n) {
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
                ElevatedButton(
                  onPressed: _refresh,
                  child: Text(l10n.retry),
                ),
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
                return false; // We handle refresh ourselves
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
                  final result =
                      await context.push('/workouts/${w.id}/edit', extra: w);
                  if (result == true) _refresh();
                },
              ),
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
