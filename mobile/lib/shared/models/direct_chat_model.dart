/// Model for a direct chat contact (any user, trainer flagged separately)
class DirectChatModel {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final bool isTrainerRelation;

  DirectChatModel({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.lastMessageText,
    this.lastMessageAt,
    this.isTrainerRelation = false,
  });

  factory DirectChatModel.fromJson(Map<String, dynamic> json) {
    return DirectChatModel(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String?,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      isTrainerRelation: (json['isTrainerRelation'] as bool?) ?? false,
    );
  }
}
