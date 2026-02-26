class CityLeaderboardEntry {
  final String id;
  final String name;
  final int membersCount;
  final int territoriesCount;
  final int points;
  final int rank;

  CityLeaderboardEntry({
    required this.id,
    required this.name,
    required this.membersCount,
    required this.territoriesCount,
    required this.points,
    required this.rank,
  });

  factory CityLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return CityLeaderboardEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      membersCount: json['membersCount'] as int,
      territoriesCount: json['territoriesCount'] as int,
      points: json['points'] as int,
      rank: json['rank'] as int,
    );
  }
}

class CityLeaderboardResponse {
  final List<CityLeaderboardEntry> leaderboard;
  final CityLeaderboardEntry? myClub;

  CityLeaderboardResponse({
    required this.leaderboard,
    this.myClub,
  });

  factory CityLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return CityLeaderboardResponse(
      leaderboard: (json['leaderboard'] as List<dynamic>)
          .map((e) => CityLeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      myClub: json['myClub'] != null
          ? CityLeaderboardEntry.fromJson(json['myClub'] as Map<String, dynamic>)
          : null,
    );
  }
}
