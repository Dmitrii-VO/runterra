import 'package:flutter/material.dart';
import 'package:wear/wear.dart';

/// Idle state screen shown when no run is active.
/// Single button to start a run on the paired phone.
class WatchIdleScreen extends StatelessWidget {
  final VoidCallback onStart;
  final bool isRound;

  const WatchIdleScreen({super.key, required this.onStart, this.isRound = false});

  @override
  Widget build(BuildContext context) {
    return AmbientMode(
      builder: (context, mode, child) {
        final isAmbient = mode == WearMode.ambient;
        // Round screens need extra padding to avoid content clipping at corners
        final padding = isRound
            ? const EdgeInsets.all(24)
            : const EdgeInsets.all(8);
        return Scaffold(
          backgroundColor: isAmbient ? Colors.black : Colors.black87,
          body: Padding(
            padding: padding,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_run,
                    size: 32,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 8),
                  if (!isAmbient)
                    ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                      ),
                      child: const Icon(Icons.play_arrow, size: 32),
                    )
                  else
                    const Text(
                      'RUNTERRA',
                      style: TextStyle(fontSize: 10, color: Colors.white54),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
