import 'dart:async';
import 'package:watch_connectivity/watch_connectivity.dart';

/// Handles communication between the watch and the paired phone.
///
/// Sends commands (start/pause/resume/stop/hr) to the phone and
/// exposes a stream of run state updates received from the phone.
class WatchConnectivityService {
  final WatchConnectivity _wc = WatchConnectivity();
  final _runStateController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;

  /// Stream of run state updates from the phone (type == 'update').
  Stream<Map<String, dynamic>> get runStateStream => _runStateController.stream;

  void init() {
    _messageSubscription = _wc.messageStream.listen((message) {
      if (message['type'] == 'update') {
        _runStateController.add(message);
      }
    });
  }

  /// Send a run control command to the phone.
  Future<void> sendCommand(String cmd) async {
    try {
      await _wc.sendMessage({'cmd': cmd});
    } catch (_) {
      // Phone not reachable — ignore
    }
  }

  /// Send heart rate reading to the phone.
  Future<void> sendHeartRate(int bpm) async {
    try {
      await _wc.sendMessage({'cmd': 'hr', 'bpm': bpm});
    } catch (_) {
      // Phone not reachable — ignore
    }
  }

  void dispose() {
    _messageSubscription?.cancel();
    _runStateController.close();
  }
}
