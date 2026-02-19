// Models for weekly and personal schedule templates.

enum ScheduleItemType { event, note }

class WeeklyScheduleItemModel {
  final String id;
  final String clubId;
  final int dayOfWeek; // 1 (Mon) - 7 (Sun)
  final String startTime; // HH:mm
  final ScheduleItemType type;
  final String? eventId;
  final String? noteText;

  WeeklyScheduleItemModel({
    required this.id,
    required this.clubId,
    required this.dayOfWeek,
    required this.startTime,
    required this.type,
    this.eventId,
    this.noteText,
  });

  factory WeeklyScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleItemModel(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: json['startTime'] as String,
      type: json['type'] == 'event' ? ScheduleItemType.event : ScheduleItemType.note,
      eventId: json['eventId'] as String?,
      noteText: json['noteText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'type': type == ScheduleItemType.event ? 'event' : 'note',
      'eventId': eventId,
      'noteText': noteText,
    };
  }
}

class PersonalScheduleItemModel {
  final String id;
  final String userId;
  final int dayOfWeek;
  final String startTime;
  final ScheduleItemType type;
  final String? eventId;
  final String? noteText;

  PersonalScheduleItemModel({
    required this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.startTime,
    required this.type,
    this.eventId,
    this.noteText,
  });

  factory PersonalScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return PersonalScheduleItemModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: json['startTime'] as String,
      type: json['type'] == 'event' ? ScheduleItemType.event : ScheduleItemType.note,
      eventId: json['eventId'] as String?,
      noteText: json['noteText'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'type': type == ScheduleItemType.event ? 'event' : 'note',
      'eventId': eventId,
      'noteText': noteText,
    };
  }
}
