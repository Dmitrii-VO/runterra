import 'dart:convert';
import 'api_client.dart';
import '../models/city_model.dart';

/// Сервис для работы с городами
/// 
/// Предоставляет методы для выполнения запросов к API городов.
/// Использует ApiClient для выполнения HTTP запросов.
class CitiesService {
  final ApiClient _apiClient;

  /// Создает CitiesService с указанным ApiClient
  CitiesService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET /api/cities запрос к backend
  /// 
  /// Возвращает список городов (List<CityModel>).
  /// Парсит JSON ответ и преобразует его в типизированные модели.
  Future<List<CityModel>> getCities() async {
    final response = await _apiClient.get('/api/cities');

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
      return jsonData.map((json) => CityModel.fromJson(json as Map<String, dynamic>)).toList();
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

  /// Выполняет GET /api/cities/:id запрос к backend
  /// 
  /// Возвращает город по указанному id (CityModel).
  /// Парсит JSON ответ и преобразует его в типизированную модель.
  /// 
  /// [id] - уникальный идентификатор города
  Future<CityModel> getCityById(String id) async {
    final response = await _apiClient.get('/api/cities/$id');

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
      return CityModel.fromJson(jsonData);
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
