import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../l10n/app_localizations.dart';
import '../../shared/api/users_service.dart' show ApiException;
import '../../shared/di/service_locator.dart';
import '../../main.dart' show DevRemoteLogger;
import '../../shared/models/map_data_model.dart';
import '../../shared/models/territory_map_model.dart';
import '../../shared/models/territory_model.dart' show TerritoryCoordinates;
import '../../shared/models/city_model.dart';
import '../../shared/models/my_club_model.dart';
import '../city/city_picker_dialog.dart';
import 'widgets/territory_bottom_sheet.dart';
import '../../shared/models/club_model.dart';
import '../../shared/models/event_list_item_model.dart';
import '../../shared/utils/map_style.dart';
import '../../shared/models/map_layer_model.dart';
import 'widgets/map_layers_panel.dart';
import 'package:intl/intl.dart';

/// Экран карты (MVP)
///
/// Отображает карту с территориями и событиями.
/// Реализует:
/// - Стартовая позиция: центр города (fallback: СПб)
/// - Территории: круги с цветами статусов
/// - События: маркеры на карте
/// - Кнопка "Моё местоположение"
/// - При [showClubs] true: после загрузки показывается bottom sheet со списком клубов города
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.showClubs = false,
    this.focusLatitude,
    this.focusLongitude,
  });

  final bool showClubs;

  /// If provided, map will center on these coordinates on load.
  final double? focusLatitude;
  final double? focusLongitude;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _mapController;
  MapDataModel? _mapData;
  bool _isMapReady = false;
  CityModel? _currentCity;
  bool _clubsSheetShown = false;

  // Дефолтные координаты СПб (fallback)
  static const double _defaultLongitude = 30.3351;
  static const double _defaultLatitude = 59.9343;
  static const double _defaultZoom = 12.0;
  // Event markers become tappable only above this zoom level
  static const double _eventTapZoomThreshold = 14.0;

  // Радиус территории в метрах
  static const double _territoryRadiusMeters = 500.0;
  static const double _minZoom = 9.0;
  static const double _maxZoom = 19.0;
  bool _isAdjustingCamera = false;
  bool _isAnimatingToFocus = false;

  // Active club and current territory (for banner)
  MyClubModel? _activeClub;
  TerritoryMapModel? _currentTerritory;
  List<MyClubModel> _myClubs = [];
  Timer? _territoryCheckTimer;

  // Map objects: territories (polygons/circles), capture labels, event markers
  List<MapObject> _territoryMapObjects = [];
  List<PlacemarkMapObject> _captureLabels = [];
  List<PlacemarkMapObject> _eventMarkers = [];
  BitmapDescriptor? _eventMarkerIcon; // fallback / open_event
  final Map<String, BitmapDescriptor> _eventMarkerIcons = {};
  final Map<int, BitmapDescriptor> _groupMarkerIconCache = {};
  double _currentZoom = _defaultZoom;

  // Layer visibility state
  MapLayerState _layerState = MapLayerState.defaults();
  // Venue markers (layer Г)
  List<PlacemarkMapObject> _venueMarkers = [];
  BitmapDescriptor? _venueMarkerIcon;

  @override
  void initState() {
    super.initState();
    _createEventMarkerIcon();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCityAndLoad());
    _loadActiveClub();
  }

  @override
  void dispose() {
    _territoryCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusLatitude != oldWidget.focusLatitude ||
        widget.focusLongitude != oldWidget.focusLongitude) {
      _flyToFocusPoint();
    }
  }

  /// Moves camera to focus coordinates if provided.
  /// Uses _isAnimatingToFocus flag to prevent _handleCameraPositionChanged
  /// from clamping intermediate animation frames to city bounds (which would
  /// interrupt the focus animation when starting position is far from target).
  Future<void> _flyToFocusPoint() async {
    final lat = widget.focusLatitude;
    final lon = widget.focusLongitude;
    if (lat != null && lon != null && _mapController != null) {
      _isAnimatingToFocus = true;

      // Small delay to ensure native map view is fully laid out
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted || _mapController == null) {
        _isAnimatingToFocus = false;
        return;
      }

      try {
        await _mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: Point(latitude: lat, longitude: lon),
              zoom: 15.0,
            ),
          ),
          animation: const MapAnimation(
            type: MapAnimationType.smooth,
            duration: 1.0,
          ),
        );
      } finally {
        _isAnimatingToFocus = false;
      }
    }
  }

  /// Pre-renders all event marker icons (type icons + group count icons).
  Future<void> _createEventMarkerIcon() async {
    // Type icons + group icons for counts 2..9 and "9+"
    final groupCounts = [2, 3, 4, 5, 6, 7, 8, 9, 10]; // 10 = "9+"
    final futures = [
      _renderMarkerIcon(_drawOpenEventIcon),
      _renderMarkerIcon(_drawTrainingIcon),
      _renderMarkerIcon(_drawGroupRunIcon),
      _renderMarkerIcon(_drawClubEventIcon),
      ...groupCounts.map((n) => _renderMarkerIcon((c, s) => _drawGroupIcon(c, s, n))),
    ];
    final icons = await Future.wait(futures);
    if (!mounted) return;
    setState(() {
      _eventMarkerIcons['open_event'] = icons[0];
      _eventMarkerIcons['training']   = icons[1];
      _eventMarkerIcons['group_run']  = icons[2];
      _eventMarkerIcons['club_event'] = icons[3];
      _eventMarkerIcon = icons[0]; // fallback
      for (var i = 0; i < groupCounts.length; i++) {
        _groupMarkerIconCache[groupCounts[i]] = icons[4 + i];
      }
    });
    if (_mapData != null && _isMapReady) {
      _updateEventMarkers();
    }
    _venueMarkerIcon = await _renderMarkerIcon(_drawVenueIcon);
    if (!mounted) return;
    if (_mapData != null && _isMapReady && _layerState.isEnabled(MapLayer.venues)) {
      _updateVenueMarkers();
    }
  }

  Future<BitmapDescriptor> _renderMarkerIcon(
      void Function(Canvas, double) draw) async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));
    draw(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _drawCircleBase(Canvas canvas, double size, Color color) {
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 1.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  // Orange circle + calendar icon → open_event
  void _drawOpenEventIcon(Canvas canvas, double size) {
    _drawCircleBase(canvas, size, Colors.deepOrange);
    canvas.save();
    canvas.scale(size / 64.0);
    final white = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(18, 22, 28, 24), const Radius.circular(3)),
      white,
    );
    final bar = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(26, 18), const Offset(26, 26), bar);
    canvas.drawLine(const Offset(38, 18), const Offset(38, 26), bar);
    final dot = Paint()..color = Colors.deepOrange;
    canvas.drawCircle(const Offset(26, 36), 2.5, dot);
    canvas.drawCircle(const Offset(32, 36), 2.5, dot);
    canvas.drawCircle(const Offset(38, 36), 2.5, dot);
    canvas.restore();
  }

  // Blue circle + lightning bolt → training
  void _drawTrainingIcon(Canvas canvas, double size) {
    _drawCircleBase(canvas, size, Colors.blue.shade700);
    canvas.save();
    canvas.scale(size / 64.0);
    final path = Path()
      ..moveTo(35, 14)
      ..lineTo(25, 34)
      ..lineTo(31, 34)
      ..lineTo(29, 50)
      ..lineTo(39, 30)
      ..lineTo(33, 30)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.restore();
  }

  // Green circle + running figure → group_run
  void _drawGroupRunIcon(Canvas canvas, double size) {
    _drawCircleBase(canvas, size, Colors.green.shade600);
    canvas.save();
    canvas.scale(size / 64.0);
    final p = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(const Offset(34, 16), 5, Paint()..color = Colors.white);
    canvas.drawLine(const Offset(34, 21), const Offset(30, 34), p);
    canvas.drawLine(const Offset(32, 26), const Offset(24, 23), p);
    canvas.drawLine(const Offset(31, 28), const Offset(38, 25), p);
    canvas.drawLine(const Offset(30, 34), const Offset(24, 44), p);
    canvas.drawLine(const Offset(30, 34), const Offset(36, 45), p);
    canvas.restore();
  }

  // Teal circle + location pin → venue (stadium/track)
  void _drawVenueIcon(Canvas canvas, double size) {
    _drawCircleBase(canvas, size, Colors.teal.shade600);
    canvas.save();
    canvas.scale(size / 64.0);
    final p = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(32, 26), 11, p);
    final path = Path()
      ..moveTo(21, 28)
      ..quadraticBezierTo(20, 46, 32, 52)
      ..quadraticBezierTo(44, 46, 43, 28)
      ..close();
    canvas.drawPath(path, p);
    canvas.drawCircle(const Offset(32, 26), 5, Paint()..color = Colors.teal.shade600);
    canvas.restore();
  }

  // Purple circle + flag → club_event
  void _drawClubEventIcon(Canvas canvas, double size) {
    _drawCircleBase(canvas, size, Colors.purple.shade600);
    canvas.save();
    canvas.scale(size / 64.0);
    final p = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    canvas.drawLine(const Offset(24, 46), const Offset(24, 18), p);
    final flag = Path()
      ..moveTo(24, 18)
      ..lineTo(42, 23)
      ..lineTo(24, 30)
      ..close();
    canvas.drawPath(flag, Paint()..color = Colors.white);
    canvas.restore();
  }

  /// Загружает данные карты в фоне (не блокирует показ карты)
  Future<void> _loadMapDataInBackground() async {
    // Check GPS permission (non-blocking, just for snackbar notification)
    _checkGpsPermission();

    // Load map data
    await _loadMapData();
  }

  /// Loads the active club for the banner.
  Future<void> _loadActiveClub() async {
    try {
      final clubs = await ServiceLocator.clubsService.getMyClubs();
      if (!mounted) return;
      final currentId = ServiceLocator.currentClubService.currentClubId;
      MyClubModel? active;
      if (currentId != null) {
        for (final c in clubs) {
          if (c.id == currentId) {
            active = c;
            break;
          }
        }
      }
      active ??= clubs
              .where((c) => c.status == 'active')
              .cast<MyClubModel?>()
              .firstOrNull ??
          clubs.cast<MyClubModel?>().firstOrNull;
      if (mounted) {
        setState(() {
          _myClubs = clubs;
          _activeClub = active;
        });
      }
    } catch (_) {}
  }

  /// Starts the periodic timer that checks user location against territories.
  void _startTerritoryCheckTimer() {
    _territoryCheckTimer?.cancel();
    _territoryCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkCurrentTerritory();
    });
    _checkCurrentTerritory();
  }

  /// Gets user GPS position and finds which territory (if any) they are in.
  Future<void> _checkCurrentTerritory() async {
    if (_mapData == null) return;
    try {
      final locationService = ServiceLocator.locationService;
      final permission = await locationService.checkPermission();
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        return;
      }
      final position = await locationService.getCurrentPosition();
      if (!mounted) return;
      final territory =
          _findTerritoryAtPoint(position.latitude, position.longitude);
      if (mounted) {
        setState(() => _currentTerritory = territory);
      }
    } catch (_) {}
  }

  /// Finds the territory containing the given point (lat/lon).
  TerritoryMapModel? _findTerritoryAtPoint(double lat, double lon) {
    if (_mapData == null) return null;
    for (final territory in _mapData!.territories) {
      if (territory.geometry != null && territory.geometry!.length >= 3) {
        if (_isPointInPolygon(lat, lon, territory.geometry!)) return territory;
      } else {
        final dist = _haversineMeters(
          lat,
          lon,
          territory.coordinates.latitude,
          territory.coordinates.longitude,
        );
        if (dist <= _territoryRadiusMeters) return territory;
      }
    }
    return null;
  }

  /// Point-in-polygon test using ray casting algorithm.
  bool _isPointInPolygon(
      double lat, double lon, List<TerritoryCoordinates> polygon) {
    bool inside = false;
    final n = polygon.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;
      if (((yi > lat) != (yj > lat)) &&
          (lon < (xj - xi) * (lat - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
    }
    return inside;
  }

  /// Approximate distance in meters between two lat/lon points (Haversine).
  double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Shows a bottom sheet to select the active club.
  void _showClubSelectionSheet() {
    if (_myClubs.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.selectClub,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ..._myClubs.map((club) => ListTile(
                title: Text(club.name),
                selected: club.id == _activeClub?.id,
                trailing: club.id == _activeClub?.id
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await ServiceLocator.currentClubService
                      .setCurrentClubId(club.id);
                  if (mounted) setState(() => _activeClub = club);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Гарантирует, что выбран город, и затем загружает данные карты.
  Future<void> _ensureCityAndLoad() async {
    final currentCityService = ServiceLocator.currentCityService;
    if (!currentCityService.isInitialized) {
      await currentCityService.init();
    }

    if (!mounted) return;

    if (currentCityService.currentCityId == null ||
        currentCityService.currentCityId!.isEmpty) {
      final selectedCityId = await showCityPickerDialog(context);
      if (!mounted) return;

      if (selectedCityId == null || selectedCityId.isEmpty) {
        // Пользователь не выбрал город — карту можно оставить пустой.
        return;
      }

      await currentCityService.setCurrentCityId(selectedCityId);
    }

    final city = await currentCityService.getCurrentCity();
    if (mounted && city != null) {
      setState(() {
        _currentCity = city;
      });
    }

    await _loadMapDataInBackground();
  }

  /// Проверяет разрешения GPS (не блокирует)
  Future<void> _checkGpsPermission() async {
    try {
      final locationService = ServiceLocator.locationService;
      var permission = await locationService.checkPermission();

      if (permission == geo.LocationPermission.denied) {
        permission = await locationService.requestPermission();
      }

      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.mapLocationDeniedSnackbar),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Could not check GPS permission: $e');
      DevRemoteLogger.logError(
        'GPS permission check failed',
        error: e,
      );
    }
  }

  /// Загружает данные карты через MapService
  Future<void> _loadMapData() async {
    final cityId = ServiceLocator.currentCityService.currentCityId;
    if (cityId == null || cityId.isEmpty) {
      // Если по какой-то причине города нет, не делаем запрос.
      return;
    }

    try {
      final data = await ServiceLocator.mapService.getMapData(
        cityId: cityId,
      );

      if (mounted) {
        setState(() {
          _mapData = data;
        });
        if (_isMapReady) {
          _updateMapObjects();
          // Territory check now that data is loaded
          _startTerritoryCheckTimer();
        }
      }
    } on ApiException catch (e) {
      if (e.code == 'unauthorized' && mounted) {
        // Try refreshing the token once and retry
        try {
          await ServiceLocator.refreshAuthToken();
          final retryData = await ServiceLocator.mapService.getMapData(
            cityId: cityId,
          );
          if (mounted) {
            setState(() {
              _mapData = retryData;
            });
            if (_isMapReady) {
              _updateMapObjects();
              _startTerritoryCheckTimer();
            }
          }
          return;
        } on ApiException catch (retryErr) {
          if (retryErr.code == 'unauthorized' && mounted) {
            context.go('/login');
            return;
          }
        } catch (_) {
          // Fall through to generic error handling below
        }
      }
      debugPrint('Error loading map data: $e');
      DevRemoteLogger.logError('Error loading map data', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .mapLoadErrorSnackbar(e.toString())),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              onPressed: _loadMapData,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading map data: $e');
      DevRemoteLogger.logError('Error loading map data', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .mapLoadErrorSnackbar(e.toString())),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              onPressed: _loadMapData,
            ),
          ),
        );
      }
    }
  }

  /// Обновляет объекты на карте (территории и события)
  void _updateMapObjects() {
    if (_mapController == null || _mapData == null) return;

    try {
      _updateTerritoryMapObjects();
      _updateCaptureLabels();
      _updateEventMarkers();
      _updateVenueMarkers();
    } catch (e) {
      debugPrint('Error updating map objects: $e');
      DevRemoteLogger.logError(
        'Error updating map objects',
        error: e,
      );
    }
  }

  /// Обновляет объекты территорий (полигоны при наличии geometry, иначе круги)
  void _updateTerritoryMapObjects() {
    if (_mapData == null) return;
    if (!_layerState.isEnabled(MapLayer.territories)) {
      setState(() => _territoryMapObjects = []);
      return;
    }

    final objects = <MapObject>[];
    for (var i = 0; i < _mapData!.territories.length; i++) {
      final territory = _mapData!.territories[i];

      // Determine colors
      final parsedColor = _parseColor(territory.color);
      final statusStrokeColor = _getTerritoryStrokeColor(territory.status);
      final statusFillColor = _getTerritoryColor(territory.status);

      // Prefer explicit territory color for stroke, fallback to status color
      final strokeColor = parsedColor != null
          ? parsedColor.withAlpha(204)
          : statusStrokeColor;

      // Use semi-transparent territory color for fill if available, fallback to status fill
      final fillColor = parsedColor != null
          ? parsedColor.withAlpha(76)
          : statusFillColor;

      void onTerritoryTap(_, __) => _showTerritoryBottomSheet(territory);

      if (territory.geometry != null && territory.geometry!.length >= 3) {
        // Polygon: geometry points + close ring if needed
        final points = territory.geometry!
            .map((c) => Point(latitude: c.latitude, longitude: c.longitude))
            .toList();

        // Only add first point as last if it's not already there
        if (points.isNotEmpty &&
            (points.first.latitude != points.last.latitude ||
                points.first.longitude != points.last.longitude)) {
          points.add(points.first);
        }

        objects.add(PolygonMapObject(
          mapId: MapObjectId('territory_$i'),
          polygon: Polygon(
            outerRing: LinearRing(points: points),
            innerRings: const [],
          ),
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: 2.0, // Slightly thicker for visibility
          onTap: onTerritoryTap,
        ));
      } else {
        // Fallback: circle by center
        objects.add(CircleMapObject(
          mapId: MapObjectId('territory_$i'),
          circle: Circle(
            center: Point(
              latitude: territory.coordinates.latitude,
              longitude: territory.coordinates.longitude,
            ),
            radius: _territoryRadiusMeters,
          ),
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: 2.0,
          onTap: onTerritoryTap,
        ));
      }
    }

    setState(() {
      _territoryMapObjects = objects;
    });
  }

  /// Creates PlacemarkMapObjects with club initials at the centroid of captured territories
  Future<void> _updateCaptureLabels() async {
    if (_mapData == null) return;
    if (!_layerState.isEnabled(MapLayer.territories)) {
      if (mounted) setState(() => _captureLabels = []);
      return;
    }

    final labels = <PlacemarkMapObject>[];
    for (var i = 0; i < _mapData!.territories.length; i++) {
      final territory = _mapData!.territories[i];
      if (territory.clubId == null) continue;

      // Compute centroid
      final Point centroid;
      if (territory.geometry != null && territory.geometry!.length >= 3) {
        double latSum = 0, lonSum = 0;
        for (final c in territory.geometry!) {
          latSum += c.latitude;
          lonSum += c.longitude;
        }
        final n = territory.geometry!.length;
        centroid = Point(latitude: latSum / n, longitude: lonSum / n);
      } else {
        centroid = Point(
          latitude: territory.coordinates.latitude,
          longitude: territory.coordinates.longitude,
        );
      }

      // Create a small icon with club initials
      final initials = territory.clubId!.length >= 2
          ? territory.clubId!.substring(0, 2).toUpperCase()
          : territory.clubId!.toUpperCase();

      final icon = await _createTextIcon(initials);
      if (icon == null || !mounted) continue;

      labels.add(PlacemarkMapObject(
        mapId: MapObjectId('capture_label_$i'),
        point: centroid,
        icon: PlacemarkIcon.single(PlacemarkIconStyle(
          image: icon,
          scale: 0.6,
        )),
        opacity: 0.9,
      ));
    }

    // Re-check layer state: user may have toggled territories off while we were awaiting
    if (!_layerState.isEnabled(MapLayer.territories)) return;
    if (mounted) {
      setState(() {
        _captureLabels = labels;
      });
    }
  }

  /// Creates a programmatic icon with text initials (circle background + text)
  Future<BitmapDescriptor?> _createTextIcon(String text) async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    // Circle background
    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(
        const Offset(size / 2, size / 2), size / 2 - 1, borderPaint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  }

  Color? _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return null;
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return null;
    }
  }

  /// Grouping precision depends on zoom: further out → coarser grid → more grouping.
  int get _groupingPrecision {
    if (_currentZoom < 15) return 3; // ~100m
    if (_currentZoom < 17) return 4; // ~10m
    return 5;                         // ~1m
  }

  /// Updates event markers on the map, grouping events at the same location.
  /// Fully synchronous — all icons are pre-rendered at startup.
  void _updateEventMarkers() {
    if (_mapData == null || _eventMarkerIcon == null) return;

    final layerBEnabled = _layerState.isEnabled(MapLayer.races);
    final layerCEnabled = _layerState.isEnabled(MapLayer.local);
    if (!layerBEnabled && !layerCEnabled) {
      setState(() => _eventMarkers = []);
      return;
    }

    const localTypes = {'group_run', 'training', 'club_event'};
    final visibleEvents = _mapData!.events.where((e) {
      if (e.type == 'open_event') return layerBEnabled;
      if (localTypes.contains(e.type)) return layerCEnabled;
      return false; // unknown types are hidden until explicitly classified
    }).toList();

    final precision = _groupingPrecision;
    final groups = <String, List<EventListItemModel>>{};
    for (final event in visibleEvents) {
      if (event.startLocation == null) continue;
      final key =
          '${event.startLocation!.latitude.toStringAsFixed(precision)},${event.startLocation!.longitude.toStringAsFixed(precision)}';
      groups.putIfAbsent(key, () => []).add(event);
    }

    final markers = <PlacemarkMapObject>[];
    final tappable = _currentZoom >= _eventTapZoomThreshold;

    for (final entry in groups.entries) {
      final events = entry.value;
      final loc = events.first.startLocation!;
      final point = Point(latitude: loc.latitude, longitude: loc.longitude);

      if (events.length == 1) {
        final event = events.first;
        final icon = _eventMarkerIcons[event.type] ?? _eventMarkerIcon!;
        markers.add(PlacemarkMapObject(
          mapId: MapObjectId('event_${event.id}'),
          point: point,
          icon: PlacemarkIcon.single(PlacemarkIconStyle(
            image: icon,
            scale: 0.55,
          )),
          onTap: tappable ? (_, __) => _showEventBottomSheet(event) : null,
        ));
      } else {
        // Clamp to max cached count (10 = "9+")
        final cacheKey = events.length > 9 ? 10 : events.length;
        final icon = _groupMarkerIconCache[cacheKey] ?? _eventMarkerIcon!;
        markers.add(PlacemarkMapObject(
          mapId: MapObjectId('event_group_${entry.key}'),
          point: point,
          icon: PlacemarkIcon.single(PlacemarkIconStyle(
            image: icon,
            scale: 0.55,
          )),
          onTap: tappable
              ? (_, __) => _showEventGroupBottomSheet(List.unmodifiable(events))
              : null,
        ));
      }
    }

    setState(() => _eventMarkers = markers);
  }

  static const List<({String name, double lat, double lon})> _spbVenues = [
    (name: 'Парк Победы', lat: 59.8684, lon: 30.3226),
    (name: 'ЦПКиО им. Кирова', lat: 59.9801, lon: 30.2615),
    (name: 'Удельный парк', lat: 60.0164, lon: 30.3170),
    (name: 'Парк 300-летия', lat: 60.0001, lon: 30.1753),
    (name: 'Петровский стадион', lat: 59.9536, lon: 30.2580),
    (name: 'Южно-Приморский парк', lat: 59.9370, lon: 30.1399),
  ];

  void _updateVenueMarkers() {
    if (_venueMarkerIcon == null ||
        !_layerState.isEnabled(MapLayer.venues) ||
        _currentCity?.id != 'spb') {
      setState(() => _venueMarkers = []);
      return;
    }
    final markers = _spbVenues
        .map((v) => PlacemarkMapObject(
              mapId: MapObjectId('venue_${v.name}'),
              point: Point(latitude: v.lat, longitude: v.lon),
              icon: PlacemarkIcon.single(PlacemarkIconStyle(
                image: _venueMarkerIcon!,
                scale: 0.55,
              )),
            ))
        .toList();
    setState(() => _venueMarkers = markers);
  }

  void _onLayerToggled(MapLayer layer) {
    setState(() => _layerState = _layerState.withToggled(layer));
    _updateMapObjects();
  }

  // Dark blue circle + white count number → event group
  void _drawGroupIcon(Canvas canvas, double size, int count) {
    // Background circle
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = const Color(0xFF1A237E),
    );
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 1.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Count number
    final tp = TextPainter(
      text: TextSpan(
        text: count > 9 ? '9+' : count.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset((size - tp.width) / 2, (size - tp.height) / 2),
    );
  }

  /// Shows a bottom sheet with event details
  void _showEventBottomSheet(EventListItemModel event) {
    if (_isSheetShowing) return;
    _isSheetShowing = true;
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d.M.y H:mm');

    String getEventTypeText(String type) {
      switch (type) {
        case 'training':
          return l10n.eventTypeTraining;
        case 'group_run':
          return l10n.eventTypeGroupRun;
        case 'club_event':
          return l10n.eventTypeClubEvent;
        case 'open_event':
          return l10n.eventTypeOpenEvent;
        default:
          return type;
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(getEventTypeText(event.type)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(dateFormat.format(event.startDateTime)),
                  ],
                ),
                if (event.locationName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(event.locationName!)),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      this.context.push('/event/${event.id}');
                    },
                    child: Text(l10n.territoryMore),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isSheetShowing = false);
        } else {
          _isSheetShowing = false;
        }
      });
    });
  }

  void _showEventGroupBottomSheet(List<EventListItemModel> events) {
    if (_isSheetShowing) return;
    _isSheetShowing = true;
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d.M.y H:mm');

    Color typeColor(String type) {
      switch (type) {
        case 'training':
          return Colors.blue.shade700;
        case 'group_run':
          return Colors.green.shade600;
        case 'club_event':
          return Colors.purple.shade600;
        default:
          return Colors.deepOrange;
      }
    }

    String typeLabel(String type) {
      switch (type) {
        case 'training':
          return l10n.eventTypeTraining;
        case 'group_run':
          return l10n.eventTypeGroupRun;
        case 'club_event':
          return l10n.eventTypeClubEvent;
        default:
          return l10n.eventTypeOpenEvent;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${events.length} ${l10n.eventsTitle.toLowerCase()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: typeColor(event.type),
                          child: const Icon(Icons.directions_run,
                              color: Colors.white, size: 18),
                        ),
                        title: Text(event.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${typeLabel(event.type)} · ${dateFormat.format(event.startDateTime)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context);
                          this.context.push('/event/${event.id}');
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isSheetShowing = false);
        } else {
          _isSheetShowing = false;
        }
      });
    });
  }

  /// Returns a discrete "marker state" based on zoom: encodes both
  /// tap-interactivity and grouping precision tier so markers rebuild
  /// only when something meaningful changes.
  int _markerZoomTier(double zoom) {
    if (zoom < _eventTapZoomThreshold) return 0; // not tappable
    if (zoom < 15) return 1;                      // tappable, precision 3
    if (zoom < 17) return 2;                      // tappable, precision 4
    return 3;                                     // tappable, precision 5
  }

  void _handleCameraPositionChanged(CameraPosition position) {
    final newZoom = position.zoom;
    if (_markerZoomTier(newZoom) != _markerZoomTier(_currentZoom)) {
      _currentZoom = newZoom;
      _updateEventMarkers();
    } else {
      _currentZoom = newZoom;
    }

    if (_isAdjustingCamera ||
        _isAnimatingToFocus ||
        _mapController == null ||
        _currentCity == null) {
      return;
    }

    var zoom = position.zoom;
    if (zoom < _minZoom) zoom = _minZoom;
    if (zoom > _maxZoom) zoom = _maxZoom;

    final bounds = _currentCity!.bounds;
    if (bounds == null) {
      return;
    }

    var latitude = position.target.latitude;
    var longitude = position.target.longitude;

    latitude = latitude.clamp(bounds.sw.latitude, bounds.ne.latitude);
    longitude = longitude.clamp(bounds.sw.longitude, bounds.ne.longitude);

    final isZoomOk = zoom == position.zoom;
    final isLatOk = latitude == position.target.latitude;
    final isLonOk = longitude == position.target.longitude;

    if (isZoomOk && isLatOk && isLonOk) {
      return;
    }

    _isAdjustingCamera = true;
    _mapController!
        .moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: latitude, longitude: longitude),
          zoom: zoom,
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.2,
      ),
    )
        .whenComplete(() {
      _isAdjustingCamera = false;
    });
  }

  /// Получает цвет заливки территории по статусу
  Color _getTerritoryColor(String status) {
    switch (status) {
      case 'captured':
        return const Color.fromRGBO(33, 150, 243, 0.3); // blue
      case 'free':
        return const Color.fromRGBO(158, 158, 158, 0.2); // grey
      case 'contested':
        return const Color.fromRGBO(255, 235, 59, 0.3); // yellow
      case 'locked':
        return const Color.fromRGBO(66, 66, 66, 0.3); // dark grey
      default:
        return const Color.fromRGBO(158, 158, 158, 0.2);
    }
  }

  /// Получает цвет границы территории по статусу
  Color _getTerritoryStrokeColor(String status) {
    switch (status) {
      case 'captured':
        return Colors.blue;
      case 'free':
        return Colors.grey;
      case 'contested':
        return Colors.yellow;
      case 'locked':
        return Colors.grey.shade800;
      default:
        return Colors.grey;
    }
  }

  bool _isSheetShowing = false;

  /// Показывает bottom sheet для территории
  void _showTerritoryBottomSheet(TerritoryMapModel territory) {
    if (_isSheetShowing) return;
    _isSheetShowing = true;
    showModalBottomSheet(
      context: context,
      builder: (context) => TerritoryBottomSheet(territory: territory),
    ).whenComplete(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _isSheetShowing = false);
        } else {
          _isSheetShowing = false;
        }
      });
    });
  }

  /// Обработчик создания карты
  void _onMapCreated(YandexMapController controller) async {
    debugPrint('MapScreen: onMapCreated called');

    _mapController = controller;
    await controller.setMapStyle(kCleanMapStyle);

    if (mounted) {
      setState(() {
        _isMapReady = true;
      });

      // If focus coordinates provided, center on them; otherwise use default city center
      if (widget.focusLatitude != null && widget.focusLongitude != null) {
        await _flyToFocusPoint();
      } else {
        await _centerMapOnStartPosition();
      }

      if (_mapData != null) {
        _updateMapObjects();
      }
      if (widget.showClubs &&
          _currentCity != null &&
          !_clubsSheetShown &&
          mounted) {
        _clubsSheetShown = true;
        _showClubsBottomSheet();
      }
    }
  }

  /// Показывает bottom sheet со списком клубов города (при переходе по «Найти клуб»)
  void _showClubsBottomSheet() {
    final cityId = _currentCity?.id;
    if (cityId == null || cityId.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _ClubsBottomSheet(cityId: cityId);
      },
    );
  }

  /// Центрирует карту на стартовой позиции
  Future<void> _centerMapOnStartPosition() async {
    if (_mapController == null) return;

    double longitude = _defaultLongitude;
    double latitude = _defaultLatitude;

    // Если известен текущий город — используем его центр.
    if (_currentCity != null) {
      longitude = _currentCity!.center.longitude;
      latitude = _currentCity!.center.latitude;
    } else if (_mapData != null && _mapData!.viewport.center.longitude != 0) {
      // Иначе используем viewport из данных карты
      longitude = _mapData!.viewport.center.longitude;
      latitude = _mapData!.viewport.center.latitude;
    } else {
      // Пытаемся получить GPS координаты
      try {
        final locationService = ServiceLocator.locationService;
        var permission = await locationService.checkPermission();
        if (permission != geo.LocationPermission.denied &&
            permission != geo.LocationPermission.deniedForever) {
          final position = await locationService.getCurrentPosition();
          longitude = position.longitude;
          latitude = position.latitude;
        }
      } catch (e) {
        // Используем fallback
      }
    }

    await _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: latitude, longitude: longitude),
          zoom: _defaultZoom,
        ),
      ),
      animation: const MapAnimation(
        type: MapAnimationType.smooth,
        duration: 0.0,
      ),
    );
  }

  /// Центрирует карту на текущей позиции пользователя
  Future<void> _centerOnMyLocation() async {
    if (_mapController == null) return;

    try {
      final locationService = ServiceLocator.locationService;

      var permission = await locationService.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await locationService.requestPermission();
      }

      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.mapNoLocationSnackbar),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final position = await locationService.getCurrentPosition();

      await _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: Point(
              latitude: position.latitude,
              longitude: position.longitude,
            ),
            zoom: 15.0,
          ),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 1.0,
        ),
      );
    } catch (e) {
      debugPrint('Error centering on location: $e');
      DevRemoteLogger.logError(
        'Error centering map on user location',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .mapLocationErrorSnackbar(e.toString())),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildClubTerritoryBanner(AppLocalizations l10n) {
    final clubLabel = _activeClub != null
        ? l10n.mapActiveClub(_activeClub!.name)
        : l10n.mapNoActiveClub;
    final territoryLabel = _currentTerritory != null
        ? l10n.mapCurrentTerritory(_currentTerritory!.name)
        : l10n.mapNoTerritory;

    return Row(
      children: [
        GestureDetector(
          onTap: _myClubs.length > 1 ? _showClubSelectionSheet : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clubLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_myClubs.length > 1) ...[
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 14,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _currentTerritory != null
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            territoryLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _currentTerritory != null
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always show the map, errors are displayed as snackbars
    return Scaffold(
      body: Stack(
        children: [
          // Карта Яндекс
          Builder(
            builder: (context) {
              debugPrint('MapScreen: Building YandexMap widget');
              return YandexMap(
                onMapCreated: _onMapCreated,
                onCameraPositionChanged: (position, reason, finished) {
                  _handleCameraPositionChanged(position);
                },
                mapObjects: [
                  ..._territoryMapObjects,
                  ..._captureLabels,
                  ..._eventMarkers,
                  ..._venueMarkers,
                ],
              );
            },
          ),

          // Панель с названием города сверху
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.mapTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    if (_myClubs.isNotEmpty || _activeClub != null) ...[
                      const SizedBox(height: 6),
                      _buildClubTerritoryBanner(AppLocalizations.of(context)!),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Map layers panel (top right, floats over city banner)
          Positioned(
            top: 0,
            right: 8,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: MapLayersPanel(
                  layerState: _layerState,
                  onToggle: _onLayerToggled,
                ),
              ),
            ),
          ),

          // Кнопка "Моё местоположение"
          if (_mapController != null)
            Positioned(
              bottom: 220,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                onPressed: _centerOnMyLocation,
                tooltip: AppLocalizations.of(context)!.mapMyLocationTooltip,
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }
}

class _ClubsBottomSheet extends StatefulWidget {
  final String cityId;

  const _ClubsBottomSheet({required this.cityId});

  @override
  State<_ClubsBottomSheet> createState() => _ClubsBottomSheetState();
}

class _ClubsBottomSheetState extends State<_ClubsBottomSheet> {
  late Future<List<ClubModel>> _clubsFuture;

  @override
  void initState() {
    super.initState();
    _clubsFuture = ServiceLocator.clubsService.getClubs(cityId: widget.cityId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return FutureBuilder<List<ClubModel>>(
          future: _clubsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(l10n.mapClubsSheetTitle),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.mapClubsSheetTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(snapshot.error.toString()),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.cancel),
                    ),
                  ],
                ),
              );
            }
            final clubs = snapshot.data ?? [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    l10n.mapClubsSheetTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Flexible(
                  child: clubs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              l10n.mapClubsEmpty,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: clubs.length,
                          itemBuilder: (context, index) {
                            final club = clubs[index];
                            return ListTile(
                              title: Text(club.name),
                              subtitle: club.description != null &&
                                      club.description!.isNotEmpty
                                  ? Text(club.description!)
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/club/');
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
