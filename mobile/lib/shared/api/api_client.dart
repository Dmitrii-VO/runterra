import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

/// Базовый HTTP клиент для работы с backend API
///
/// Предоставляет базовый функционал для выполнения HTTP запросов.
/// Поддерживает опциональный [authToken]: при задании ко всем запросам
/// добавляется заголовок Authorization: Bearer &lt;token&gt; (ожидается backend auth middleware).
/// Получение токена (например Firebase ID token) и передача в ApiClient — ответственность вызывающего кода.
///
/// В production используйте [getInstance]: один экземпляр на приложение, один [http.Client],
/// чтобы не создавать новые сокеты на каждый экран (утечка ресурсов). Конструктор остаётся
/// для тестов и для явного создания с инъекцией [client].
/// 
/// TODO: Add retry logic with exponential backoff for network failures
class ApiClient {
  static ApiClient? _instance;

  /// Единственный экземпляр для приложения; переиспользует один [http.Client].
  /// Первый вызов создаёт экземпляр; последующие возвращают его (baseUrl/authToken первого вызова).
  /// Для тестов или сброса можно вызвать [dispose], тогда следующий getInstance создаст новый экземпляр.
  static ApiClient getInstance({
    required String baseUrl,
    String? authToken,
    http.Client? client,
  }) {
    _instance ??= ApiClient(baseUrl: baseUrl, authToken: authToken, client: client);
    return _instance!;
  }

  final String baseUrl;
  /// Optional Firebase ID token; when set, all requests get Authorization: Bearer header.
  /// Mutable: call [updateToken] after login/logout to change.
  String? _authToken;
  String? get authToken => _authToken;
  final http.Client _client;
  final bool _ownsClient;

  /// Обновить токен авторизации (вызывать после логина/логаута)
  void updateToken(String? token) {
    _authToken = token;
  }

  /// Таймаут для HTTP запросов (30 секунд)
  ///
  /// ЗАЧЕМ: Предотвращает бесконечное ожидание при проблемах с сетью
  static const Duration _timeout = Duration(seconds: 30);

  /// Headers added to every request when [authToken] is set.
  Map<String, String> get _authHeaders {
    if (_authToken == null || _authToken!.isEmpty) return const {};
    return {'Authorization': 'Bearer ${_authToken!}'};
  }

  /// Создает ApiClient с указанным baseUrl и опциональным токеном авторизации.
  /// Для production используйте [getInstance]. Конструктор — для тестов и инъекции [client].
  ///
  /// [baseUrl] - базовый URL backend API (например: 'http://localhost:3000')
  /// [authToken] - опциональный ID token (например Firebase); при задании подставляется в Authorization
  /// [client] - опциональная инъекция; если не задан, создаётся свой и закрывается в [dispose]
  ApiClient({
    required this.baseUrl,
    String? authToken,
    http.Client? client,
  })  : _authToken = authToken,
        _client = client ?? http.Client(),
        _ownsClient = client == null;

  /// Выполняет GET запрос к указанному endpoint
  /// 
  /// [endpoint] - путь относительно baseUrl (например: '/health')
  /// Возвращает Response от http пакета
  /// 
  /// Бросает TimeoutException если запрос превышает таймаут
  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final headers = _authHeaders;

    final response = await _client.get(uri, headers: headers).timeout(
      _timeout,
      onTimeout: () {
        throw TimeoutException(
          'Запрос к $uri превысил таймаут (${_timeout.inSeconds} секунд). '
          'Проверьте, что backend сервер запущен и доступен.',
          _timeout,
        );
      },
    );
    
    return response;
  }

  /// Выполняет POST запрос к указанному endpoint
  /// 
  /// [endpoint] - путь относительно baseUrl (например: '/api/runs')
  /// [body] - тело запроса в формате JSON (будет преобразовано в строку)
  /// [headers] - дополнительные заголовки (опционально)
  /// Возвращает Response от http пакета
  /// 
  /// Бросает TimeoutException если запрос превышает таймаут
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final requestHeaders = {
      ..._authHeaders,
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    
    final response = await _client
        .post(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(
          _timeout,
          onTimeout: () {
            throw TimeoutException(
              'Запрос к $uri превысил таймаут (${_timeout.inSeconds} секунд). '
              'Проверьте, что backend сервер запущен и доступен.',
              _timeout,
            );
          },
        );
    
    return response;
  }

  /// Выполняет PATCH запрос к указанному endpoint
  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      ..._authHeaders,
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    final response = await _client
        .patch(
          uri,
          headers: requestHeaders,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(
          _timeout,
          onTimeout: () {
            throw TimeoutException(
              'Запрос к $uri превысил таймаут (${_timeout.inSeconds} секунд). '
              'Проверьте, что backend сервер запущен и доступен.',
              _timeout,
            );
          },
        );
    return response;
  }

  /// Закрывает [http.Client], если он был создан этим экземпляром.
  /// Для синглтона (полученного через [getInstance]) сбрасывает статический экземпляр,
  /// чтобы следующий [getInstance] создал новый. Вызывать в production не обязательно;
  /// предназначено для тестов и явного завершения (например при logout).
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
    if (_instance == this) {
      _instance = null;
    }
  }
}
