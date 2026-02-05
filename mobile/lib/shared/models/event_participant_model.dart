/// DTO model for event participants.
///
/// Used for parsing JSON from /api/events/:id/participants.
class EventParticipantModel {
  /// Participant record id.
  final String id;

  /// User id.
  final String userId;

  /// User name (nullable when not available).
  final String? name;

  /// Avatar URL (optional).
  final String? avatarUrl;

  /// Participation status.
  final String status;

  /// Check-in timestamp (optional).
  final DateTime? checkedInAt;

  EventParticipantModel({
    required this.id,
    required this.userId,
    this.name,
    this.avatarUrl,
    required this.status,
    this.checkedInAt,
  });

  /// Creates EventParticipantModel from JSON.
  factory EventParticipantModel.fromJson(Map<String, dynamic> json) {
    return EventParticipantModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      status: json['status'] as String? ?? 'registered',
      checkedInAt: json['checkedInAt'] != null
          ? DateTime.parse(json['checkedInAt'] as String)
          : null,
    );
  }

  /// Converts EventParticipantModel to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'status': status,
      if (checkedInAt != null) 'checkedInAt': checkedInAt!.toIso8601String(),
    };
  }
}
