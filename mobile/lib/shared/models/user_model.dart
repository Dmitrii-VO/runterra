/// DTO-модель пользователя
/// 
/// Используется для парсинга JSON ответов от API /api/users.
/// Содержит только структуру данных без бизнес-логики и валидации.
class UserModel {
  /// Уникальный идентификатор пользователя
  final String id;
  
  /// Уникальный идентификатор пользователя в Firebase Authentication
  final String firebaseUid;
  
  /// Email пользователя
  final String email;
  
  /// Имя пользователя
  final String name;
  
  /// URL фото профиля (опционально)
  final String? avatarUrl;
  
  /// Идентификатор города пользователя (опционально)
  final String? cityId;
  
  /// Флаг меркателя (true - меркатель, false - участник клуба)
  final bool isMercenary;
  
  /// Статус пользователя
  /// 
  /// Возможные значения: 'active', 'inactive', 'blocked'
  final String status;
  
  /// Дата создания пользователя
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.cityId,
    required this.isMercenary,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает UserModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      cityId: json['cityId'] as String?,
      isMercenary: json['isMercenary'] as bool? ?? false,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует UserModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'email': email,
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (cityId != null) 'cityId': cityId,
      'isMercenary': isMercenary,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
