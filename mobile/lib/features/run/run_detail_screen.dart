import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/run_model.dart';
import 'widgets/run_detail_map.dart';

/// Detail view for a completed run with GPS route and metrics.
/// If [clientId] is provided, fetches via the trainer endpoint (trainer viewing a client's run).
class RunDetailScreen extends StatefulWidget {
  final String runId;
  final String? clientId;

  const RunDetailScreen({super.key, required this.runId, this.clientId});

  @override
  State<RunDetailScreen> createState() => _RunDetailScreenState();
}

class _RunDetailScreenState extends State<RunDetailScreen> {
  late Future<RunDetailModel> _detailFuture;

  @override
  void initState() {
    super.initState();
    if (widget.clientId != null) {
      _detailFuture = ServiceLocator.trainerService.getClientRunDetail(
        widget.clientId!,
        widget.runId,
      );
    } else {
      _detailFuture = ServiceLocator.runService.getRunDetail(widget.runId);
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDistance(BuildContext context, double meters) {
    final l10n = AppLocalizations.of(context)!;
    if (meters < 1000) {
      return l10n.distanceMeters(meters.toStringAsFixed(0));
    }
    return l10n.distanceKm((meters / 1000).toStringAsFixed(2));
  }

  String _formatPace(int durationSeconds, double distanceMeters) {
    if (distanceMeters <= 0) return '--:--';
    final paceSeconds = ((durationSeconds / distanceMeters) * 1000).round();
    final m = paceSeconds ~/ 60;
    final s = paceSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _formatSpeed(int durationSeconds, double distanceMeters) {
    if (durationSeconds <= 0) return '0.0';
    final speedKmh = (distanceMeters / 1000) / (durationSeconds / 3600);
    return speedKmh.toStringAsFixed(1);
  }

  int _calcCalories(double distanceMeters) {
    return ((distanceMeters / 1000) * 65).round();
  }

  Widget _buildMetricCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.runDetailTitle),
      ),
      body: FutureBuilder<RunDetailModel>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.runDetailLoadError),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (widget.clientId != null) {
                          _detailFuture = ServiceLocator.trainerService.getClientRunDetail(
                            widget.clientId!,
                            widget.runId,
                          );
                        } else {
                          _detailFuture = ServiceLocator.runService.getRunDetail(widget.runId);
                        }
                      });
                    },
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          final run = snapshot.data!;
          final durationSec = run.duration.inSeconds;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map with GPS route
                if (run.gpsPoints.isNotEmpty)
                  SizedBox(
                    height: 280,
                    child: RunDetailMap(gpsPoints: run.gpsPoints),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date/time header
                      Text(
                        '${run.startedAt.day.toString().padLeft(2, '0')}.${run.startedAt.month.toString().padLeft(2, '0')}.${run.startedAt.year}  '
                        '${run.startedAt.hour.toString().padLeft(2, '0')}:${run.startedAt.minute.toString().padLeft(2, '0')}'
                        ' — '
                        '${run.endedAt.hour.toString().padLeft(2, '0')}:${run.endedAt.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Metrics grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.0,
                        children: [
                          _buildMetricCard(
                            value: _formatDuration(durationSec),
                            label: l10n.runDuration,
                            icon: Icons.timer,
                          ),
                          _buildMetricCard(
                            value: _formatDistance(context, run.distance),
                            label: l10n.runDistance,
                            icon: Icons.straighten,
                          ),
                          _buildMetricCard(
                            value: l10n.runPaceValue(
                              _formatPace(durationSec, run.distance),
                            ),
                            label: l10n.runPace,
                            icon: Icons.speed,
                          ),
                          _buildMetricCard(
                            value: l10n.runAvgSpeedValue(
                              _formatSpeed(durationSec, run.distance),
                            ),
                            label: l10n.runAvgSpeed,
                            icon: Icons.show_chart,
                          ),
                          _buildMetricCard(
                            value: l10n.runCaloriesValue(_calcCalories(run.distance)),
                            label: l10n.runCalories,
                            icon: Icons.local_fire_department,
                          ),
                          _buildMetricCard(
                            value: run.gpsPoints.length.toString(),
                            label: l10n.runGpsPoints,
                            icon: Icons.location_on,
                          ),
                          if (run.avgCadence != null)
                            _buildMetricCard(
                              value: l10n.runCadenceValue(run.avgCadence!),
                              label: l10n.runCadence,
                              icon: Icons.directions_walk,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
