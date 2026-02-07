// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../../l10n/app_localizations.dart';
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

  /// Centers the camera on the current position (last GPS point).
  void centerOnCurrentPosition() {
    if (_mapController == null || widget.gpsPoints.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final points = widget.gpsPoints
        .map((p) => Point(latitude: p.latitude, longitude: p.longitude))
        .toList();

    final List<MapObject> mapObjects = [];

    // Draw polyline if we have 2+ points
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

    // Show current position marker if we have at least 1 GPS point
    if (points.isNotEmpty) {
      mapObjects.add(
        CircleMapObject(
          mapId: const MapObjectId('current_position'),
          circle: Circle(center: points.last, radius: 10),
          strokeColor: Colors.white,
          strokeWidth: 3,
          fillColor: Colors.blue,
        ),
      );
    }

    return Stack(
      children: [
        YandexMap(
          onMapCreated: _onMapCreated,
          mapObjects: mapObjects,
        ),
        // "Find me" FAB button
        if (widget.gpsPoints.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: centerOnCurrentPosition,
              tooltip: l10n.runFindMe,
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }
}
