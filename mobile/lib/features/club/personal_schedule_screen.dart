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
      }
    }
  }

  Future<void> _replaceSchedule() async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.navRun),
        content: const Text("Это действие заменит текущий план бегуна. Для проверки мы установим 'Пробежка 5км' на понедельник."),
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
        await ServiceLocator.clubsService.setMemberPersonalSchedule(
          widget.clubId,
          widget.userId,
          [
            {
              'dayOfWeek': 1,
              'startTime': '09:00',
              'type': 'note',
              'name': 'Персональная пробежка: 5км',
              'noteText': 'Персональная пробежка: 5км',
            }
          ],
        );
        _loadSchedule();
        if (mounted) Navigator.pop(context, true);
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.member.displayName),
            Text(
              l10n.planTypePersonal,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Текущий персональный план",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: _schedule == null || _schedule!.isEmpty
                      ? const Center(child: Text("Используется клубное расписание"))
                      : ListView.builder(
                          itemCount: _schedule!.length,
                          itemBuilder: (context, index) {
                            final item = _schedule![index];
                            final dayNames = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'];
                            return ListTile(
                              leading: CircleAvatar(child: Text(dayNames[item.dayOfWeek][0])),
                              title: Text("${dayNames[item.dayOfWeek]} ${item.startTime}"),
                              subtitle: Text(item.noteText ?? item.name),
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
                      child: const Text("Заменить персональный план"),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
