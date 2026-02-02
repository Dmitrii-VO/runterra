/// DTO-модель города
///
/// Используется для парсинга JSON ответов от API /api/cities.
/// Содержит только структуру данных без бизнес-логики и валидации.
class CityModel {
  /// Уникальный идентификатор города
  final String id;

  /// Название города
  final String name;

  /// Координаты города (историческое поле, используется как центр по умолчанию)
  final CityCoordinates coordinates;

  /// Центр города (если отсутствует — равен [coordinates])
  final CityCoordinates center;

  /// Прямоугольные границы города (опционально)
  final CityBounds? bounds;

  /// Дата создания записи
  final DateTime createdAt;

  /// Дата последнего обновления
  final DateTime updatedAt;

  CityModel({
    required this.id,
    required this.name,
    required this.coordinates,
    CityCoordinates? center,
    this.bounds,
    required this.createdAt,
    required this.updatedAt,
  }) : center = center ?? coordinates;

  /// Создает CityModel из JSON
  ///
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory CityModel.fromJson(Map<String, dynamic> json) {
    final coordinatesJson = json['coordinates'] as Map<String, dynamic>?;
    final centerJson = json['center'] as Map<String, dynamic>?;

    final coordinates = coordinatesJson != null
        ? CityCoordinates.fromJson(coordinatesJson)
        : CityCoordinates(
            longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
            latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
          );

    final center = centerJson != null
        ? CityCoordinates.fromJson(centerJson)
        : coordinates;

    CityBounds? bounds;
    if (json['bounds'] is Map<String, dynamic>) {
      bounds = CityBounds.fromJson(json['bounds'] as Map<String, dynamic>);
    }

    return CityModel(
      id: json['id'] as String,
      name: json['name'] as String,
      coordinates: coordinates,
      center: center,
      bounds: bounds,
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
      'center': center.toJson(),
      if (bounds != null) 'bounds': bounds!.toJson(),
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

/// Прямоугольные границы города на карте.
class CityBounds {
  final CityCoordinates ne;
  final CityCoordinates sw;

  CityBounds({
    required this.ne,
    required this.sw,
  });

  factory CityBounds.fromJson(Map<String, dynamic> json) {
    return CityBounds(
      ne: CityCoordinates.fromJson(json['ne'] as Map<String, dynamic>),
      sw: CityCoordinates.fromJson(json['sw'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ne': ne.toJson(),
      'sw': sw.toJson(),
    };
  }
}
