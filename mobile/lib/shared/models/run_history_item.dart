/// Compact run item for history list.
/// Matches backend RunHistoryItemDto.
class RunHistoryItem {
  final String id;
  final DateTime startedAt;
  final int duration; // seconds
  final int distance; // meters
  final int paceSecondsPerKm;
  final int? rpe;

  RunHistoryItem({
    required this.id,
    required this.startedAt,
    required this.duration,
    required this.distance,
    required this.paceSecondsPerKm,
    this.rpe,
  });

  factory RunHistoryItem.fromJson(Map<String, dynamic> json) {
    return RunHistoryItem(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      duration: (json['duration'] as num).toInt(),
      distance: (json['distance'] as num).toInt(),
      paceSecondsPerKm: (json['paceSecondsPerKm'] as num).toInt(),
      rpe: json['rpe'] != null ? (json['rpe'] as num).toInt() : null,
    );
  }
}
