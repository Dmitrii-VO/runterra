import 'dart:async';
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
import '../../shared/models/city_model.dart';
import '../city/city_picker_dialog.dart';
import 'widgets/territory_bottom_sheet.dart';
import '../../shared/models/club_model.dart';
import '../../shared/models/event_list_item_model.dart';
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
  
  // Радиус территории в метрах
  static const double _territoryRadiusMeters = 500.0;
  static const double _minZoom = 9.0;
  static const double _maxZoom = 19.0;
  bool _isAdjustingCamera = false;
  bool _hasFocusPoint = false;
  bool _isAnimatingToFocus = false;
  
  // Объекты на карте (территории — полигоны или круги; события — маркеры)
  List<MapObject> _territoryMapObjects = [];
  List<PlacemarkMapObject> _eventMarkers = [];
  BitmapDescriptor? _eventMarkerIcon;

  @override
  void initState() {
    super.initState();
    _createEventMarkerIcon();
    _ensureCityAndLoad();
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
      _hasFocusPoint = true;
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

  /// Creates a programmatic event marker icon (orange circle with calendar icon)
  Future<void> _createEventMarkerIcon() async {
    const size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    // Orange circle background
    final paint = Paint()..color = Colors.deepOrange;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 1.5, borderPaint);

    // White inner icon (simple calendar-like shape)
    final iconPaint = Paint()..color = Colors.white;
    // Draw a small rectangle (event icon body)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 22, 28, 24),
        const Radius.circular(3),
      ),
      iconPaint,
    );
    // Draw top bars of calendar
    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(26, 18), const Offset(26, 26), barPaint);
    canvas.drawLine(const Offset(38, 18), const Offset(38, 26), barPaint);

    // Orange dots inside calendar
    final dotPaint = Paint()..color = Colors.deepOrange;
    canvas.drawCircle(const Offset(26, 36), 2.5, dotPaint);
    canvas.drawCircle(const Offset(32, 36), 2.5, dotPaint);
    canvas.drawCircle(const Offset(38, 36), 2.5, dotPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null && mounted) {
      setState(() {
        _eventMarkerIcon = BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
      });
      // Re-update markers if data already loaded
      if (_mapData != null && _isMapReady) {
        _updateEventMarkers();
      }
    }
  }

  /// Загружает данные карты в фоне (не блокирует показ карты)
  Future<void> _loadMapDataInBackground() async {
    // Check GPS permission (non-blocking, just for snackbar notification)
    _checkGpsPermission();
    
    // Load map data
    await _loadMapData();
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
              content: Text(AppLocalizations.of(context)!.mapLocationDeniedSnackbar),
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
          if (!_hasFocusPoint) {
            await _centerMapOnStartPosition();
          }
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
              if (!_hasFocusPoint) {
                await _centerMapOnStartPosition();
              }
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
            content: Text(AppLocalizations.of(context)!.mapLoadErrorSnackbar(e.toString())),
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
            content: Text(AppLocalizations.of(context)!.mapLoadErrorSnackbar(e.toString())),
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
      _updateEventMarkers();
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

    final objects = <MapObject>[];
    for (var i = 0; i < _mapData!.territories.length; i++) {
      final territory = _mapData!.territories[i];
      final color = _getTerritoryColor(territory.status);
      final strokeColor = _getTerritoryStrokeColor(territory.status);
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
          fillColor: color,
          strokeColor: strokeColor,
          strokeWidth: 1.5,
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
          fillColor: color,
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

  /// Updates event markers on the map
  void _updateEventMarkers() {
    if (_mapData == null || _eventMarkerIcon == null) return;

    final markers = <PlacemarkMapObject>[];
    for (final event in _mapData!.events) {
      markers.add(PlacemarkMapObject(
        mapId: MapObjectId('event_${event.id}'),
        point: Point(
          latitude: event.startLocation.latitude,
          longitude: event.startLocation.longitude,
        ),
        icon: PlacemarkIcon.single(PlacemarkIconStyle(
          image: _eventMarkerIcon!,
          scale: 0.8,
        )),
        onTap: (_, __) => _showEventBottomSheet(event),
      ));
    }

    setState(() {
      _eventMarkers = markers;
    });
  }

  /// Shows a bottom sheet with event details
  void _showEventBottomSheet(EventListItemModel event) {
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
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
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
    );
  }

  void _handleCameraPositionChanged(CameraPosition position) {
    if (_isAdjustingCamera || _isAnimatingToFocus || _mapController == null || _currentCity == null) {
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
  
  /// Показывает bottom sheet для территории
  void _showTerritoryBottomSheet(TerritoryMapModel territory) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TerritoryBottomSheet(territory: territory),
    );
  }

  /// Обработчик создания карты
  void _onMapCreated(YandexMapController controller) async {
    debugPrint('MapScreen: onMapCreated called');

    _mapController = controller;
    
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
      if (widget.showClubs && _currentCity != null && !_clubsSheetShown && mounted) {
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
        duration: 0.5,
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
              content: Text(AppLocalizations.of(context)!.mapNoLocationSnackbar),
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
            content: Text(AppLocalizations.of(context)!.mapLocationErrorSnackbar(e.toString())),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
                mapObjects: [..._territoryMapObjects, ..._eventMarkers],
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.mapTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
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
                              subtitle: club.description != null && club.description!.isNotEmpty
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
