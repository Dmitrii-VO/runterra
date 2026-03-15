// Personal workout plan model

enum WorkoutPlanType {
  easyRun,
  longRun,
  intervals,
  progression,
  recovery,
  hillRun;

  String toApi() {
    switch (this) {
      case WorkoutPlanType.easyRun:
        return 'EASY_RUN';
      case WorkoutPlanType.longRun:
        return 'LONG_RUN';
      case WorkoutPlanType.intervals:
        return 'INTERVALS';
      case WorkoutPlanType.progression:
        return 'PROGRESSION';
      case WorkoutPlanType.recovery:
        return 'RECOVERY';
      case WorkoutPlanType.hillRun:
        return 'HILL_RUN';
    }
  }

  static WorkoutPlanType fromApi(String value) {
    switch (value) {
      case 'EASY_RUN':
        return WorkoutPlanType.easyRun;
      case 'LONG_RUN':
        return WorkoutPlanType.longRun;
      case 'INTERVALS':
        return WorkoutPlanType.intervals;
      case 'PROGRESSION':
        return WorkoutPlanType.progression;
      case 'RECOVERY':
        return WorkoutPlanType.recovery;
      case 'HILL_RUN':
        return WorkoutPlanType.hillRun;
      default:
        return WorkoutPlanType.easyRun;
    }
  }
}

/// Cooldown config: duration in minutes or distance in metres
class CooldownConfig {
  final String type; // 'duration' | 'distance'
  final int value;

  const CooldownConfig({required this.type, required this.value});

  factory CooldownConfig.fromJson(Map<String, dynamic> json) =>
      CooldownConfig(type: json['type'] as String, value: json['value'] as int);

  Map<String, dynamic> toJson() => {'type': type, 'value': value};
}

/// Optional warmup for Intervals (distance in metres)
class WarmupConfig {
  final int valueM;

  const WarmupConfig({required this.valueM});

  factory WarmupConfig.fromJson(Map<String, dynamic> json) =>
      WarmupConfig(valueM: json['valueM'] as int);

  Map<String, dynamic> toJson() => {'valueM': valueM};
}

/// A segment in a Progression workout
class ProgressionSegment {
  final int? distanceM;
  final int? paceTargetSecPerKm;
  final int? heartRate;

  const ProgressionSegment({this.distanceM, this.paceTargetSecPerKm, this.heartRate});

  factory ProgressionSegment.fromJson(Map<String, dynamic> json) => ProgressionSegment(
        distanceM: json['distanceM'] as int?,
        paceTargetSecPerKm: json['paceTargetSecPerKm'] as int?,
        heartRate: json['heartRate'] as int?,
      );

  Map<String, dynamic> toJson() => {
        if (distanceM != null) 'distanceM': distanceM,
        if (paceTargetSecPerKm != null) 'paceTargetSecPerKm': paceTargetSecPerKm,
        if (heartRate != null) 'heartRate': heartRate,
      };
}

/// Interval config: one interval block with repeats
class IntervalConfig {
  final WarmupConfig? warmup;
  final int? distanceM;
  final int? restDistanceM;
  final int? restDurationMin;
  final int reps;
  final int? recoveryDistanceM;
  final int? recoveryDurationMin;

  const IntervalConfig({
    this.warmup,
    this.distanceM,
    this.restDistanceM,
    this.restDurationMin,
    required this.reps,
    this.recoveryDistanceM,
    this.recoveryDurationMin,
  });

  factory IntervalConfig.fromJson(Map<String, dynamic> json) => IntervalConfig(
        warmup: json['warmup'] != null
            ? WarmupConfig.fromJson(json['warmup'] as Map<String, dynamic>)
            : null,
        distanceM: json['distanceM'] as int?,
        restDistanceM: json['restDistanceM'] as int?,
        restDurationMin: json['restDurationMin'] as int?,
        reps: json['reps'] as int,
        recoveryDistanceM: json['recoveryDistanceM'] as int?,
        recoveryDurationMin: json['recoveryDurationMin'] as int?,
      );

  Map<String, dynamic> toJson() => {
        if (warmup != null) 'warmup': warmup!.toJson(),
        if (distanceM != null) 'distanceM': distanceM,
        if (restDistanceM != null) 'restDistanceM': restDistanceM,
        if (restDurationMin != null) 'restDurationMin': restDurationMin,
        'reps': reps,
        if (recoveryDistanceM != null) 'recoveryDistanceM': recoveryDistanceM,
        if (recoveryDurationMin != null) 'recoveryDurationMin': recoveryDurationMin,
      };
}

/// Full workout plan
class WorkoutPlan {
  final String? id;
  final String name;
  final WorkoutPlanType type;

  // Common optional parameters
  final int? durationMin;
  final int? distanceM;
  final int? paceTargetSecPerKm; // seconds per km
  final int? heartRateTarget;

  // Intervals
  final IntervalConfig? intervalConfig;

  // Progression segments
  final List<ProgressionSegment>? progressionSegments;

  // HillRun
  final int? hillElevationM;

  // Cooldown (any type)
  final CooldownConfig? cooldown;

  // Scheduling
  final DateTime? scheduledAt;

  // Template/favorite flags
  final bool isTemplate;
  final bool isFavorite;

  const WorkoutPlan({
    this.id,
    required this.name,
    required this.type,
    this.durationMin,
    this.distanceM,
    this.paceTargetSecPerKm,
    this.heartRateTarget,
    this.intervalConfig,
    this.progressionSegments,
    this.hillElevationM,
    this.cooldown,
    this.scheduledAt,
    this.isTemplate = false,
    this.isFavorite = false,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    // blocks JSONB stores type-specific configs
    final blocks = json['blocks'] as List<dynamic>?;
    IntervalConfig? intervalConfig;
    List<ProgressionSegment>? progressionSegments;
    CooldownConfig? cooldown;

    if (blocks != null) {
      for (final block in blocks) {
        final b = block as Map<String, dynamic>;
        final bType = b['type'] as String?;
        if (bType == 'interval_config') {
          intervalConfig = IntervalConfig.fromJson(b);
        } else if (bType == 'progression_segment') {
          progressionSegments ??= [];
          progressionSegments.add(ProgressionSegment.fromJson(b));
        } else if (bType == 'cooldown') {
          cooldown = CooldownConfig.fromJson(b);
        }
      }
    }

    return WorkoutPlan(
      id: json['id'] as String?,
      name: json['name'] as String,
      type: WorkoutPlanType.fromApi(json['type'] as String),
      durationMin: json['durationMin'] as int?,
      distanceM: json['distance_m'] as int?,
      paceTargetSecPerKm: json['pace_target'] as int?,
      heartRateTarget: json['heart_rate_target'] as int?,
      hillElevationM: json['hill_elevation_m'] as int?,
      intervalConfig: intervalConfig,
      progressionSegments: progressionSegments,
      cooldown: cooldown,
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'] as String)
          : null,
      isTemplate: (json['is_template'] as bool?) ?? false,
      isFavorite: (json['is_favorite'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final blocks = <Map<String, dynamic>>[];
    if (intervalConfig != null) {
      blocks.add({'type': 'interval_config', ...intervalConfig!.toJson()});
    }
    if (progressionSegments != null) {
      for (final seg in progressionSegments!) {
        blocks.add({'type': 'progression_segment', ...seg.toJson()});
      }
    }
    if (cooldown != null) {
      blocks.add({'type': 'cooldown', ...cooldown!.toJson()});
    }

    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type.toApi(),
      'difficulty': 'BEGINNER',
      'targetMetric': 'DISTANCE',
      if (distanceM != null) 'distanceM': distanceM,
      if (paceTargetSecPerKm != null) 'paceTarget': paceTargetSecPerKm,
      if (heartRateTarget != null) 'heartRateTarget': heartRateTarget,
      if (hillElevationM != null) 'hillElevationM': hillElevationM,
      if (blocks.isNotEmpty) 'blocks': blocks,
      if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
      'isTemplate': isTemplate,
    };
  }

  WorkoutPlan copyWith({
    String? id,
    String? name,
    WorkoutPlanType? type,
    int? durationMin,
    int? distanceM,
    int? paceTargetSecPerKm,
    int? heartRateTarget,
    IntervalConfig? intervalConfig,
    List<ProgressionSegment>? progressionSegments,
    int? hillElevationM,
    CooldownConfig? cooldown,
    DateTime? scheduledAt,
    bool? isTemplate,
    bool? isFavorite,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      durationMin: durationMin ?? this.durationMin,
      distanceM: distanceM ?? this.distanceM,
      paceTargetSecPerKm: paceTargetSecPerKm ?? this.paceTargetSecPerKm,
      heartRateTarget: heartRateTarget ?? this.heartRateTarget,
      intervalConfig: intervalConfig ?? this.intervalConfig,
      progressionSegments: progressionSegments ?? this.progressionSegments,
      hillElevationM: hillElevationM ?? this.hillElevationM,
      cooldown: cooldown ?? this.cooldown,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      isTemplate: isTemplate ?? this.isTemplate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
