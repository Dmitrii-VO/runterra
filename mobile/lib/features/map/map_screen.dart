import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../shared/di/service_locator.dart';
import '../../main.dart' show DevRemoteLogger;
import '../../shared/models/map_data_model.dart';
import '../../shared/models/territory_map_model.dart';
import '../../shared/models/event_list_item_model.dart';
import 'widgets/territory_bottom_sheet.dart';
import 'widgets/event_card.dart';
import 'widgets/my_location_button.dart';
import 'widgets/map_filters.dart';

/// Класс-обработчик тапов на территории
/// 
/// Реализует OnCircleAnnotationClickListener для обработки тапов на CircleAnnotation
class _TerritoryTapListenerImpl extends OnCircleAnnotationClickListener {
  final void Function(CircleAnnotation) onTap;
  
  _TerritoryTapListenerImpl(this.onTap);
  
  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    onTap(annotation);
  }
}

/// Экран карты (MVP)
/// 
/// Отображает карту с территориями и событиями.
/// Реализует согласно 123.md:
/// - Стартовая позиция: GPS координаты пользователя (fallback: СПб)
/// - Территории: полигоны-круги с цветами статусов
/// - События: маркеры на карте
/// - Фильтры: минимум (сегодня/неделя, мой клуб, активные территории)
/// - Персонализация: подсветка территорий/событий пользователя
/// - Кнопка "Моё местоположение"
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  MapDataModel? _mapData;
  bool _isLoading = true;
  String? _error;
  MapFilters _filters = MapFilters();
  bool _showFilters = false;
  bool _isMapReady = false; // Flag to synchronize map creation and data loading
  
  // Дефолтные координаты СПб (fallback)
  static const double _defaultLongitude = 30.3351;
  static const double _defaultLatitude = 59.9343;
  static const double _defaultZoom = 12.0;
  
  // Радиус территории в метрах (константа для MVP)
  static const double _territoryRadiusMeters = 500.0;
  
  // Менеджеры аннотаций
  CircleAnnotationManager? _territoriesAnnotationManager;
  
  // Списки аннотаций для управления
  List<CircleAnnotation> _territoryAnnotations = [];

  // Текущее значение zoom для пересчета радиуса в пикселях
  double? _lastZoom;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  /// Инициализация карты
  /// 
  /// 1. Получает GPS координаты пользователя (или использует fallback)
  /// 2. Загружает данные карты через shared MapService
  Future<void> _initializeMap() async {
    try {
      final locationService = ServiceLocator.locationService;

      // Получаем стартовую позицию (GPS или fallback)
      // Координаты будут использованы в _centerMapOnStartPosition после загрузки данных
      try {
        // Проверяем разрешения (для будущего использования)
        var permission = await locationService.checkPermission();
        if (permission == geo.LocationPermission.denied) {
          permission = await locationService.requestPermission();
        }
        
        // Handle permission denial
        if (permission == geo.LocationPermission.denied ||
            permission == geo.LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Доступ к геолокации не предоставлен. Карта будет показана с дефолтной позицией.',
                ),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      } catch (e) {
        // Log error but continue with default position
        debugPrint('Could not check GPS permission: $e');
        DevRemoteLogger.logError(
          'GPS permission check during map initialization failed',
          error: e,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка проверки разрешений GPS: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Загружаем данные карты
      await _loadMapData();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
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
        });
        // Update annotations only if map is ready
        if (_isMapReady) {
          _updateMapAnnotations();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }
  
  /// Обновляет аннотации на карте (территории и события)
  Future<void> _updateMapAnnotations() async {
    if (_mapboxMap == null || _mapData == null) return;
    
    try {
      // Обновляем аннотации территорий
      await _updateTerritoriesAnnotations();
      
      // Обновляем аннотации маркеров событий
      await _updateEventsAnnotations();
    } catch (e) {
      debugPrint('Error updating map annotations: $e');
      DevRemoteLogger.logError(
        'Error updating map annotations',
        error: e,
      );
    }
  }
  
  /// Обновляет аннотации территорий (CircleAnnotation)
  Future<void> _updateTerritoriesAnnotations() async {
    if (_territoriesAnnotationManager == null || _mapData == null || _mapboxMap == null) return;
    
    try {
      // Получаем текущий zoom камеры для пересчета радиуса в пикселях
      final cameraState = await _mapboxMap!.getCameraState();
      final zoom = cameraState.zoom;
      _lastZoom = zoom;

      // Удаляем старые аннотации
      if (_territoryAnnotations.isNotEmpty) {
        for (final annotation in _territoryAnnotations) {
          await _territoriesAnnotationManager!.delete(annotation);
        }
        _territoryAnnotations.clear();
      }
      
      // Создаем новые аннотации для каждой территории
      final annotations = _mapData!.territories.map((territory) {
        final color = _getTerritoryAnnotationColor(territory.status);
        final strokeColor = _getTerritoryAnnotationStrokeColor(territory.status);
        final radiusPixels = _computeTerritoryRadiusPixels(
          territory.coordinates.latitude,
          zoom,
        );
        
        // Mapbox expects ARGB int format (0xAARRGGBB)
        // Color.value already returns ARGB, but we ensure proper format
        final colorValue = color.value;
        final strokeColorValue = strokeColor.value;
        
        return CircleAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              territory.coordinates.longitude,
              territory.coordinates.latitude,
            ),
          ),
          circleRadius: radiusPixels,
          circleColor: colorValue,
          circleStrokeColor: strokeColorValue,
          circleStrokeWidth: 2.0,
        );
      }).toList();
      
      // Добавляем аннотации на карту
      // Создаем аннотации по одной (createMulti может не существовать)
      _territoryAnnotations = [];
      for (final annotationOptions in annotations) {
        final annotation = await _territoriesAnnotationManager!.create(annotationOptions);
        _territoryAnnotations.add(annotation);
      }
    } catch (e) {
      debugPrint('Error updating territories annotations: $e');
      DevRemoteLogger.logError(
        'Error updating territories annotations',
        error: e,
      );
    }
  }

  /// Конвертирует радиус территории в метрах в радиус в пикселях
  /// для текущего уровня зума и широты.
  double _computeTerritoryRadiusPixels(double latitude, double zoom) {
    // Формула основана на WebMercator: метров на пиксель = cos(lat) * C / (256 * 2^zoom),
    // где C — длина экватора Земли.
    const double earthCircumferenceMeters = 40075016.686; // приблизительно
    final latRad = latitude * math.pi / 180.0;
    final metersPerPixel =
        (earthCircumferenceMeters * math.cos(latRad)) / (256 * math.pow(2.0, zoom));

    if (metersPerPixel <= 0) {
      // Fallback: используем приближение на дефолтном зуме
      final fallbackMetersPerPixel =
          (earthCircumferenceMeters * math.cos(_defaultLatitude * math.pi / 180.0)) /
              (256 * math.pow(2.0, _defaultZoom));
      return _territoryRadiusMeters / fallbackMetersPerPixel;
    }

    return _territoryRadiusMeters / metersPerPixel;
  }
  
  /// Обновляет аннотации маркеров событий (используем PointAnnotation как упрощение)
  Future<void> _updateEventsAnnotations() async {
    // TODO: Реализовать маркеры событий через PointAnnotation или другой способ
    // Для MVP пока пропускаем, так как SymbolAnnotation требует дополнительной настройки
    debugPrint('Events annotations: ${_mapData?.events.length} events');
  }
  
  /// Получает цвет аннотации территории по статусу
  Color _getTerritoryAnnotationColor(String status) {
    switch (status) {
      case 'captured':
        return const Color.fromRGBO(33, 150, 243, 0.3); // 🟦 Colors.blue
      case 'free':
        return const Color.fromRGBO(158, 158, 158, 0.2); // ⚪ Colors.grey
      case 'contested':
        return const Color.fromRGBO(255, 235, 59, 0.3); // 🟨 Colors.yellow
      case 'locked':
        return const Color.fromRGBO(66, 66, 66, 0.3); // Colors.grey.shade800
      default:
        return const Color.fromRGBO(158, 158, 158, 0.2); // Colors.grey
    }
  }
  
  /// Получает цвет границы аннотации территории по статусу
  Color _getTerritoryAnnotationStrokeColor(String status) {
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
  
  /// Обработчик тапа на территорию
  void _onTerritoryTap(CircleAnnotation annotation) {
    if (_mapData == null) return;
    
    // Находим территорию по индексу аннотации
    // Для MVP используем упрощенный подход: находим по индексу в списке
    try {
      final index = _territoryAnnotations.indexOf(annotation);
      if (index >= 0 && index < _mapData!.territories.length) {
        final territory = _mapData!.territories[index];
        _showTerritoryBottomSheet(territory);
      } else {
        // Error: annotation not found in list
        debugPrint('Territory annotation not found in list');
        DevRemoteLogger.logError(
          'Territory annotation not found in list',
          error: Exception('Annotation index out of bounds'),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка: не удалось найти территорию'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error finding territory: $e');
      DevRemoteLogger.logError(
        'Error finding territory on tap',
        error: e,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при обработке тапа на территорию: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  /// Показывает bottom sheet для территории
  void _showTerritoryBottomSheet(TerritoryMapModel territory) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TerritoryBottomSheet(territory: territory),
    );
  }
  

  /// Обработчик создания карты (callback от MapWidget)
  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    // Инициализируем текущее значение zoom
    try {
      final cameraState = await _mapboxMap!.getCameraState();
      _lastZoom = cameraState.zoom;
    } catch (_) {
      _lastZoom = _defaultZoom;
    }

    // Создаем менеджер аннотаций для территорий
    _territoriesAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    
    // Добавляем обработчик тапов на аннотации территорий
    // Создаем класс-обработчик, который реализует OnCircleAnnotationClickListener
    _territoriesAnnotationManager?.addOnCircleAnnotationClickListener(
      _TerritoryTapListenerImpl(_onTerritoryTap),
    );
    
    // Mark map as ready
    if (mounted) {
      setState(() {
        _isMapReady = true;
      });
      
      // Apply data if already loaded, otherwise wait for _loadMapData
      if (_mapData != null) {
        _centerMapOnStartPosition();
        _updateMapAnnotations();
      }
    }
  }
  

  /// Центрирует карту на стартовой позиции
  Future<void> _centerMapOnStartPosition() async {
    if (_mapboxMap == null) return;

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

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(longitude, latitude),
        ),
        zoom: _defaultZoom,
      ),
      MapAnimationOptions(duration: 500, startDelay: 0),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Загрузка карты...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки карты',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initializeMap();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Карта
          MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(_defaultLongitude, _defaultLatitude),
              ),
              zoom: _defaultZoom,
            ),
            onMapCreated: _onMapCreated,
            onCameraChangeListener: _onCameraChanged,
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
          if (_mapboxMap != null)
            Positioned(
              bottom: 220,
              right: 16,
              child: MyLocationButton(
                mapboxMap: _mapboxMap,
                locationService: ServiceLocator.locationService,
              ),
            ),

        ],
      ),
    );
  }

  /// Обработчик изменения параметров камеры.
  /// 
  /// Используем для динамического пересчета радиуса территорий в пикселях
  /// при изменении уровня зума.
  void _onCameraChanged(CameraChangedEventData data) {
    if (_mapboxMap == null ||
        _mapData == null ||
        _territoriesAnnotationManager == null) {
      return;
    }

    final zoom = data.cameraState.zoom;
    // Обновляем аннотации только при заметном изменении зума,
    // чтобы не перегружать перерисовку.
    if (_lastZoom != null && (zoom - _lastZoom!).abs() < 0.1) {
      return;
    }

    _lastZoom = zoom;
    // Пересчитываем радиус кругов для текущего зума.
    _updateTerritoriesAnnotations();
  }
}
