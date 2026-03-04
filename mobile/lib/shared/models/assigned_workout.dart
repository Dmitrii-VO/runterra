import 'workout.dart';

/// Workout template assigned to the current user by a trainer
class AssignedWorkout extends Workout {
  final String trainerId;
  final String trainerName;
  final String? note;
  final DateTime assignedAt;
  final String assignmentId;
  final bool isCompleted;

  AssignedWorkout({
    required super.id,
    required super.authorId,
    super.clubId,
    required super.name,
    super.description,
    required super.type,
    required super.difficulty,
    super.distanceM,
    super.heartRateTarget,
    super.paceTarget,
    super.repCount,
    super.repDistanceM,
    super.exerciseName,
    super.exerciseInstructions,
    required super.createdAt,
    required this.trainerId,
    required this.trainerName,
    this.note,
    required this.assignedAt,
    required this.assignmentId,
    this.isCompleted = false,
  });

  factory AssignedWorkout.fromJson(Map<String, dynamic> json) {
    return AssignedWorkout(
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
      trainerId: json['trainerId'] as String,
      trainerName: json['trainerName'] as String,
      note: json['note'] as String?,
      assignedAt: DateTime.parse(json['assignedAt'] as String),
      assignmentId: json['assignmentId'] as String,
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }
}
