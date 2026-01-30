/// DTO-модель города
/// 
/// Используется для парсинга JSON ответов от API /api/cities.
/// Содержит только структуру данных без бизнес-логики и валидации.
class CityModel {
  /// Уникальный идентификатор города
  final String id;
  
  /// Название города
  final String name;
  
  /// Координаты города на карте
  final CityCoordinates coordinates;
  
  /// Дата создания записи
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  CityModel({
    required this.id,
    required this.name,
    required this.coordinates,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает CityModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      coordinates: CityCoordinates.fromJson(json['coordinates'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует CityModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coordinates': coordinates.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Координаты города на карте
/// 
/// Используется для отображения города на карте через Mapbox.
/// Формат: longitude (долгота), latitude (широта).
class CityCoordinates {
  /// Долгота (longitude)
  final double longitude;
  
  /// Широта (latitude)
  final double latitude;

  CityCoordinates({
    required this.longitude,
    required this.latitude,
  });

  /// Создает CityCoordinates из JSON
  factory CityCoordinates.fromJson(Map<String, dynamic> json) {
    return CityCoordinates(
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
    );
  }

  /// Преобразует CityCoordinates в JSON
  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}
