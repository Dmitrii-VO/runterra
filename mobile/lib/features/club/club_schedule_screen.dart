import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/schedule_model.dart';
import '../../shared/models/workout.dart';

class ClubScheduleScreen extends StatefulWidget {
  final String clubId;

  const ClubScheduleScreen({super.key, required this.clubId});

  @override
  State<ClubScheduleScreen> createState() => _ClubScheduleScreenState();
}

class _ClubScheduleScreenState extends State<ClubScheduleScreen> {
  int _selectedDay = 1; // 1 (Mon) to 7 (Sun) in UI
  List<WeeklyScheduleItemModel>? _allSchedule;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  // Convert UI day (1-7, Mon-Sun) to Backend day (0-6, Sun-Sat)
  int _uiDayToBackend(int uiDay) {
    return uiDay % 7;
  }

  // Convert Backend day (0-6, Sun-Sat) to UI day (1-7, Mon-Sun)
  int _backendDayToUi(int backendDay) {
    return backendDay == 0 ? 7 : backendDay;
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      final schedule = await ServiceLocator.clubsService.getWeeklySchedule(widget.clubId);
      if (mounted) {
        setState(() {
          _allSchedule = schedule;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  List<WeeklyScheduleItemModel> get _currentDayItems {
    if (_allSchedule == null) return [];
    final backendDay = _uiDayToBackend(_selectedDay);
    return _allSchedule!.where((item) => item.dayOfWeek == backendDay).toList();
  }

  Future<void> _addItem() async {
    final l10n = AppLocalizations.of(context)!;
    final type = await showModalBottomSheet<ScheduleItemType>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(l10n.eventTypeTraining),
              onTap: () => Navigator.pop(context, ScheduleItemType.event),
            ),
            ListTile(
              leading: const Icon(Icons.note_alt),
              title: Text(l10n.tabPersonal),
              onTap: () => Navigator.pop(context, ScheduleItemType.note),
            ),
          ],
        ),
      ),
    );

    if (type == null || !mounted) return;

    final timeController = TextEditingController(text: "10:00");

    if (type == ScheduleItemType.note) {
      final textController = TextEditingController();
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.tabPersonal),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: InputDecoration(labelText: '${l10n.eventCreateTime} (HH:mm)'),
              ),
              TextField(
                controller: textController,
                decoration: InputDecoration(labelText: l10n.eventDescription),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.editProfileSave),
            ),
          ],
        ),
      );

      if (confirm == true && textController.text.isNotEmpty) {
        try {
          await ServiceLocator.clubsService.createWeeklyItem(widget.clubId, {
            'dayOfWeek': _uiDayToBackend(_selectedDay),
            'startTime': timeController.text,
            'type': 'note',
            'activityType': 'note',
            'name': textController.text,
            'noteText': textController.text,
          });
          _loadSchedule();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      }
    } else {
      // Pick from library
      final workout = await showDialog<Workout>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.quickFindTraining),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: FutureBuilder<List<Workout>>(
              future: ServiceLocator.workoutsService.getWorkouts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(snapshot.error.toString()));
                }
                final workouts = snapshot.data ?? [];
                if (workouts.isEmpty) {
                  return Center(child: Text(l10n.workoutEmpty));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final w = workouts[index];
                    return ListTile(
                      title: Text(w.name),
                      subtitle: Text(w.type),
                      onTap: () => Navigator.pop(context, w),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          ],
        ),
      );

      if (workout != null && mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(workout.name),
            content: TextField(
              controller: timeController,
              decoration: InputDecoration(labelText: '${l10n.eventCreateTime} (HH:mm)'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.editProfileSave),
              ),
            ],
          ),
        );

        if (confirm == true) {
          try {
            await ServiceLocator.clubsService.createWeeklyItem(widget.clubId, {
              'dayOfWeek': _uiDayToBackend(_selectedDay),
              'startTime': timeController.text,
              'type': 'event',
              'activityType': workout.type,
              'name': workout.name,
              'workoutId': workout.id,
            });
            _loadSchedule();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

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
                    ? const Center(child: Text("Нет данных"))
                    : ListView.builder(
                        itemCount: _currentDayItems.length,
                        itemBuilder: (context, index) {
                          final item = _currentDayItems[index];
                          return ListTile(
                            leading: Icon(
                              item.type == ScheduleItemType.event ? Icons.event : Icons.note_alt,
                              color: item.type == ScheduleItemType.event ? Colors.blue : Colors.orange,
                            ),
                            title: Text(item.startTime),
                            subtitle: Text(item.type == ScheduleItemType.event 
                              ? (item.name) 
                              : (item.noteText ?? '')),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteItem(item.id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
