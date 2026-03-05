import 'dart:async';
import 'package:watch_connectivity/watch_connectivity.dart';
import '../api/run_service.dart';
import '../models/run_session.dart';
import 'current_club_service.dart';

/// Bridge between the Wear OS watch app and RunService.
///
/// Listens for commands from the watch (start/pause/resume/stop/hr) and
/// forwards them to RunService. Broadcasts run state to the watch every 5s
/// while a run is active.
class WatchService {
  final RunService _runService;
  final CurrentClubService _currentClubService;
  final WatchConnectivity _wc;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  Timer? _broadcastTimer;

  WatchService({
    required RunService runService,
    required CurrentClubService currentClubService,
  })  : _runService = runService,
        _currentClubService = currentClubService,
        _wc = WatchConnectivity();

  /// Start listening for watch messages. Call once after ServiceLocator.init().
  void init() {
    _messageSubscription = _wc.messageStream.listen(_handleWatchMessage);
  }

  void _handleWatchMessage(Map<String, dynamic> message) {
    final cmd = message['cmd'] as String?;
    switch (cmd) {
      case 'start':
        _runService
            .startRun(scoringClubId: _currentClubService.currentClubId)
            .then((_) => _startBroadcasting())
            .catchError((_) {});
      case 'pause':
        try {
          _runService.pauseRun();
        } catch (_) {}
      case 'resume':
        _runService.resumeRun().catchError((_) {});
        _startBroadcasting();
      case 'stop':
        _runService
            .stopRun()
            .then((_) => _stopBroadcasting())
            .catchError((_) {});
      case 'getState':
        // Watch just booted — send current state immediately if run is active
        final current = _runService.currentSession;
        if (current != null) {
          _broadcastRunState();
          if (current.status == RunSessionStatus.running) _startBroadcasting();
        }
      case 'hr':
        final bpm = message['bpm'];
        if (bpm is int) _runService.updateHeartRate(bpm);
    }
  }

  void _startBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _broadcastRunState();
    });
  }

  void _stopBroadcasting() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
  }

  Future<void> _broadcastRunState() async {
    final session = _runService.currentSession;
    if (session == null) return;

    final distanceM = session.distance;
    // Calculate effective duration: accumulated + time since last resume (if running)
    final Duration effectiveDuration;
    if (session.status == RunSessionStatus.running && session.lastResumedAt != null) {
      effectiveDuration = session.accumulatedDuration +
          DateTime.now().difference(session.lastResumedAt!);
    } else {
      effectiveDuration = session.accumulatedDuration;
    }
    final durationSec = effectiveDuration.inSeconds;
    int? paceSecPerKm;
    if (distanceM > 50) {
      paceSecPerKm = (durationSec / (distanceM / 1000)).round();
    }

    final message = <String, dynamic>{
      'type': 'update',
      'state': session.status.name,
      'durationSec': durationSec,
      'distanceM': distanceM.round(),
      if (paceSecPerKm != null) 'paceSecPerKm': paceSecPerKm,
      if (session.heartRate != null) 'bpm': session.heartRate,
    };

    try {
      await _wc.sendMessage(message);
    } catch (_) {
      // Watch not reachable — ignore silently
    }
  }

  /// Resume broadcasting if a run is already active (e.g. after app restart).
  void maybeResumeBroadcasting() {
    final session = _runService.currentSession;
    if (session != null && session.status == RunSessionStatus.running) {
      _startBroadcasting();
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
    _broadcastTimer?.cancel();
  }
}
