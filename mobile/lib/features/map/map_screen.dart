import 'dart:async';
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
import 'widgets/map_filters.dart';

/// Экран карты (MVP)
/// 
/// Отображает карту с территориями и событиями.
/// Реализует:
/// - Стартовая позиция: GPS координаты пользователя (fallback: СПб)
/// - Территории: круги с цветами статусов
/// - События: маркеры на карте
/// - Фильтры: минимум (сегодня/неделя, мой клуб, активные территории)
/// - Кнопка "Моё местоположение"
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  YandexMapController? _mapController;
  MapDataModel? _mapData;
  MapFilters _filters = MapFilters();
  bool _showFilters = false;
  bool _isMapReady = false;
  CityModel? _currentCity;
  
  // Дефолтные координаты СПб (fallback)
  static const double _defaultLongitude = 30.3351;
  static const double _defaultLatitude = 59.9343;
  static const double _defaultZoom = 12.0;
  
  // Радиус территории в метрах
  static const double _territoryRadiusMeters = 500.0;
  static const double _minZoom = 9.0;
  static const double _maxZoom = 19.0;
  bool _isAdjustingCamera = false;
  
  // Объекты на карте
  List<CircleMapObject> _territoryCircles = [];

  @override
  void initState() {
    super.initState();
    _ensureCityAndLoad();
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
        dateFilter: _filters.dateFilter,
        clubId: _filters.clubId,
        onlyActive: _filters.onlyActive,
      );

      if (mounted) {
        setState(() {
          _mapData = data;
        });
        if (_isMapReady) {
          _updateMapObjects();
          await _centerMapOnStartPosition();
        }
      }
    } on ApiException catch (e) {
      if (e.code == 'unauthorized' && mounted) {
        // Try refreshing the token once and retry
        try {
          await ServiceLocator.refreshAuthToken();
          final retryData = await ServiceLocator.mapService.getMapData(
            cityId: cityId,
            dateFilter: _filters.dateFilter,
            clubId: _filters.clubId,
            onlyActive: _filters.onlyActive,
          );
          if (mounted) {
            setState(() {
              _mapData = retryData;
            });
            if (_isMapReady) {
              _updateMapObjects();
              await _centerMapOnStartPosition();
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
      _updateTerritoryCircles();
    } catch (e) {
      debugPrint('Error updating map objects: $e');
      DevRemoteLogger.logError(
        'Error updating map objects',
        error: e,
      );
    }
  }
  
  /// Обновляет круги территорий
  void _updateTerritoryCircles() {
    if (_mapData == null) return;
    
    final circles = _mapData!.territories.asMap().entries.map((entry) {
      final index = entry.key;
      final territory = entry.value;
      final color = _getTerritoryColor(territory.status);
      final strokeColor = _getTerritoryStrokeColor(territory.status);
      
      return CircleMapObject(
        mapId: MapObjectId('territory_$index'),
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
        onTap: (mapObject, point) {
          _showTerritoryBottomSheet(territory);
        },
      );
    }).toList();
    
    setState(() {
      _territoryCircles = circles;
    });
  }

  void _handleCameraPositionChanged(CameraPosition position) {
    if (_isAdjustingCamera || _mapController == null || _currentCity == null) {
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
      // Всегда центрируем по городу/СПб при открытии, чтобы не показывать вид с экватора
      await _centerMapOnStartPosition();
      if (_mapData != null) {
        _updateMapObjects();
      }
    }
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
                onCameraPositionChanged: (position, _reason, _finished) {
                  _handleCameraPositionChanged(position);
                },
                mapObjects: _territoryCircles,
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
                    IconButton(
                      icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      tooltip: AppLocalizations.of(context)!.mapFiltersTooltip,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Панель фильтров
          if (_showFilters)
            Positioned(
              top: 80,
              right: 16,
              child: MapFiltersPanel(
                initialFilters: _filters,
                onFiltersChanged: (filters) {
                  setState(() {
                    _filters = filters;
                  });
                  _loadMapData();
                },
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
