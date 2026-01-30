import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
        String errorMessage = 'Ошибка при запуске пробежки';
        
        // Provide more user-friendly error messages
        final errorString = e.toString();
        if (errorString.contains('permission denied') || 
            errorString.contains('Location permission denied')) {
          errorMessage = 'Разрешение на геолокацию не предоставлено.\n\n'
              'Для Windows: откройте Настройки → Конфиденциальность → Расположение → '
              'Разрешения приложений и включите доступ для Runterra.\n\n'
              'Для Android: разрешите доступ к геолокации при запросе.';
        } else if (errorString.contains('permanently denied') || 
                   errorString.contains('permanently denied')) {
          errorMessage = 'Доступ к геолокации заблокирован.\n\n'
              'Пожалуйста, включите разрешение в настройках устройства:\n'
              'Windows: Настройки → Конфиденциальность → Расположение\n'
              'Android: Настройки → Приложения → Runterra → Разрешения';
        } else if (errorString.contains('service is disabled') || 
                   errorString.contains('Location service is disabled')) {
          errorMessage = 'Служба геолокации отключена.\n\n'
              'Пожалуйста, включите геолокацию в настройках устройства.';
        } else {
          errorMessage = 'Ошибка при запуске пробежки:\n$e';
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
            content: Text('Ошибка при завершении пробежки: $e'),
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

  String _formatDistance(double distanceMeters) {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} м';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(2)} км';
  }

  String _getGpsStatusText(GpsStatus status) {
    switch (status) {
      case GpsStatus.searching:
        return 'Поиск сигнала';
      case GpsStatus.recording:
        return 'Запись';
      case GpsStatus.error:
        return 'Ошибка GPS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run'),
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
                'Пробежка будет засчитана для тренировки "${widget.activityId}"',
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
              label: const Text('Начать пробежку'),
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
                      '📍 GPS: ${_getGpsStatusText(gpsStatus)}',
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
                  _formatDistance(distance),
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
            label: Text(_isSubmitting ? 'Завершение...' : 'Завершить'),
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
              'Готово 🎉',
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
              '📏 ${_formatDistance(distance)}',
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
                        'Участие в тренировке засчитано',
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
                      'Вклад в территорию',
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
              child: const Text('Готово'),
            ),
          ],
        ),
      ),
    );
  }
}
