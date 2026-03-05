import 'dart:convert';
import 'api_client.dart';
import '../models/calendar_model.dart';
import '../models/profile_model.dart';
import '../models/public_profile_model.dart';
import '../models/user_nav_status.dart';
import '../models/user_search_result_model.dart';

/// Исключение при ошибке API (статус, HTML вместо JSON, неверный JSON).
class ApiException implements Exception {
  final String code;
  final String message;

  ApiException(this.code, this.message);

  @override
  String toString() => 'ApiException($code): $message';
}

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
      if (response.statusCode == 401) {
        String code = 'unauthorized';
        String message = 'Authorization required';
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          if (json['code'] != null) code = json['code'] as String;
          if (json['message'] != null) message = json['message'] as String;
        } catch (_) {}
        throw ApiException(code, message);
      }
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

  /// Обновляет профиль текущего пользователя (PATCH /api/users/me/profile).
  /// [currentCityId] — идентификатор города из /api/cities.
  /// [name] — имя пользователя. [avatarUrl] — URL фото (omit to leave unchanged, '' to clear).
  /// [profileVisible] — видимость профиля (false — скрыт от публичного поиска).
  Future<void> updateProfile({
    String? currentCityId,
    String? name,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? country,
    String? gender,
    String? avatarUrl,
    bool? profileVisible,
  }) async {
    final body = <String, dynamic>{};
    if (currentCityId != null) body['currentCityId'] = currentCityId;
    if (name != null) body['name'] = name;
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (birthDate != null) {
      body['birthDate'] =
          '${birthDate.year.toString().padLeft(4, '0')}-'
          '${birthDate.month.toString().padLeft(2, '0')}-'
          '${birthDate.day.toString().padLeft(2, '0')}';
    }
    if (country != null) body['country'] = country;
    if (gender != null) body['gender'] = gender;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;
    if (profileVisible != null) body['profileVisible'] = profileVisible;
    if (body.isEmpty) return;

    final response = await _apiClient.patch(
      '/api/users/me/profile',
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'HTTP ${response.statusCode}',
        'Не удалось обновить профиль: ${response.statusCode}. ${response.body}',
      );
    }
  }

  /// Возвращает флаги видимости вкладок навигации (hasClubs, hasTrainers).
  Future<UserNavStatus> getNavigationStatus() async {
    final response = await _apiClient.get('/api/users/me/nav-status');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return UserNavStatus.fromJson(json);
      } catch (_) {
        return UserNavStatus.initial();
      }
    }
    return UserNavStatus.initial();
  }

  /// Fetches the full public profile of another user (GET /api/users/:id/profile).
  /// Throws [ApiException] with code 'not_found' if user is hidden or doesn't exist.
  Future<PublicProfileModel> getPublicProfile(String userId) async {
    final response = await _apiClient.get('/api/users/$userId/profile');
    if (response.statusCode == 404) {
      throw ApiException('not_found', 'User not found');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('http_${response.statusCode}', 'Request failed');
    }
    return PublicProfileModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Returns raw JSON map for a user by ID (GET /api/users/:id).
  /// Used by PublicProfileScreen when no preloaded data is available.
  Future<Map<String, dynamic>> getRawUserById(String userId) async {
    final response = await _apiClient.get('/api/users/$userId');
    if (response.statusCode == 404) {
      throw ApiException('not_found', 'User not found');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('http_${response.statusCode}', 'Request failed');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Search users by name (GET /api/users/search).
  /// [query] must be at least 2 characters.
  Future<List<UserSearchResult>> searchUsers(
    String query, {
    String? cityId,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'q': query,
      'limit': '$limit',
      'offset': '$offset',
    };
    if (cityId != null) params['cityId'] = cityId;
    final queryString = Uri(queryParameters: params).query;
    final response = await _apiClient.get('/api/users/search?$queryString');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String code = 'http_${response.statusCode}';
      String message = 'Search failed: ${response.statusCode}';
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['code'] != null) code = json['code'] as String;
        if (json['message'] != null) message = json['message'] as String;
      } catch (_) {}
      throw ApiException(code, message);
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/users/me/calendar?year=&month=
  /// Returns training calendar days for the given month.
  Future<List<CalendarDayModel>> getCalendar(int year, int month) async {
    final response = await _apiClient.get(
      '/api/users/me/calendar?year=$year&month=$month',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String code = 'http_${response.statusCode}';
      String message = 'Failed to load calendar';
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['code'] != null) code = json['code'] as String;
        if (json['message'] != null) message = json['message'] as String;
      } catch (_) {}
      throw ApiException(code, message);
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final days = jsonData['days'] as List<dynamic>;
    return days
        .map((e) => CalendarDayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Удаляет аккаунт текущего пользователя (DELETE /api/users/me).
  /// После успешного удаления необходимо вызвать signOut и перейти на экран входа.
  Future<void> deleteAccount() async {
    final response = await _apiClient.delete('/api/users/me');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Could not delete account: ${response.statusCode}';
      String code = 'http_${response.statusCode}';
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['message'] != null) message = json['message'] as String;
        if (json['code'] != null) code = json['code'] as String;
      } catch (_) {}
      throw ApiException(code, message);
    }
  }
}
