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
    this.difficultyLevel,
    this.description,
    this.participantLimit,
    required this.participantCount,
    this.territoryId,
    required this.cityId,
    required this.createdAt,
    required this.updatedAt,
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
      if (difficultyLevel != null) 'difficultyLevel': difficultyLevel,
      if (description != null) 'description': description,
      if (participantLimit != null) 'participantLimit': participantLimit,
      'participantCount': participantCount,
      if (territoryId != null) 'territoryId': territoryId,
      'cityId': cityId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
