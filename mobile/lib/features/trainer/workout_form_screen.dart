import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout.dart';
import '../../shared/models/my_club_model.dart';
import '../../shared/api/users_service.dart' show ApiException;
import 'block_editor_sheet.dart';

/// Draws a row of colored bars representing workout block intensity.
class _BlockVisualizerPainter extends CustomPainter {
  final List<Map<String, dynamic>> blocks;

  _BlockVisualizerPainter(this.blocks);

  static double _heightFraction(String type) {
    switch (type) {
      case 'warmup': return 0.4;
      case 'work': return 1.0;
      case 'rest': return 0.15;
      case 'cooldown': return 0.35;
      default: return 0.5;
    }
  }

  static Color _color(String type) {
    switch (type) {
      case 'warmup': return Colors.orange;
      case 'work': return Colors.red;
      case 'rest': return Colors.blue;
      case 'cooldown': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (blocks.isEmpty) return;
    final barWidth = size.width / blocks.length;
    for (int i = 0; i < blocks.length; i++) {
      final type = blocks[i]['type'] as String? ?? '';
      final frac = _heightFraction(type);
      final barHeight = size.height * frac;
      final rect = Rect.fromLTWH(
        i * barWidth + 2,
        size.height - barHeight,
        barWidth - 4,
        barHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = _color(type),
      );
    }
  }

  @override
  bool shouldRepaint(_BlockVisualizerPainter old) => old.blocks != blocks;
}

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
  String _type = 'TEMPO';
  String? _clubId;
  String? _currentClubId;
  bool _saving = false;

  // TEMPO / RECOVERY fields
  final _distanceMController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _paceController = TextEditingController(); // "M:SS" format

  // ACCELERATIONS fields
  final _repDistanceMController = TextEditingController();
  final _repCountController = TextEditingController();
  // pace reused from above

  // FUNCTIONAL fields
  final _exerciseNameController = TextEditingController();
  final _exerciseInstructionsController = TextEditingController();
  // repCount reused from above

  static const _types = ['TEMPO', 'RECOVERY', 'ACCELERATIONS', 'FUNCTIONAL'];

  final List<Map<String, dynamic>> _blocks = [];

  @override
  void initState() {
    super.initState();
    final w = widget.existing;
    _currentClubId = ServiceLocator.currentClubService.currentClubId;
    _nameController = TextEditingController(text: w?.name ?? '');
    _descriptionController = TextEditingController(text: w?.description ?? '');

    if (w != null) {
      _type = w.type;
      _clubId = w.clubId;
      if (w.blocks != null) _blocks.addAll(w.blocks!);
      _distanceMController.text = w.distanceM?.toString() ?? '';
      _heartRateController.text = w.heartRateTarget?.toString() ?? '';
      _paceController.text = w.paceTarget != null ? _secondsToPace(w.paceTarget!) : '';
      _repDistanceMController.text = w.repDistanceM?.toString() ?? '';
      _repCountController.text = w.repCount?.toString() ?? '';
      _exerciseNameController.text = w.exerciseName ?? '';
      _exerciseInstructionsController.text = w.exerciseInstructions ?? '';
    }
    _resolveClubIdIfNeeded();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _distanceMController.dispose();
    _heartRateController.dispose();
    _paceController.dispose();
    _repDistanceMController.dispose();
    _repCountController.dispose();
    _exerciseNameController.dispose();
    _exerciseInstructionsController.dispose();
    super.dispose();
  }

  /// Convert "M:SS" string to seconds/km integer. Returns null if invalid.
  int? _paceToSeconds(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length != 2) return null;
    final mins = int.tryParse(parts[0]);
    final secs = int.tryParse(parts[1]);
    if (mins == null || secs == null || secs >= 60) return null;
    return mins * 60 + secs;
  }

  /// Convert seconds/km to "M:SS" display string.
  String _secondsToPace(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();

      // Collect type-specific fields
      int? distanceM;
      int? heartRateTarget;
      int? paceTarget;
      int? repCount;
      int? repDistanceM;
      String? exerciseName;
      String? exerciseInstructions;

      if (_type == 'TEMPO' || _type == 'RECOVERY') {
        distanceM = int.tryParse(_distanceMController.text.trim());
        heartRateTarget = int.tryParse(_heartRateController.text.trim());
        paceTarget = _paceToSeconds(_paceController.text);
      } else if (_type == 'ACCELERATIONS') {
        repDistanceM = int.tryParse(_repDistanceMController.text.trim());
        repCount = int.tryParse(_repCountController.text.trim());
        paceTarget = _paceToSeconds(_paceController.text);
      } else if (_type == 'FUNCTIONAL') {
        exerciseName = _exerciseNameController.text.trim().isEmpty
            ? null
            : _exerciseNameController.text.trim();
        exerciseInstructions = _exerciseInstructionsController.text.trim().isEmpty
            ? null
            : _exerciseInstructionsController.text.trim();
        repCount = int.tryParse(_repCountController.text.trim());
      }

      final isEdit = widget.existing != null;
      if (isEdit) {
        await ServiceLocator.workoutsService.updateWorkout(
          widget.existing!.id,
          {
            'name': name,
            if (description != null) 'description': description,
            'type': _type,
            if (distanceM != null) 'distanceM': distanceM,
            if (heartRateTarget != null) 'heartRateTarget': heartRateTarget,
            if (paceTarget != null) 'paceTarget': paceTarget,
            if (repCount != null) 'repCount': repCount,
            if (repDistanceM != null) 'repDistanceM': repDistanceM,
            if (exerciseName != null) 'exerciseName': exerciseName,
            if (exerciseInstructions != null) 'exerciseInstructions': exerciseInstructions,
            if (_blocks.isNotEmpty) 'blocks': _blocks,
          },
        );
      } else {
        await ServiceLocator.workoutsService.createWorkout(
          clubId: _clubId,
          name: name,
          description: description,
          type: _type,
          distanceM: distanceM,
          heartRateTarget: heartRateTarget,
          paceTarget: paceTarget,
          repCount: repCount,
          repDistanceM: repDistanceM,
          exerciseName: exerciseName,
          exerciseInstructions: exerciseInstructions,
          blocks: _blocks.isNotEmpty ? _blocks : null,
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
          SnackBar(content: Text(AppLocalizations.of(context)!.workoutDeleted)),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
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

      final List<MyClubModel> activeClubs =
          myClubs.where((club) => club.status == 'active').toList();
      final selectedClub = activeClubs.isNotEmpty ? activeClubs.first : myClubs.first;
      await ServiceLocator.currentClubService.setCurrentClubId(selectedClub.id);
      if (!mounted) return;
      setState(() => _currentClubId = selectedClub.id);
    } catch (_) {
      // Keep form usable in personal mode if clubs cannot be resolved.
    }
  }

  String _localizeType(AppLocalizations l10n, String type) {
    switch (type) {
      case 'TEMPO':
        return l10n.typeTempo;
      case 'RECOVERY':
        return l10n.typeRecovery;
      case 'FUNCTIONAL':
        return l10n.typeFunctional;
      case 'ACCELERATIONS':
        return l10n.typeAccelerations;
      default:
        return type;
    }
  }

  /// Validate pace format M:SS
  String? _validatePace(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (_paceToSeconds(value) == null) return 'Format: M:SS (e.g. 4:30)';
    return null;
  }

  Future<void> _openBlockEditor({Map<String, dynamic>? existing, int? index}) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlockEditorSheet(initial: existing),
    );
    if (result == null) return;
    if (!mounted) return;
    setState(() {
      if (index != null) {
        _blocks[index] = result;
      } else {
        _blocks.add(result);
      }
    });
  }

  String _blockTypeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'warmup': return l10n.workoutBlockWarmup;
      case 'work': return l10n.workoutBlockWork;
      case 'rest': return l10n.workoutBlockRest;
      case 'cooldown': return l10n.workoutBlockCooldown;
      default: return type;
    }
  }

  Widget _buildBlocksSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.workoutBlocks, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            TextButton.icon(
              onPressed: _saving ? null : () => _openBlockEditor(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.workoutAddBlock),
            ),
          ],
        ),

        if (_blocks.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Load visualizer
          SizedBox(
            height: 40,
            child: CustomPaint(
              size: const Size(double.infinity, 40),
              painter: _BlockVisualizerPainter(_blocks),
            ),
          ),
          const SizedBox(height: 8),
          // Block list
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _blocks.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = _blocks.removeAt(oldIndex);
                _blocks.insert(newIndex, item);
              });
            },
            itemBuilder: (context, i) {
              final b = _blocks[i];
              final type = b['type'] as String? ?? '';
              final parts = <String>[];
              if (b['durationMin'] != null) parts.add('${b['durationMin']} min');
              if (b['distanceM'] != null) parts.add('${b['distanceM']} m');
              return ListTile(
                key: ValueKey(i),
                dense: true,
                leading: const Icon(Icons.drag_handle, size: 20),
                title: Text(_blockTypeLabel(l10n, type)),
                subtitle: parts.isNotEmpty ? Text(parts.join(' · ')) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _openBlockEditor(existing: b, index: i),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => setState(() => _blocks.removeAt(i)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTypeSpecificFields(AppLocalizations l10n) {
    switch (_type) {
      case 'TEMPO':
      case 'RECOVERY':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _distanceMController,
              decoration: InputDecoration(labelText: l10n.workoutDistanceM),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heartRateController,
              decoration: InputDecoration(labelText: l10n.workoutHeartRate),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paceController,
              decoration: InputDecoration(
                labelText: l10n.workoutPaceTarget,
                hintText: '4:30',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              validator: _validatePace,
            ),
          ],
        );

      case 'ACCELERATIONS':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _repDistanceMController,
              decoration: InputDecoration(labelText: l10n.workoutRepDistance),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _repCountController,
              decoration: InputDecoration(labelText: l10n.workoutRepCount),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paceController,
              decoration: InputDecoration(
                labelText: l10n.workoutPaceTarget,
                hintText: '4:30',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              validator: _validatePace,
            ),
          ],
        );

      case 'FUNCTIONAL':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _exerciseNameController,
              decoration: InputDecoration(labelText: l10n.workoutExercise),
              maxLength: 200,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _exerciseInstructionsController,
              decoration: InputDecoration(labelText: l10n.workoutInstructions),
              maxLines: 4,
              maxLength: 5000,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _repCountController,
              decoration: InputDecoration(labelText: l10n.workoutRepCount),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  final n = int.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Enter a positive number';
                }
                return null;
              },
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
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

            // Description (optional)
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

            // Club selector (create only)
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
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 24),

            // Type-specific fields
            _buildTypeSpecificFields(l10n),
            const SizedBox(height: 24),

            // Blocks section
            _buildBlocksSection(l10n),
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
}
