enum SegmentType { warmup, run, rest, cooldown }

enum DurationType { time, distance, manual }

enum RecoveryType { jog, walk, stand }

class WorkoutSegment {
  final SegmentType type;
  final int durationValue; // seconds or meters
  final DurationType durationType;
  final String? targetValue;
  final String? targetZone;
  final RecoveryType? recoveryType;
  final String? instructions;
  final String? mediaUrl;

  WorkoutSegment({
    required this.type,
    required this.durationValue,
    required this.durationType,
    this.targetValue,
    this.targetZone,
    this.recoveryType,
    this.instructions,
    this.mediaUrl,
  });

  factory WorkoutSegment.fromJson(Map<String, dynamic> json) {
    return WorkoutSegment(
      type: SegmentType.values.firstWhere((e) => e.name.toUpperCase() == (json['type'] as String).toUpperCase()),
      durationValue: json['durationValue'] as int,
      durationType: DurationType.values.firstWhere((e) => e.name.toUpperCase() == (json['durationType'] as String).toUpperCase()),
      targetValue: json['targetValue'] as String?,
      targetZone: json['targetZone'] as String?,
      recoveryType: json['recoveryType'] != null
          ? RecoveryType.values.firstWhere((e) => e.name.toUpperCase() == (json['recoveryType'] as String).toUpperCase())
          : null,
      instructions: json['instructions'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name.toUpperCase(),
      'durationValue': durationValue,
      'durationType': durationType.name.toUpperCase(),
      if (targetValue != null) 'targetValue': targetValue,
      if (targetZone != null) 'targetZone': targetZone,
      if (recoveryType != null) 'recoveryType': recoveryType!.name.toUpperCase(),
      if (instructions != null) 'instructions': instructions,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };
  }
}

class WorkoutBlock {
  final int repeatCount;
  final List<WorkoutSegment> segments;

  WorkoutBlock({
    required this.repeatCount,
    required this.segments,
  });

  factory WorkoutBlock.fromJson(Map<String, dynamic> json) {
    return WorkoutBlock(
      repeatCount: json['repeatCount'] as int,
      segments: (json['segments'] as List)
          .map((s) => WorkoutSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'repeatCount': repeatCount,
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }
}

/// Workout template model
class Workout {
  final String id;
  final String authorId;
  final String? clubId;
  final String name;
  final String? description;
  final String type;
  final String difficulty;
  final String? surface;
  final List<WorkoutBlock>? blocks;
  final String targetMetric;
  final int? targetValue;
  final String? targetZone;
  final DateTime createdAt;

  Workout({
    required this.id,
    required this.authorId,
    this.clubId,
    required this.name,
    this.description,
    required this.type,
    required this.difficulty,
    this.surface,
    this.blocks,
    required this.targetMetric,
    this.targetValue,
    this.targetZone,
    required this.createdAt,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      clubId: json['clubId'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      surface: json['surface'] as String?,
      blocks: json['blocks'] != null
          ? (json['blocks'] as List)
              .map((b) => WorkoutBlock.fromJson(b as Map<String, dynamic>))
              .toList()
          : null,
      targetMetric: json['targetMetric'] as String,
      targetValue: json['targetValue'] as int?,
      targetZone: json['targetZone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorId': authorId,
      if (clubId != null) 'clubId': clubId,
      'name': name,
      if (description != null) 'description': description,
      'type': type,
      'difficulty': difficulty,
      if (surface != null) 'surface': surface,
      if (blocks != null) 'blocks': blocks!.map((b) => b.toJson()).toList(),
      'targetMetric': targetMetric,
      if (targetValue != null) 'targetValue': targetValue,
      if (targetZone != null) 'targetZone': targetZone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
