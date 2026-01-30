import 'territory_map_model.dart';
import 'event_list_item_model.dart';

/// Модель данных карты
/// 
/// Используется для парсинга JSON ответов от API /api/map/data.
/// Содержит территории и события для отображения на карте.
/// 
/// ВАЖНО: На текущей стадии (skeleton) не содержит бизнес-логику,
/// только структуру данных.
class MapDataModel {
  /// Область видимости карты (viewport)
  final MapViewport viewport;
  
  /// Список территорий для отображения на карте
  final List<TerritoryMapModel> territories;
  
  /// Список событий для отображения на карте
  final List<EventListItemModel> events;
  
  /// Метаданные ответа
  final MapMeta? meta;

  MapDataModel({
    required this.viewport,
    required this.territories,
    required this.events,
    this.meta,
  });

  /// Создает MapDataModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  factory MapDataModel.fromJson(Map<String, dynamic> json) {
    return MapDataModel(
      viewport: MapViewport.fromJson(
        json['viewport'] as Map<String, dynamic>,
      ),
      territories: (json['territories'] as List<dynamic>)
          .map((item) => TerritoryMapModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List<dynamic>)
          .map((item) => EventListItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] != null
          ? MapMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Преобразует MapDataModel в JSON
  Map<String, dynamic> toJson() {
    return {
      'viewport': viewport.toJson(),
      'territories': territories.map((t) => t.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      if (meta != null) 'meta': meta!.toJson(),
    };
  }
}

/// Область видимости карты (viewport)
class MapViewport {
  /// Центр карты
  final MapCoordinates center;
  
  /// Уровень масштабирования
  final double zoom;

  MapViewport({
    required this.center,
    required this.zoom,
  });

  /// Создает MapViewport из JSON
  factory MapViewport.fromJson(Map<String, dynamic> json) {
    return MapViewport(
      center: MapCoordinates.fromJson(
        json['center'] as Map<String, dynamic>,
      ),
      zoom: (json['zoom'] as num).toDouble(),
    );
  }

  /// Преобразует MapViewport в JSON
  Map<String, dynamic> toJson() {
    return {
      'center': center.toJson(),
      'zoom': zoom,
    };
  }
}

/// Координаты точки на карте
class MapCoordinates {
  /// Долгота (longitude)
  final double longitude;
  
  /// Широта (latitude)
  final double latitude;

  MapCoordinates({
    required this.longitude,
    required this.latitude,
  });

  /// Создает MapCoordinates из JSON
  factory MapCoordinates.fromJson(Map<String, dynamic> json) {
    return MapCoordinates(
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
    );
  }

  /// Преобразует MapCoordinates в JSON
  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}

/// Метаданные ответа API карты
class MapMeta {
  /// Версия API
  final String? version;
  
  /// Временная метка ответа
  final DateTime? timestamp;

  MapMeta({
    this.version,
    this.timestamp,
  });

  /// Создает MapMeta из JSON
  factory MapMeta.fromJson(Map<String, dynamic> json) {
    return MapMeta(
      version: json['version'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  /// Преобразует MapMeta в JSON
  Map<String, dynamic> toJson() {
    return {
      if (version != null) 'version': version,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }
}
