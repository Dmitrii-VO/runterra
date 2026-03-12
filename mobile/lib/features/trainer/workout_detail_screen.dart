import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/auth/auth_service.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout.dart';
import '../../shared/models/assigned_workout.dart';

/// Read-only workout detail screen.
/// Accepts any Workout (or AssignedWorkout) via constructor.
/// Shows edit button only when current user is the author.
class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final profile = await ServiceLocator.usersService.getProfile();
      if (mounted) setState(() => _currentUserId = profile.user.id);
    } catch (_) {
      // If fetch fails, fall back to Firebase UID (edit button may not show)
      if (mounted) {
        setState(() => _currentUserId = AuthService.instance.currentUser?.uid);
      }
    }
  }

  bool get _canEdit =>
      _currentUserId != null && widget.workout.authorId == _currentUserId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final w = widget.workout;
    final assigned = w is AssignedWorkout ? w : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(w.name),
        actions: [
          if (_canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.workoutEdit,
              onPressed: () async {
                final result = await context.push('/workouts/${w.id}/edit', extra: w);
                if (result == true && context.mounted) context.pop(true);
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Type + difficulty chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Chip(label: Text(_localizeType(l10n, w.type))),
              Chip(label: Text(_localizeDifficulty(l10n, w.difficulty))),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          if (w.description != null && w.description!.isNotEmpty) ...[
            Text(w.description!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],

          // Assigned-workout info
          if (assigned != null) ...[
            _InfoRow(
              icon: Icons.person_outline,
              label: l10n.workoutAssignedBy(assigned.trainerName),
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: DateFormat('d MMM yyyy').format(assigned.assignedAt),
            ),
            if (assigned.note != null && assigned.note!.isNotEmpty)
              _InfoRow(icon: Icons.notes_outlined, label: assigned.note!),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
          ],

          // Type-specific fields
          ..._typeSpecificWidgets(context, l10n, w),

          // Blocks timeline
          if (w.blocks != null && w.blocks!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.workoutBlocks, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...w.blocks!.asMap().entries.map((entry) {
              return _BlockRow(index: entry.key, block: entry.value, l10n: l10n);
            }),
          ],
        ],
      ),
    );
  }

  List<Widget> _typeSpecificWidgets(
      BuildContext context, AppLocalizations l10n, Workout w) {
    final widgets = <Widget>[];
    if (w.distanceM != null) {
      widgets.add(_InfoRow(
        icon: Icons.straighten_outlined,
        label: '${(w.distanceM! / 1000).toStringAsFixed(1)} km',
      ));
    }
    if (w.paceTarget != null) {
      final min = w.paceTarget! ~/ 60;
      final sec = w.paceTarget! % 60;
      widgets.add(_InfoRow(
        icon: Icons.speed_outlined,
        label: 'Pace: $min:${sec.toString().padLeft(2, '0')} /km',
      ));
    }
    if (w.heartRateTarget != null) {
      widgets.add(_InfoRow(
        icon: Icons.favorite_border,
        label: 'HR: ${w.heartRateTarget} bpm',
      ));
    }
    if (w.repCount != null) {
      widgets.add(_InfoRow(
        icon: Icons.repeat_outlined,
        label: '${w.repCount} reps'
            '${w.repDistanceM != null ? ' × ${w.repDistanceM} m' : ''}',
      ));
    }
    if (w.exerciseName != null) {
      widgets.add(_InfoRow(icon: Icons.fitness_center_outlined, label: w.exerciseName!));
    }
    if (w.exerciseInstructions != null && w.exerciseInstructions!.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(w.exerciseInstructions!,
            style: Theme.of(context).textTheme.bodySmall),
      ));
    }
    return widgets;
  }

  String _localizeType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'RECOVERY': return l10n.typeRecovery;
      case 'TEMPO': return l10n.typeTempo;
      case 'FUNCTIONAL': return l10n.typeFunctional;
      case 'ACCELERATIONS': return l10n.typeAccelerations;
      default: return type;
    }
  }

  String _localizeDifficulty(AppLocalizations l10n, String d) {
    switch (d) {
      case 'BEGINNER': return l10n.difficultyBeginner;
      case 'INTERMEDIATE': return l10n.difficultyIntermediate;
      case 'ADVANCED': return l10n.difficultyAdvanced;
      default: return d;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _BlockRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> block;
  final AppLocalizations l10n;

  const _BlockRow({required this.index, required this.block, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final type = block['type'] as String? ?? '';
    final durationMin = block['durationMin'] as int?;
    final distanceM = block['distanceM'] as int?;
    final note = block['note'] as String?;

    final color = _blockColor(type);
    final label = _blockLabel(type);

    final details = <String>[];
    if (durationMin != null) details.add('$durationMin min');
    if (distanceM != null) details.add('$distanceM m');
    if (note != null && note.isNotEmpty) details.add(note);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          if (details.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(details.join(' · '),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Color _blockColor(String type) {
    switch (type) {
      case 'warmup': return Colors.orange;
      case 'work': return Colors.red;
      case 'rest': return Colors.blue;
      case 'cooldown': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _blockLabel(String type) {
    switch (type) {
      case 'warmup': return l10n.workoutBlockWarmup;
      case 'work': return l10n.workoutBlockWork;
      case 'rest': return l10n.workoutBlockRest;
      case 'cooldown': return l10n.workoutBlockCooldown;
      default: return type;
    }
  }
}
