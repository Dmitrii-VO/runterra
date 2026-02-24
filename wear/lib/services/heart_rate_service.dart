import 'dart:async';
import 'package:flutter/services.dart';

/// Reads heart rate from the watch sensor via a platform channel.
///
/// The native side (HeartRatePlugin.kt) registers a SensorManager listener
/// for Sensor.TYPE_HEART_RATE and emits values through an EventChannel.
class HeartRateService {
  static const _channel = EventChannel('com.runterra.wear/heart_rate');

  StreamSubscription<int>? _subscription;
  final _controller = StreamController<int>.broadcast();

  /// Stream of heart rate readings in BPM from the watch sensor.
  Stream<int> get heartRateStream => _controller.stream;

  HeartRateService() {
    _subscription = _channel
        .receiveBroadcastStream()
        .where((event) => event is int && event > 0)
        .cast<int>()
        .listen(
          _controller.add,
          onError: (_) {}, // Sensor unavailable — ignore silently
        );
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
