import 'event_start_location.dart';

/// DTO-модель события для детального экрана
/// 
/// Используется для парсинга JSON ответов от API /api/events/:id (детали).
/// Содержит только структуру данных без бизнес-логики и валидации.
/// 
/// ВАЖНО: На текущей стадии (skeleton) не содержит GPS check-in данных,
/// расчётов участников, валидации.
/// 
/// Содержит все поля, включая полное описание и координаты точки старта.
class EventDetailsModel {
  /// Уникальный идентификатор события
  final String id;
  
  /// Название события
  final String name;
  
  /// Тип события
  /// 
  /// Возможные значения: 'training', 'group_run', 'club_event', 'open_event'
  final String type;
  
  /// Статус события
  /// 
  /// Возможные значения: 'draft', 'open', 'full', 'cancelled', 'completed'
  final String status;
  
  /// Дата и время начала события
  final DateTime startDateTime;
  
  /// Координаты точки старта
  final EventStartLocation startLocation;
  
  /// Краткое название локации (парк / район)
  final String? locationName;
  
  /// Идентификатор организатора (клуб или тренер)
  final String organizerId;
  
  /// Тип организатора
  /// 
  /// Возможные значения: 'club', 'trainer'
  final String organizerType;
  
  /// Отображаемое имя организатора (название клуба или имя тренера). Приходит с backend.
  final String? organizerDisplayName;
  
  /// Уровень подготовки
  /// 
  /// Возможные значения: 'beginner', 'intermediate', 'advanced'
  final String? difficultyLevel;
  
  /// Описание события (опционально)
  final String? description;
  
  /// 
  /// Лимит участников (опционально)
  /// 
  /// Также называется capacity - максимальное количество участников.
  /// Если не указан, событие без ограничений по количеству участников.
  /// Используется для определения статуса FULL (participantCount >= participantLimit).
  /// 
  /// Invariant: FULL means participantCount >= participantLimit (when both are not null)
  final int? participantLimit;
  
  /// 
  /// Количество записавшихся участников
  /// 
  /// Также называется participantsCount - текущее количество участников.
  /// Используется вместе с participantLimit для определения статуса FULL.
  /// TODO: Вычислять автоматически при записи/отмене участия.
  /// 
  /// Invariant: FULL means participantCount >= participantLimit (when both are not null)
  final int participantCount;
  
  /// Идентификатор территории, к которой привязано событие (если есть)
  final String? territoryId;
  
  /// Идентификатор города, в котором проходит событие
  final String cityId;
  
  /// Дата создания записи
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  /// Linked workout template ID
  final String? workoutId;

  /// Assigned trainer ID
  final String? trainerId;

  /// Workout name (resolved for display)
  final String? workoutName;

  /// Workout description (resolved for display)
  final String? workoutDescription;

  /// Workout type (resolved for display)
  final String? workoutType;

  /// Workout difficulty (resolved for display)
  final String? workoutDifficulty;

  /// Trainer display name (resolved for display)
  final String? trainerName;

  /// Признак участия текущего пользователя
  final bool? isParticipant;

  /// Статус участия текущего пользователя
  final String? participantStatus;

  /// Whether the current user is an organizer (can edit the event)
  final bool? isOrganizer;

  EventDetailsModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.startDateTime,
    required this.startLocation,
    this.locationName,
    required this.organizerId,
    required this.organizerType,
    this.organizerDisplayName,
    this.difficultyLevel,
    this.description,
    this.participantLimit,
    required this.participantCount,
    this.territoryId,
    required this.cityId,
    required this.createdAt,
    required this.updatedAt,
    this.workoutId,
    this.trainerId,
    this.workoutName,
    this.workoutDescription,
    this.workoutType,
    this.workoutDifficulty,
    this.trainerName,
    this.isParticipant,
    this.participantStatus,
    this.isOrganizer,
  });

  /// Создает EventDetailsModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory EventDetailsModel.fromJson(Map<String, dynamic> json) {
    return EventDetailsModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      startLocation: EventStartLocation.fromJson(
        json['startLocation'] as Map<String, dynamic>,
      ),
      locationName: json['locationName'] as String?,
      organizerId: json['organizerId'] as String,
      organizerType: json['organizerType'] as String,
      organizerDisplayName: json['organizerDisplayName'] as String?,
      difficultyLevel: json['difficultyLevel'] as String?,
      description: json['description'] as String?,
      participantLimit: json['participantLimit'] != null
          ? (json['participantLimit'] as num).toInt()
          : null,
      participantCount: (json['participantCount'] as num).toInt(),
      territoryId: json['territoryId'] as String?,
      cityId: json['cityId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      workoutId: json['workoutId'] as String?,
      trainerId: json['trainerId'] as String?,
      workoutName: json['workoutName'] as String?,
      workoutDescription: json['workoutDescription'] as String?,
      workoutType: json['workoutType'] as String?,
      workoutDifficulty: json['workoutDifficulty'] as String?,
      trainerName: json['trainerName'] as String?,
      isParticipant: json['isParticipant'] as bool?,
      participantStatus: json['participantStatus'] as String?,
      isOrganizer: json['isOrganizer'] as bool?,
    );
  }

  /// Преобразует EventDetailsModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'startDateTime': startDateTime.toIso8601String(),
      'startLocation': startLocation.toJson(),
      if (locationName != null) 'locationName': locationName,
      'organizerId': organizerId,
      'organizerType': organizerType,
      if (organizerDisplayName != null) 'organizerDisplayName': organizerDisplayName,
      if (difficultyLevel != null) 'difficultyLevel': difficultyLevel,
      if (description != null) 'description': description,
      if (participantLimit != null) 'participantLimit': participantLimit,
      'participantCount': participantCount,
      if (territoryId != null) 'territoryId': territoryId,
      'cityId': cityId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (workoutId != null) 'workoutId': workoutId,
      if (trainerId != null) 'trainerId': trainerId,
      if (workoutName != null) 'workoutName': workoutName,
      if (workoutDescription != null) 'workoutDescription': workoutDescription,
      if (workoutType != null) 'workoutType': workoutType,
      if (workoutDifficulty != null) 'workoutDifficulty': workoutDifficulty,
      if (trainerName != null) 'trainerName': trainerName,
      if (isParticipant != null) 'isParticipant': isParticipant,
      if (participantStatus != null) 'participantStatus': participantStatus,
      if (isOrganizer != null) 'isOrganizer': isOrganizer,
    };
  }
}
