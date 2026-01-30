import 'dart:convert';
import 'api_client.dart';
import '../models/profile_model.dart';

/// Сервис для работы с пользователями
/// 
/// Предоставляет методы для выполнения запросов к API пользователей.
/// Использует ApiClient для выполнения HTTP запросов.
class UsersService {
  final ApiClient _apiClient;

  /// Создает UsersService с указанным ApiClient
  UsersService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET /api/users/me/profile запрос к backend
  /// 
  /// Возвращает агрегированные данные личного кабинета (ProfileModel).
  /// Парсит JSON ответ и преобразует его в типизированную модель.
  /// 
  /// Бросает [ApiException], если сервер вернул не 2xx, HTML вместо JSON
  /// (например, 404 от Next.js при запущенной админке вместо backend) или неверный JSON.
  /// 
  /// TODO: Добавить авторизацию (передача токена)
  Future<ProfileModel> getProfile() async {
    final response = await _apiClient.get('/api/users/me/profile');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'HTTP ${response.statusCode}',
        'Сервер вернул ошибку ${response.statusCode}. '
        'Убедитесь, что запущен backend (npm run dev в папке backend).',
      );
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      throw ApiException(
        'Пустой ответ',
        'Сервер вернул пустое тело. Проверьте, что backend запущен.',
      );
    }
    if (body.toLowerCase().startsWith('<!doctype') ||
        body.toLowerCase().startsWith('<html')) {
      throw ApiException(
        'HTML вместо JSON',
        'Сервер вернул HTML вместо JSON (ожидался API). '
        'Часто это значит, что на порту 3000 запущена админка (Next.js), а не backend. '
        'Остановите админку и запустите backend: npm run dev в папке backend.',
      );
    }

    try {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return ProfileModel.fromJson(jsonData);
    } on FormatException catch (e) {
      throw ApiException(
        'Ошибка разбора JSON',
        'Не удалось разобрать ответ сервера. ${e.message} '
        'Убедитесь, что запрос идёт на backend (порт 3000), а не на админку.',
      );
    }
  }
}

/// Исключение при ошибке API (статус, HTML вместо JSON, неверный JSON).
class ApiException implements Exception {
  final String code;
  final String message;

  ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}
