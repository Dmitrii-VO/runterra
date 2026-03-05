import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../shared/models/my_club_model.dart';
import '../../shared/models/run_model.dart';
import '../../shared/models/run_session.dart';
import 'widgets/run_detail_map.dart';
import 'widgets/run_route_map.dart';

/// Callback invoked when user dismisses completed run result.
typedef OnRunCompleted = void Function();

/// Run tracking screen (idle → running → completed).
///
/// Extracted from the original RunScreen to separate tracking from history.
class RunTrackingScreen extends StatefulWidget {
  final String? activityId;
  final String? scheduledItemId;
  final OnRunCompleted? onRunCompleted;

  const RunTrackingScreen({super.key, this.activityId, this.scheduledItemId, this.onRunCompleted});

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

enum _TrackingState { idle, running, paused, completed }

class _RunTrackingScreenState extends State<RunTrackingScreen> {
  _TrackingState _state = _TrackingState.idle;
  RunSession? _session;
  final _runService = ServiceLocator.runService;
  Timer? _timer;
  StreamSubscription? _gpsSubscription;
  bool _isSubmitting = false;
  MyClubModel? _selectedScoringClub;
  List<MyClubModel>? _myClubs;
  int _rpe = 5;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClubs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = _runService.currentSession;
      if (session == null) return;
      if (session.status == RunSessionStatus.running) {
        _restoreRunningState();
      } else if (session.status == RunSessionStatus.paused) {
        setState(() {
          _session = session;
          _state = _TrackingState.paused;
        });
      } else if (session.status == RunSessionStatus.completed) {
        setState(() {
          _session = session;
          _state = _TrackingState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsSubscription?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClubs() async {
    try {
      final clubs = await ServiceLocator.clubsService.getMyClubs();
      final activeId = ServiceLocator.currentClubService.currentClubId;
      if (mounted) {
        setState(() {
          _myClubs = clubs;
          if (activeId != null) {
            _selectedScoringClub = clubs.where((c) => c.id == activeId).firstOrNull;
          }
          if (_selectedScoringClub == null && clubs.isNotEmpty) {
             _selectedScoringClub = clubs.first;
          }
        });
      }
    } catch (_) {
      // Ignore errors silently
    }
  }

  Future<void> _showPreRunClubSelectionDialog() async {
    if (_myClubs == null || _myClubs!.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.runSelectClubTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ..._myClubs!.map((club) => ListTile(
              title: Text(club.name),
              trailing: _selectedScoringClub?.id == club.id ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                setState(() {
                  _selectedScoringClub = club;
                });
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _restoreRunningState() {
    final session = _runService.currentSession;
    if (session == null || session.status != RunSessionStatus.running) return;

    setState(() {
      _session = session;
      _state = _TrackingState.running;
    });

    _startTimerAndGps();
  }

  void _startTimerAndGps() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_session != null && _state == _TrackingState.running && mounted) {
        final lastResumed = _session!.lastResumedAt ?? _session!.startedAt;
        final activeSinceResume = DateTime.now().difference(lastResumed);
        final totalDuration = _session!.accumulatedDuration + activeSinceResume;
        _runService.updateSessionMetrics(duration: totalDuration);
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
        if (mounted) {
          setState(() => _session = _runService.currentSession);
        }
      },
      onError: (_) {
        _runService.updateGpsStatus(GpsStatus.error);
        if (mounted) setState(() => _session = _runService.currentSession);
      },
    );
  }

  Future<void> _startRun() async {
    try {
      final session = await _runService.startRun(
        activityId: widget.activityId,
        scheduledItemId: widget.scheduledItemId,
        scoringClubId: _selectedScoringClub?.id,
      );

      // Логируем начало пробежки
      FirebaseAnalytics.instance.logEvent(
        name: 'run_start',
        parameters: {
          'activity_id': widget.activityId ?? 'none',
          'scheduled_item_id': widget.scheduledItemId ?? 'none',
          'club_id': _selectedScoringClub?.id ?? 'none',
        },
      );

      setState(() {
        _session = session;
        _state = _TrackingState.running;
      });

      _startTimerAndGps();
      ServiceLocator.watchService.maybeResumeBroadcasting();
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
        } else if (errorString.contains('Run already started')) {
          _showStuckSessionDialog();
          return;
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

  void _pauseRun() {
    _timer?.cancel();
    _gpsSubscription?.cancel();
    _runService.pauseRun();
    setState(() {
      _session = _runService.currentSession;
      _state = _TrackingState.paused;
    });
  }

  Future<void> _resumeRun() async {
    try {
      await _runService.resumeRun();
      if (!mounted) return;
      setState(() {
        _session = _runService.currentSession;
        _state = _TrackingState.running;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_session != null && _state == _TrackingState.running && mounted) {
          final lastResumed = _session!.lastResumedAt ?? _session!.startedAt;
          final activeSinceResume = DateTime.now().difference(lastResumed);
          final totalDuration = _session!.accumulatedDuration + activeSinceResume;
          _runService.updateSessionMetrics(duration: totalDuration);
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
          if (!mounted) return;
          setState(() {
            _session = _runService.currentSession;
          });
        },
        onError: (error) {
          _runService.updateGpsStatus(GpsStatus.error);
          if (!mounted) return;
          setState(() {
            _session = _runService.currentSession;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
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

      // Логируем завершение записи пробежки
      FirebaseAnalytics.instance.logEvent(
        name: 'run_finish',
        parameters: {
          'distance': completedSession.distance,
          'duration': completedSession.duration.inSeconds,
        },
      );

      if (mounted) {
        setState(() {
          _session = completedSession;
          _state = _TrackingState.completed;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final errorText = (e is ApiException)
            ? e.message
            : AppLocalizations.of(context)!.runFinishError(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorText),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitCompletedRun() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await _runService.submitRun(rpe: _rpe, notes: _notesController.text);

      // Логируем отправку результата
      FirebaseAnalytics.instance.logEvent(
        name: 'run_submit',
        parameters: {
          'rpe': _rpe,
          'has_notes': _notesController.text.isNotEmpty,
        },
      );

      if (mounted) {
        _backToIdle();
      }
    } catch (e) {
      if (e is ApiException && e.code == 'club_required_for_scoring') {
         if (mounted) {
           await _showClubSelectionDialog();
         }
         return;
      }

      if (mounted) {
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

  Future<void> _showClubSelectionDialog() async {
    try {
      final clubs = await ServiceLocator.clubsService.getMyClubs();
      
      if (!mounted) return;

      // Filter active clubs only? 
      // The API returns active clubs by default usually, but let's assume getMyClubs returns all.
      // If MyClubModel has status, we should filter. Assuming it does or API filters.
      // Let's assume the user picks from the list returned.

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context)!.runSelectClubTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (clubs.isEmpty)
                 Padding(
                   padding: const EdgeInsets.all(16.0),
                   child: Text(AppLocalizations.of(context)!.runNoClubs),
                 )
              else
                ...clubs.map((club) => ListTile(
                  title: Text(club.name), // MyClubModel uses 'name' not 'clubName'
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _submitWithClub(club.id); // MyClubModel uses 'id' not 'clubId'
                  },
                )),
              // Per spec: if >1 active clubs, user MUST choose a club for scoring.
              // No skip option — user can dismiss the sheet to cancel submission.
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load clubs: $e')),
        );
      }
    }
  }

  Future<void> _submitWithClub(String clubId) async {
    setState(() => _isSubmitting = true);
    try {
      await _runService.submitRun(scoringClubId: clubId, rpe: _rpe, notes: _notesController.text);
      if (mounted) {
        _backToIdle();
      }
    } catch (e) {
      if (mounted) {
        final errorText = (e is ApiException)
            ? e.message
            : AppLocalizations.of(context)!.runFinishError(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorText), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _backToIdle() {
    _runService.clearCompletedSession();
    setState(() {
      _state = _TrackingState.idle;
      _session = null;
    });
    widget.onRunCompleted?.call();
  }

  void _showStuckSessionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.runStuckSessionTitle),
        content: Text(l10n.runStuckSessionMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final session = _runService.currentSession;
              if (session?.status == RunSessionStatus.paused) {
                setState(() {
                  _session = session;
                  _state = _TrackingState.paused;
                });
              } else {
                _restoreRunningState();
              }
            },
            child: Text(l10n.runStuckSessionResume),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _runService.cancelRun();
              setState(() {
                _state = _TrackingState.idle;
                _session = null;
              });
            },
            child: Text(l10n.runStuckSessionCancel),
          ),
        ],
      ),
    );
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

  String? _formatPace(Duration duration, double distanceMeters) {
    final distanceKm = distanceMeters / 1000;
    if (distanceKm < 0.05) return null;
    final totalSeconds = (duration.inSeconds / distanceKm).round();
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  double? _calcAvgSpeedKmh(Duration duration, double distanceMeters) {
    if (duration.inSeconds <= 0) return null;
    return (distanceMeters / 1000) / (duration.inSeconds / 3600);
  }

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
        leading: _state == _TrackingState.idle && widget.onRunCompleted != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onRunCompleted,
              )
            : null,
      ),
      body: switch (_state) {
        _TrackingState.idle => _buildIdleContent(),
        _TrackingState.running => _buildRunningContent(),
        _TrackingState.paused => _buildRunningContent(),
        _TrackingState.completed => _buildCompletedContent(),
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
            if (_myClubs != null && _myClubs!.isNotEmpty) ...[
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    AppLocalizations.of(context)!.runSelectClubTitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  subtitle: Text(
                    _selectedScoringClub?.name ?? AppLocalizations.of(context)!.runClubNotSelected,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.edit, size: 20),
                  onTap: _showPreRunClubSelectionDialog,
                ),
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
    final l10n = AppLocalizations.of(context)!;
    final duration = _session?.duration ?? Duration.zero;
    final distance = _session?.distance ?? 0.0;
    final gpsStatus = _session?.gpsStatus ?? GpsStatus.searching;
    final gpsPoints = _session?.gpsPoints ?? [];
    final paceStr = _formatPace(duration, distance);
    final workout = _session?.workout;

    return Column(
      children: [
        if (workout != null)
          Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              workout.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        Expanded(
          flex: 2,
          child: RunRouteMap(gpsPoints: gpsPoints),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'GPS: ${_getGpsStatusText(context, gpsStatus)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _state == _TrackingState.paused
                      ? Colors.amber
                      : gpsStatus == GpsStatus.recording
                          ? Colors.green
                          : Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _formatDuration(duration),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _formatDistance(context, distance),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                paceStr != null
                    ? '${l10n.runPace}: ${l10n.runPaceValue(paceStr)}'
                    : '${l10n.runPace}: ${l10n.runNoData}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: paceStr != null ? null : Colors.grey,
                    ),
              ),
              if (_session?.heartRate != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      l10n.runHeartRateValue(_session!.heartRate!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : (_state == _TrackingState.paused ? _resumeRun : _pauseRun),
                  icon: Icon(
                    _state == _TrackingState.paused
                        ? Icons.play_arrow
                        : Icons.pause,
                  ),
                  label: Text(
                    _state == _TrackingState.paused
                        ? l10n.runResume
                        : l10n.runPause,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _finishRun,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.stop),
                  label: Text(_isSubmitting ? l10n.runFinishing : l10n.runFinish),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
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

    final int? heartRateBpm = _session?.heartRate;

    final gpsPoints = (_session?.gpsPoints ?? [])
        .map((p) => GpsPointModel(
              latitude: p.latitude,
              longitude: p.longitude,
              timestamp: p.timestamp,
            ))
        .toList();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Text(
              l10n.runDone,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (gpsPoints.length >= 2) ...[
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: RunDetailMap(gpsPoints: gpsPoints),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                      _selectedScoringClub != null
                          ? l10n.runCountedTerritoryForClub(_selectedScoringClub!.name)
                          : l10n.runCountedTerritory,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              l10n.runRPE,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Slider(
              value: _rpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _rpe.toString(),
              onChanged: (double value) {
                setState(() {
                  _rpe = value.toInt();
                });
              },
            ),
            Text(
              '$_rpe / 10',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l10n.notesForCoach,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSubmitting ? null : _submitCompletedRun,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.runReady),
            ),
          ],
        ),
      ),
    );
  }
}
