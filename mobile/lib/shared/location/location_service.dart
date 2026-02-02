import 'dart:async';
import 'package:background_location/background_location.dart' as bg;
import 'package:geolocator/geolocator.dart';

/// Сервис для работы с GPS / Location
///
/// Предоставляет функционал для работы с геолокацией:
/// - проверка разрешений
/// - запрос разрешений
/// - получение текущей позиции
/// - continuous tracking для записи пробежек (foreground или background)
///
/// При [startTracking] с [background: true] используется пакет background_location
/// (Android: foreground service с уведомлением; iOS: при добавлении платформы — UIBackgroundModes location).
/// Вычисление расстояний и сохранение данных — не входят в обязанности сервиса.
class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  bool _isBackgroundTracking = false;

  /// Проверяет текущий статус разрешения на доступ к геолокации
  ///
  /// Возвращает [LocationPermission] - статус разрешения:
  /// - denied - разрешение не предоставлено
  /// - deniedForever - разрешение отклонено навсегда
  /// - whileInUse - разрешение предоставлено только во время использования приложения
  /// - always - разрешение предоставлено всегда (включая фон)
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Запрашивает разрешение на доступ к геолокации
  ///
  /// Возвращает [LocationPermission] - результат запроса разрешения
  /// Если разрешение уже предоставлено, возвращает текущий статус без показа диалога
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Получает текущую позицию устройства
  ///
  /// Возвращает [Position] - объект с координатами (latitude, longitude) и другой информацией
  ///
  /// Может выбросить исключение, если:
  /// - разрешение не предоставлено
  /// - GPS недоступен
  /// - не удалось получить позицию
  ///
  /// TODO: добавить обработку ошибок
  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Проверяет, включена ли служба геолокации
  ///
  /// Возвращает true, если служба геолокации включена, false в противном случае
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Converts background_location [Location] to geolocator [Position] for API consistency.
  ///
  /// Note: background_location returns [Location.time] in milliseconds on Android
  /// (android.location.Location.getTime()) but in seconds on iOS
  /// (NSDate.timeIntervalSince1970). Currently only Android is supported.
  Position _locationToPosition(bg.Location location) {
    final timeMs = location.time ?? 0.0;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(timeMs.round());
    return Position(
      longitude: location.longitude ?? 0.0,
      latitude: location.latitude ?? 0.0,
      timestamp: timestamp,
      accuracy: location.accuracy ?? 0.0,
      altitude: location.altitude ?? 0.0,
      altitudeAccuracy: 0.0,
      heading: location.bearing ?? 0.0,
      headingAccuracy: 0.0,
      speed: location.speed ?? 0.0,
      speedAccuracy: 0.0,
      isMocked: location.isMock ?? false,
    );
  }

  /// Начинает continuous GPS tracking
  ///
  /// Запускает поток позиций через [positionStream].
  /// Требует разрешения на доступ к геолокации.
  ///
  /// [distanceFilter] - минимальное расстояние в метрах для обновления позиции (по умолчанию 5 метров)
  /// [background] - при true трекинг продолжается в фоне (Android: foreground service с уведомлением)
  ///
  /// Бросает исключение, если:
  /// - разрешение не предоставлено
  /// - служба геолокации отключена
  Future<void> startTracking({int distanceFilter = 5, bool background = false}) async {
    final isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      throw Exception('Location service is disabled. Please enable location services in your device settings.');
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied. Please grant location permission to use this feature.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied. Please enable location permission in your device settings.');
    }
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      throw Exception('Location permission not granted. Current status: $permission');
    }

    if (background) {
      await bg.BackgroundLocation.stopLocationService();
      await bg.BackgroundLocation.setAndroidNotification(
        title: 'Runterra',
        message: 'Run in progress',
        icon: '@mipmap/ic_launcher',
      );
      bg.BackgroundLocation.getLocationUpdates((bg.Location location) {
        _positionController.add(_locationToPosition(location));
      });
      await bg.BackgroundLocation.startLocationService(distanceFilter: distanceFilter.toDouble());
      _isBackgroundTracking = true;
      return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).listen(
      (position) {
        _positionController.add(position);
      },
      onError: (error) {
        _positionController.addError(error);
      },
    );
    _isBackgroundTracking = false;
  }

  /// Останавливает continuous GPS tracking
  ///
  /// Отменяет подписку на поток позиций или останавливает фоновый сервис.
  void stopTracking() {
    if (_isBackgroundTracking) {
      bg.BackgroundLocation.stopLocationService();
      _isBackgroundTracking = false;
    } else {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    }
  }

  /// Stream позиций GPS в реальном времени
  ///
  /// Используется для получения обновлений позиции во время трекинга.
  /// Слушатели должны подписаться на этот stream после вызова [startTracking()].
  Stream<Position> get positionStream => _positionController.stream;

  /// Освобождает ресурсы
  ///
  /// Должен быть вызван при уничтожении сервиса.
  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
