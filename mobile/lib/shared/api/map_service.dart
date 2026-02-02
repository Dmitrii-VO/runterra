import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/map_data_model.dart';

/// Сервис для работы с картой
/// 
/// Предоставляет методы для выполнения запросов к API карты.
/// Использует ApiClient для выполнения HTTP запросов.
class MapService {
  final ApiClient _apiClient;

  /// Создает MapService с указанным ApiClient
  MapService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET /api/map/data запрос к backend
  /// 
  /// Возвращает данные для отображения на карте (территории + события).
  /// 
  /// [cityId] - идентификатор города (обязателен)
  /// [bounds] - границы видимой области карты (опционально, формат: "minLng,minLat,maxLng,maxLat")
  /// [dateFilter] - фильтр по дате: 'today' | 'week' (опционально)
  /// [clubId] - фильтр по клубу (опционально)
  /// [onlyActive] - только активные территории (опционально)
  /// 
  /// TODO: Реализовать реальную фильтрацию на backend
  Future<MapDataModel> getMapData({
    required String cityId,
    String? bounds,
    String? dateFilter,
    String? clubId,
    bool? onlyActive,
  }) async {
    // Формируем query параметры
    final queryParams = <String, String>{'cityId': cityId};
    if (bounds != null) queryParams['bounds'] = bounds;
    if (dateFilter != null) queryParams['dateFilter'] = dateFilter;
    if (clubId != null) queryParams['clubId'] = clubId;
    if (onlyActive != null) queryParams['onlyActive'] = onlyActive.toString();
    
    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
    
    final response = await _apiClient.get('/api/map/data$queryString');
    
    if (response.statusCode == 401) {
      throw ApiException('unauthorized', 'Authorization required');
    }

    // Проверяем, что ответ - JSON
    if (response.statusCode != 200) {
      throw Exception(
        'Ошибка сервера: ${response.statusCode}\n'
        'Убедитесь, что backend сервер запущен (npm run dev в папке backend)',
      );
    }
    
    // Проверяем Content-Type
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (response.body.trim().startsWith('<!DOCTYPE') || 
          response.body.trim().startsWith('<html')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.\n\n'
          'Убедитесь, что:\n'
          '1. Backend сервер запущен: cd backend && npm run dev\n'
          '2. Сервер слушает на порту 3000\n'
          '3. Роутер /api/map подключен в backend/src/api/index.ts\n'
          '4. Для Android эмулятора используется адрес http://10.0.2.2:3000',
          response.body.substring(0, response.body.length > 200 ? 200 : response.body.length),
        );
      }
      throw FormatException(
        'Ожидался JSON, но получен $contentType\n'
        'Проверьте, что backend сервер запущен и роутер /api/map/data работает.',
        response.body.substring(0, response.body.length > 100 ? 100 : response.body.length),
      );
    }
    
    try {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return MapDataModel.fromJson(jsonData);
    } catch (e) {
      if (e is FormatException && response.body.trim().startsWith('<!DOCTYPE')) {
        throw FormatException(
          'Получен HTML вместо JSON. Backend сервер не запущен или роутер не зарегистрирован.\n\n'
          'Убедитесь, что:\n'
          '1. Backend сервер запущен: cd backend && npm run dev\n'
          '2. Сервер слушает на порту 3000\n'
          '3. Роутер /api/map подключен в backend/src/api/index.ts',
          response.body.substring(0, 200),
        );
      }
      rethrow;
    }
  }
}
