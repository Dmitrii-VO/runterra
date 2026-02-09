/// Model for a club member (from GET /api/clubs/:id/members).
class ClubMemberModel {
  final String userId;
  final String displayName;
  final String role;
  final DateTime joinedAt;

  ClubMemberModel({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  factory ClubMemberModel.fromJson(Map<String, dynamic> json) {
    return ClubMemberModel(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
