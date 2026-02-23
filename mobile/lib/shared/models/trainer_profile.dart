/// Trainer profile model
class Certificate {
  final String name;
  final String? date;
  final String? organization;

  Certificate({
    required this.name,
    this.date,
    this.organization,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      name: json['name'] as String,
      date: json['date'] as String?,
      organization: json['organization'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (date != null) 'date': date,
      if (organization != null) 'organization': organization,
    };
  }
}

class TrainerProfile {
  final String userId;
  final String? bio;
  final List<String> specialization;
  final int experienceYears;
  final List<Certificate> certificates;
  final bool acceptsPrivateClients;
  final DateTime createdAt;

  TrainerProfile({
    required this.userId,
    this.bio,
    required this.specialization,
    required this.experienceYears,
    required this.certificates,
    this.acceptsPrivateClients = false,
    required this.createdAt,
  });

  factory TrainerProfile.fromJson(Map<String, dynamic> json) {
    return TrainerProfile(
      userId: json['userId'] as String,
      bio: json['bio'] as String?,
      specialization: (json['specialization'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      experienceYears: (json['experienceYears'] as num).toInt(),
      certificates: (json['certificates'] as List<dynamic>? ?? [])
          .map((e) => Certificate.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptsPrivateClients: json['acceptsPrivateClients'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      if (bio != null) 'bio': bio,
      'specialization': specialization,
      'experienceYears': experienceYears,
      'certificates': certificates.map((c) => c.toJson()).toList(),
      'acceptsPrivateClients': acceptsPrivateClients,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Public trainer entry for discovery (accepts_private_clients = true)
class PublicTrainerEntry {
  final String userId;
  final String name;
  final String? bio;
  final List<String> specialization;
  final int experienceYears;

  PublicTrainerEntry({
    required this.userId,
    required this.name,
    this.bio,
    required this.specialization,
    required this.experienceYears,
  });

  factory PublicTrainerEntry.fromJson(Map<String, dynamic> json) {
    return PublicTrainerEntry(
      userId: json['userId'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String?,
      specialization: (json['specialization'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      experienceYears: (json['experienceYears'] as num).toInt(),
    );
  }
}
