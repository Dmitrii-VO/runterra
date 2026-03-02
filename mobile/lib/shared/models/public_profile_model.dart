/// Public profile of another user, including run stats and recent runs.
class PublicProfileModel {
  final PublicProfileUser user;
  final PublicProfileClub? club;
  final PublicProfileStats stats;
  final List<PublicRunSummary> recentRuns;

  const PublicProfileModel({
    required this.user,
    this.club,
    required this.stats,
    required this.recentRuns,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      user: PublicProfileUser.fromJson(json['user'] as Map<String, dynamic>),
      club: json['club'] != null
          ? PublicProfileClub.fromJson(json['club'] as Map<String, dynamic>)
          : null,
      stats: PublicProfileStats.fromJson(json['stats'] as Map<String, dynamic>),
      recentRuns: (json['recentRuns'] as List<dynamic>)
          .map((e) => PublicRunSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PublicProfileUser {
  final String id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? cityId;
  final String? cityName;

  const PublicProfileUser({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.cityId,
    this.cityName,
  });

  factory PublicProfileUser.fromJson(Map<String, dynamic> json) {
    return PublicProfileUser(
      id: json['id'] as String,
      name: json['name'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      cityId: json['cityId'] as String?,
      cityName: json['cityName'] as String?,
    );
  }
}

class PublicProfileClub {
  final String id;
  final String name;

  const PublicProfileClub({required this.id, required this.name});

  factory PublicProfileClub.fromJson(Map<String, dynamic> json) {
    return PublicProfileClub(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class PublicProfileStats {
  final int totalRuns;
  final double totalDistanceKm;
  final int totalDurationMin;
  final int averagePace; // sec/km
  final int contributionPoints;

  const PublicProfileStats({
    required this.totalRuns,
    required this.totalDistanceKm,
    required this.totalDurationMin,
    required this.averagePace,
    required this.contributionPoints,
  });

  factory PublicProfileStats.fromJson(Map<String, dynamic> json) {
    return PublicProfileStats(
      totalRuns: (json['totalRuns'] as num).toInt(),
      totalDistanceKm: (json['totalDistanceKm'] as num).toDouble(),
      totalDurationMin: (json['totalDurationMin'] as num).toInt(),
      averagePace: (json['averagePace'] as num).toInt(),
      contributionPoints: (json['contributionPoints'] as num).toInt(),
    );
  }
}

class PublicRunSummary {
  final String id;
  final DateTime startedAt;
  final int distance; // meters
  final int duration; // seconds
  final int pace; // sec/km

  const PublicRunSummary({
    required this.id,
    required this.startedAt,
    required this.distance,
    required this.duration,
    required this.pace,
  });

  factory PublicRunSummary.fromJson(Map<String, dynamic> json) {
    return PublicRunSummary(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      distance: (json['distance'] as num).toInt(),
      duration: (json['duration'] as num).toInt(),
      pace: (json['pace'] as num).toInt(),
    );
  }
}
