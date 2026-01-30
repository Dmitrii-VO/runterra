/// DTO-модель территории
/// 
/// Используется для парсинга JSON ответов от API /api/territories.
/// Содержит только структуру данных без бизнес-логики и валидации.
class TerritoryModel {
  /// Уникальный идентификатор территории
  final String id;
  
  /// Название территории
  final String name;
  
  /// Статус территории
  /// 
  /// Возможные значения: 'free', 'captured', 'contested', 'locked'
  final String status;
  
  /// Координаты центра территории на карте
  final TerritoryCoordinates coordinates;
  
  /// Идентификатор города, к которому относится территория
  final String cityId;
  
  /// Идентификатор игрока, захватившего территорию (если захвачена)
  final String? capturedByUserId;
  
  /// Идентификатор клуба-владельца территории (если захвачена клубом)
  final String? clubId;
  
  /// Дата создания записи
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  TerritoryModel({
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

  /// Создает TerritoryModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory TerritoryModel.fromJson(Map<String, dynamic> json) {
    return TerritoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      coordinates: TerritoryCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
      cityId: json['cityId'] as String,
      capturedByUserId: json['capturedByUserId'] as String?,
      clubId: json['clubId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует TerritoryModel в JSON
  /// 
  /// Используется для отправки данных на backend.
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

/// Координаты центра территории на карте
/// 
/// Используется для отображения территории на карте через Mapbox.
/// Формат: longitude (долгота), latitude (широта).
/// 
/// ВАЖНО: Это только координаты центра, не геометрия границ.
class TerritoryCoordinates {
  /// Долгота (longitude)
  final double longitude;
  
  /// Широта (latitude)
  final double latitude;

  TerritoryCoordinates({
    required this.longitude,
    required this.latitude,
  });

  /// Создает TerritoryCoordinates из JSON
  factory TerritoryCoordinates.fromJson(Map<String, dynamic> json) {
    return TerritoryCoordinates(
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
    );
  }

  /// Преобразует TerritoryCoordinates в JSON
  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}
