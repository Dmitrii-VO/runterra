/// A completed run by a client, visible to their trainer
class ClientRunModel {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int duration; // seconds
  final int distance; // meters
  final int? rpe;
  final String? notes;
  final String? assignmentId;
  final String? workoutTitle;
  final int? avgCadence;

  ClientRunModel({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.distance,
    this.rpe,
    this.notes,
    this.assignmentId,
    this.workoutTitle,
    this.avgCadence,
  });

  factory ClientRunModel.fromJson(Map<String, dynamic> json) {
    return ClientRunModel(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      duration: (json['duration'] as num).toInt(),
      distance: (json['distance'] as num).toInt(),
      rpe: json['rpe'] as int?,
      notes: json['notes'] as String?,
      assignmentId: json['assignmentId'] as String?,
      workoutTitle: json['workoutTitle'] as String?,
      avgCadence: json['avgCadence'] != null ? (json['avgCadence'] as num).toInt() : null,
    );
  }
}
