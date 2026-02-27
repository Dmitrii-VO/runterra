/// Model for a direct chat contact (trainer client or trainer)
class DirectChatModel {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String? lastMessageText;
  final DateTime? lastMessageAt;

  DirectChatModel({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.lastMessageText,
    this.lastMessageAt,
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
    );
  }
}
