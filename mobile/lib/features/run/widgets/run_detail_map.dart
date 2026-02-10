import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../../shared/models/run_model.dart';

/// Static map widget for displaying a completed run's GPS route.
///
/// Shows polyline of the route and auto-zooms to the bounding box.
class RunDetailMap extends StatefulWidget {
  final List<GpsPointModel> gpsPoints;

  const RunDetailMap({super.key, required this.gpsPoints});

  @override
  State<RunDetailMap> createState() => _RunDetailMapState();
}

class _RunDetailMapState extends State<RunDetailMap> {
  YandexMapController? _mapController;

  void _onMapCreated(YandexMapController controller) {
    _mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_mapController == null || widget.gpsPoints.isEmpty) return;

    final points = widget.gpsPoints;
    if (points.length == 1) {
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(
              latitude: points.first.latitude,
              longitude: points.first.longitude,
            ),
            zoom: 16.0,
          ),
        ),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    // Add padding to bounds
    final latPad = (maxLat - minLat) * 0.15;
    final lonPad = (maxLon - minLon) * 0.15;

    _mapController!.moveCamera(
      CameraUpdate.newBounds(
        BoundingBox(
          southWest: Point(latitude: minLat - latPad, longitude: minLon - lonPad),
          northEast: Point(latitude: maxLat + latPad, longitude: maxLon + lonPad),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapPoints = widget.gpsPoints
        .map((p) => Point(latitude: p.latitude, longitude: p.longitude))
        .toList();

    final List<MapObject> mapObjects = [];

    if (mapPoints.length >= 2) {
      mapObjects.add(
        PolylineMapObject(
          mapId: const MapObjectId('run_route_detail'),
          polyline: Polyline(points: mapPoints),
          strokeColor: Colors.blue,
          strokeWidth: 5.0,
        ),
      );
    }

    // Start marker
    if (mapPoints.isNotEmpty) {
      mapObjects.add(
        CircleMapObject(
          mapId: const MapObjectId('start_point'),
          circle: Circle(center: mapPoints.first, radius: 8),
          strokeColor: Colors.white,
          strokeWidth: 2,
          fillColor: Colors.green,
        ),
      );
    }

    // End marker
    if (mapPoints.length >= 2) {
      mapObjects.add(
        CircleMapObject(
          mapId: const MapObjectId('end_point'),
          circle: Circle(center: mapPoints.last, radius: 8),
          strokeColor: Colors.white,
          strokeWidth: 2,
          fillColor: Colors.red,
        ),
      );
    }

    return YandexMap(
      onMapCreated: _onMapCreated,
      mapObjects: mapObjects,
    );
  }
}
