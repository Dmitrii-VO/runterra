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
  String _surface = 'ROAD';
  String _targetMetric = 'DISTANCE';
  final _targetValueController = TextEditingController();
  String? _targetZone;
  String? _clubId;
  String? _currentClubId;
  List<WorkoutBlock> _blocks = [];
  bool _saving = false;

  static const _types = [
    'RECOVERY',
    'TEMPO',
    'INTERVAL',
    'FARTLEK',
    'LONG_RUN'
  ];
  static const _difficulties = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'PRO'];
  static const _surfaces = ['ROAD', 'TRACK', 'TRAIL'];
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
      _surface = w.surface ?? 'ROAD';
      _targetMetric = w.targetMetric;
      _targetValueController.text = w.targetValue?.toString() ?? '';
      _targetZone = w.targetZone;
      _clubId = w.clubId;
      _blocks = w.blocks != null ? List.from(w.blocks!) : [];
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
      final payload = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _type,
        'difficulty': _difficulty,
        'surface': _surface,
        'targetMetric': _targetMetric,
        'targetValue': targetValue,
        'targetZone': _targetZone,
        'blocks': _blocks.map((b) => b.toJson()).toList(),
      };

      if (isEdit) {
        await ServiceLocator.workoutsService.updateWorkout(
          widget.existing!.id,
          payload,
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
          surface: _surface,
          targetMetric: _targetMetric,
          targetValue: targetValue,
          targetZone: _targetZone,
          blocks: _blocks,
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

  Future<void> _delete() async {
    final workout = widget.existing;
    if (workout == null || _saving) return;

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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.workoutDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await ServiceLocator.workoutsService.deleteWorkout(workout.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workoutDeleted)),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        final msg = e.code == 'workout_in_use' ? l10n.workoutInUse : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
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

            // Surface dropdown
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _surface,
              decoration: InputDecoration(labelText: l10n.workoutSurface),
              items: _surfaces
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_localizeSurface(l10n, s)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _surface = v!),
            ),
            const SizedBox(height: 16),

            // Blocks editor
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.workouts,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton.icon(
                  onPressed: _addBlock,
                  icon: const Icon(Icons.add),
                  label: const Text('Блок'),
                ),
              ],
            ),
            if (_blocks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Нет тренировочных блоков',
                  style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _blocks.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final b = _blocks.removeAt(oldIndex);
                    _blocks.insert(newIndex, b);
                  });
                },
                itemBuilder: (context, index) {
                  final block = _blocks[index];
                  return Card(
                    key: ValueKey('block_$index'),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.drag_handle, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Блок ${index + 1} (x${block.repeatCount})',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _editBlock(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                onPressed: () => setState(() => _blocks.removeAt(index)),
                              ),
                            ],
                          ),
                          ...block.segments.map((s) => _buildSegmentRow(l10n, s)),
                          TextButton.icon(
                            onPressed: () => _addSegment(index),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Сегмент', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

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

            if (isEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    l10n.workoutDeleteAction,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
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

  String _localizeSurface(AppLocalizations l10n, String surface) {
    switch (surface) {
      case 'ROAD':
        return l10n.surfaceRoad;
      case 'TRACK':
        return l10n.surfaceTrack;
      case 'TRAIL':
        return l10n.surfaceTrail;
      default:
        return surface;
    }
  }

  String _localizeSegmentType(AppLocalizations l10n, SegmentType type) {
    switch (type) {
      case SegmentType.warmup:
        return l10n.segmentTypeWarmup;
      case SegmentType.run:
        return l10n.segmentTypeRun;
      case SegmentType.rest:
        return l10n.segmentTypeRest;
      case SegmentType.cooldown:
        return l10n.segmentTypeCooldown;
    }
  }

  String _localizeRecoveryType(AppLocalizations l10n, RecoveryType type) {
    switch (type) {
      case RecoveryType.jog:
        return l10n.recoveryJog;
      case RecoveryType.walk:
        return l10n.recoveryWalk;
      case RecoveryType.stand:
        return l10n.recoveryStand;
    }
  }

  Widget _buildSegmentRow(AppLocalizations l10n, WorkoutSegment s) {
    final duration = s.durationType == DurationType.time
        ? _formatDuration(s.durationValue)
        : '${s.durationValue}m';
    final target = s.targetZone ?? s.targetValue ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: _getSegmentColor(s.type),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_localizeSegmentType(l10n, s.type)}: $duration @ $target',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (s.recoveryType != null) ...[
            const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 2),
            Text(
              _localizeRecoveryType(l10n, s.recoveryType!),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Color _getSegmentColor(SegmentType type) {
    switch (type) {
      case SegmentType.warmup:
        return Colors.orange;
      case SegmentType.run:
        return Colors.green;
      case SegmentType.rest:
        return Colors.blue;
      case SegmentType.cooldown:
        return Colors.lightBlue;
    }
  }

  void _addBlock() {
    setState(() {
      _blocks.add(WorkoutBlock(repeatCount: 1, segments: []));
    });
  }

  Future<void> _editBlock(int index) async {
    final block = _blocks[index];
    final countController = TextEditingController(text: block.repeatCount.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Повторения блока'),
        content: TextField(
          controller: countController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Количество повторов'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(countController.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null && result > 0) {
      setState(() {
        _blocks[index] = WorkoutBlock(repeatCount: result, segments: block.segments);
      });
    }
  }

  Future<void> _addSegment(int blockIndex) async {
    final segment = await _showSegmentDialog();
    if (segment != null) {
      setState(() {
        _blocks[blockIndex].segments.add(segment);
      });
    }
  }

  Future<WorkoutSegment?> _showSegmentDialog([WorkoutSegment? existing]) async {
    final l10n = AppLocalizations.of(context)!;
    SegmentType type = existing?.type ?? SegmentType.run;
    DurationType durationType = existing?.durationType ?? DurationType.time;
    final durationController = TextEditingController(
      text: existing?.durationValue.toString() ?? '',
    );
    final targetValueController = TextEditingController(text: existing?.targetValue ?? '');
    String? targetZone = existing?.targetZone;
    RecoveryType? recoveryType = existing?.recoveryType;
    final instructionsController = TextEditingController(text: existing?.instructions ?? '');
    final mediaUrlController = TextEditingController(text: existing?.mediaUrl ?? '');

    return showDialog<WorkoutSegment>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Добавить сегмент' : 'Изменить сегмент'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SegmentType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Тип'),
                  items: SegmentType.values
                      .map((e) => DropdownMenuItem(value: e, child: Text(_localizeSegmentType(l10n, e))))
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                DropdownButtonFormField<DurationType>(
                  value: durationType,
                  decoration: const InputDecoration(labelText: 'Тип длительности'),
                  items: DurationType.values
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e == DurationType.time ? l10n.durationTime : l10n.durationDistance)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => durationType = v!),
                ),
                TextFormField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: durationType == DurationType.time ? 'Секунды' : 'Метры',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: targetValueController,
                  decoration: const InputDecoration(labelText: 'Цель (Темп/Пульс)', hintText: '4:00 или 160'),
                ),
                DropdownButtonFormField<String?>(
                  value: targetZone,
                  decoration: InputDecoration(labelText: l10n.workoutIntensityZone),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.zoneNone)),
                    const DropdownMenuItem(value: 'Z1', child: Text('Z1')),
                    const DropdownMenuItem(value: 'Z2', child: Text('Z2')),
                    const DropdownMenuItem(value: 'Z3', child: Text('Z3')),
                    const DropdownMenuItem(value: 'Z4', child: Text('Z4')),
                    const DropdownMenuItem(value: 'Z5', child: Text('Z5')),
                  ],
                  onChanged: (v) => setDialogState(() => targetZone = v),
                ),
                DropdownButtonFormField<RecoveryType?>(
                  value: recoveryType,
                  decoration: InputDecoration(labelText: l10n.recoveryType),
                  items: [
                    DropdownMenuItem(value: null, child: Text(l10n.zoneNone)),
                    ...RecoveryType.values.map((e) => DropdownMenuItem(value: e, child: Text(_localizeRecoveryType(l10n, e)))),
                  ],
                  onChanged: (v) => setDialogState(() => recoveryType = v),
                ),
                TextFormField(
                  controller: instructionsController,
                  decoration: const InputDecoration(labelText: 'Инструкции'),
                ),
                TextFormField(
                  controller: mediaUrlController,
                  decoration: InputDecoration(labelText: l10n.mediaUrlInstruction),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () {
                final val = int.tryParse(durationController.text) ?? 0;
                Navigator.pop(
                  ctx,
                  WorkoutSegment(
                    type: type,
                    durationValue: val,
                    durationType: durationType,
                    targetValue: targetValueController.text.isEmpty ? null : targetValueController.text,
                    targetZone: targetZone,
                    recoveryType: recoveryType,
                    instructions: instructionsController.text.isEmpty ? null : instructionsController.text,
                    mediaUrl: mediaUrlController.text.isEmpty ? null : mediaUrlController.text,
                  ),
                );
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
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
