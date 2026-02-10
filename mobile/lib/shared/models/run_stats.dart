/// User running statistics.
/// Matches backend UserRunStatsDto.
class RunStats {
  final int totalRuns;
  final int totalDistance; // meters
  final int totalDuration; // seconds
  final int averagePace; // seconds per km

  RunStats({
    required this.totalRuns,
    required this.totalDistance,
    required this.totalDuration,
    required this.averagePace,
  });

  factory RunStats.fromJson(Map<String, dynamic> json) {
    return RunStats(
      totalRuns: (json['totalRuns'] as num).toInt(),
      totalDistance: (json['totalDistance'] as num).toInt(),
      totalDuration: (json['totalDuration'] as num).toInt(),
      averagePace: (json['averagePace'] as num).toInt(),
    );
  }
}
