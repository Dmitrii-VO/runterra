class UserSearchResult {
  final String id;
  final String name;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? cityId;
  final String? cityName;
  final String? clubName;

  const UserSearchResult({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.cityId,
    this.cityName,
    this.clubName,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) => UserSearchResult(
        id: json['id'] as String,
        name: json['name'] as String,
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        cityId: json['cityId'] as String?,
        cityName: json['cityName'] as String?,
        clubName: json['clubName'] as String?,
      );
}
