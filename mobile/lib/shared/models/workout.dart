/// Workout template model
class Workout {
  final String id;
  final String authorId;
  final String? clubId;
  final String name;
  final String? description;
  final String type;
  final String difficulty;
  final String targetMetric;
  final int? targetValue;
  final String? targetZone;
  final DateTime createdAt;

  Workout({
    required this.id,
    required this.authorId,
    this.clubId,
    required this.name,
    this.description,
    required this.type,
    required this.difficulty,
    required this.targetMetric,
    this.targetValue,
    this.targetZone,
    required this.createdAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      clubId: json['clubId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      targetMetric: json['targetMetric'] as String,
      targetValue: json['targetValue'] as int?,
      targetZone: json['targetZone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      if (clubId != null) 'clubId': clubId,
      'name': name,
      if (description != null) 'description': description,
      'type': type,
      'difficulty': difficulty,
      'targetMetric': targetMetric,
      if (targetValue != null) 'targetValue': targetValue,
      if (targetZone != null) 'targetZone': targetZone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
