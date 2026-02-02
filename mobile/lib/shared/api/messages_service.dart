import 'dart:convert';
import 'api_client.dart';
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/club_chat_model.dart';

/// Сервис для работы с сообщениями
/// 
/// Предоставляет методы для выполнения запросов к API сообщений.
/// Использует ApiClient для выполнения HTTP запросов.
class MessagesService {
  final ApiClient _apiClient;

  /// Создает MessagesService с указанным ApiClient
  MessagesService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET запрос для получения сообщений общего чата (городской чат).
  /// Backend использует cityId текущего пользователя из БД.
  Future<List<MessageModel>> getGlobalChatMessages({int limit = 50, int offset = 0}) async {
    final endpoint = '/api/messages/global?limit=$limit&offset=$offset';
    final response = await _apiClient.get(endpoint);

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        final body = _tryParseJson(response.body);
        if (body != null && body['code'] == 'user_city_required') {
          throw Exception(
            body['message'] as String? ?? 'Укажите город в профиле, чтобы участвовать в чате',
          );
        }
      }
      if (response.statusCode == 401) {
        throw Exception('Требуется авторизация');
      }
      throw Exception(
        'Ошибка загрузки сообщений: ${response.statusCode}\n${response.body}',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      throw FormatException(
        'Ожидался JSON, получен: $contentType',
        response.body,
      );
    }

    try {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw FormatException(
        'Не удалось разобрать ответ сервера',
        response.body,
      );
    }
  }

  static Map<String, dynamic>? _tryParseJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Выполняет GET запрос для получения списка личных переписок
  /// 
  /// TODO: Реализовать запрос к /api/messages/chats
  /// TODO: Добавить обработку ошибок HTTP запросов
  /// TODO: Добавить сортировку по дате последнего сообщения
  Future<List<ChatModel>> getPrivateChats() async {
    // TODO: Реализовать реальный запрос к backend API
    // final response = await _apiClient.get('/api/messages/chats');
    // final jsonData = jsonDecode(response.body) as List<dynamic>;
    // return jsonData.map((json) => ChatModel.fromJson(json as Map<String, dynamic>)).toList();
    
    // Заглушка: возвращаем пустой список
    return [];
  }

  /// Выполняет GET запрос для получения списка чатов клубов
  /// 
  /// TODO: Реализовать запрос к /api/messages/clubs
  /// TODO: Добавить обработку ошибок HTTP запросов
  /// TODO: Добавить фильтрацию по клубам, в которых состоит пользователь
  /// TODO: Добавить сортировку по дате последнего сообщения
  Future<List<ClubChatModel>> getClubChats() async {
    // TODO: Реализовать реальный запрос к backend API
    // final response = await _apiClient.get('/api/messages/clubs');
    // final jsonData = jsonDecode(response.body) as List<dynamic>;
    // return jsonData.map((json) => ClubChatModel.fromJson(json as Map<String, dynamic>)).toList();
    
    // Заглушка: возвращаем пустой список
    return [];
  }

  /// Выполняет GET запрос для получения сообщений конкретного личного чата
  /// 
  /// [chatId] - уникальный идентификатор чата
  /// 
  /// TODO: Реализовать запрос к /api/messages/chats/:chatId
  /// TODO: Добавить пагинацию (limit, offset)
  /// TODO: Добавить обработку ошибок HTTP запросов
  Future<List<MessageModel>> getChatMessages(String chatId) async {
    // TODO: Реализовать реальный запрос к backend API
    // final response = await _apiClient.get('/api/messages/chats/$chatId');
    // final jsonData = jsonDecode(response.body) as List<dynamic>;
    // return jsonData.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
    
    // Заглушка: возвращаем пустой список
    return [];
  }

  /// Выполняет GET запрос для получения сообщений чата клуба
  /// 
  /// [clubId] - уникальный идентификатор клуба
  /// 
  /// TODO: Реализовать запрос к /api/messages/clubs/:clubId
  /// TODO: Добавить пагинацию (limit, offset)
  /// TODO: Добавить обработку ошибок HTTP запросов
  Future<List<MessageModel>> getClubChatMessages(String clubId) async {
    // TODO: Реализовать реальный запрос к backend API
    // final response = await _apiClient.get('/api/messages/clubs/$clubId');
    // final jsonData = jsonDecode(response.body) as List<dynamic>;
    // return jsonData.map((json) => MessageModel.fromJson(json as Map<String, dynamic>)).toList();
    
    // Заглушка: возвращаем пустой список
    return [];
  }

  /// Выполняет POST запрос для отправки сообщения в общий чат (городской чат).
  Future<MessageModel> sendGlobalMessage(String text) async {
    final response = await _apiClient.post(
      '/api/messages/global',
      body: {'text': text.trim()},
    );

    if (response.statusCode == 201) {
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        throw FormatException('Ожидался JSON', response.body);
      }
      try {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        return MessageModel.fromJson(jsonData);
      } catch (_) {
        throw FormatException(
          'Не удалось разобрать ответ сервера',
          response.body,
        );
      }
    }

    if (response.statusCode == 400) {
      final body = _tryParseJson(response.body);
      if (body != null && body['code'] == 'validation_error') {
        final details = body['details'];
        final fields = details is Map && details['fields'] is List
            ? (details['fields'] as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        final msg = fields.isNotEmpty
            ? (fields.first['message'] as String? ?? 'Ошибка валидации')
            : (body['message'] as String? ?? 'Ошибка валидации');
        throw Exception(msg);
      }
      if (body != null && body['code'] == 'user_city_required') {
        throw Exception(
          body['message'] as String? ?? 'Укажите город в профиле',
        );
      }
    }
    if (response.statusCode == 401) {
      throw Exception('Требуется авторизация');
    }
    throw Exception(
      'Ошибка отправки сообщения: ${response.statusCode}\n${response.body}',
    );
  }

  /// Выполняет POST запрос для отправки сообщения в личный чат
  /// 
  /// [chatId] - уникальный идентификатор чата
  /// [text] - текст сообщения
  /// 
  /// TODO: Реализовать запрос к POST /api/messages/chats/:chatId
  /// TODO: Добавить валидацию текста сообщения
  /// TODO: Добавить обработку ошибок HTTP запросов
  Future<MessageModel> sendChatMessage(String chatId, String text) async {
    // TODO: Реализовать реальный запрос к backend API
    // final response = await _apiClient.post('/api/messages/chats/$chatId', body: {'text': text});
    // final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    // return MessageModel.fromJson(jsonData);
    
    // Заглушка: выбрасываем исключение
    throw UnimplementedError('sendChatMessage not implemented yet');
  }

  /// Выполняет POST запрос для отправки сообщения в чат клуба
  /// 
  /// [clubId] - уникальный идентификатор клуба
  /// [text] - текст сообщения
  /// 
  /// TODO: Реализовать запрос к POST /api/messages/clubs/:clubId
  /// TODO: Добавить валидацию текста сообщения
  /// TODO: Добавить обработку ошибок HTTP запросов
  Future<MessageModel> sendClubMessage(String clubId, String text) async {
    // TODO: Реализовать реальный запрос к backend API
    // final response = await _apiClient.post('/api/messages/clubs/$clubId', body: {'text': text});
    // final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    // return MessageModel.fromJson(jsonData);
    
    // Заглушка: выбрасываем исключение
    throw UnimplementedError('sendClubMessage not implemented yet');
  }
}
