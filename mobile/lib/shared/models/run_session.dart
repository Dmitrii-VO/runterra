import 'package:geolocator/geolocator.dart';

/// Local UI/tracker state model for the run screen (idle / recording / result).
///
/// NOT a DTO: no fromJson/toJson. Used only in-app for:
/// - holding screen state (RunSessionStatus: running, completed)
/// - GPS status and points during tracking
/// - passing data to RunService for submit (session → CreateRunDto on backend).
///
/// For deserializing backend responses (RunViewDto) use [RunModel] in run_model.dart.
class RunSession {
  final String id;
  final String? activityId;
  final String? scheduledItemId;
  final String? scoringClubId;
  final DateTime startedAt;
  final RunSessionStatus status;
  final Duration duration;
  final double distance; // in meters
  final GpsStatus gpsStatus;
  final List<Position> gpsPoints; // GPS coordinates collected during run
  /// Accumulated active duration before the last pause
  final Duration accumulatedDuration;
  /// Timestamp of last resume (used to calculate active time since last resume)
  final DateTime? lastResumedAt;
  /// Heart rate in BPM from watch sensor (null if watch not connected)
  final int? heartRate;

  RunSession({
    required this.id,
    this.activityId,
    this.scheduledItemId,
    this.scoringClubId,
    required this.startedAt,
    required this.status,
    Duration? duration,
    double? distance,
    GpsStatus? gpsStatus,
    List<Position>? gpsPoints,
    Duration? accumulatedDuration,
    this.lastResumedAt,
    this.heartRate,
  })  : duration = duration ?? Duration.zero,
        distance = distance ?? 0.0,
        gpsStatus = gpsStatus ?? GpsStatus.searching,
        gpsPoints = gpsPoints ?? [],
        accumulatedDuration = accumulatedDuration ?? Duration.zero;

  RunSession copyWith({
    String? id,
    String? activityId,
    String? scheduledItemId,
    String? scoringClubId,
    DateTime? startedAt,
    RunSessionStatus? status,
    Duration? duration,
    double? distance,
    GpsStatus? gpsStatus,
    List<Position>? gpsPoints,
    Duration? accumulatedDuration,
    DateTime? lastResumedAt,
    int? heartRate,
  }) {
    return RunSession(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      scheduledItemId: scheduledItemId ?? this.scheduledItemId,
      scoringClubId: scoringClubId ?? this.scoringClubId,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      gpsStatus: gpsStatus ?? this.gpsStatus,
      gpsPoints: gpsPoints ?? this.gpsPoints,
      accumulatedDuration: accumulatedDuration ?? this.accumulatedDuration,
      lastResumedAt: lastResumedAt ?? this.lastResumedAt,
      heartRate: heartRate ?? this.heartRate,
    );
  }
}

enum RunSessionStatus {
  running,
  paused,
  completed,
}

/// GPS status during run tracking
enum GpsStatus {
  searching, // Looking for GPS signal
  recording, // GPS signal found, recording positions
  error, // GPS error (no permission, unavailable, etc.)
}
