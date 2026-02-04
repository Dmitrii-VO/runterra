import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/club_model.dart';

/// Сервис для работы с клубами
/// 
/// Предоставляет методы для выполнения запросов к API клубов.
/// Использует ApiClient для выполнения HTTP запросов.
class ClubsService {
  final ApiClient _apiClient;

  /// Создает ClubsService с указанным ApiClient
  ClubsService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET /api/clubs запрос к backend
  /// 
  /// Возвращает список клубов (List<ClubModel>).
  /// Парсит JSON ответ и преобразует его в типизированные модели.
  Future<List<ClubModel>> getClubs({required String cityId}) async {
    final uri = Uri(
      path: '/api/clubs',
      queryParameters: {'cityId': cityId},
    );
    final response = await _apiClient.get(uri.toString());

    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка сервера: ${response.statusCode}\n'
        'Убедитесь, что backend сервер запущен (npm run dev в папке backend)',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.',
          response.body.substring(0, response.body.length > 200 ? 200 : response.body.length),
        );
      }
      throw FormatException(
        'Ожидался JSON, но получен $contentType',
        response.body.substring(0, response.body.length > 100 ? 100 : response.body.length),
      );
    }

    try {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData.map((json) => ClubModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (e is FormatException && response.body.trim().startsWith('<!DOCTYPE')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.',
          response.body.substring(0, 200),
        );
      }
      rethrow;
    }
  }

  /// Выполняет GET /api/clubs/:id запрос к backend
  /// 
  /// Возвращает клуб по указанному id (ClubModel).
  /// Парсит JSON ответ и преобразует его в типизированную модель.
  /// 
  /// [id] - уникальный идентификатор клуба
  Future<ClubModel> getClubById(String id) async {
    final response = await _apiClient.get('/api/clubs/$id');

    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка сервера: ${response.statusCode}\n'
        'Убедитесь, что backend сервер запущен (npm run dev в папке backend)',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.',
          response.body.substring(0, response.body.length > 200 ? 200 : response.body.length),
        );
      }
      throw FormatException(
        'Ожидался JSON, но получен $contentType',
        response.body.substring(0, response.body.length > 100 ? 100 : response.body.length),
      );
    }

    try {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ClubModel.fromJson(jsonData);
    } catch (e) {
      if (e is FormatException && response.body.trim().startsWith('<!DOCTYPE')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.',
          response.body.substring(0, 200),
        );
      }
      rethrow;
    }
  }

  /// Выполняет POST /api/clubs — создание клуба.
  ///
  /// Возвращает созданный клуб (ClubModel).
  /// Бросает [ApiException] при 4xx/5xx или не-JSON ответе.
  Future<ClubModel> createClub({
    required String name,
    String? description,
    required String cityId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'cityId': cityId,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _apiClient.post('/api/clubs', body: body);

    if (response.statusCode != 201) {
      String errorMessage = 'Failed to create club (${response.statusCode})';
      String errorCode = 'create_club_error';
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

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw ApiException(
        'invalid_response',
        'Server returned non-JSON. Status: ${response.statusCode}',
      );
    }
    try {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ClubModel.fromJson(jsonData);
    } catch (e) {
      if (e is ApiException) rethrow;
      rethrow;
    }
  }

  /// Выполняет POST /api/clubs/:id/join — присоединение текущего пользователя к клубу.
  /// Бросает [ApiException] при 4xx/5xx с code и message из ответа.
  Future<void> joinClub(String clubId) async {
    final response = await _apiClient.post('/api/clubs/$clubId/join');
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String errorCode = 'join_club_error';
    String errorMessage = 'Failed to join club (${response.statusCode})';
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
}
