/// DTO for run entity from backend API (RunViewDto).
///
/// Used to deserialize responses from GET /api/runs and POST /api/runs.
/// Matches backend RunViewDto: id, userId, activityId?, startedAt, endedAt,
/// duration (seconds in JSON → Duration), distance, status, createdAt, updatedAt.
///
/// For in-app tracker state (idle / recording / result) use [RunSession], not this model.
class RunModel {
  final String id;
  final String userId;
  final String? activityId;
  final DateTime startedAt;
  final DateTime endedAt;
  /// Duration derived from backend duration (seconds).
  final Duration duration;
  final double distance;
  final RunModelStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  RunModel({
    required this.id,
    required this.userId,
    this.activityId,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.distance,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Deserializes from backend RunViewDto JSON.
  /// Backend sends: startedAt, endedAt, createdAt, updatedAt as ISO 8601 strings;
  /// duration as number (seconds); status as 'completed' | 'invalid'.
  factory RunModel.fromJson(Map<String, dynamic> json) {
    final durationSec = json['duration'] as num;
    final statusRaw = json['status'] as String? ?? 'completed';
    return RunModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      activityId: json['activityId'] as String?,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: DateTime.parse(json['endedAt'] as String),
      duration: Duration(seconds: durationSec.toInt()),
      distance: (json['distance'] as num).toDouble(),
      status: RunModelStatus.fromString(statusRaw),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Run status from backend (RunStatus).
/// Matches backend: 'completed' | 'invalid'.
enum RunModelStatus {
  completed,
  invalid;

  static RunModelStatus fromString(String value) {
    switch (value) {
      case 'completed':
        return RunModelStatus.completed;
      case 'invalid':
        return RunModelStatus.invalid;
      default:
        return RunModelStatus.completed;
    }
  }
}
