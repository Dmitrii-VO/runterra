/// DTO-модель активности для личного кабинета
/// 
/// Упрощенная модель активности для отображения в личном кабинете.
/// Используется для парсинга JSON ответов от API /api/users/me/profile.
class ProfileActivityModel {
  /// Идентификатор активности
  final String id;
  
  /// Название тренировки (опционально)
  final String? name;
  
  /// Дата и время (опционально)
  /// 
  /// TODO: Consider changing to DateTime? instead of String? for better type safety
  final String? dateTime;
  
  /// Статус активности
  /// 
  /// Возможные значения: 'planned', 'in_progress', 'completed', 'cancelled'
  final String status;
  
  /// Результат (засчитано / не засчитано) - для последней активности
  /// 
  /// Возможные значения: 'counted', 'not_counted'
  final String? result;
  
  /// Краткое сообщение - для последней активности
  final String? message;

  ProfileActivityModel({
    required this.id,
    this.name,
    this.dateTime,
    required this.status,
    this.result,
    this.message,
  });

  /// Создает ProfileActivityModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory ProfileActivityModel.fromJson(Map<String, dynamic> json) {
    return ProfileActivityModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      dateTime: json['dateTime'] as String?,
      status: json['status'] as String,
      result: json['result'] as String?,
      message: json['message'] as String?,
    );
  }

  /// Преобразует ProfileActivityModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (dateTime != null) 'dateTime': dateTime,
      'status': status,
      if (result != null) 'result': result,
      if (message != null) 'message': message,
    };
  }
}
