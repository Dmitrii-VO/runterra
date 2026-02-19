/// Model for a club member (from GET /api/clubs/:id/members).
class ClubMemberModel {
  final String userId;
  final String displayName;
  final String role;
  final DateTime joinedAt;
  final String planType; // 'club' or 'personal'

  ClubMemberModel({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    required this.planType,
  });

  factory ClubMemberModel.fromJson(Map<String, dynamic> json) {
    return ClubMemberModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      planType: json['planType'] as String? ?? 'club',
    );
  }
}
