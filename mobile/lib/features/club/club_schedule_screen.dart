import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/schedule_model.dart';

class ClubScheduleScreen extends StatefulWidget {
  final String clubId;

  const ClubScheduleScreen({super.key, required this.clubId});

  @override
  State<ClubScheduleScreen> createState() => _ClubScheduleScreenState();
}

class _ClubScheduleScreenState extends State<ClubScheduleScreen> {
  int _selectedDay = 1; // 1 (Mon) to 7 (Sun)
  List<WeeklyScheduleItemModel>? _allSchedule;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
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
    return _allSchedule!.where((item) => item.dayOfWeek == _selectedDay).toList();
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
              title: Text(l10n.tabPersonal), // Using "Personal" as label for Note
              onTap: () => Navigator.pop(context, ScheduleItemType.note),
            ),
          ],
        ),
      ),
    );

    if (type == null || !mounted) return;

    if (type == ScheduleItemType.note) {
      final textController = TextEditingController();
      final timeController = TextEditingController(text: "10:00");
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.tabPersonal),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time (HH:mm)'),
              ),
              TextField(
                controller: textController,
                decoration: const InputDecoration(labelText: 'Note Text'),
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
            'dayOfWeek': _selectedDay,
            'startTime': timeController.text,
            'type': 'note',
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
      // Event selection (Simplified: just input text for now or pick from existing workouts)
      // For Stage 5 MVP, we'll use a simple dialog.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Event selection to be integrated with Workouts library")),
      );
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
    final dayNames = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ]; // TODO: l10n

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.scheduleTitle),
        actions: [
          IconButton(onPressed: _loadSchedule, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Day Selector
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
          // Items List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _currentDayItems.isEmpty
                    ? Center(child: Text(l10n.noData))
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
                              ? (item.eventId ?? 'Workout') 
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
