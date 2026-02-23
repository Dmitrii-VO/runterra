/// Model for a club member (from GET /api/clubs/:id/members).
class ClubMemberModel {
  final String userId;
  final String displayName;
  final String role;
  final DateTime joinedAt;
  final String planType; // 'club' or 'personal'
  final int totalDistance; // in meters

  ClubMemberModel({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    required this.planType,
    this.totalDistance = 0,
  });

  factory ClubMemberModel.fromJson(Map<String, dynamic> json) {
    return ClubMemberModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      planType: (json['planType'] ?? json['plan_type']) as String? ?? 'club',
      totalDistance: (json['totalDistance'] ?? json['total_distance']) as int? ?? 0,
    );
  }
}
