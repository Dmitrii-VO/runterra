import 'territory_model.dart';

/// Модель территории для отображения на карте
/// 
/// Используется для парсинга JSON ответов от API /api/map/data.
/// Содержит только структуру данных без бизнес-логики.
/// 
/// ВАЖНО: На текущей стадии (skeleton) не содержит геометрию границ,
/// только координаты центра для отображения placeholder-полигонов.
class TerritoryMapModel {
  /// Уникальный идентификатор территории
  final String id;
  
  /// Название территории
  final String name;
  
  /// Статус территории
  /// 
  /// Возможные значения: 'free', 'captured', 'contested', 'locked'
  final String status;
  
  /// Координаты центра территории
  final TerritoryCoordinates coordinates;
  
  /// Идентификатор города
  final String cityId;
  
  /// Идентификатор игрока, захватившего территорию (если захвачена)
  final String? capturedByUserId;
  
  /// Идентификатор клуба-владельца территории (если захвачена клубом)
  final String? clubId;
  
  /// Дата создания
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  TerritoryMapModel({
    required this.id,
    required this.name,
    required this.status,
    required this.coordinates,
    required this.cityId,
    this.capturedByUserId,
    this.clubId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает TerritoryMapModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  factory TerritoryMapModel.fromJson(Map<String, dynamic> json) {
    return TerritoryMapModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      coordinates: TerritoryCoordinates.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
      cityId: json['cityId'] as String,
      capturedByUserId: json['capturedByUserId'] as String?,
      clubId: json['clubId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует TerritoryMapModel в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'coordinates': coordinates.toJson(),
      'cityId': cityId,
      if (capturedByUserId != null) 'capturedByUserId': capturedByUserId,
      if (clubId != null) 'clubId': clubId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
