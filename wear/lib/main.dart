import 'package:flutter/material.dart';
import 'package:wear/wear.dart';
import 'screens/watch_idle_screen.dart';
import 'screens/watch_running_screen.dart';
import 'services/heart_rate_service.dart';
import 'services/watch_connectivity_service.dart';

void main() {
  runApp(const WearApp());
}

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        return MaterialApp(
          title: 'Runterra',
          theme: ThemeData.dark(useMaterial3: true),
          home: const WatchHome(),
        );
      },
    );
  }
}

class WatchHome extends StatefulWidget {
  const WatchHome({super.key});

  @override
  State<WatchHome> createState() => _WatchHomeState();
}

class _WatchHomeState extends State<WatchHome> {
  final _connectivityService = WatchConnectivityService();
  final _heartRateService = HeartRateService();

  bool _isRunning = false;
  bool _isPaused = false;
  Map<String, dynamic> _runState = {};

  @override
  void initState() {
    super.initState();
    _connectivityService.init();

    // Receive run state updates from the phone
    _connectivityService.runStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _runState = state;
        final s = state['state'] as String?;
        _isRunning = s == 'running' || s == 'paused';
        _isPaused = s == 'paused';
      });
    });

    // Send heart rate readings to phone every time sensor fires
    _heartRateService.heartRateStream.listen((bpm) {
      _connectivityService.sendHeartRate(bpm);
    });
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    _heartRateService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, child) {
        final isRound = shape == WearShape.round;
        if (_isRunning) {
          return WatchRunningScreen(
            runState: _runState,
            isPaused: _isPaused,
            isRound: isRound,
            onPause: () => _connectivityService.sendCommand('pause'),
            onResume: () => _connectivityService.sendCommand('resume'),
            onStop: () {
              _connectivityService.sendCommand('stop');
              setState(() {
                _isRunning = false;
                _isPaused = false;
                _runState = {};
              });
            },
          );
        }
        return WatchIdleScreen(
          onStart: () => _connectivityService.sendCommand('start'),
          isRound: isRound,
        );
      },
    );
  }
}
