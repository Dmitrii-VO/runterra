enum WorkoutType { functional, tempo, recovery, accelerations }

/// Workout template model
class Workout {
  final String id;
  final String authorId;
  final String? clubId;
  final String name;
  final String? description;
  final String type;
  final String difficulty;
  // Type-specific fields
  final int? distanceM;
  final int? heartRateTarget;
  final int? paceTarget;
  final int? repCount;
  final int? repDistanceM;
  final String? exerciseName;
  final String? exerciseInstructions;
  final DateTime createdAt;

  Workout({
    required this.id,
    required this.authorId,
    this.clubId,
    required this.name,
    this.description,
    required this.type,
    required this.difficulty,
    this.distanceM,
    this.heartRateTarget,
    this.paceTarget,
    this.repCount,
    this.repDistanceM,
    this.exerciseName,
    this.exerciseInstructions,
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
      difficulty: (json['difficulty'] as String?) ?? 'BEGINNER',
      distanceM: json['distanceM'] as int?,
      heartRateTarget: json['heartRateTarget'] as int?,
      paceTarget: json['paceTarget'] as int?,
      repCount: json['repCount'] as int?,
      repDistanceM: json['repDistanceM'] as int?,
      exerciseName: json['exerciseName'] as String?,
      exerciseInstructions: json['exerciseInstructions'] as String?,
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
      if (distanceM != null) 'distanceM': distanceM,
      if (heartRateTarget != null) 'heartRateTarget': heartRateTarget,
      if (paceTarget != null) 'paceTarget': paceTarget,
      if (repCount != null) 'repCount': repCount,
      if (repDistanceM != null) 'repDistanceM': repDistanceM,
      if (exerciseName != null) 'exerciseName': exerciseName,
      if (exerciseInstructions != null) 'exerciseInstructions': exerciseInstructions,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
