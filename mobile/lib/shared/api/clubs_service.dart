import 'dart:convert';
import 'api_client.dart';
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
  Future<List<ClubModel>> getClubs() async {
    final response = await _apiClient.get('/api/clubs');

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
}
