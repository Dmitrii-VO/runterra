import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_member_model.dart';
import '../../shared/models/schedule_model.dart';

class PersonalScheduleScreen extends StatefulWidget {
  final String clubId;
  final String userId;
  final ClubMemberModel member;

  const PersonalScheduleScreen({
    super.key,
    required this.clubId,
    required this.userId,
    required this.member,
  });

  @override
  State<PersonalScheduleScreen> createState() => _PersonalScheduleScreenState();
}

class _PersonalScheduleScreenState extends State<PersonalScheduleScreen> {
  List<PersonalScheduleItemModel>? _schedule;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _loading = true);
    try {
      final schedule = await ServiceLocator.clubsService.getMemberPersonalSchedule(
        widget.clubId,
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _schedule = schedule;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        // If 404/Empty, it's just no personal schedule yet
      }
    }
  }

  Future<void> _replaceSchedule() async {
    final l10n = AppLocalizations.of(context)!;
    // For Stage 5 MVP, we implement a simple "Replace with template" or "Clear" logic.
    // In a full implementation, this would be a complex editor.
    // Let's add a "Quick Add Rest Day" as a proof of concept for Personal Notes.
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Personal Plan"),
        content: const Text("This will replace the runner's current plan. For MVP, we will set a simple 'Run 5km' note for Monday."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Set Plan"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ServiceLocator.clubsService.setMemberPersonalSchedule(
          widget.clubId,
          widget.userId,
          [
            {
              'dayOfWeek': 1, // Monday
              'startTime': '09:00',
              'type': 'note',
              'noteText': 'Personal Run: 5km easy',
            }
          ],
        );
        _loadSchedule();
        if (mounted) Navigator.pop(context, true); // Signal change to roster
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.displayName),
        subtitle: Text(l10n.planTypePersonal),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Current Personal Plan",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: _schedule == null || _schedule!.isEmpty
                      ? const Center(child: Text("Using Club Schedule (Default)"))
                      : ListView.builder(
                          itemCount: _schedule!.length,
                          itemBuilder: (context, index) {
                            final item = _schedule![index];
                            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            return ListTile(
                              leading: CircleAvatar(child: Text(dayNames[item.dayOfWeek - 1][0])),
                              title: Text("${dayNames[item.dayOfWeek - 1]} ${item.startTime}"),
                              subtitle: Text(item.noteText ?? 'Training'),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _replaceSchedule,
                      child: const Text("Replace Personal Plan"),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
