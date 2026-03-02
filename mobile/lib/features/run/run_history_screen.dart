import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/run_history_item.dart';
import '../../shared/models/run_stats.dart';
import '../../shared/models/calendar_model.dart';

/// Training journal — run history with stats summary.
class RunHistoryScreen extends StatefulWidget {
  final Function(String? scheduledItemId) onStartRun;

  const RunHistoryScreen({super.key, required this.onStartRun});

  @override
  State<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends State<RunHistoryScreen> {
  final _runService = ServiceLocator.runService;

  late Future<RunStats> _statsFuture;
  final List<RunHistoryItem> _runs = [];
  bool _historyLoading = false;
  bool _historyError = false;
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _statsFuture = _runService.getRunStats();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_historyLoading) return;
    setState(() {
      _historyLoading = true;
      _historyError = false;
    });
    try {
      final items = await _runService.getRunHistory(limit: _pageSize, offset: 0);
      if (mounted) {
        setState(() {
          _runs
            ..clear()
            ..addAll(items);
          _offset = items.length;
          _hasMore = items.length == _pageSize;
          _historyLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _historyLoading = false;
          _historyError = true;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final items = await _runService.getRunHistory(limit: _pageSize, offset: _offset);
      if (mounted) {
        setState(() {
          _runs.addAll(items);
          _offset += items.length;
          _hasMore = items.length == _pageSize;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = _runService.getRunStats();
    });
    await _loadHistory();
  }

  Future<String?> _resolveClubId() async {
    final cachedClubId = ServiceLocator.currentClubService.currentClubId;
    if (cachedClubId != null && cachedClubId.isNotEmpty) return cachedClubId;

    try {
      final myClubs = await ServiceLocator.clubsService.getMyClubs();
      if (myClubs.isEmpty) return null;
      final selectedClub = myClubs.first;
      await ServiceLocator.currentClubService.setCurrentClubId(selectedClub.id);
      return selectedClub.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleStartRun() async {
    final clubId = await _resolveClubId();
    
    if (clubId == null) {
      widget.onStartRun(null);
      return;
    }

    try {
      final now = DateTime.now();
      final monthStr = DateFormat('yyyy-MM').format(now);
      final calendar = await ServiceLocator.clubsService.getCalendar(clubId, monthStr);
      
      final todayTasks = calendar.where((item) => 
        item.date.year == now.year && 
        item.date.month == now.month && 
        item.date.day == now.day &&
        !item.isCompleted
      ).toList();

      if (todayTasks.isEmpty || !mounted) {
        widget.onStartRun(null);
        return;
      }

      final selectedTask = await showModalBottomSheet<CalendarItemModel>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(ctx)!.runSelectTaskTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...todayTasks.map((task) => ListTile(
                leading: Icon(
                  task.type == CalendarItemType.event ? Icons.directions_run : Icons.note_alt_outlined,
                  color: task.isPersonal ? Colors.purple : Colors.blue,
                ),
                title: Text(task.name),
                subtitle: Text(task.startTime ?? ''),
                onTap: () => Navigator.pop(ctx, task),
              )),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(AppLocalizations.of(ctx)!.runNoTask),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );

      if (mounted) {
        widget.onStartRun(selectedTask?.id);
      }
    } catch (e) {
      widget.onStartRun(null);
    }
  }

  String _formatTotalDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
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
        onPressed: _handleStartRun,
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.quickStartRun),
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
                        value: _formatTotalDuration(stats.totalDuration),
                        label: l10n.runStatsTotalTime,
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
    if (_historyLoading && _runs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_historyError && _runs.isEmpty) {
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

    if (_runs.isEmpty) {
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
      children: [
        ..._runs.map((run) => _buildRunCard(run)),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _loadingMore
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: _loadMore,
                    child: Text(l10n.loadMore),
                  ),
          ),
      ],
    );
  }

  Color _rpeColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 6) return Colors.orange;
    return Colors.red;
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
              if (run.rpe != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _rpeColor(run.rpe!).withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'RPE ${run.rpe}',
                    style: TextStyle(fontSize: 11, color: _rpeColor(run.rpe!)),
                  ),
                ),
              ],
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

