import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
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
  void dispose() {
    _timer?.cancel();
    _gpsSubscription?.cancel();
    _runService.cancelRun();
    super.dispose();
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
      await _runService.submitRun();

      setState(() {
        _session = completedSession;
        _state = RunTabState.completed;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.runFinishError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
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
    final duration = _session?.duration ?? Duration.zero;
    final distance = _session?.distance ?? 0.0;
    final hasActivity = _session?.activityId != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.runDone,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Time
            Text(
              '⏱ ${_formatDuration(duration)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // Distance
            Text(
              '📏 ${_formatDistance(context, distance)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            // Counted items (placeholders)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasActivity)
                  Row(
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.runCountedTraining,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.runCountedTerritory,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                // TODO: Add points if available
                // const SizedBox(height: 8),
                // Row(
                //   children: [
                //     const Icon(Icons.check, color: Colors.green, size: 20),
                //     const SizedBox(width: 8),
                //     Text('+баллы (если есть)'),
                //   ],
                // ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _backToIdle,
              child: Text(AppLocalizations.of(context)!.runReady),
            ),
          ],
        ),
      ),
    );
  }
}
