import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/event_list_item_model.dart';
import '../models/event_details_model.dart';
import '../models/event_participant_model.dart';
import '../models/event_start_location.dart';

/// Сервис для работы с событиями
/// 
/// Предоставляет методы для выполнения запросов к API событий.
/// Использует ApiClient для выполнения HTTP запросов.
class EventsService {
  final ApiClient _apiClient;

  /// Создает EventsService с указанным ApiClient
  EventsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET /api/events запрос к backend
  /// 
  /// Возвращает список событий (List<EventListItemModel>).
  /// Парсит JSON ответ и преобразует его в типизированные модели.
  /// 
  /// [filters] - параметры фильтрации, отправляются как query параметры
  Future<List<EventListItemModel>> getEvents({
    required String cityId,
    String? dateFilter,
    String? clubId,
    String? difficultyLevel,
    String? eventType,
    bool? onlyOpen,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{'cityId': cityId};
    if (dateFilter != null) queryParams['dateFilter'] = dateFilter;
    if (clubId != null) queryParams['clubId'] = clubId;
    if (difficultyLevel != null) queryParams['difficultyLevel'] = difficultyLevel;
    if (eventType != null) queryParams['eventType'] = eventType;
    if (onlyOpen == true) queryParams['onlyOpen'] = 'true';
    
    final endpoint = queryParams.isEmpty 
        ? '/api/events'
        : '/api/events?${Uri(queryParameters: queryParams).query}';
    final response = await _apiClient.get(endpoint);
    
    // Проверяем, что ответ - JSON, а не HTML
    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка сервера: ${response.statusCode}\n'
        'Убедитесь, что backend сервер запущен (npm run dev в папке backend)',
      );
    }
    
    // Проверяем Content-Type
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      // Если получен HTML, значит backend не запущен или роутер не работает
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.\n\n'
          'Убедитесь, что:\n'
          '1. Backend сервер запущен: cd backend && npm run dev\n'
          '2. Сервер слушает на порту 3000\n'
          '3. Роутер /api/events подключен в backend/src/api/index.ts\n'
          '4. Для Android эмулятора используется адрес http://10.0.2.2:3000',
          response.body.substring(0, response.body.length > 200 ? 200 : response.body.length),
        );
      }
      throw FormatException(
        'Ожидался JSON, но получен $contentType\n'
        'Проверьте, что backend сервер запущен и роутер /api/events работает.',
        response.body.substring(0, response.body.length > 100 ? 100 : response.body.length),
      );
    }
    
    try {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((json) => EventListItemModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (e is FormatException && response.body.trim().startsWith('<!DOCTYPE')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.\n\n'
          'Убедитесь, что:\n'
          '1. Backend сервер запущен: cd backend && npm run dev\n'
          '2. Сервер слушает на порту 3000\n'
          '3. Роутер /api/events подключен в backend/src/api/index.ts',
          response.body.substring(0, 200),
        );
      }
      rethrow;
    }
  }

  /// Выполняет GET /api/events/:id запрос к backend
  /// 
  /// Возвращает событие по указанному id (EventDetailsModel).
  /// Парсит JSON ответ и преобразует его в типизированную модель.
  /// 
  /// [id] - уникальный идентификатор события
  /// 
  /// TODO: Добавить обработку ошибок HTTP запросов
  Future<EventDetailsModel> getEventById(String id) async {
    final response = await _apiClient.get('/api/events/$id');
    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return EventDetailsModel.fromJson(jsonData);
  }

  /// Выполняет GET /api/events/:id/participants запрос к backend
  ///
  /// Возвращает список участников события.
  Future<List<EventParticipantModel>> getEventParticipants(String eventId) async {
    final response = await _apiClient.get('/api/events/$eventId/participants');
    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка сервера: ${response.statusCode}\n'
        'Убедитесь, что backend сервер запущен (npm run dev в папке backend)',
      );
    }
    final jsonData = jsonDecode(response.body) as List<dynamic>;
    return jsonData
        .map((json) => EventParticipantModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Выполняет POST /api/events запрос к backend
  /// 
  /// Создает новое событие.
  Future<EventDetailsModel> createEvent({
    required String name,
    required String type,
    required DateTime startDateTime,
    required EventStartLocation startLocation,
    String? locationName,
    required String organizerId,
    required String organizerType,
    required String cityId,
    String? difficultyLevel,
    String? description,
    int? participantLimit,
    String? territoryId,
  }) async {
    final response = await _apiClient.post(
      '/api/events',
      body: {
        'name': name,
        'type': type,
        'startDateTime': startDateTime.toIso8601String(),
        'startLocation': startLocation.toJson(),
        if (locationName != null) 'locationName': locationName,
        'organizerId': organizerId,
        'organizerType': organizerType,
        if (difficultyLevel != null) 'difficultyLevel': difficultyLevel,
        if (description != null) 'description': description,
        if (participantLimit != null) 'participantLimit': participantLimit,
        if (territoryId != null) 'territoryId': territoryId,
        'cityId': cityId,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _throwApiException(response, 'create_event_error');
    }
    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    return EventDetailsModel.fromJson(jsonData);
  }

  /// Выполняет POST /api/events/:id/join запрос к backend.
  ///
  /// Записывает текущего пользователя на событие (userId из auth).
  /// Бросает [ApiException] при 4xx/5xx с code и message из ответа ADR-0002.
  Future<void> joinEvent(String eventId) async {
    final response = await _apiClient.post('/api/events/$eventId/join');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'join_event_error');
  }

  /// Выполняет POST /api/events/:id/check-in запрос к backend.
  ///
  /// Check-in на событие с координатами (backend проверяет радиус и окно времени).
  /// Бросает [ApiException] при 4xx/5xx с code и message из ответа ADR-0002.
  Future<void> checkInEvent(
    String eventId, {
    required double longitude,
    required double latitude,
  }) async {
    final response = await _apiClient.post(
      '/api/events/$eventId/check-in',
      body: {'longitude': longitude, 'latitude': latitude},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'check_in_error');
  }

  void _throwApiException(dynamic response, String fallbackCode) {
    String errorCode = fallbackCode;
    String errorMessage = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded != null) {
        errorCode = (decoded['code'] as String?) ?? errorCode;
        errorMessage = (decoded['message'] as String?) ?? errorMessage;
      }
    } on FormatException {
      // Non-JSON response
    }
    throw ApiException(errorCode, errorMessage);
  }

  /// Выполняет POST /api/events/:id/leave запрос к backend.
  ///
  /// Отменяет участие в событии. Бросает [ApiException] при ошибках.
  Future<void> leaveEvent(String eventId) async {
    final response = await _apiClient.post('/api/events/$eventId/leave');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _throwApiException(response, 'leave_event_error');
  }
}
