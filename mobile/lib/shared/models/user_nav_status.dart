/// Model for dynamic UI navigation status (tabs visibility).
class UserNavStatus {
  final bool hasClubs;
  final bool hasTrainers;

  UserNavStatus({
    required this.hasClubs,
    required this.hasTrainers,
  });

  factory UserNavStatus.fromJson(Map<String, dynamic> json) {
    return UserNavStatus(
      hasClubs: json['hasClubs'] as bool? ?? false,
      hasTrainers: json['hasTrainers'] as bool? ?? false,
    );
  }

  /// Default status for new or unauthenticated users.
  factory UserNavStatus.initial() {
    return UserNavStatus(hasClubs: false, hasTrainers: false);
  }

  @override
  String toString() => 'UserNavStatus(hasClubs: $hasClubs, hasTrainers: $hasTrainers)';
}
