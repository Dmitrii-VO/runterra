import 'territory_model.dart';

/// Модель территории для отображения на карте
/// 
/// Используется для парсинга JSON ответов от API /api/map/data.
/// Содержит только структуру данных без бизнес-логики.
/// 
/// [geometry] — опциональный массив точек полигона границ.
/// Если задан, рисуется PolygonMapObject; иначе — CircleMapObject (fallback).
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
  
  /// Опциональная геометрия границ — массив точек полигона
  final List<TerritoryCoordinates>? geometry;
  
  /// Идентификатор города
  final String cityId;
  
  /// Идентификатор игрока, захватившего территорию (если захвачена)
  final String? capturedByUserId;
  
  /// Идентификатор клуба-владельца территории (если захвачена клубом)
  final String? clubId;

  /// Цвет территории (hex string, e.g. '#FF0000') для отображения границ
  final String? color;
  
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
    this.geometry,
    this.capturedByUserId,
    this.clubId,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает TerritoryMapModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  factory TerritoryMapModel.fromJson(Map<String, dynamic> json) {
    final geometryJson = json['geometry'] as List<dynamic>?;
    final geometry = geometryJson?.map((e) {
      return TerritoryCoordinates.fromJson(e as Map<String, dynamic>);
    }).toList();

    return TerritoryMapModel(
      id: json['id'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      coordinates: TerritoryCoordinates.fromJson(
        json['coordinates'] as Map<String, dynamic>,
      ),
      cityId: json['cityId'] as String,
      geometry: geometry,
      capturedByUserId: json['capturedByUserId'] as String?,
      clubId: json['clubId'] as String?,
      color: json['color'] as String?,
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
      if (geometry != null) 'geometry': geometry!.map((e) => e.toJson()).toList(),
      if (capturedByUserId != null) 'capturedByUserId': capturedByUserId,
      if (clubId != null) 'clubId': clubId,
      if (color != null) 'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
