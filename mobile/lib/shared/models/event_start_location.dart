/// Координаты точки старта события
/// 
/// Используется в EventListItemModel и EventDetailsModel.
/// Вынесен в отдельный файл для избежания дублирования.
class EventStartLocation {
  /// Долгота (longitude)
  final double longitude;
  
  /// Широта (latitude)
  final double latitude;

  EventStartLocation({
    required this.longitude,
    required this.latitude,
  });

  /// Создает EventStartLocation из JSON
  factory EventStartLocation.fromJson(Map<String, dynamic> json) {
    return EventStartLocation(
      longitude: (json['longitude'] as num).toDouble(),
      latitude: (json['latitude'] as num).toDouble(),
    );
  }

  /// Преобразует EventStartLocation в JSON
  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
    };
  }
}
