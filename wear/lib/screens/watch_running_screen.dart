import 'package:flutter/material.dart';
import 'package:wear/wear.dart';

/// Active run screen showing time, distance, pace and heart rate.
/// Provides pause/resume and stop buttons.
class WatchRunningScreen extends StatelessWidget {
  final Map<String, dynamic> runState;
  final bool isPaused;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const WatchRunningScreen({
    super.key,
    required this.runState,
    required this.isPaused,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDistance(int meters) {
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(2)}km';
  }

  String _formatPace(int secPerKm) {
    final m = secPerKm ~/ 60;
    final s = secPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')}/km';
  }

  @override
  Widget build(BuildContext context) {
    final durationSec = (runState['durationSec'] as int?) ?? 0;
    final distanceM = (runState['distanceM'] as int?) ?? 0;
    final paceSecPerKm = runState['paceSecPerKm'] as int?;
    final bpm = runState['bpm'] as int?;

    return AmbientMode(
      builder: (context, mode, child) {
        final isAmbient = mode == WearMode.ambient;
        return Scaffold(
          backgroundColor: Colors.black,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Timer
                Text(
                  _formatDuration(durationSec),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                // Distance
                Text(
                  _formatDistance(distanceM),
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                // Pace
                Text(
                  paceSecPerKm != null ? _formatPace(paceSecPerKm) : '--:--/km',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
                // Heart rate (only if available)
                if (bpm != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite, size: 12, color: Colors.red),
                      const SizedBox(width: 2),
                      Text(
                        '$bpm bpm',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ),
                ],
                if (!isAmbient) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pause / Resume
                      GestureDetector(
                        onTap: isPaused ? onResume : onPause,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      // Stop
                      GestureDetector(
                        onTap: onStop,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stop,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
