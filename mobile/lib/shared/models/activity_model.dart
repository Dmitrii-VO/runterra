/// DTO-модель активности
/// 
/// Используется для парсинга JSON ответов от API /api/activities.
/// Содержит только структуру данных без бизнес-логики и валидации.
/// 
/// ВАЖНО: На текущей стадии (skeleton) не содержит GPS данных,
/// check-in точек, расчётов дистанции, времени, скорости.
class ActivityModel {
  /// Уникальный идентификатор активности
  final String id;
  
  /// Идентификатор пользователя, создавшего активность
  final String userId;
  
  /// Тип активности
  /// 
  /// Возможные значения: 'running', 'walking', 'cycling', 'training'
  final String type;
  
  /// Статус активности
  /// 
  /// Возможные значения: 'planned', 'in_progress', 'completed', 'cancelled'
  final String status;
  
  /// Название активности (опционально)
  final String? name;
  
  /// Описание активности (опционально)
  final String? description;
  
  /// Дата создания записи
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  ActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает ActivityModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует ActivityModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'status': status,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
