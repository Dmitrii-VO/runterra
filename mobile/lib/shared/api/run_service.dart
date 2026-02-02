import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../location/location_service.dart';
import '../models/run_model.dart';
import '../models/run_session.dart';
import 'api_client.dart';

/// Сервис для работы с пробежками
///
/// Предоставляет методы для сценария: начать → трекинг → завершить → отправить.
/// Управляет GPS-трекингом и отправкой данных на backend.
class RunService {
  late LocationService _locationService;
  final bool _ownLocationService;
  final ApiClient _apiClient;

  RunSession? _currentSession;
  StreamSubscription<Position>? _positionSubscription;
  final List<Position> _gpsPoints = [];
  DateTime? _startTime;

  RunService({
    LocationService? locationService,
    ApiClient? apiClient,
  })  : _ownLocationService = locationService == null,
        _apiClient = apiClient ?? ApiClient.getInstance(baseUrl: ApiConfig.getBaseUrl()) {
    _locationService = locationService ?? LocationService();
  }

  /// Начать пробежку.
  ///
  /// [activityId] — опциональный ID тренировки для привязки пробежки.
  /// 
  /// Выполняет:
  /// - проверку разрешений на геолокацию
  /// - запрос разрешений, если необходимо
  /// - старт GPS-трекинга
  /// - создание сессии пробежки
  /// 
  /// Бросает исключение, если:
  /// - служба геолокации отключена
  /// - разрешение на геолокацию отклонено
  Future<RunSession> startRun({String? activityId}) async {
    if (_currentSession != null) {
      throw Exception('Run already started');
    }

    _startTime = DateTime.now();
    _gpsPoints.clear();

    // Start GPS tracking (background so run continues when app is in background)
    await _locationService.startTracking(distanceFilter: 5, background: true);

    // Listen to position updates
    _positionSubscription = _locationService.positionStream.listen(
      (position) {
        _gpsPoints.add(position);
      },
      onError: (error) {
        // Handle GPS errors (will be reflected in gpsStatus)
      },
    );

    // Create session
    _currentSession = RunSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityId: activityId,
      startedAt: _startTime!,
      status: RunSessionStatus.running,
      gpsStatus: GpsStatus.searching,
      gpsPoints: List.from(_gpsPoints), // Copy list to maintain immutability
    );

    return _currentSession!;
  }

  /// Обновляет статус GPS в текущей сессии
  /// 
  /// Вызывается из RunScreen при получении первой валидной GPS точки.
  void updateGpsStatus(GpsStatus status) {
    if (_currentSession != null) {
      _currentSession = RunSession(
        id: _currentSession!.id,
        activityId: _currentSession!.activityId,
        startedAt: _currentSession!.startedAt,
        status: _currentSession!.status,
        duration: _currentSession!.duration,
        distance: _currentSession!.distance,
        gpsStatus: status,
        gpsPoints: List.from(_currentSession!.gpsPoints), // Copy list to maintain immutability
      );
    }
  }

  /// Обновляет длительность и расстояние в текущей сессии
  /// 
  /// Вызывается из RunScreen для обновления UI.
  void updateSessionMetrics({
    Duration? duration,
    double? distance,
  }) {
    if (_currentSession != null) {
      _currentSession = RunSession(
        id: _currentSession!.id,
        activityId: _currentSession!.activityId,
        startedAt: _currentSession!.startedAt,
        status: _currentSession!.status,
        duration: duration ?? _currentSession!.duration,
        distance: distance ?? _currentSession!.distance,
        gpsStatus: _currentSession!.gpsStatus,
        gpsPoints: List.from(_currentSession!.gpsPoints), // Copy list to maintain immutability
      );
    }
  }

  /// Получить текущую сессию
  RunSession? get currentSession => _currentSession;

  /// Завершить трекинг.
  ///
  /// Останавливает GPS-трекинг и подготавливает данные для отправки.
  /// Возвращает финальную сессию с обновлёнными данными.
  Future<RunSession> stopRun() async {
    if (_currentSession == null) {
      throw Exception('No active run session');
    }

    // Stop GPS tracking
    _locationService.stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;

    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime!);

    // TODO: Calculate real distance from GPS points
    // For now, use a placeholder calculation
    double distance = 0.0;
    if (_gpsPoints.length > 1) {
      for (int i = 1; i < _gpsPoints.length; i++) {
        distance += Geolocator.distanceBetween(
          _gpsPoints[i - 1].latitude,
          _gpsPoints[i - 1].longitude,
          _gpsPoints[i].latitude,
          _gpsPoints[i].longitude,
        );
      }
    }

    // Update session with final data
    _currentSession = RunSession(
      id: _currentSession!.id,
      activityId: _currentSession!.activityId,
      startedAt: _currentSession!.startedAt,
      status: RunSessionStatus.completed,
      duration: duration,
      distance: distance,
      gpsStatus: _currentSession!.gpsStatus,
      gpsPoints: List.from(_gpsPoints),
    );

    return _currentSession!;
  }

  /// Отправить данные пробежки на backend.
  ///
  /// Вызывает API POST /api/runs для сохранения пробежки.
  /// Требует, чтобы сессия была завершена (stopRun вызван).
  /// 
  /// Бросает исключение, если:
  /// - сессия не завершена
  /// - запрос к API не удался
  Future<void> submitRun() async {
    if (_currentSession == null) {
      throw Exception('No run session to submit');
    }

    if (_currentSession!.status != RunSessionStatus.completed) {
      throw Exception('Run session is not completed');
    }

    final session = _currentSession!;
    final endTime = session.startedAt.add(session.duration);

    // Prepare request body
    final requestBody = <String, dynamic>{
      'startedAt': session.startedAt.toUtc().toIso8601String(),
      'endedAt': endTime.toUtc().toIso8601String(),
      'duration': session.duration.inSeconds,
      'distance': session.distance,
      'gpsPoints': session.gpsPoints.map((p) => <String, dynamic>{
          'lat': p.latitude,
          'lon': p.longitude,
          'timestamp': p.timestamp.toUtc().toIso8601String(),
        }).toList(),
    };
    // Only include activityId if not null
    if (session.activityId != null) {
      requestBody['activityId'] = session.activityId;
    }

    // Send to backend
    final response = await _apiClient.post(
      '/api/runs',
      body: requestBody,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Failed to submit run: ${response.statusCode} ${response.body}',
      );
    }

    // Parse response as RunViewDto (RunModel) for consistency with backend contract
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        if (decoded != null) {
          RunModel.fromJson(decoded);
        }
      } on FormatException {
        // Ignore parse errors; submission succeeded
      }
    }

    // Clear session after successful submission
    _currentSession = null;
    _gpsPoints.clear();
    _startTime = null;
  }

  /// Отменить текущую пробежку без отправки на backend
  ///
  /// Очищает все данные и останавливает трекинг.
  /// Если RunService создан со своим LocationService (не инжектирован),
  /// освобождает его и создаёт новый для следующего startRun().
  void cancelRun() {
    _locationService.stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentSession = null;
    _gpsPoints.clear();
    _startTime = null;
    if (_ownLocationService) {
      _locationService.dispose();
      _locationService = LocationService();
    }
  }

  /// Освобождает ресурсы собственного LocationService (если был создан внутри).
  /// Вызывать при уничтожении RunService, если он не из ServiceLocator.
  void dispose() {
    if (_ownLocationService) {
      _locationService.stopTracking();
      _locationService.dispose();
    }
  }

  /// Stream позиций GPS для подписки извне
  /// 
  /// Используется для обновления UI при получении новых GPS точек.
  Stream<Position> get gpsPositionStream => _locationService.positionStream;
}
