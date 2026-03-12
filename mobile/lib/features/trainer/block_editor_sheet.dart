import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Modal bottom sheet for creating or editing a single workout block.
/// Returns a Map<String, dynamic> on save, or null if dismissed.
class BlockEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const BlockEditorSheet({super.key, this.initial});

  @override
  State<BlockEditorSheet> createState() => _BlockEditorSheetState();
}

class _BlockEditorSheetState extends State<BlockEditorSheet> {
  static const _blockTypes = ['warmup', 'work', 'rest', 'cooldown'];

  late String _type;
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _paceController = TextEditingController();
  final _hrController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final b = widget.initial;
    _type = (b?['type'] as String?) ?? 'work';
    _durationController.text = (b?['durationMin'] as int?)?.toString() ?? '';
    _distanceController.text = (b?['distanceM'] as int?)?.toString() ?? '';
    if (b?['paceTarget'] != null) {
      final s = b!['paceTarget'] as int;
      _paceController.text = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    }
    _hrController.text = (b?['heartRate'] as int?)?.toString() ?? '';
    _noteController.text = (b?['note'] as String?) ?? '';
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _paceController.dispose();
    _hrController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? _parsePace(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final parts = t.split(':');
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]);
    final s = int.tryParse(parts[1]);
    if (m == null || s == null || s >= 60) return null;
    return m * 60 + s;
  }

  void _save() {
    final block = <String, dynamic>{'type': _type};
    final dur = int.tryParse(_durationController.text.trim());
    final dist = int.tryParse(_distanceController.text.trim());
    final pace = _parsePace(_paceController.text);
    final hr = int.tryParse(_hrController.text.trim());
    final note = _noteController.text.trim();

    if (dur != null && dur > 0) block['durationMin'] = dur;
    if (dist != null && dist > 0) block['distanceM'] = dist;
    if (pace != null) block['paceTarget'] = pace;
    if (hr != null && hr > 0) block['heartRate'] = hr;
    if (note.isNotEmpty) block['note'] = note;

    Navigator.of(context).pop(block);
  }

  String _typeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'warmup': return l10n.workoutBlockWarmup;
      case 'work': return l10n.workoutBlockWork;
      case 'rest': return l10n.workoutBlockRest;
      case 'cooldown': return l10n.workoutBlockCooldown;
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.workoutAddBlock,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // Block type
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Phase'),
              items: _blockTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_typeLabel(l10n, t)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: 12),

            // Duration + Distance side by side
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: l10n.workoutBlockDurationMin,
                      hintText: '10',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _distanceController,
                    decoration: const InputDecoration(
                      labelText: 'Distance (m)',
                      hintText: '1000',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pace + HR side by side
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paceController,
                    decoration: const InputDecoration(
                      labelText: 'Pace (min/km)',
                      hintText: '5:30',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _hrController,
                    decoration: const InputDecoration(
                      labelText: 'HR (bpm)',
                      hintText: '150',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(labelText: l10n.workoutBlockNote),
              maxLength: 500,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.editProfileSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
