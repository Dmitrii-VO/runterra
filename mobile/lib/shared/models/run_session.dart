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
  final DateTime startedAt;
  final RunSessionStatus status;
  final Duration duration;
  final double distance; // in meters
  final GpsStatus gpsStatus;
  final List<Position> gpsPoints; // GPS coordinates collected during run

  RunSession({
    required this.id,
    this.activityId,
    required this.startedAt,
    required this.status,
    Duration? duration,
    double? distance,
    GpsStatus? gpsStatus,
    List<Position>? gpsPoints,
  })  : duration = duration ?? Duration.zero,
        distance = distance ?? 0.0,
        gpsStatus = gpsStatus ?? GpsStatus.searching,
        gpsPoints = gpsPoints ?? [];
}

enum RunSessionStatus {
  running,
  completed,
}

/// GPS status during run tracking
enum GpsStatus {
  searching, // Looking for GPS signal
  recording, // GPS signal found, recording positions
  error, // GPS error (no permission, unavailable, etc.)
}
