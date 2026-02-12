/// DTO model for a club sub-channel.
class ClubChannelModel {
  final String id;
  final String clubId;
  final String type;
  final String name;
  final bool isDefault;
  final DateTime createdAt;

  ClubChannelModel({
    required this.id,
    required this.clubId,
    required this.type,
    required this.name,
    required this.isDefault,
    required this.createdAt,
  });

  factory ClubChannelModel.fromJson(Map<String, dynamic> json) {
    return ClubChannelModel(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
