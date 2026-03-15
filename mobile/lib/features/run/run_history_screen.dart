import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/run_history_item.dart';
import '../../shared/models/run_stats.dart';
import '../../shared/models/calendar_model.dart';
import '../../shared/models/my_club_model.dart';

/// Training tab — club calendar, run stats, run history, workouts, trainers.
class RunHistoryScreen extends StatefulWidget {
  final Function(String? scheduledItemId) onStartRun;

  const RunHistoryScreen({super.key, required this.onStartRun});

  @override
  State<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends State<RunHistoryScreen> {
  final _runService = ServiceLocator.runService;

  // Stats & history
  late Future<RunStats> _statsFuture;
  final List<RunHistoryItem> _runs = [];
  bool _historyLoading = false;
  bool _historyError = false;
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;

  // Club calendar
  final ScrollController _calendarScrollController = ScrollController(
    initialScrollOffset: 14 * 58.0 - 150.0,
  );
  DateTime _selectedDate = DateTime.now();
  late Future<String?> _trainingClubIdFuture;
  late Future<List<CalendarItemModel>> _calendarFuture;
  List<CalendarItemModel> _loadedCalendarItems = [];
  String? _myRoleInClub;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _statsFuture = _runService.getRunStats();
    _loadHistory();
    _trainingClubIdFuture = _resolveTrainingClubId();
    _calendarFuture = _fetchCalendar();
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
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
      _trainingClubIdFuture = _resolveTrainingClubId();
      _calendarFuture = _fetchCalendar();
    });
    await _loadHistory();
  }

  Future<String?> _resolveTrainingClubId() async {
    try {
      final myClubs = await ServiceLocator.clubsService.getMyClubs();
      if (myClubs.isEmpty) {
        if (mounted) setState(() => _myRoleInClub = null);
        return null;
      }
      final cachedClubId = ServiceLocator.currentClubService.currentClubId;
      MyClubModel? selectedClub;
      if (cachedClubId != null && cachedClubId.isNotEmpty) {
        for (final c in myClubs) {
          if (c.id == cachedClubId) {
            selectedClub = c;
            break;
          }
        }
      }
      selectedClub ??= myClubs
              .where((c) => c.status == 'active')
              .cast<MyClubModel?>()
              .firstOrNull ??
          myClubs.first;
      await ServiceLocator.currentClubService.setCurrentClubId(selectedClub.id);
      if (mounted) setState(() => _myRoleInClub = selectedClub!.role);
      return selectedClub.id;
    } catch (_) {
      if (mounted) setState(() => _myRoleInClub = null);
      return null;
    }
  }

  Future<List<CalendarItemModel>> _fetchCalendar() async {
    final clubId = await _trainingClubIdFuture;
    if (clubId == null || clubId.isEmpty) return [];
    // Capture selected date before the async gap so we can discard stale results.
    final fetchDate = _selectedDate;
    final yearMonth = DateFormat('yyyy-MM').format(fetchDate);
    final result = await ServiceLocator.clubsService.getCalendar(clubId, yearMonth);
    // Only write items if the user hasn't navigated to a different month/day.
    if (mounted && _selectedDate == fetchDate) {
      setState(() => _loadedCalendarItems = result);
    }
    return result;
  }

  Future<void> _handleStartRun() async {
    // Reuse the already-resolved club selection from _resolveTrainingClubId
    // so there is a single source of truth for which club to use.
    final clubId = await _trainingClubIdFuture;
    if (clubId == null) {
      if (mounted) widget.onStartRun(null);
      return;
    }

    try {
      final now = DateTime.now();
      final monthStr = DateFormat('yyyy-MM').format(now);
      final calendar = await ServiceLocator.clubsService.getCalendar(clubId, monthStr);
      final todayTasks = calendar
          .where((item) =>
              item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day &&
              !item.isCompleted)
          .toList();

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
                      task.type == CalendarItemType.event
                          ? Icons.directions_run
                          : Icons.note_alt_outlined,
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

      if (mounted) widget.onStartRun(selectedTask?.id);
    } catch (_) {
      if (mounted) widget.onStartRun(null);
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
    if (meters < 1000) return l10n.distanceMeters(meters.toString());
    return l10n.distanceKm((meters / 1000).toStringAsFixed(2));
  }

  String _formatDateRelative(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    if (dateDay == today) return l10n.runHistoryToday;
    if (dateDay == today.subtract(const Duration(days: 1))) return l10n.runHistoryYesterday;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Color _rpeColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final archiveCount = _runs.length > 1 ? _runs.length - 1 : 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.runHistoryTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleStartRun,
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.quickStartRun),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // Club weekly calendar
            SliverToBoxAdapter(child: _buildCalendarSection(l10n)),

            // Stats summary
            SliverToBoxAdapter(child: _buildStatsSection(l10n)),

            // Last run card
            if (_runs.isNotEmpty)
              SliverToBoxAdapter(child: _buildLastRunCard(l10n, _runs.first)),

            // My Workouts section (above journal)
            SliverToBoxAdapter(child: _buildMyWorkoutsSection(l10n)),

            // Run archive header
            if (_runs.length > 1)
              SliverToBoxAdapter(child: _buildSectionHeader(l10n.runHistoryTitle)),

            // Run archive list
            if (_historyLoading && _runs.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_historyError && _runs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Text(l10n.runDetailLoadError),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _refresh, child: Text(l10n.retry)),
                      ],
                    ),
                  ),
                ),
              )
            else if (_runs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.directions_run, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.runHistoryEmpty,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.runHistoryEmptyHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildRunCard(_runs[index + 1]),
                  childCount: archiveCount,
                ),
              ),

            // Load more
            if (_hasMore && _runs.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _loadingMore
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: TextButton(
                            onPressed: _loadMore,
                            child: Text(l10n.loadMore),
                          ),
                        ),
                ),
              ),

            // Find Trainer section
            SliverToBoxAdapter(child: _buildFindTrainerSection(l10n)),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────────

  Widget _buildCalendarSection(AppLocalizations l10n) {
    return FutureBuilder<String?>(
      future: _trainingClubIdFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final clubId = snapshot.data;
        if (clubId == null || clubId.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.group_off, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.noClubChats,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/map?showClubs=true'),
                      child: Text(l10n.quickFindClub),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendarStrip(),
            _buildDayItems(l10n),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildCalendarStrip() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            DateFormat('MMMM yyyy').format(_selectedDate),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            controller: _calendarScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 45, // 14 days back + today + 30 forward
            itemBuilder: (context, index) {
              final day = today
                  .subtract(const Duration(days: 14))
                  .add(Duration(days: index));
              final isSelected = day.year == _selectedDate.year &&
                  day.month == _selectedDate.month &&
                  day.day == _selectedDate.day;
              final isToday = day == today;
              final isPast = day.isBefore(today);

              Color dayNumColor;
              Color dayNameColor;
              if (isSelected) {
                dayNumColor = Colors.white;
                dayNameColor = Colors.white;
              } else if (isPast) {
                dayNumColor = Colors.grey.shade400;
                dayNameColor = Colors.grey.shade400;
              } else if (isToday) {
                dayNumColor = Theme.of(context).colorScheme.primary;
                dayNameColor = Theme.of(context).colorScheme.primary;
              } else {
                dayNumColor = Colors.black;
                dayNameColor = Colors.grey.shade600;
              }

              return GestureDetector(
                onTap: () {
                  final oldMonth = _selectedDate.month;
                  final oldYear = _selectedDate.year;
                  setState(() {
                    _selectedDate = day;
                    if (day.month != oldMonth || day.year != oldYear) {
                      _loadedCalendarItems = [];
                      _calendarFuture = _fetchCalendar();
                    }
                  });
                },
                child: Container(
                  width: 52,
                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : (isToday
                            ? const Color.fromRGBO(233, 213, 255, 0.1)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      width: isToday && !isSelected ? 1.5 : 1.0,
                      color: isSelected
                          ? Colors.transparent
                          : (isToday
                              ? Theme.of(context).colorScheme.primary
                              : (isPast
                                  ? Colors.grey.shade100
                                  : Colors.grey.shade200)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: (isSelected || isToday)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: dayNameColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: dayNumColor,
                        ),
                      ),
                      _buildDots(day),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDots(DateTime day) {
    final items = _loadedCalendarItems
        .where((i) =>
            i.date.year == day.year &&
            i.date.month == day.month &&
            i.date.day == day.day)
        .toList();

    final hasEvent = items.any((i) => i.type == CalendarItemType.event);
    final hasNote = items.any((i) => i.type == CalendarItemType.note);

    if (!hasEvent && !hasNote) return const SizedBox(height: 6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasEvent) _dot(Colors.blue),
        if (hasEvent && hasNote) const SizedBox(width: 3),
        if (hasNote) _dot(Colors.orange),
      ],
    );
  }

  Widget _dot(Color color) => Container(
        width: 5,
        height: 5,
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildDayItems(AppLocalizations l10n) {
    return FutureBuilder<List<CalendarItemModel>>(
      future: _calendarFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                snapshot.error.toString(),
                style: TextStyle(color: Colors.red.shade400, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final allItems = snapshot.data ?? [];
        final dayItems = allItems
            .where((item) =>
                item.date.year == _selectedDate.year &&
                item.date.month == _selectedDate.month &&
                item.date.day == _selectedDate.day)
            .toList();

        if (dayItems.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                l10n.noData,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: dayItems.map((item) => _buildCalendarItemCard(item, l10n)).toList(),
        );
      },
    );
  }

  Widget _buildCalendarItemCard(CalendarItemModel item, AppLocalizations l10n) {
    final isEvent = item.type == CalendarItemType.event;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isEvent ? () => context.push('/event/${item.id}') : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: item.isPersonal
                      ? Colors.purple.shade50
                      : (isEvent ? Colors.blue.shade50 : Colors.orange.shade50),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEvent ? Icons.directions_run : Icons.note_alt_outlined,
                  size: 20,
                  color: item.isPersonal
                      ? Colors.purple
                      : (isEvent ? Colors.blue : Colors.orange),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.startTime != null)
                          Text(
                            item.startTime!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        if (item.startTime != null) const SizedBox(width: 8),
                        if (item.isPersonal)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.tabPersonal.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (item.startTime != null) const SizedBox(height: 2),
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (item.description != null && item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (item.isCompleted)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (isEvent)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

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
        if (stats == null || snapshot.hasError || stats.totalRuns == 0) {
          return const SizedBox.shrink();
        }
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.runStatsTitle,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statItem(
                          value: stats.totalRuns.toString(),
                          label: l10n.runStatsTotalRuns),
                    ),
                    Expanded(
                      child: _statItem(
                          value: _formatTotalDuration(stats.totalDuration),
                          label: l10n.runStatsTotalTime),
                    ),
                    Expanded(
                      child: _statItem(
                          value: _formatDistance(context, stats.totalDistance),
                          label: l10n.runStatsTotalDistance),
                    ),
                    Expanded(
                      child: _statItem(
                          value: _formatPace(stats.averagePace),
                          label: l10n.runStatsAvgPace),
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
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Last run ──────────────────────────────────────────────────────────────

  Widget _buildLastRunCard(AppLocalizations l10n, RunHistoryItem run) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/run/detail/${run.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withAlpha(200),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateRelative(context, run.startedAt),
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const Icon(Icons.directions_run, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDistance(context, run.distance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatDuration(run.duration)}  •  ${AppLocalizations.of(context)!.runPaceValue(_formatPace(run.paceSecondsPerKm))}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (run.rpe != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RPE ${run.rpe}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Run archive ───────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
      ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDateRelative(context, run.startedAt),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                  Text(
                    '${run.startedAt.hour.toString().padLeft(2, '0')}:${run.startedAt.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDistance(context, run.distance),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDuration(run.duration)}  •  ${l10n.runPaceValue(_formatPace(run.paceSecondsPerKm))}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
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

  // ── My Workouts ───────────────────────────────────────────────────────────

  Widget _buildMyWorkoutsSection(AppLocalizations l10n) {
    final canCreateTraining =
        _myRoleInClub == 'trainer' || _myRoleInClub == 'leader';
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center),
                const SizedBox(width: 8),
                Text(
                  l10n.workouts,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/workout/create'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.createWorkout),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => context.push('/workout/list'),
                  child: Text(l10n.myWorkouts),
                ),
              ],
            ),
            if (canCreateTraining) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/event/create?type=training'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.eventTypeTraining),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Find Trainer ──────────────────────────────────────────────────────────

  Widget _buildFindTrainerSection(AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search),
                const SizedBox(width: 8),
                Text(
                  l10n.findTrainers,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/trainers'),
                child: Text(l10n.trainersList),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
