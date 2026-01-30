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
  
  /// Статус клуба
  /// 
  /// Возможные значения: 'active', 'inactive', 'disbanded', 'pending'
  final String status;
  
  /// Дата создания записи
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  ClubModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
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
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
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
