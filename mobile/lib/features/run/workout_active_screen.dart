import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/workout_plan.dart';
import '../../l10n/app_localizations.dart';

/// Active workout screen — always-on display (WakeLock enabled).
/// Shows type-specific real-time metrics from GPS/HR.
class WorkoutActiveScreen extends StatefulWidget {
  final WorkoutPlan plan;

  const WorkoutActiveScreen({super.key, required this.plan});

  @override
  State<WorkoutActiveScreen> createState() => _WorkoutActiveScreenState();
}

class _WorkoutActiveScreenState extends State<WorkoutActiveScreen> {
  // Elapsed time
  late final Stopwatch _stopwatch;
  Timer? _ticker;

  // GPS/pace data from RunService
  double _distanceM = 0;
  double _currentPaceSecPerKm = 0;
  int _currentHR = 0;
  double _elevationGainM = 0;

  // Intervals state
  int _intervalPhase = 0; // 0=warmup, 1=work, 2=rest
  int _repsDone = 0;
  double _phaseDistanceM = 0;

  // Progression state
  int _currentSegment = 0;
  double _segmentDistanceM = 0;

  // Cooldown state
  bool _inCooldown = false; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateMetrics();
    });
  }

  void _updateMetrics() {
    final session = ServiceLocator.runService.currentSession;
    if (session == null) return;
    setState(() {
      _distanceM = session.distance;
      // Estimate pace from distance and elapsed time (m/s → sec/km)
      final elapsedSec = _stopwatch.elapsed.inSeconds;
      _currentPaceSecPerKm = (_distanceM > 0 && elapsedSec > 0)
          ? (elapsedSec / (_distanceM / 1000))
          : 0;
      _currentHR = session.heartRate ?? 0;
      // Elevation: approximate from GPS altitude points if available
      if (session.gpsPoints.length >= 2) {
        double gain = 0;
        for (int i = 1; i < session.gpsPoints.length; i++) {
          final diff = session.gpsPoints[i].altitude - session.gpsPoints[i - 1].altitude;
          if (diff > 0) gain += diff;
        }
        _elevationGainM = gain;
      }

      // Update interval/progression state based on distance
      _updateIntervalState();
      _updateProgressionState();
    });
  }

  void _updateIntervalState() {
    if (widget.plan.type != WorkoutPlanType.intervals) return;
    final config = widget.plan.intervalConfig;
    if (config == null) return;

    final workDist = (config.distanceM ?? 0).toDouble();
    final restDist = (config.restDistanceM ?? 0).toDouble();
    final warmupDist = (config.warmup?.valueM ?? 0).toDouble();

    double tracked = _distanceM;
    if (_intervalPhase == 0 && warmupDist > 0) {
      if (tracked >= warmupDist) {
        _intervalPhase = 1;
        _phaseDistanceM = 0;
        tracked -= warmupDist;
      }
    }
    if (_intervalPhase >= 1 && workDist > 0) {
      final cycleLen = workDist + restDist;
      if (cycleLen > 0 && _repsDone < config.reps) {
        final cyclesDone = (tracked / cycleLen).floor();
        _repsDone = cyclesDone.clamp(0, config.reps);
        final inCycle = tracked - cyclesDone * cycleLen;
        if (inCycle < workDist) {
          _intervalPhase = 1;
          _phaseDistanceM = inCycle;
        } else {
          _intervalPhase = 2;
          _phaseDistanceM = inCycle - workDist;
        }
      }
    }
  }

  void _updateProgressionState() {
    if (widget.plan.type != WorkoutPlanType.progression) return;
    final segs = widget.plan.progressionSegments;
    if (segs == null || segs.isEmpty) return;

    double covered = 0;
    for (int i = 0; i < segs.length; i++) {
      final segDist = (segs[i].distanceM ?? 0).toDouble();
      if (_distanceM < covered + segDist || i == segs.length - 1) {
        _currentSegment = i;
        _segmentDistanceM = _distanceM - covered;
        return;
      }
      covered += segDist;
    }
  }

  void _finish() {
    context.go('/run');
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    WakelockPlus.disable();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}ч ${m.toString().padLeft(2, '0')}м';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatPace(double secPerKm) {
    if (secPerKm <= 0) return '--:--';
    final min = (secPerKm / 60).floor();
    final sec = (secPerKm % 60).round();
    return '$min:${sec.toString().padLeft(2, '0')}';
  }

  String _formatPaceTarget(int? secPerKm) {
    if (secPerKm == null) return '--:--';
    return _formatPace(secPerKm.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elapsed = _stopwatch.elapsed;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.plan.name),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Завершить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildContent(context, l10n, elapsed),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n, Duration elapsed) {
    switch (widget.plan.type) {
      case WorkoutPlanType.easyRun:
        return _buildEasyRun(elapsed);
      case WorkoutPlanType.longRun:
        return _buildLongRun(elapsed);
      case WorkoutPlanType.intervals:
        return _buildIntervals(elapsed);
      case WorkoutPlanType.progression:
        return _buildProgression(elapsed);
      case WorkoutPlanType.recovery:
        return _buildRecovery(elapsed);
      case WorkoutPlanType.hillRun:
        return _buildHillRun(elapsed);
    }
  }

  // ── EasyRun: distance | pace | duration | HR ─────────────────────────────

  Widget _buildEasyRun(Duration elapsed) {
    return _MetricGrid(metrics: [
      _Metric(label: 'Расстояние', value: '${(_distanceM / 1000).toStringAsFixed(2)} км'),
      _Metric(label: 'Темп', value: _formatPace(_currentPaceSecPerKm)),
      _Metric(label: 'Длительность', value: _formatDuration(elapsed)),
      _Metric(label: 'Пульс', value: _currentHR > 0 ? '$_currentHR уд/мин' : '--'),
    ]);
  }

  // ── LongRun: duration fact|remain, distance fact|remain, pace fact|plan, HR fact|plan ──

  Widget _buildLongRun(Duration elapsed) {
    final targetDur = widget.plan.durationMin != null
        ? Duration(minutes: widget.plan.durationMin!)
        : null;
    final remaining = targetDur != null && targetDur > elapsed
        ? targetDur - elapsed
        : null;
    final targetDistM = widget.plan.distanceM;
    final remainDistM = targetDistM != null ? targetDistM - _distanceM : null;

    return _MetricGrid(metrics: [
      _Metric(
        label: 'Длительность',
        value: _formatDuration(elapsed),
        sub: remaining != null ? 'осталось ${_formatDuration(remaining)}' : null,
      ),
      _Metric(
        label: 'Расстояние',
        value: '${(_distanceM / 1000).toStringAsFixed(2)} км',
        sub: remainDistM != null && remainDistM > 0
            ? 'осталось ${(remainDistM / 1000).toStringAsFixed(2)} км'
            : null,
      ),
      _Metric(
        label: 'Темп',
        value: _formatPace(_currentPaceSecPerKm),
        sub: widget.plan.paceTargetSecPerKm != null
            ? 'план ${_formatPaceTarget(widget.plan.paceTargetSecPerKm)}'
            : null,
      ),
      _Metric(
        label: 'Пульс',
        value: _currentHR > 0 ? '$_currentHR' : '--',
        sub: widget.plan.heartRateTarget != null
            ? 'план ${widget.plan.heartRateTarget}'
            : null,
      ),
    ]);
  }

  // ── Intervals ────────────────────────────────────────────────────────────

  Widget _buildIntervals(Duration elapsed) {
    final config = widget.plan.intervalConfig;
    if (config == null) return _buildEasyRun(elapsed);

    String phase;
    double phaseTarget = 0;
    if (_intervalPhase == 0) {
      phase = 'Разминка';
      phaseTarget = config.warmup?.valueM.toDouble() ?? 0;
    } else if (_intervalPhase == 1) {
      phase = 'Ускорение';
      phaseTarget = config.distanceM?.toDouble() ?? 0;
    } else {
      phase = 'Отдых';
      phaseTarget = config.restDistanceM?.toDouble() ?? 0;
    }
    final phaseRemain = (phaseTarget - _phaseDistanceM).clamp(0.0, phaseTarget);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: _intervalPhase == 1 ? Colors.orange[900] : Colors.blueGrey[900],
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            phase,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _MetricGrid(metrics: [
            _Metric(
              label: 'Осталось',
              value: '${phaseRemain.toStringAsFixed(0)} м',
            ),
            _Metric(
              label: 'Повторений',
              value: '$_repsDone / ${config.reps}',
            ),
            _Metric(label: 'Темп', value: _formatPace(_currentPaceSecPerKm)),
            _Metric(
              label: 'Пульс',
              value: _currentHR > 0 ? '$_currentHR' : '--',
            ),
          ]),
        ),
      ],
    );
  }

  // ── Progression ───────────────────────────────────────────────────────────

  Widget _buildProgression(Duration elapsed) {
    final segs = widget.plan.progressionSegments ?? [];
    final seg = segs.isNotEmpty ? segs[_currentSegment] : null;
    final segDist = seg?.distanceM?.toDouble() ?? 0;
    final segRemain = (segDist - _segmentDistanceM).clamp(0.0, segDist);

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.deepPurple[900],
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Отрезок ${_currentSegment + 1} / ${segs.length}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: _MetricGrid(metrics: [
            _Metric(
              label: 'Расстояние',
              value: '${(_segmentDistanceM / 1000).toStringAsFixed(2)} км',
              sub: segRemain > 0 ? 'осталось ${segRemain.toStringAsFixed(0)} м' : null,
            ),
            _Metric(
              label: 'Длительность',
              value: _formatDuration(elapsed),
            ),
            _Metric(
              label: 'Темп',
              value: _formatPace(_currentPaceSecPerKm),
              sub: seg?.paceTargetSecPerKm != null
                  ? 'план ${_formatPaceTarget(seg!.paceTargetSecPerKm)}'
                  : null,
            ),
            _Metric(
              label: 'Пульс',
              value: _currentHR > 0 ? '$_currentHR' : '--',
              sub: seg?.heartRate != null ? 'план ${seg!.heartRate}' : null,
            ),
          ]),
        ),
      ],
    );
  }

  // ── Recovery ─────────────────────────────────────────────────────────────

  Widget _buildRecovery(Duration elapsed) {
    final targetDur = widget.plan.durationMin != null
        ? Duration(minutes: widget.plan.durationMin!)
        : null;
    final remaining = targetDur != null && targetDur > elapsed
        ? targetDur - elapsed
        : null;
    final targetDistM = widget.plan.distanceM;
    final remainDistM = targetDistM != null ? targetDistM - _distanceM : null;

    return _MetricGrid(metrics: [
      _Metric(
        label: 'Длительность',
        value: _formatDuration(elapsed),
        sub: remaining != null ? 'осталось ${_formatDuration(remaining)}' : null,
      ),
      _Metric(
        label: 'Расстояние',
        value: '${(_distanceM / 1000).toStringAsFixed(2)} км',
        sub: remainDistM != null && remainDistM > 0
            ? 'осталось ${(remainDistM / 1000).toStringAsFixed(2)} км'
            : null,
      ),
      _Metric(
        label: 'Темп',
        value: _formatPace(_currentPaceSecPerKm),
        sub: widget.plan.paceTargetSecPerKm != null
            ? 'план ${_formatPaceTarget(widget.plan.paceTargetSecPerKm)}'
            : null,
      ),
      _Metric(
        label: 'Пульс',
        value: _currentHR > 0 ? '$_currentHR' : '--',
        sub: widget.plan.heartRateTarget != null
            ? 'план ${widget.plan.heartRateTarget}'
            : null,
      ),
    ]);
  }

  // ── HillRun ──────────────────────────────────────────────────────────────

  Widget _buildHillRun(Duration elapsed) {
    final elevationM = _elevationGainM;

    return _MetricGrid(metrics: [
      _Metric(label: 'Длительность', value: _formatDuration(elapsed)),
      _Metric(
        label: 'Расстояние',
        value: '${(_distanceM / 1000).toStringAsFixed(2)} км',
      ),
      _Metric(
        label: 'Темп',
        value: _formatPace(_currentPaceSecPerKm),
        sub: widget.plan.paceTargetSecPerKm != null
            ? 'план ${_formatPaceTarget(widget.plan.paceTargetSecPerKm)}'
            : null,
      ),
      _Metric(
        label: 'Пульс',
        value: _currentHR > 0 ? '$_currentHR' : '--',
        sub: widget.plan.heartRateTarget != null
            ? 'план ${widget.plan.heartRateTarget}'
            : null,
      ),
      _Metric(
        label: 'Подъём',
        value: '${elevationM.toStringAsFixed(0)} м',
        sub: widget.plan.hillElevationM != null
            ? 'цель ${widget.plan.hillElevationM} м'
            : null,
      ),
    ]);
  }
}

// ── Reusable metric widgets ───────────────────────────────────────────────────

class _Metric {
  final String label;
  final String value;
  final String? sub;

  const _Metric({required this.label, required this.value, this.sub});
}

class _MetricGrid extends StatelessWidget {
  final List<_Metric> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) {
        final m = metrics[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                m.label,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                m.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (m.sub != null)
                Text(
                  m.sub!,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
            ],
          ),
        );
      },
    );
  }
}
