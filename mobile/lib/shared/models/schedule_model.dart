// Models for weekly and personal schedule templates.

class WeeklyScheduleItemModel {
  final String id;
  final String clubId;
  final int dayOfWeek; // 0-6 (0=Sun, 1=Mon, ..., 6=Sat) — matches backend
  final String startTime; // HH:mm
  final String activityType; // 'note', 'training', 'tempo', etc.
  final String? name;
  final String? description;
  final String? workoutId;
  final String? trainerId;

  WeeklyScheduleItemModel({
    required this.id,
    required this.clubId,
    required this.dayOfWeek,
    required this.startTime,
    required this.activityType,
    this.name,
    this.description,
    this.workoutId,
    this.trainerId,
  });

  /// True when this item is a free-text note, not a workout event.
  bool get isNote => activityType == 'note';

  factory WeeklyScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleItemModel(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: json['startTime'] as String,
      activityType: json['activityType'] as String? ?? 'note',
      name: json['name'] as String?,
      description: json['description'] as String?,
      workoutId: json['workoutId'] as String?,
      trainerId: json['trainerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'activityType': activityType,
      'name': name,
      'description': description,
      'workoutId': workoutId,
      'trainerId': trainerId,
    };
  }
}

class PersonalScheduleItemModel {
  final String id;
  final String userId;
  final int dayOfWeek; // 0-6 (0=Sun, 1=Mon, ..., 6=Sat) — matches backend
  final String name;
  final String? description;
  final String? workoutId;
  final String? trainerId;

  PersonalScheduleItemModel({
    required this.id,
    required this.userId,
    required this.dayOfWeek,
    required this.name,
    this.description,
    this.workoutId,
    this.trainerId,
  });

  factory PersonalScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return PersonalScheduleItemModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      workoutId: json['workoutId'] as String?,
      trainerId: json['trainerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'name': name,
      'description': description,
      'workoutId': workoutId,
      'trainerId': trainerId,
    };
  }
}
