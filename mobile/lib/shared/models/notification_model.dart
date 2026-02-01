/// DTO-модель уведомления
/// 
/// Используется для парсинга JSON ответов от API /api/users/me/profile.
/// Содержит только структуру данных без бизнес-логики и валидации.
/// 
/// ВАЖНО: На текущей стадии (skeleton) содержит только заглушки
/// без логики отправки уведомлений.
class NotificationModel {
  /// Уникальный идентификатор уведомления
  final String id;
  
  /// Идентификатор пользователя-получателя
  final String userId;
  
  /// Тип уведомления
  /// 
  /// Возможные значения: 'territory_threat', 'new_training', 
  /// 'territory_captured', 'training_reminder'
  final String type;
  
  /// Заголовок уведомления
  final String title;
  
  /// Текст уведомления
  final String message;
  
  /// Флаг прочтения уведомления
  final bool read;
  
  /// Дата создания уведомления
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  /// Создает NotificationModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Преобразует NotificationModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
