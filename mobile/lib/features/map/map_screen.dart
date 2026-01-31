import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../shared/di/service_locator.dart';
import '../../main.dart' show DevRemoteLogger;
import '../../shared/models/map_data_model.dart';
import '../../shared/models/territory_map_model.dart';
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
  String? _dataError; // Error loading data, but map still shows
  MapFilters _filters = MapFilters();
  bool _showFilters = false;
  bool _isMapReady = false;
  
  // Дефолтные координаты СПб (fallback)
  static const double _defaultLongitude = 30.3351;
  static const double _defaultLatitude = 59.9343;
  static const double _defaultZoom = 12.0;
  
  // Радиус территории в метрах
  static const double _territoryRadiusMeters = 500.0;
  
  // Объекты на карте
  List<CircleMapObject> _territoryCircles = [];

  @override
  void initState() {
    super.initState();
    // Load data in background, don't block map display
    _loadMapDataInBackground();
  }

  /// Загружает данные карты в фоне (не блокирует показ карты)
  Future<void> _loadMapDataInBackground() async {
    // Check GPS permission (non-blocking, just for snackbar notification)
    _checkGpsPermission();
    
    // Load map data
    await _loadMapData();
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
            const SnackBar(
              content: Text(
                'Доступ к геолокации не предоставлен. Используется позиция по умолчанию.',
              ),
              duration: Duration(seconds: 3),
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
    try {
      final data = await ServiceLocator.mapService.getMapData(
        dateFilter: _filters.dateFilter,
        clubId: _filters.clubId,
        onlyActive: _filters.onlyActive,
      );

      if (mounted) {
        setState(() {
          _mapData = data;
          _dataError = null;
        });
        if (_isMapReady) {
          _updateMapObjects();
        }
      }
    } catch (e) {
      debugPrint('Error loading map data: $e');
      DevRemoteLogger.logError('Error loading map data', error: e);
      if (mounted) {
        setState(() {
          _dataError = e.toString();
        });
        // Show snackbar but don't block map
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки данных: $e'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Повторить',
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
    _mapController = controller;
    
    if (mounted) {
      setState(() {
        _isMapReady = true;
      });
      
      if (_mapData != null) {
        await _centerMapOnStartPosition();
        _updateMapObjects();
      }
    }
  }

  /// Центрирует карту на стартовой позиции
  Future<void> _centerMapOnStartPosition() async {
    if (_mapController == null) return;

    double longitude = _defaultLongitude;
    double latitude = _defaultLatitude;

    // Используем координаты из загруженных данных или GPS
    if (_mapData != null && _mapData!.viewport.center.longitude != 0) {
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
            const SnackBar(
              content: Text('Нет доступа к геолокации'),
              duration: Duration(seconds: 2),
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
            content: Text('Ошибка геолокации: $e'),
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
          YandexMap(
            onMapCreated: _onMapCreated,
            mapObjects: _territoryCircles,
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
                        'Карта',
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
                      tooltip: 'Фильтры',
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
                tooltip: 'Моё местоположение',
                child: const Icon(Icons.my_location),
              ),
            ),

        ],
      ),
    );
  }
}
