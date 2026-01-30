import 'dart:convert';
import 'api_client.dart';
import '../models/event_list_item_model.dart';
import '../models/event_details_model.dart';
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
    String? dateFilter,
    String? clubId,
    String? difficultyLevel,
    String? eventType,
    bool? onlyOpen,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{};
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

  /// Выполняет POST /api/events запрос к backend
  /// 
  /// Создает новое событие.
  /// 
  /// TODO: Реализовать POST метод в ApiClient
  /// TODO: Добавить валидацию данных
  /// TODO: Добавить обработку ошибок HTTP запросов
  Future<EventDetailsModel> createEvent({
    required String name,
    required String type,
    required DateTime startDateTime,
    required EventStartLocation startLocation,
    String? locationName,
    required String organizerId,
    required String organizerType,
    String? difficultyLevel,
    String? description,
    int? participantLimit,
    String? territoryId,
  }) async {
    // TODO: Реализовать POST запрос
    // final response = await _apiClient.post('/api/events', body: {...});
    // final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    // return EventDetailsModel.fromJson(jsonData);
    throw UnimplementedError('createEvent not implemented yet');
  }

  /// Выполняет POST /api/events/:id/join запрос к backend
  /// 
  /// Записывает текущего пользователя на событие.
  /// 
  /// [eventId] - уникальный идентификатор события
  /// 
  /// TODO: Реализовать POST метод в ApiClient
  /// TODO: Получить userId из авторизации
  /// TODO: Добавить обработку ошибок HTTP запросов
  Future<void> joinEvent(String eventId) async {
    // TODO: Реализовать POST запрос
    // final response = await _apiClient.post('/api/events/$eventId/join');
    throw UnimplementedError('joinEvent not implemented yet');
  }

  /// Выполняет POST /api/events/:id/check-in запрос к backend
  /// 
  /// Выполняет check-in на событие через GPS.
  /// 
  /// [eventId] - уникальный идентификатор события
  /// [longitude] - долгота текущей позиции пользователя
  /// [latitude] - широта текущей позиции пользователя
  /// 
  /// TODO: Реализовать POST метод в ApiClient
  /// TODO: Получить координаты из LocationService
  /// TODO: Добавить GPS проверку на backend
  /// TODO: Добавить обработку ошибок HTTP запросов
  Future<void> checkInEvent(
    String eventId, {
    required double longitude,
    required double latitude,
  }) async {
    // TODO: Реализовать POST запрос
    // final response = await _apiClient.post(
    //   '/api/events/$eventId/check-in',
    //   body: {'longitude': longitude, 'latitude': latitude},
    // );
    throw UnimplementedError('checkInEvent not implemented yet');
  }
}
