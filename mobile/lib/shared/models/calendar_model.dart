// Training calendar models (ProfileScreen calendar section)

class CalendarRunEntry {
  final String id;
  final int distanceM;
  final int durationS;

  const CalendarRunEntry({
    required this.id,
    required this.distanceM,
    required this.durationS,
  });

  factory CalendarRunEntry.fromJson(Map<String, dynamic> json) {
    return CalendarRunEntry(
      id: json['id'] as String,
      distanceM: (json['distanceM'] as num).toInt(),
      durationS: (json['durationS'] as num).toInt(),
    );
  }
}

class CalendarEventEntry {
  final String id;
  final String name;

  const CalendarEventEntry({required this.id, required this.name});

  factory CalendarEventEntry.fromJson(Map<String, dynamic> json) {
    return CalendarEventEntry(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class CalendarDayModel {
  final String date; // YYYY-MM-DD
  final List<CalendarRunEntry> runs;
  final List<CalendarEventEntry> events;

  const CalendarDayModel({
    required this.date,
    required this.runs,
    required this.events,
  });

  factory CalendarDayModel.fromJson(Map<String, dynamic> json) {
    return CalendarDayModel(
      date: json['date'] as String,
      runs: (json['runs'] as List<dynamic>)
          .map((e) => CalendarRunEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List<dynamic>)
          .map((e) => CalendarEventEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Schedule/trainer calendar model (legacy)
enum CalendarItemType { event, note }

class CalendarItemModel {
  final String id;
  final CalendarItemType type;
  final DateTime date;
  final String? startTime;
  final String name;
  final String? description;
  final String activityType;
  final String? workoutId;
  final String? trainerId;
  final String? status;
  final bool isPersonal;
  final bool isCompleted;
  final String? activityId;

  CalendarItemModel({
    required this.id,
    required this.type,
    required this.date,
    this.startTime,
    required this.name,
    this.description,
    required this.activityType,
    this.workoutId,
    this.trainerId,
    this.status,
    required this.isPersonal,
    this.isCompleted = false,
    this.activityId,
  });

  factory CalendarItemModel.fromJson(Map<String, dynamic> json) {
    return CalendarItemModel(
      id: json['id'] as String,
      type: json['type'] == 'event' ? CalendarItemType.event : CalendarItemType.note,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      activityType: json['activityType'] as String,
      workoutId: json['workoutId'] as String?,
      trainerId: json['trainerId'] as String?,
      status: json['status'] as String?,
      isPersonal: json['isPersonal'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      activityId: json['activityId'] as String?,
    );
  }
}
