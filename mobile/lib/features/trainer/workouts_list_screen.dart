import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout.dart';
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
    _currentClubId = ServiceLocator.currentClubService.currentClubId;
    _personalFuture = ServiceLocator.workoutsService.getWorkouts();
    _clubFuture = _loadClubWorkouts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _personalFuture = ServiceLocator.workoutsService.getWorkouts();
      _currentClubId = ServiceLocator.currentClubService.currentClubId;
      _clubFuture = _loadClubWorkouts();
    });
  }

  Future<List<Workout>> _loadClubWorkouts() {
    final clubId = _currentClubId;
    if (clubId == null || clubId.isEmpty) {
      return Future.value(<Workout>[]);
    }
    return ServiceLocator.workoutsService.getWorkouts(clubId: clubId);
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
          (_currentClubId == null || _currentClubId!.isEmpty)
              ? Center(child: Text(l10n.profileMyClubsEmpty))
              : _buildWorkoutsList(_clubFuture, l10n),
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
                    Chip(
                      label: Text(_localizeDifficulty(l10n, w.difficulty)),
                      visualDensity: VisualDensity.compact,
                    ),
                    Chip(
                      label: Text(_localizeTargetMetric(l10n, w.targetMetric)),
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
      case 'INTERVAL':
        return l10n.typeInterval;
      case 'FARTLEK':
        return l10n.typeFartlek;
      case 'LONG_RUN':
        return l10n.typeLongRun;
      default:
        return type;
    }
  }

  String _localizeDifficulty(AppLocalizations l10n, String diff) {
    switch (diff) {
      case 'BEGINNER':
        return l10n.diffBeginner;
      case 'INTERMEDIATE':
        return l10n.diffIntermediate;
      case 'ADVANCED':
        return l10n.diffAdvanced;
      case 'PRO':
        return l10n.diffPro;
      default:
        return diff;
    }
  }

  String _localizeTargetMetric(AppLocalizations l10n, String metric) {
    switch (metric) {
      case 'DISTANCE':
        return l10n.metricDistance;
      case 'TIME':
        return l10n.metricTime;
      case 'PACE':
        return l10n.metricPace;
      default:
        return metric;
    }
  }
}
