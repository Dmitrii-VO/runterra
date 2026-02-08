import 'event_start_location.dart';

/// DTO-модель события для списка
/// 
/// Используется для парсинга JSON ответов от API /api/events (список).
/// Содержит только структуру данных без бизнес-логики и валидации.
/// 
/// ВАЖНО: На текущей стадии (skeleton) не содержит GPS check-in данных,
/// расчётов участников, валидации.
/// 
/// TODO: Consider adding Equatable or freezed for value equality and copyWith support
/// 
/// Отличается от EventDetailsModel тем, что не содержит полное описание
/// и некоторые детальные поля для оптимизации списка.
class EventListItemModel {
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
  
  /// Координаты точки старта (для отображения на карте)
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
  
  /// Количество записавшихся участников
  final int participantCount;
  
  /// Идентификатор территории, к которой привязано событие (если есть)
  final String? territoryId;
  
  /// Идентификатор города, в котором проходит событие
  final String cityId;

  EventListItemModel({
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
    required this.participantCount,
    this.territoryId,
    required this.cityId,
  });

  /// Создает EventListItemModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  /// 
  /// TODO: Add null safety checks instead of hard casts (as String, as int)
  /// to handle malformed JSON gracefully
  factory EventListItemModel.fromJson(Map<String, dynamic> json) {
    return EventListItemModel(
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
      participantCount: (json['participantCount'] as num).toInt(),
      territoryId: json['territoryId'] as String?,
      cityId: json['cityId'] as String? ?? '',
    );
  }

  /// Преобразует EventListItemModel в JSON
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
      'participantCount': participantCount,
      if (territoryId != null) 'territoryId': territoryId,
      'cityId': cityId,
    };
  }
}
