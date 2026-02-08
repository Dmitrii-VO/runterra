/// DTO-модель клуба
/// 
/// Используется для парсинга JSON ответов от API /api/clubs.
/// Содержит только структуру данных без бизнес-логики и валидации.
class ClubModel {
  /// Уникальный идентификатор клуба
  final String id;
  
  /// Название клуба
  final String name;
  
  /// Описание клуба (опционально)
  final String? description;
  
  /// Идентификатор города клуба
  final String? cityId;

  /// Название города (из конфига backend, для отображения)
  final String? cityName;

  /// Статус клуба
  /// 
  /// Возможные значения: 'active', 'inactive', 'disbanded', 'pending'
  final String status;
  
  /// Дата создания записи
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  /// Текущий пользователь является участником клуба (при наличии auth)
  final bool? isMember;

  /// Статус членства: pending, active, inactive, suspended (если isMember == true)
  final String? membershipStatus;

  /// Роль пользователя в клубе: 'member', 'trainer', 'leader', null
  final String? userRole;

  /// Количество участников (MVP метрика, placeholder если нет с backend)
  final int? membersCount;

  /// Количество удерживаемых территорий (MVP метрика)
  final int? territoriesCount;

  /// Рейтинг в городе (MVP метрика)
  final int? cityRank;

  ClubModel({
    required this.id,
    required this.name,
    this.description,
    this.cityId,
    this.cityName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.isMember,
    this.membershipStatus,
    this.userRole,
    this.membersCount,
    this.territoriesCount,
    this.cityRank,
  });

  /// Создает ClubModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      cityId: json['cityId'] as String?,
      cityName: json['cityName'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isMember: json['isMember'] as bool?,
      membershipStatus: json['membershipStatus'] as String?,
      userRole: json['userRole'] as String?,
      membersCount: (json['membersCount'] as num?)?.toInt(),
      territoriesCount: (json['territoriesCount'] as num?)?.toInt(),
      cityRank: (json['cityRank'] as num?)?.toInt(),
    );
  }

  /// Преобразует ClubModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
