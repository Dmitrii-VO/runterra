import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../di/service_locator.dart';
import '../../models/calendar_model.dart';

/// Self-contained training calendar widget for ProfileScreen.
/// Shows a monthly grid (Mon–Sun) with dots for completed runs and registered events.
/// Navigation: run → /run/detail/:id; event → /event/:id; both → bottom sheet picker.
class TrainingCalendarWidget extends StatefulWidget {
  const TrainingCalendarWidget({super.key});

  @override
  State<TrainingCalendarWidget> createState() => _TrainingCalendarWidgetState();
}

class _TrainingCalendarWidgetState extends State<TrainingCalendarWidget> {
  late DateTime _currentMonth;
  Future<List<CalendarDayModel>>? _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _currentMonth = DateTime.utc(now.year, now.month);
    _future = _load(_currentMonth);
  }

  Future<List<CalendarDayModel>> _load(DateTime month) {
    return ServiceLocator.usersService.getCalendar(month.year, month.month);
  }

  void _prevMonth() {
    final prev = DateTime.utc(_currentMonth.year, _currentMonth.month - 1);
    setState(() {
      _currentMonth = prev;
      _future = _load(prev);
    });
  }

  void _nextMonth() {
    final next = DateTime.utc(_currentMonth.year, _currentMonth.month + 1);
    setState(() {
      _currentMonth = next;
      _future = _load(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthLabel = DateFormat('MMMM yyyy', Localizations.localeOf(context).toString())
        .format(_currentMonth);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: title + month navigation
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.calendarTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _prevMonth,
                  visualDensity: VisualDensity.compact,
                ),
                Text(monthLabel, style: Theme.of(context).textTheme.bodyMedium),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<CalendarDayModel>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const SizedBox(
                    height: 60,
                    child: Center(child: Icon(Icons.error_outline, color: Colors.grey)),
                  );
                }
                final days = snapshot.data ?? [];
                return _CalendarGrid(
                  month: _currentMonth,
                  days: days,
                  onDayTap: (day) => _onDayTap(context, day, l10n),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onDayTap(BuildContext context, CalendarDayModel day, AppLocalizations l10n) {
    final hasRuns = day.runs.isNotEmpty;
    final hasEvents = day.events.isNotEmpty;

    if (!hasRuns && !hasEvents) return;

    if (hasRuns && !hasEvents && day.runs.length == 1) {
      context.push('/run/detail/${day.runs.first.id}');
      return;
    }
    if (!hasRuns && hasEvents && day.events.length == 1) {
      context.push('/event/${day.events.first.id}');
      return;
    }

    // Multiple items or mixed — show bottom sheet
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _DayPickerSheet(day: day, l10n: l10n),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<CalendarDayModel> days;
  final void Function(CalendarDayModel) onDayTap;

  const _CalendarGrid({
    required this.month,
    required this.days,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    // Jan 1, 2024 was a Monday — use as anchor to get Mon–Sun abbreviated names
    final weekDayLabels = List.generate(
      7,
      (i) => DateFormat.E(locale).format(DateTime(2024, 1, i + 1)),
    );
    final dayMap = {for (final d in days) d.date: d};

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // First day of month (weekday: 1=Mon ... 7=Sun)
    final firstDay = DateTime.utc(month.year, month.month, 1);
    final startOffset = firstDay.weekday - 1; // 0-based offset from Monday
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);

    return Column(
      children: [
        // Weekday labels
        Row(
          children: weekDayLabels
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        // Day cells
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final dayNum = index - startOffset + 1;
            final dateStr =
                '${month.year}-${month.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
            final model = dayMap[dateStr];
            return _DayCell(
              day: dayNum,
              dateStr: dateStr,
              todayStr: todayStr,
              model: model,
              onTap: model != null ? () => onDayTap(model) : null,
            );
          },
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String dateStr;
  final String todayStr;
  final CalendarDayModel? model;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.dateStr,
    required this.todayStr,
    this.model,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasRuns = model?.runs.isNotEmpty ?? false;
    final hasEvents = model?.events.isNotEmpty ?? false;
    final isToday = dateStr == todayStr;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isToday
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isToday ? FontWeight.bold : null,
                  ),
            ),
            if (hasRuns || hasEvents)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasRuns)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                  if (hasEvents)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

}

class _DayPickerSheet extends StatelessWidget {
  final CalendarDayModel day;
  final AppLocalizations l10n;

  const _DayPickerSheet({required this.day, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final run in day.runs)
              ListTile(
                leading: const Icon(Icons.directions_run, color: Colors.green),
                title: Text(l10n.calendarRun),
                subtitle: Text(
                  '${(run.distanceM / 1000).toStringAsFixed(2)} km · ${_formatDuration(run.durationS)}',
                ),
                trailing: Text(l10n.calendarChoose),
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push('/run/detail/${run.id}');
                },
              ),
            for (final event in day.events)
              ListTile(
                leading: const Icon(Icons.event, color: Colors.blue),
                title: Text(l10n.calendarEvent),
                subtitle: Text(event.name),
                trailing: Text(l10n.calendarChoose),
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  router.push('/event/${event.id}');
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m ${s}s';
  }
}
