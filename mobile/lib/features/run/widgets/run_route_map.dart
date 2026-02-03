// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../../shared/di/service_locator.dart';

/// Карта с маршрутом пробежки в реальном времени.
///
/// Отображает полилинию из [gpsPoints]; при появлении новых точек
/// камера следует за последней позицией (follow runner).
class RunRouteMap extends StatefulWidget {
  final List<Position> gpsPoints;

  const RunRouteMap({super.key, required this.gpsPoints});

  @override
  State<RunRouteMap> createState() => _RunRouteMapState();
}

class _RunRouteMapState extends State<RunRouteMap> {
  YandexMapController? _mapController;
  Point? _initialCenter;
  static const double _defaultZoom = 14.0;
  static const double _runZoom = 16.0;
  static const double _defaultLon = 30.3351;
  static const double _defaultLat = 59.9343;

  @override
  void initState() {
    super.initState();
    _loadInitialCenter();
  }

  Future<void> _loadInitialCenter() async {
    final city = await ServiceLocator.currentCityService.getCurrentCity();
    if (!mounted) return;
    setState(() {
      _initialCenter = city != null
          ? Point(latitude: city.center.latitude, longitude: city.center.longitude)
          : const Point(latitude: _defaultLat, longitude: _defaultLon);
    });
  }

  @override
  void didUpdateWidget(covariant RunRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLen = oldWidget.gpsPoints.length;
    final newLen = widget.gpsPoints.length;
    if (_mapController != null && newLen > oldLen && newLen > 0) {
      final last = widget.gpsPoints.last;
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(latitude: last.latitude, longitude: last.longitude),
            zoom: _runZoom,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.3,
        ),
      );
    }
  }

  void _onMapCreated(YandexMapController controller) {
    _mapController = controller;
    final points = widget.gpsPoints;
    if (points.isNotEmpty) {
      final p = points.last;
      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(latitude: p.latitude, longitude: p.longitude),
            zoom: _runZoom,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.3,
        ),
      );
    } else if (_initialCenter != null) {
      final center = _initialCenter!;
      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: _defaultZoom),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.3,
        ),
      );
    } else {
      controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: const Point(latitude: _defaultLat, longitude: _defaultLon),
            zoom: _defaultZoom,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.3,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.gpsPoints
        .map((p) => Point(latitude: p.latitude, longitude: p.longitude))
        .toList();

    final List<MapObject> mapObjects = [];
    if (points.length >= 2) {
      mapObjects.add(
        PolylineMapObject(
          mapId: const MapObjectId('run_route'),
          polyline: Polyline(points: points),
          strokeColor: Colors.blue,
          strokeWidth: 5.0,
        ),
      );
    }

    return YandexMap(
      onMapCreated: _onMapCreated,
      mapObjects: mapObjects,
    );
  }
}
