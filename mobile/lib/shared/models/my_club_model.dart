/// DTO model for clubs where current user is a member.
class MyClubModel {
  final String id;
  final String name;
  final String? description;
  final String cityId;
  final String? cityName;
  final String status;
  final String role;
  final DateTime joinedAt;

  MyClubModel({
    required this.id,
    required this.name,
    this.description,
    required this.cityId,
    this.cityName,
    required this.status,
    required this.role,
    required this.joinedAt,
  });

  factory MyClubModel.fromJson(Map<String, dynamic> json) {
    return MyClubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      cityId: json['cityId'] as String,
      cityName: json['cityName'] as String?,
      status: json['status'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
