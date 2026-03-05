// Models for GET /api/clubs/:id/trainer-assignments response.

class MemberRef {
  final String userId;
  final String displayName;

  MemberRef({required this.userId, required this.displayName});

  factory MemberRef.fromJson(Map<String, dynamic> json) {
    return MemberRef(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
    );
  }
}

class TrainerGroupRef {
  final String groupId;
  final String groupName;
  final List<MemberRef> members;

  TrainerGroupRef({
    required this.groupId,
    required this.groupName,
    required this.members,
  });

  factory TrainerGroupRef.fromJson(Map<String, dynamic> json) {
    return TrainerGroupRef(
      groupId: json['groupId'] as String,
      groupName: json['groupName'] as String,
      members: (json['members'] as List<dynamic>)
          .map((e) => MemberRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrainerEntry {
  final String trainerId;
  final String trainerName;
  final List<MemberRef> personalClients;
  final List<TrainerGroupRef> groups;

  TrainerEntry({
    required this.trainerId,
    required this.trainerName,
    required this.personalClients,
    required this.groups,
  });

  factory TrainerEntry.fromJson(Map<String, dynamic> json) {
    return TrainerEntry(
      trainerId: json['trainerId'] as String,
      trainerName: json['trainerName'] as String,
      personalClients: (json['personalClients'] as List<dynamic>)
          .map((e) => MemberRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      groups: (json['groups'] as List<dynamic>)
          .map((e) => TrainerGroupRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrainerAssignmentsModel {
  final String currentUserRole;
  final List<TrainerEntry> trainers;
  final List<MemberRef> unassigned;

  TrainerAssignmentsModel({
    required this.currentUserRole,
    required this.trainers,
    required this.unassigned,
  });

  factory TrainerAssignmentsModel.fromJson(Map<String, dynamic> json) {
    return TrainerAssignmentsModel(
      currentUserRole: json['currentUserRole'] as String,
      trainers: (json['trainers'] as List<dynamic>)
          .map((e) => TrainerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      unassigned: (json['unassigned'] as List<dynamic>)
          .map((e) => MemberRef.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
