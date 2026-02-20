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
    );
  }
}
