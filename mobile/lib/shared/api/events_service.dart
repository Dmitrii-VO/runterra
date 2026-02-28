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
    bool? participantOnly,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{'cityId': cityId};
    if (dateFilter != null) queryParams['dateFilter'] = dateFilter;
    if (clubId != null) queryParams['clubId'] = clubId;
    if (difficultyLevel != null) queryParams['difficultyLevel'] = difficultyLevel;
    if (eventType != null) queryParams['eventType'] = eventType;
    if (onlyOpen == true) queryParams['onlyOpen'] = 'true';
    if (participantOnly == true) queryParams['participantOnly'] = 'true';
    
    final endpoint = queryParams.isEmpty 
        ? '/api/events'
        : '/api/events?${Uri(queryParameters: queryParams).query}';
    final response = await _apiClient.get(endpoint);

    final body = response.body.trim();
    final contentType = response.headers['content-type'] ?? '';

    // Non-2xx: prefer ADR-0002 envelope (code/message) when available.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (contentType.contains('application/json')) {
        _throwApiException(response, 'get_events_error');
      }
      if (body.toLowerCase().startsWith('<!doctype') ||
          body.toLowerCase().startsWith('<html')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.\n\n'
          'Убедитесь, что:\n'
          '1. Backend сервер запущен: cd backend && npm run dev\n'
          '2. Сервер слушает на порту 3000\n'
          '3. Роутер /api/events подключен в backend/src/api/index.ts\n'
          '4. Для Android эмулятора используется адрес http://10.0.2.2:3000',
          body.substring(0, body.length > 200 ? 200 : body.length),
        );
      }
      throw ApiException(
        'HTTP ${response.statusCode}',
        'Ошибка сервера: ${response.statusCode}',
      );
    }

    // Проверяем Content-Type
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
  Future<EventDetailsModel> getEventById(String id) async {
    final response = await _apiClient.get('/api/events/$id');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return EventDetailsModel.fromJson(jsonData);
    }
    _throwApiException(response, 'get_event_error');
  }

  /// Выполняет GET /api/events/:id/participants запрос к backend
  ///
  /// Возвращает список участников события.
  Future<List<EventParticipantModel>> getEventParticipants(String eventId) async {
    final response = await _apiClient.get('/api/events/$eventId/participants');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((json) => EventParticipantModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_event_participants_error');
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
    String? visibility, // 'public' or 'private'
    String? workoutId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'type': type,
      'startDateTime': startDateTime.toUtc().toIso8601String(),
      'startLocation': <String, dynamic>{
        'latitude': startLocation.latitude,
        'longitude': startLocation.longitude,
      },
      'organizerId': organizerId,
      'organizerType': organizerType,
      'cityId': cityId,
    };

    if (locationName != null && locationName.isNotEmpty) {
      body['locationName'] = locationName;
    }
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    if (participantLimit != null) {
      body['participantLimit'] = participantLimit;
    }
    if (difficultyLevel != null) {
      body['difficultyLevel'] = difficultyLevel;
    }
    if (territoryId != null) {
      body['territoryId'] = territoryId;
    }
    if (visibility != null) {
      body['visibility'] = visibility;
    }
    if (workoutId != null) {
      body['workoutId'] = workoutId;
    }

    final response = await _apiClient.post('/api/events', body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Helper defined below in the file
      String errorCode = 'create_event_error';
      String errorMessage = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        if (decoded != null) {
          errorCode = (decoded['code'] as String?) ?? errorCode;
          errorMessage = (decoded['message'] as String?) ?? errorMessage;
          // Propagate specific field-level code (e.g. coordinates_out_of_city)
          final details = decoded['details'] as Map<String, dynamic>?;
          final fields = details?['fields'] as List<dynamic>?;
          if (fields != null && fields.isNotEmpty) {
            final firstField = fields.first as Map<String, dynamic>?;
            final fieldCode = firstField?['code'] as String?;
            if (fieldCode != null) errorCode = fieldCode;
          }
        }
      } on FormatException {
        // Non-JSON response
      }
      throw ApiException(errorCode, errorMessage);
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

  Never _throwApiException(dynamic response, String fallbackCode) {
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

  /// Выполняет PATCH /api/events/:id for general event updates.
  Future<EventDetailsModel> updateEvent(
    String eventId, {
    String? name,
    String? type,
    DateTime? startDateTime,
    EventStartLocation? startLocation,
    String? locationName,
    String? description,
    int? participantLimit,
    bool clearParticipantLimit = false,
    String? difficultyLevel,
    bool clearDifficultyLevel = false,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (type != null) body['type'] = type;
    if (startDateTime != null) body['startDateTime'] = startDateTime.toUtc().toIso8601String();
    if (startLocation != null) body['startLocation'] = startLocation.toJson();
    if (locationName != null) body['locationName'] = locationName;
    if (description != null) body['description'] = description;
    if (participantLimit != null) body['participantLimit'] = participantLimit;
    if (clearParticipantLimit) body['participantLimit'] = null;
    if (difficultyLevel != null) body['difficultyLevel'] = difficultyLevel;
    if (clearDifficultyLevel) body['difficultyLevel'] = null;

    final response = await _apiClient.patch('/api/events/$eventId', body: body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return EventDetailsModel.fromJson(jsonData);
    }
    _throwApiException(response, 'update_event_error');
  }

  /// Выполняет PATCH /api/events/:id для назначения workout/trainer.
  Future<EventDetailsModel> updateEventTrainerFields(
    String eventId, {
    String? workoutId,
    String? trainerId,
  }) async {
    final body = <String, dynamic>{};
    if (workoutId != null) body['workoutId'] = workoutId;
    if (trainerId != null) body['trainerId'] = trainerId;

    final response = await _apiClient.patch('/api/events/$eventId', body: body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return EventDetailsModel.fromJson(jsonData);
    }
    _throwApiException(response, 'update_event_trainer_fields_error');
  }
}
