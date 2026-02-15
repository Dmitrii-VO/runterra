/// Zone difficulty tier for territory leagues
enum ZoneTier { green, blue, red, black }

/// Parses a ZoneTier from a JSON string value, returns null if unknown
ZoneTier? zoneTierFromString(String? value) {
  if (value == null) return null;
  switch (value) {
    case 'green':
      return ZoneTier.green;
    case 'blue':
      return ZoneTier.blue;
    case 'red':
      return ZoneTier.red;
    case 'black':
      return ZoneTier.black;
    default:
      return null;
  }
}

/// A club entry in the territory leaderboard
class LeaderboardEntry {
  final String clubId;
  final String clubName;
  final double totalKm;
  final int position;

  const LeaderboardEntry({
    required this.clubId,
    required this.clubName,
    required this.totalKm,
    required this.position,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      clubId: json['clubId'] as String,
      clubName: json['clubName'] as String,
      totalKm: (json['totalKm'] as num).toDouble(),
      position: json['position'] as int,
    );
  }
}

/// Progress of the user's club in a territory
class ClubProgress {
  final String clubId;
  final String clubName;
  final double totalKm;
  final int position;
  final double gapToLeader;

  const ClubProgress({
    required this.clubId,
    required this.clubName,
    required this.totalKm,
    required this.position,
    required this.gapToLeader,
  });

  factory ClubProgress.fromJson(Map<String, dynamic> json) {
    return ClubProgress(
      clubId: json['clubId'] as String,
      clubName: json['clubName'] as String,
      totalKm: (json['totalKm'] as num).toDouble(),
      position: json['position'] as int,
      gapToLeader: (json['gapToLeader'] as num).toDouble(),
    );
  }
}

/// League info for a territory, parsed from flat fields in the territory JSON
class TerritoryLeagueInfo {
  final ZoneTier tier;
  final String paceThreshold;
  final double pointMultiplier;
  final double zoneBounty;
  final DateTime seasonEndsAt;
  final List<LeaderboardEntry> leaderboard;
  final ClubProgress? myClubProgress;

  const TerritoryLeagueInfo({
    required this.tier,
    required this.paceThreshold,
    required this.pointMultiplier,
    required this.zoneBounty,
    required this.seasonEndsAt,
    required this.leaderboard,
    this.myClubProgress,
  });

  /// Parses league info from the flat territory JSON object.
  /// Returns null if tier is not present.
  static TerritoryLeagueInfo? fromJson(Map<String, dynamic> json) {
    final tier = zoneTierFromString(json['tier'] as String?);
    if (tier == null) return null;

    final leaderboardJson = json['leaderboard'] as List<dynamic>?;
    final leaderboard = leaderboardJson
        ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    final myClubJson = json['myClubProgress'] as Map<String, dynamic>?;
    final myClubProgress =
        myClubJson != null ? ClubProgress.fromJson(myClubJson) : null;

    return TerritoryLeagueInfo(
      tier: tier,
      paceThreshold: json['paceThreshold'] as String? ?? '7:00',
      pointMultiplier: (json['pointMultiplier'] as num?)?.toDouble() ?? 1.0,
      zoneBounty: (json['zoneBounty'] as num?)?.toDouble() ?? 1.5,
      seasonEndsAt: json['seasonEndsAt'] != null
          ? DateTime.parse(json['seasonEndsAt'] as String)
          : DateTime(DateTime.now().year, DateTime.now().month + 1, 1),
      leaderboard: leaderboard,
      myClubProgress: myClubProgress,
    );
  }
}
