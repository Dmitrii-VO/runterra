import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/run_session.dart';

/// Состояния вкладки Run (до пробежки / во время / после).
enum RunTabState {
  idle,
  running,
  completed,
}

/// Экран бега (MVP).
///
/// Три фазы: до пробежки → во время → после.
/// Реализует GPS-трекинг, таймер, статус GPS, экран результата.
class RunScreen extends StatefulWidget {
  /// ID тренировки при открытии через /run?activityId=...
  final String? activityId;

  const RunScreen({super.key, this.activityId});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  RunTabState _state = RunTabState.idle;
  RunSession? _session;
  final _runService = ServiceLocator.runService;
  Timer? _timer;
  StreamSubscription? _gpsSubscription;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // При возврате на вкладку восстанавливаем UI, если пробежка уже идёт в фоне.
    if (_runService.currentSession?.status == RunSessionStatus.running) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _restoreRunningState();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsSubscription?.cancel();
    // Не отменяем пробежку при уходе на другую вкладку — сессия продолжается в RunService.
    super.dispose();
  }

  /// Восстанавливает UI при возврате на вкладку, если пробежка уже идёт в RunService.
  void _restoreRunningState() {
    final session = _runService.currentSession;
    if (session == null || session.status != RunSessionStatus.running) return;

    setState(() {
      _session = session;
      _state = RunTabState.running;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_session != null && _state == RunTabState.running && mounted) {
        final duration = DateTime.now().difference(_session!.startedAt);
        _runService.updateSessionMetrics(duration: duration);
        setState(() {
          _session = _runService.currentSession;
        });
      }
    });

    _gpsSubscription = _runService.gpsPositionStream.listen(
      (position) {
        if (_session?.gpsStatus == GpsStatus.searching) {
          _runService.updateGpsStatus(GpsStatus.recording);
        }
        if (_session != null && _session!.gpsPoints.length > 1 && mounted) {
          final gpsPoints = List.from(_session!.gpsPoints);
          final lastIndex = gpsPoints.length - 1;
          final increment = Geolocator.distanceBetween(
            gpsPoints[lastIndex - 1].latitude,
            gpsPoints[lastIndex - 1].longitude,
            gpsPoints[lastIndex].latitude,
            gpsPoints[lastIndex].longitude,
          );
          final newDistance = (_session!.distance) + increment;
          _runService.updateSessionMetrics(distance: newDistance);
        }
        if (mounted) setState(() => _session = _runService.currentSession);
      },
      onError: (_) {
        _runService.updateGpsStatus(GpsStatus.error);
        if (mounted) setState(() => _session = _runService.currentSession);
      },
    );
  }

  Future<void> _startRun() async {
    try {
      final session = await _runService.startRun(activityId: widget.activityId);
      
      setState(() {
        _session = session;
        _state = RunTabState.running;
      });

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_session != null && _state == RunTabState.running) {
          final duration = DateTime.now().difference(_session!.startedAt);
          _runService.updateSessionMetrics(duration: duration);
          setState(() {
            _session = _runService.currentSession;
          });
        }
      });

      // Listen to GPS updates
      _gpsSubscription = _runService.gpsPositionStream.listen(
        (position) {
          // Update GPS status to recording when first position is received
          if (_session?.gpsStatus == GpsStatus.searching) {
            _runService.updateGpsStatus(GpsStatus.recording);
            setState(() {
              _session = _runService.currentSession;
            });
          }

          // Update distance (calculated from GPS points)
          // Optimization: only calculate increment from last point to avoid O(n²)
          if (_session != null && _session!.gpsPoints.length > 1) {
            final gpsPoints = List.from(_session!.gpsPoints); // Copy list to maintain immutability
            final lastIndex = gpsPoints.length - 1;
            // Calculate only the increment from previous point to current
            final increment = Geolocator.distanceBetween(
              gpsPoints[lastIndex - 1].latitude,
              gpsPoints[lastIndex - 1].longitude,
              gpsPoints[lastIndex].latitude,
              gpsPoints[lastIndex].longitude,
            );
            // Add increment to existing distance
            final newDistance = (_session!.distance) + increment;
            _runService.updateSessionMetrics(distance: newDistance);
            setState(() {
              _session = _runService.currentSession;
            });
          }
        },
        onError: (error) {
          _runService.updateGpsStatus(GpsStatus.error);
          setState(() {
            _session = _runService.currentSession;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        String errorMessage;
        final errorString = e.toString();
        if (errorString.contains('permission denied') ||
            errorString.contains('Location permission denied')) {
          errorMessage = l10n.runStartPermissionDenied;
        } else if (errorString.contains('permanently denied')) {
          errorMessage = l10n.runStartPermanentlyDenied;
        } else if (errorString.contains('service is disabled') ||
            errorString.contains('Location service is disabled')) {
          errorMessage = l10n.runStartServiceDisabled;
        } else {
          errorMessage = l10n.runStartErrorGeneric(e.toString());
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _finishRun() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      _timer?.cancel();
      _gpsSubscription?.cancel();

      final completedSession = await _runService.stopRun();
      if (mounted) {
        setState(() {
          _session = completedSession;
          _state = RunTabState.completed;
        });
      }
      await _runService.submitRun();
    } catch (e) {
      if (mounted) {
        // Show backend message directly for ApiException, generic wrapper otherwise
        final errorText = (e is ApiException)
            ? e.message
            : AppLocalizations.of(context)!.runFinishError(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _backToIdle() {
    setState(() {
      _state = RunTabState.idle;
      _session = null;
    });
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDistance(BuildContext context, double distanceMeters) {
    final l10n = AppLocalizations.of(context)!;
    if (distanceMeters < 1000) {
      return l10n.distanceMeters(distanceMeters.toStringAsFixed(0));
    }
    return l10n.distanceKm((distanceMeters / 1000).toStringAsFixed(2));
  }

  /// Pace in min:sec per km. Returns null if distance is too small.
  String? _formatPace(Duration duration, double distanceMeters) {
    final distanceKm = distanceMeters / 1000;
    if (distanceKm < 0.01) return null;
    final totalSeconds = (duration.inSeconds / distanceKm).round();
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Average speed in km/h. Returns null if duration is zero.
  double? _calcAvgSpeedKmh(Duration duration, double distanceMeters) {
    if (duration.inSeconds <= 0) return null;
    return (distanceMeters / 1000) / (duration.inSeconds / 3600);
  }

  /// Rough calorie estimate: ~65 kcal per km (no weight).
  int _calcCalories(double distanceMeters) {
    final distanceKm = distanceMeters / 1000;
    return (distanceKm * 65).round();
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String value,
    required String label,
    IconData? icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
            ],
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getGpsStatusText(BuildContext context, GpsStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case GpsStatus.searching:
        return l10n.runGpsSearching;
      case GpsStatus.recording:
        return l10n.runGpsRecording;
      case GpsStatus.error:
        return l10n.runGpsError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.runTitle),
      ),
      body: switch (_state) {
        RunTabState.idle => _buildIdleContent(),
        RunTabState.running => _buildRunningContent(),
        RunTabState.completed => _buildCompletedContent(),
      },
    );
  }

  Widget _buildIdleContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.activityId != null) ...[
              Text(
                AppLocalizations.of(context)!.runForActivity(widget.activityId!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
            FilledButton.icon(
              onPressed: _startRun,
              icon: const Icon(Icons.play_arrow),
              label: Text(AppLocalizations.of(context)!.runStart),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunningContent() {
    final duration = _session?.duration ?? Duration.zero;
    final distance = _session?.distance ?? 0.0;
    final gpsStatus = _session?.gpsStatus ?? GpsStatus.searching;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // GPS Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '📍 GPS: ${_getGpsStatusText(context, gpsStatus)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Active indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: gpsStatus == GpsStatus.recording
                        ? Colors.green
                        : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 24),
                // Timer
                Text(
                  '⏱ ${_formatDuration(duration)}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                // Distance
                Text(
                  _formatDistance(context, distance),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _finishRun,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.stop),
            label: Text(_isSubmitting ? AppLocalizations.of(context)!.runFinishing : AppLocalizations.of(context)!.runFinish),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedContent() {
    final l10n = AppLocalizations.of(context)!;
    final duration = _session?.duration ?? Duration.zero;
    final distance = _session?.distance ?? 0.0;
    final hasActivity = _session?.activityId != null;

    final paceStr = _formatPace(duration, distance);
    final avgSpeed = _calcAvgSpeedKmh(duration, distance);
    final calories = _calcCalories(distance);

    // TODO: Heart rate — placeholder for future Health Connect integration
    const int? heartRateBpm = null;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Text(
              l10n.runDone,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Metrics grid (fitness-app style)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _buildMetricCard(
                  context: context,
                  value: _formatDuration(duration),
                  label: l10n.runDuration,
                  icon: Icons.timer,
                ),
                _buildMetricCard(
                  context: context,
                  value: _formatDistance(context, distance),
                  label: l10n.runDistance,
                  icon: Icons.straighten,
                ),
                _buildMetricCard(
                  context: context,
                  value: paceStr != null
                      ? l10n.runPaceValue(paceStr)
                      : l10n.runNoData,
                  label: l10n.runPace,
                  icon: Icons.speed,
                ),
                _buildMetricCard(
                  context: context,
                  value: avgSpeed != null
                      ? l10n.runAvgSpeedValue(avgSpeed.toStringAsFixed(1))
                      : l10n.runNoData,
                  label: l10n.runAvgSpeed,
                  icon: Icons.show_chart,
                ),
                _buildMetricCard(
                  context: context,
                  value: l10n.runCaloriesValue(calories),
                  label: l10n.runCalories,
                  icon: Icons.local_fire_department,
                ),
                _buildMetricCard(
                  context: context,
                  value: heartRateBpm != null
                      ? l10n.runHeartRateValue(heartRateBpm)
                      : l10n.runNoData,
                  label: l10n.runHeartRate,
                  icon: Icons.favorite,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Counted items
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasActivity)
                  Row(
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.runCountedTraining,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                if (hasActivity) const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      l10n.runCountedTerritory,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _backToIdle,
              child: Text(l10n.runReady),
            ),
          ],
        ),
      ),
    );
  }
}
