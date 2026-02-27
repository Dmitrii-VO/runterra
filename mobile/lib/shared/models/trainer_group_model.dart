/// Model for trainer group
class TrainerGroupModel {
  final String id;
  final String clubId;
  final String trainerId;
  final String name;
  final DateTime createdAt;
  final int memberCount;

  TrainerGroupModel({
    required this.id,
    required this.clubId,
    required this.trainerId,
    required this.name,
    required this.createdAt,
    required this.memberCount,
  });

  factory TrainerGroupModel.fromJson(Map<String, dynamic> json) {
    return TrainerGroupModel(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      trainerId: json['trainerId'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      memberCount: json['memberCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'trainerId': trainerId,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'memberCount': memberCount,
    };
  }
}
