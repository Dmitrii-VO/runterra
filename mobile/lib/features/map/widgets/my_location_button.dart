import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../shared/location/location_service.dart';
import '../../../main.dart' show DevRemoteLogger;

/// Кнопка "Моё местоположение"
/// 
/// Центрирует карту на GPS координатах пользователя.
/// Использует LocationService для получения текущей позиции.
class MyLocationButton extends StatelessWidget {
  final MapboxMap? mapboxMap;
  final LocationService locationService;

  const MyLocationButton({
    super.key,
    required this.mapboxMap,
    required this.locationService,
  });

  /// Центрирует карту на текущей позиции пользователя
  Future<void> _centerOnMyLocation() async {
    if (mapboxMap == null) return;

    try {
      // Проверяем разрешения
      var permission = await locationService.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await locationService.requestPermission();
      }

      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        // TODO: Показать сообщение об ошибке
        return;
      }

      // Получаем текущую позицию
      final position = await locationService.getCurrentPosition();

      // Центрируем карту
      await mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              position.longitude,
              position.latitude,
            ),
          ),
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1000, startDelay: 0),
      );
    } catch (e) {
      // TODO: Показать сообщение об ошибке
      debugPrint('Error centering on location: $e');
      DevRemoteLogger.logError(
        'Error centering map on user location',
        error: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      onPressed: _centerOnMyLocation,
      tooltip: 'Моё местоположение',
      child: const Icon(Icons.my_location),
    );
  }
}
