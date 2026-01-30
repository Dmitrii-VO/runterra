import 'dart:convert';
import 'api_client.dart';
import '../models/activity_model.dart';

/// Сервис для работы с активностями
/// 
/// Предоставляет методы для выполнения запросов к API активностей.
/// Использует ApiClient для выполнения HTTP запросов.
class ActivitiesService {
  final ApiClient _apiClient;

  /// Создает ActivitiesService с указанным ApiClient
  ActivitiesService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET /api/activities/:id запрос к backend
  /// 
  /// Возвращает активность по указанному id (ActivityModel).
  /// Парсит JSON ответ и преобразует его в типизированную модель.
  /// 
  /// [id] - уникальный идентификатор активности
  Future<ActivityModel> getActivityById(String id) async {
    final response = await _apiClient.get('/api/activities/$id');

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
      return ActivityModel.fromJson(jsonData);
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
