import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout.dart';
import '../../shared/models/my_club_model.dart';
import '../../shared/api/users_service.dart' show ApiException;

/// Screen to create or edit a workout template
class WorkoutFormScreen extends StatefulWidget {
  final Workout? existing;

  const WorkoutFormScreen({super.key, this.existing});

  @override
  State<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends State<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _type = 'RECOVERY';
  String _difficulty = 'BEGINNER';
  String _targetMetric = 'DISTANCE';
  final _targetValueController = TextEditingController();
  String? _targetZone;
  String? _clubId;
  String? _currentClubId;
  bool _saving = false;

  static const _types = [
    'RECOVERY',
    'TEMPO',
    'INTERVAL',
    'FARTLEK',
    'LONG_RUN'
  ];
  static const _difficulties = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'PRO'];
  static const _metrics = ['DISTANCE', 'TIME', 'PACE'];

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    _currentClubId = ServiceLocator.currentClubService.currentClubId;
    _nameController = TextEditingController(text: w?.name ?? '');
    _descriptionController =
        TextEditingController(text: w?.description ?? '');
    if (w != null) {
      _type = w.type;
      _difficulty = w.difficulty;
      _targetMetric = w.targetMetric;
      _targetValueController.text = w.targetValue?.toString() ?? '';
      _targetZone = w.targetZone;
      _clubId = w.clubId;
    } else {
      _clubId = null;
    }
    _resolveClubIdIfNeeded();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final targetValue = int.tryParse(_targetValueController.text.trim());

    setState(() => _saving = true);
    try {
      final isEdit = widget.existing != null;
      if (isEdit) {
        await ServiceLocator.workoutsService.updateWorkout(
          widget.existing!.id,
          {
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'type': _type,
            'difficulty': _difficulty,
            'targetMetric': _targetMetric,
            'targetValue': targetValue,
            'targetZone': _targetZone,
          },
        );
      } else {
        await ServiceLocator.workoutsService.createWorkout(
          clubId: _clubId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          type: _type,
          difficulty: _difficulty,
          targetMetric: _targetMetric,
          targetValue: targetValue,
          targetZone: _targetZone,
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workoutSaved)),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resolveClubIdIfNeeded() async {
    final cachedClubId = _currentClubId;
    try {
      final myClubs = await ServiceLocator.clubsService.getMyClubs();
      if (myClubs.isEmpty) return;

      final myClubIds = myClubs.map((club) => club.id).toSet();
      if (cachedClubId != null &&
          cachedClubId.isNotEmpty &&
          myClubIds.contains(cachedClubId)) {
        return;
      }

      final List<MyClubModel> activeClubs = myClubs
          .where((club) => club.status == 'active')
          .toList();
      final selectedClub = activeClubs.isNotEmpty ? activeClubs.first : myClubs.first;
      await ServiceLocator.currentClubService.setCurrentClubId(selectedClub.id);
      if (!mounted) return;
      setState(() => _currentClubId = selectedClub.id);
    } catch (_) {
      // Keep form usable in personal mode if clubs cannot be resolved.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? l10n.editWorkout : l10n.createWorkout),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.workoutName),
              maxLength: 200,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.eventCreateNameRequired : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.workoutDescription,
                hintText: l10n.workoutDescriptionHint,
              ),
              maxLines: 4,
              maxLength: 5000,
            ),
            const SizedBox(height: 16),

            if (isEdit)
              InputDecorator(
                decoration: InputDecoration(labelText: l10n.workoutClub),
                child: Text(
                  _clubId == null
                      ? l10n.workoutPersonal
                      : l10n.eventCreateOrganizerClub,
                ),
              )
            else
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _clubId == null ? 'personal' : 'club',
                decoration: InputDecoration(labelText: l10n.workoutClub),
                items: [
                  DropdownMenuItem(
                    value: 'personal',
                    child: Text(l10n.workoutPersonal),
                  ),
                  if (_currentClubId != null && _currentClubId!.isNotEmpty)
                    DropdownMenuItem(
                      value: 'club',
                      child: Text(l10n.eventCreateOrganizerClub),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (value) {
                        setState(() {
                          _clubId = value == 'club' ? _currentClubId : null;
                        });
                      },
              ),
            const SizedBox(height: 16),

            // Type dropdown
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _type,
              decoration: InputDecoration(labelText: l10n.workoutType),
              items: _types
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_localizeType(l10n, t)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 16),

            // Difficulty dropdown
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _difficulty,
              decoration: InputDecoration(labelText: l10n.workoutDifficulty),
              items: _difficulties
                  .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(_localizeDifficulty(l10n, d)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _difficulty = v!),
            ),
            const SizedBox(height: 16),

            // Target metric dropdown
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _targetMetric,
              decoration: InputDecoration(labelText: l10n.workoutTargetMetric),
              items: _metrics
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(_localizeMetric(l10n, m)),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _targetMetric = v!;
                  _targetValueController.clear();
                });
              },
            ),
            const SizedBox(height: 16),

            // Target value input
            TextFormField(
              controller: _targetValueController,
              decoration: InputDecoration(
                labelText: _getTargetValueLabel(l10n, _targetMetric),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Invalid value';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Target zone dropdown
            DropdownButtonFormField<String?>(
              // ignore: deprecated_member_use
              value: _targetZone,
              decoration: InputDecoration(labelText: l10n.workoutTargetZone),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.zoneNone)),
                DropdownMenuItem(value: 'Z1', child: Text(l10n.zoneZ1)),
                DropdownMenuItem(value: 'Z2', child: Text(l10n.zoneZ2)),
                DropdownMenuItem(value: 'Z3', child: Text(l10n.zoneZ3)),
                DropdownMenuItem(value: 'Z4', child: Text(l10n.zoneZ4)),
                DropdownMenuItem(value: 'Z5', child: Text(l10n.zoneZ5)),
              ],
              onChanged: (v) => setState(() => _targetZone = v),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.editProfileSave),
              ),
            ),
          ],
        ),
      ),
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

  String _localizeMetric(AppLocalizations l10n, String metric) {
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

  String _getTargetValueLabel(AppLocalizations l10n, String metric) {
    switch (metric) {
      case 'DISTANCE':
        return l10n.workoutTargetValueDistance;
      case 'TIME':
        return l10n.workoutTargetValueTime;
      case 'PACE':
        return l10n.workoutTargetValuePace;
      default:
        return 'Value';
    }
  }
}
