import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/schedule_model.dart';
import '../../shared/models/workout.dart';

class ClubScheduleScreen extends StatefulWidget {
  final String clubId;
  final String? userRole; // 'leader', 'trainer', or null for regular members

  const ClubScheduleScreen({super.key, required this.clubId, this.userRole});

  @override
  State<ClubScheduleScreen> createState() => _ClubScheduleScreenState();
}

class _ClubScheduleScreenState extends State<ClubScheduleScreen> {
  int _selectedDay = 1; // 1 (Mon) to 7 (Sun) in UI
  List<WeeklyScheduleItemModel>? _allSchedule;
  List<Workout> _workouts = [];
  bool _loading = true;

  bool get _canManage =>
      widget.userRole == 'leader' || widget.userRole == 'trainer';

  @override
  void initState() {
    super.initState();
    _loadSchedule();
    if (_canManage) _loadWorkouts();
  }

  // Convert UI day (1=Mon … 7=Sun) to backend day (0=Sun, 1=Mon … 6=Sat)
  int _uiDayToBackend(int uiDay) => uiDay % 7;

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      final schedule =
          await ServiceLocator.clubsService.getWeeklySchedule(widget.clubId);
      if (mounted) {
        setState(() {
          _allSchedule = schedule;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _loadWorkouts() async {
    try {
      final personal = await ServiceLocator.workoutsService.getWorkouts();
      final club = await ServiceLocator.workoutsService
          .getWorkouts(clubId: widget.clubId);
      final seen = <String>{};
      final merged =
          [...personal, ...club].where((w) => seen.add(w.id)).toList();
      if (mounted) setState(() => _workouts = merged);
    } catch (_) {
      // Non-critical — workout picker will just be empty
    }
  }

  List<WeeklyScheduleItemModel> get _currentDayItems {
    if (_allSchedule == null) return [];
    final backendDay = _uiDayToBackend(_selectedDay);
    return _allSchedule!
        .where((item) => item.dayOfWeek == backendDay)
        .toList();
  }

  Future<void> _addItem() async {
    final l10n = AppLocalizations.of(context)!;

    // Step 1: pick type
    final isNote = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(l10n.eventTypeTraining),
              onTap: () => Navigator.pop(ctx, false),
            ),
            ListTile(
              leading: const Icon(Icons.note_alt),
              title: Text(l10n.tabPersonal),
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (isNote == null || !mounted) return;

    final timeController = TextEditingController(text: '10:00');

    if (isNote) {
      // Note: free text, no workout link
      final textController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.tabPersonal),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                    labelText: '${l10n.eventCreateTime} (HH:mm)'),
              ),
              TextField(
                controller: textController,
                decoration:
                    InputDecoration(labelText: l10n.eventDescription),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.editProfileSave),
            ),
          ],
        ),
      );

      if (confirm == true && textController.text.isNotEmpty && mounted) {
        try {
          await ServiceLocator.clubsService.createWeeklyItem(widget.clubId, {
            'dayOfWeek': _uiDayToBackend(_selectedDay),
            'startTime': timeController.text,
            'activityType': 'note',
            'name': textController.text,
          });
          _loadSchedule();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      }
    } else {
      // Workout event: pick from prefetched library
      if (_workouts.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.workoutEmpty)),
        );
        return;
      }

      final workout = await showDialog<Workout>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.quickFindTraining),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _workouts.length,
              itemBuilder: (_, index) {
                final w = _workouts[index];
                return ListTile(
                  title: Text(w.name),
                  subtitle: Text(w.type),
                  onTap: () => Navigator.pop(ctx, w),
                );
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel)),
          ],
        ),
      );

      if (workout == null || !mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(workout.name),
          content: TextField(
            controller: timeController,
            decoration:
                InputDecoration(labelText: '${l10n.eventCreateTime} (HH:mm)'),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.editProfileSave),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        try {
          await ServiceLocator.clubsService.createWeeklyItem(widget.clubId, {
            'dayOfWeek': _uiDayToBackend(_selectedDay),
            'startTime': timeController.text,
            'activityType': workout.type,
            'name': workout.name,
            'workoutId': workout.id,
          });
          _loadSchedule();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await ServiceLocator.clubsService.deleteWeeklyItem(widget.clubId, itemId);
      _loadSchedule();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _conductItem(WeeklyScheduleItemModel item) {
    final params = <String, String>{
      'type': 'training', // all schedule templates are trainings
      if (item.name != null) 'name': item.name!,
      'time': item.startTime,
      if (item.workoutId != null) 'workoutId': item.workoutId!,
      'clubId': widget.clubId,
    };
    final query = Uri(queryParameters: params).query;
    context.push('/event/create?$query');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    // Generate localized short day names: index 0 = Mon, ..., 6 = Sun
    // 2024-01-01 is Monday → add index days to get Mon-Sun sequence
    final dayNames = List.generate(7, (i) {
      final date = DateTime(2024, 1, 1 + i);
      return DateFormat.E(locale).format(date);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleTitle),
        actions: [
          IconButton(onPressed: _loadSchedule, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _selectedDay == day;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(dayNames[index]),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedDay = day);
                    },
                  ),
                );
              }),
            ),
          ),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _currentDayItems.isEmpty
                    ? Center(child: Text(l10n.scheduleEmptyDay))
                    : ListView.builder(
                        itemCount: _currentDayItems.length,
                        itemBuilder: (context, index) {
                          final item = _currentDayItems[index];
                          return ListTile(
                            leading: Icon(
                              item.isNote
                                  ? Icons.note_alt
                                  : Icons.directions_run,
                              color: item.isNote
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                            title: Text(item.startTime),
                            subtitle: Text(item.name ?? ''),
                            trailing: _canManage
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!item.isNote)
                                        IconButton(
                                          icon: const Icon(
                                              Icons.play_circle_outline),
                                          tooltip: l10n.scheduleConduct,
                                          onPressed: () =>
                                              _conductItem(item),
                                        ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _deleteItem(item.id),
                                      ),
                                    ],
                                  )
                                : null,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              onPressed: _addItem,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
