/// DTO-модель информации о клубе для личного кабинета
/// 
/// Используется для парсинга JSON ответов от API /api/users/me/profile.
/// Содержит только структуру данных без бизнес-логики и валидации.
class ProfileClubModel {
  /// Идентификатор клуба
  final String id;
  
  /// Название клуба
  final String name;
  
  /// Роль пользователя в клубе
  /// 
  /// Возможные значения: 'member', 'moderator', 'leader'
  final String role;

  ProfileClubModel({
    required this.id,
    required this.name,
    required this.role,
  });

  /// Создает ProfileClubModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory ProfileClubModel.fromJson(Map<String, dynamic> json) {
    return ProfileClubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  /// Преобразует ProfileClubModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }
}
