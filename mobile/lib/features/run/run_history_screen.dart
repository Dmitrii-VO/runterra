import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/run_history_item.dart';
import '../../shared/models/run_stats.dart';

/// Training journal — run history with stats summary.
class RunHistoryScreen extends StatefulWidget {
  final VoidCallback onStartRun;

  const RunHistoryScreen({super.key, required this.onStartRun});

  @override
  State<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends State<RunHistoryScreen> {
  final _runService = ServiceLocator.runService;

  late Future<RunStats> _statsFuture;
  late Future<List<RunHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _statsFuture = _runService.getRunStats();
    _historyFuture = _runService.getRunHistory();
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  String _formatPace(int paceSecondsPerKm) {
    if (paceSecondsPerKm <= 0) return '--:--';
    final m = paceSecondsPerKm ~/ 60;
    final s = paceSecondsPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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

  String _formatDistance(BuildContext context, int meters) {
    final l10n = AppLocalizations.of(context)!;
    if (meters < 1000) {
      return l10n.distanceMeters(meters.toString());
    }
    return l10n.distanceKm((meters / 1000).toStringAsFixed(2));
  }

  String _formatDateRelative(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return l10n.runHistoryToday;
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return l10n.runHistoryYesterday;
    }

    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.runHistoryTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onStartRun,
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.runStart),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // Stats card
            _buildStatsSection(l10n),
            const SizedBox(height: 8),
            // Run history list
            _buildHistorySection(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(AppLocalizations l10n) {
    return FutureBuilder<RunStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data;
        if (stats == null || snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (stats.totalRuns == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.runStatsTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statItem(
                        value: stats.totalRuns.toString(),
                        label: l10n.runStatsTotalRuns,
                      ),
                    ),
                    Expanded(
                      child: _statItem(
                        value: _formatDistance(context, stats.totalDistance),
                        label: l10n.runStatsTotalDistance,
                      ),
                    ),
                    Expanded(
                      child: _statItem(
                        value: _formatPace(stats.averagePace),
                        label: l10n.runStatsAvgPace,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statItem({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
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
    );
  }

  Widget _buildHistorySection(AppLocalizations l10n) {
    return FutureBuilder<List<RunHistoryItem>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Text(l10n.runDetailLoadError),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _refresh,
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final runs = snapshot.data ?? [];
        if (runs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.directions_run, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    l10n.runHistoryEmpty,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.runHistoryEmptyHint,
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

        return Column(
          children: runs.map((run) => _buildRunCard(run)).toList(),
        );
      },
    );
  }

  Widget _buildRunCard(RunHistoryItem run) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/run/detail/${run.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateRelative(context, run.startedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Text(
                    '${run.startedAt.hour.toString().padLeft(2, '0')}:${run.startedAt.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Distance
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDistance(context, run.distance),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDuration(run.duration)}  •  ${l10n.runPaceValue(_formatPace(run.paceSecondsPerKm))}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
