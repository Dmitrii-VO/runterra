// ignore_for_file: prefer_const_constructors
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';

/// Карта с маршрутом пробежки в реальном времени.
///
/// Отображает полилинию из [gpsPoints]; при появлении новых точек
/// камера следует за последней позицией (follow runner).
/// Текущая позиция показана стрелкой направления движения (heading).
class RunRouteMap extends StatefulWidget {
  final List<Position> gpsPoints;

  const RunRouteMap({super.key, required this.gpsPoints});

  @override
  State<RunRouteMap> createState() => _RunRouteMapState();
}

class _RunRouteMapState extends State<RunRouteMap> {
  YandexMapController? _mapController;
  Point? _initialCenter;
  Uint8List? _arrowIcon;
  static const double _defaultZoom = 14.0;
  static const double _runZoom = 16.0;
  static const double _defaultLon = 30.3351;
  static const double _defaultLat = 59.9343;
  static const int _arrowSize = 80;
  static const MapObjectId _currentPositionArrowId = MapObjectId('current_position_arrow');
  static const MapObjectId _currentPositionDotId = MapObjectId('current_position_dot');

  @override
  void initState() {
    super.initState();
    _loadInitialCenter();
    _generateArrowIcon();
  }

  /// Draw a navigation arrow icon (blue arrow with white border).
  Future<void> _generateArrowIcon() async {
    final size = _arrowSize.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 4;

    // White circle background with shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center + const Offset(0, 2), radius, shadowPaint);

    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius, bgPaint);

    // Blue navigation arrow pointing UP (north)
    final arrowPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    // Arrow tip at top
    path.moveTo(size / 2, size * 0.18);
    // Right wing
    path.lineTo(size * 0.72, size * 0.72);
    // Inner notch
    path.lineTo(size / 2, size * 0.58);
    // Left wing
    path.lineTo(size * 0.28, size * 0.72);
    path.close();

    canvas.drawPath(path, arrowPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null && mounted) {
      setState(() {
        _arrowIcon = byteData.buffer.asUint8List();
      });
    }
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

    // Current position: directional arrow (or fallback blue dot)
    if (points.isNotEmpty) {
      final lastPosition = widget.gpsPoints.last;
      final heading = lastPosition.heading; // 0-360, 0 = north
      final hasValidHeading = heading.isFinite && heading >= 0 && heading <= 360;

      if (_arrowIcon != null && hasValidHeading) {
        mapObjects.add(
          PlacemarkMapObject(
            mapId: _currentPositionArrowId,
            point: points.last,
            direction: heading,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image: BitmapDescriptor.fromBytes(_arrowIcon!),
                scale: 0.5,
                rotationType: RotationType.rotate,
              ),
            ),
          ),
        );
      } else {
        // Fallback: blue dot when no heading data
        mapObjects.add(
          CircleMapObject(
            mapId: _currentPositionDotId,
            circle: Circle(center: points.last, radius: 16),
            strokeColor: Colors.white,
            strokeWidth: 3,
            fillColor: Colors.blue,
          ),
        );
      }
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
