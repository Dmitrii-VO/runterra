import 'dart:async';
import 'dart:io' show Platform;
import 'package:geolocator/geolocator.dart';

/// Сервис для работы с GPS / Location
///
/// Предоставляет функционал для работы с геолокацией:
/// - проверка разрешений
/// - запрос разрешений
/// - получение текущей позиции
/// - continuous tracking для записи пробежек (foreground или background)
///
/// При [startTracking] с [background: true] на Android используется
/// foreground service geolocator_android (AndroidSettings.foregroundNotificationConfig)
/// с постоянным уведомлением, чтобы GPS-трекинг продолжался при сворачивании приложения.
/// Вычисление расстояний и сохранение данных — не входят в обязанности сервиса.
class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _positionController = StreamController<Position>.broadcast();

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

    LocationSettings locationSettings;

    if (background && Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Runterra',
          notificationText: 'Run in progress',
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          setOngoing: true,
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      );
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        _positionController.add(position);
      },
      onError: (error) {
        _positionController.addError(error);
      },
    );
  }

  /// Останавливает continuous GPS tracking
  ///
  /// Отменяет подписку на поток позиций.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
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
