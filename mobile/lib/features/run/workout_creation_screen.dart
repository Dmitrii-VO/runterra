import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout_plan.dart';
import '../../l10n/app_localizations.dart';

/// 4-step wizard for creating a personal workout plan
class WorkoutCreationScreen extends StatefulWidget {
  const WorkoutCreationScreen({super.key});

  @override
  State<WorkoutCreationScreen> createState() => _WorkoutCreationScreenState();
}

class _WorkoutCreationScreenState extends State<WorkoutCreationScreen> {
  int _step = 0; // 0=type, 1=params, 2=schedule, 3=saved

  WorkoutPlanType? _selectedType;
  WorkoutPlan? _savedPlan;

  // Step 1 → Step 2
  void _onTypeSelected(WorkoutPlanType type) {
    setState(() {
      _selectedType = type;
      _step = 1;
    });
  }

  // Step 2 → Step 3
  void _onParamsDone(WorkoutPlan plan) {
    setState(() {
      _savedPlan = plan;
      _step = 2;
    });
  }

  // Step 3 → Step 4 (save workout)
  Future<void> _onScheduleDone(DateTime? scheduledAt) async {
    final plan = scheduledAt != null
        ? _savedPlan!.copyWith(scheduledAt: scheduledAt)
        : _savedPlan!;

    try {
      final created = await ServiceLocator.workoutPlanService.createWorkout(plan);
      setState(() {
        _savedPlan = created;
        _step = 3;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutCreationTitle),
        leading: _step > 0 && _step < 3
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: IndexedStack(
        index: _step,
        children: [
          _TypeStep(onSelected: _onTypeSelected),
          if (_selectedType != null)
            _ParamsStep(type: _selectedType!, onDone: _onParamsDone)
          else
            const SizedBox.shrink(),
          _ScheduleStep(onDone: _onScheduleDone),
          if (_savedPlan != null)
            _SavedStep(plan: _savedPlan!)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

// ── Step 0: Type selection ───────────────────────────────────────────────────

class _TypeStep extends StatelessWidget {
  final void Function(WorkoutPlanType) onSelected;

  const _TypeStep({required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final types = [
      (WorkoutPlanType.easyRun, Icons.directions_run, l10n.workoutTypeEasyRun),
      (WorkoutPlanType.longRun, Icons.timer, l10n.workoutTypeLongRun),
      (WorkoutPlanType.intervals, Icons.repeat, l10n.workoutTypeIntervals),
      (WorkoutPlanType.progression, Icons.trending_up, l10n.workoutTypeProgression),
      (WorkoutPlanType.recovery, Icons.favorite, l10n.workoutTypeRecovery),
      (WorkoutPlanType.hillRun, Icons.terrain, l10n.workoutTypeHillRun),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.workoutTypeSelectTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...types.map(
          (t) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(t.$2, color: Theme.of(context).colorScheme.primary),
              title: Text(t.$3),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onSelected(t.$1),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 1: Parameters ───────────────────────────────────────────────────────

class _ParamsStep extends StatefulWidget {
  final WorkoutPlanType type;
  final void Function(WorkoutPlan) onDone;

  const _ParamsStep({required this.type, required this.onDone});

  @override
  State<_ParamsStep> createState() => _ParamsStepState();
}

class _ParamsStepState extends State<_ParamsStep> {
  // Common fields
  final _durationCtrl = TextEditingController();
  final _distanceCtrl = TextEditingController();
  final _paceCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();

  // Intervals
  final _intervalDistCtrl = TextEditingController();
  final _repsCtrl = TextEditingController(text: '1');
  final _restMinCtrl = TextEditingController();
  final _restMCtrl = TextEditingController();
  final _recoveryMinCtrl = TextEditingController();
  final _recoveryMCtrl = TextEditingController();
  final _warmupCtrl = TextEditingController();

  // Progression segments
  List<_SegmentControllers> _segments = [];

  // HillRun
  final _elevationCtrl = TextEditingController();

  // Cooldown
  CooldownConfig? _cooldown;

  @override
  void initState() {
    super.initState();
    if (widget.type == WorkoutPlanType.progression) {
      _segments = [_SegmentControllers()];
    }
  }

  @override
  void dispose() {
    _durationCtrl.dispose();
    _distanceCtrl.dispose();
    _paceCtrl.dispose();
    _hrCtrl.dispose();
    _intervalDistCtrl.dispose();
    _repsCtrl.dispose();
    _restMinCtrl.dispose();
    _restMCtrl.dispose();
    _recoveryMinCtrl.dispose();
    _recoveryMCtrl.dispose();
    _warmupCtrl.dispose();
    _elevationCtrl.dispose();
    for (final s in _segments) {
      s.dispose();
    }
    super.dispose();
  }

  int? _parseInt(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : int.tryParse(v);
  }

  int? _parsePace(String text) {
    // Accepts "5:30" or "5.5" or "330" (seconds)
    final t = text.trim();
    if (t.isEmpty) return null;
    if (t.contains(':')) {
      final parts = t.split(':');
      if (parts.length == 2) {
        final min = int.tryParse(parts[0]);
        final sec = int.tryParse(parts[1]);
        if (min != null && sec != null) return min * 60 + sec;
      }
    }
    final d = double.tryParse(t);
    if (d != null) return (d * 60).round();
    return null;
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final typeName = _typeLabel(widget.type, l10n);

    WorkoutPlan plan;

    switch (widget.type) {
      case WorkoutPlanType.intervals:
        final reps = _parseInt(_repsCtrl) ?? 1;
        final warmupM = _parseInt(_warmupCtrl);
        plan = WorkoutPlan(
          name: typeName,
          type: widget.type,
          heartRateTarget: _parseInt(_hrCtrl),
          intervalConfig: IntervalConfig(
            warmup: warmupM != null ? WarmupConfig(valueM: warmupM) : null,
            distanceM: _parseInt(_intervalDistCtrl),
            restDurationMin: _parseInt(_restMinCtrl),
            restDistanceM: _parseInt(_restMCtrl),
            reps: reps,
            recoveryDurationMin: _parseInt(_recoveryMinCtrl),
            recoveryDistanceM: _parseInt(_recoveryMCtrl),
          ),
          cooldown: _cooldown,
        );

      case WorkoutPlanType.progression:
        final segs = _segments.map((s) => ProgressionSegment(
              distanceM: _parseInt(s.distanceCtrl),
              paceTargetSecPerKm: _parsePace(s.paceCtrl.text),
              heartRate: _parseInt(s.hrCtrl),
            )).toList();
        plan = WorkoutPlan(
          name: typeName,
          type: widget.type,
          progressionSegments: segs,
          cooldown: _cooldown,
        );

      case WorkoutPlanType.hillRun:
        plan = WorkoutPlan(
          name: typeName,
          type: widget.type,
          hillElevationM: _parseInt(_elevationCtrl),
          paceTargetSecPerKm: _parsePace(_paceCtrl.text),
          heartRateTarget: _parseInt(_hrCtrl),
          cooldown: _cooldown,
        );

      default:
        plan = WorkoutPlan(
          name: typeName,
          type: widget.type,
          durationMin: _parseInt(_durationCtrl),
          distanceM: _parseDistanceKm(_distanceCtrl.text),
          paceTargetSecPerKm: _parsePace(_paceCtrl.text),
          heartRateTarget: _parseInt(_hrCtrl),
          cooldown: _cooldown,
        );
    }

    widget.onDone(plan);
  }

  int? _parseDistanceKm(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final d = double.tryParse(t);
    if (d == null) return null;
    return (d * 1000).round();
  }

  String _typeLabel(WorkoutPlanType type, AppLocalizations l10n) {
    switch (type) {
      case WorkoutPlanType.easyRun:
        return l10n.workoutTypeEasyRun;
      case WorkoutPlanType.longRun:
        return l10n.workoutTypeLongRun;
      case WorkoutPlanType.intervals:
        return l10n.workoutTypeIntervals;
      case WorkoutPlanType.progression:
        return l10n.workoutTypeProgression;
      case WorkoutPlanType.recovery:
        return l10n.workoutTypeRecovery;
      case WorkoutPlanType.hillRun:
        return l10n.workoutTypeHillRun;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _typeLabel(widget.type, l10n),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildParamsForm(l10n),
          const SizedBox(height: 16),
          _CooldownSelector(
            cooldown: _cooldown,
            onChanged: (c) => setState(() => _cooldown = c),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Далее'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamsForm(AppLocalizations l10n) {
    switch (widget.type) {
      case WorkoutPlanType.intervals:
        return _buildIntervalsForm(l10n);
      case WorkoutPlanType.progression:
        return _buildProgressionForm(l10n);
      case WorkoutPlanType.hillRun:
        return _buildHillRunForm(l10n);
      default:
        return _buildSimpleForm(l10n);
    }
  }

  Widget _buildSimpleForm(AppLocalizations l10n) {
    return Column(
      children: [
        _NumField(controller: _durationCtrl, label: l10n.workoutParamsDuration),
        const SizedBox(height: 12),
        _NumField(controller: _distanceCtrl, label: l10n.workoutParamsDistance, decimal: true),
        const SizedBox(height: 12),
        _PaceField(controller: _paceCtrl, label: l10n.workoutParamsPace),
        const SizedBox(height: 12),
        _NumField(controller: _hrCtrl, label: l10n.workoutParamsHeartRate),
      ],
    );
  }

  Widget _buildIntervalsForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NumField(controller: _warmupCtrl, label: l10n.workoutParamsWarmup),
        const SizedBox(height: 16),
        // Row: Distance | Reps | Rest
        Row(
          children: [
            Expanded(
              child: _NumField(controller: _intervalDistCtrl, label: 'Расстояние (м)'),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: _NumField(controller: _repsCtrl, label: l10n.workoutParamsReps),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumField(controller: _restMinCtrl, label: l10n.workoutParamsRestMin),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _NumField(controller: _recoveryMinCtrl, label: '${l10n.workoutParamsRecovery} (мин)'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _NumField(controller: _recoveryMCtrl, label: '${l10n.workoutParamsRecovery} (м)'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _NumField(controller: _hrCtrl, label: l10n.workoutParamsHeartRate),
      ],
    );
  }

  Widget _buildProgressionForm(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(_segments.length, (i) {
          final s = _segments[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.workoutParamsSegment(i + 1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    if (_segments.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => setState(() => _segments.removeAt(i)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _NumField(controller: s.distanceCtrl, label: 'Расстояние (м)')),
                    const SizedBox(width: 8),
                    Expanded(child: _PaceField(controller: s.paceCtrl, label: l10n.workoutParamsPace)),
                    const SizedBox(width: 8),
                    Expanded(child: _NumField(controller: s.hrCtrl, label: 'Пульс')),
                  ],
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(() => _segments.add(_SegmentControllers())),
          icon: const Icon(Icons.add),
          label: Text(l10n.workoutParamsAddSegment),
        ),
      ],
    );
  }

  Widget _buildHillRunForm(AppLocalizations l10n) {
    return Column(
      children: [
        _NumField(controller: _elevationCtrl, label: l10n.workoutParamsHillElevation),
        const SizedBox(height: 12),
        _PaceField(controller: _paceCtrl, label: l10n.workoutParamsPace),
        const SizedBox(height: 12),
        _NumField(controller: _hrCtrl, label: l10n.workoutParamsHeartRate),
      ],
    );
  }
}

class _SegmentControllers {
  final distanceCtrl = TextEditingController();
  final paceCtrl = TextEditingController();
  final hrCtrl = TextEditingController();

  void dispose() {
    distanceCtrl.dispose();
    paceCtrl.dispose();
    hrCtrl.dispose();
  }
}

// ── Cooldown Selector ────────────────────────────────────────────────────────

class _CooldownSelector extends StatelessWidget {
  final CooldownConfig? cooldown;
  final void Function(CooldownConfig?) onChanged;

  const _CooldownSelector({required this.cooldown, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showModal(context, l10n),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cooldown != null
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.self_improvement, size: 20),
            const SizedBox(width: 8),
            Text(
              cooldown != null
                  ? '${l10n.workoutCooldownSelect}: ${cooldown!.value} '
                      '${cooldown!.type == 'duration' ? 'мин' : 'м'}'
                  : l10n.workoutCooldownNone,
              style: TextStyle(
                color: cooldown != null ? null : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModal(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _CooldownModal(
        current: cooldown,
        onChanged: (c) {
          Navigator.of(ctx).pop();
          onChanged(c);
        },
      ),
    );
  }
}

class _CooldownModal extends StatefulWidget {
  final CooldownConfig? current;
  final void Function(CooldownConfig?) onChanged;

  const _CooldownModal({required this.current, required this.onChanged});

  @override
  State<_CooldownModal> createState() => _CooldownModalState();
}

class _CooldownModalState extends State<_CooldownModal> {
  String _type = 'duration'; // 'duration' | 'distance'
  final _valueCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.current != null) {
      _type = widget.current!.type;
      _valueCtrl.text = widget.current!.value.toString();
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.workoutCooldownSelect,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _type = 'duration'),
                  style: _type == 'duration'
                      ? OutlinedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer)
                      : null,
                  child: Text(l10n.workoutCooldownMinutes),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _type = 'distance'),
                  style: _type == 'distance'
                      ? OutlinedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer)
                      : null,
                  child: Text(l10n.workoutCooldownMetres),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _valueCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: _type == 'duration'
                  ? l10n.workoutCooldownValueMin
                  : l10n.workoutCooldownValueM,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onChanged(null),
                  child: Text(l10n.workoutCooldownNo),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final val = int.tryParse(_valueCtrl.text.trim());
                    if (val != null && val > 0) {
                      widget.onChanged(CooldownConfig(type: _type, value: val));
                    }
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Schedule ─────────────────────────────────────────────────────────

class _ScheduleStep extends StatefulWidget {
  final Future<void> Function(DateTime?) onDone;

  const _ScheduleStep({required this.onDone});

  @override
  State<_ScheduleStep> createState() => _ScheduleStepState();
}

class _ScheduleStepState extends State<_ScheduleStep> {
  bool _loading = false;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;

    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() => _loading = true);
    await widget.onDone(dt);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _skip() async {
    setState(() => _loading = true);
    await widget.onDone(null);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.workoutScheduleTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _pickDateTime,
                      child: Text(l10n.workoutScheduleYes),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _skip,
                      child: Text(l10n.workoutScheduleNo),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Step 3: Saved ────────────────────────────────────────────────────────────

class _SavedStep extends StatefulWidget {
  final WorkoutPlan plan;

  const _SavedStep({required this.plan});

  @override
  State<_SavedStep> createState() => _SavedStepState();
}

class _SavedStepState extends State<_SavedStep> {
  bool _savingTemplate = false;

  Future<void> _saveAsTemplate() async {
    setState(() => _savingTemplate = true);
    try {
      await ServiceLocator.workoutPlanService.saveAsTemplate(widget.plan);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.workoutTemplateSaved)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _savingTemplate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.workoutSavedTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.pushReplacement(
                  '/workout/active',
                  extra: widget.plan,
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.workoutSavedStart),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _savingTemplate ? null : _saveAsTemplate,
                child: _savingTemplate
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.workoutSavedSaveTemplate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable field widgets ────────────────────────────────────────────────────

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool decimal;

  const _NumField({
    required this.controller,
    required this.label,
    this.decimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _PaceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _PaceField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d:.]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: '5:30',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
