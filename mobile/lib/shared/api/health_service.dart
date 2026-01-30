import 'api_client.dart';

/// Сервис для проверки здоровья backend
/// 
/// Предоставляет метод для выполнения GET /health запроса.
/// Использует ApiClient для выполнения HTTP запросов.
class HealthService {
  final ApiClient _apiClient;

  /// Создает HealthService с указанным ApiClient
  HealthService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET /health запрос к backend
  /// 
  /// Возвращает строку с результатом запроса (тело ответа).
  /// В случае ошибки возвращает строку с описанием ошибки.
  /// 
  /// TODO: Добавить обработку ошибок и парсинг JSON ответа
  Future<String> getHealth() async {
    try {
      final response = await _apiClient.get('/health');
      return response.body;
    } catch (e) {
      return 'Error: $e';
    }
  }
}
