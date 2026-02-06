import 'dart:convert';
import 'api_client.dart';
import 'users_service.dart' show ApiException;
import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/club_chat_model.dart';

/// Сервис для работы с сообщениями
/// 
/// Предоставляет методы для выполнения запросов к API сообщений.
/// Использует ApiClient для выполнения HTTP запросов.
class MessagesService {
  // ignore: unused_field - used when club/personal chat methods are implemented
  final ApiClient _apiClient;

  /// Создает MessagesService с указанным ApiClient
  MessagesService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Выполняет GET запрос для получения списка личных переписок.
  ///
  /// NOTE: Personal chats are not part of MVP backend yet.
  /// This method returns an empty list to keep API stable.
  Future<List<ChatModel>> getPrivateChats() async {
    return [];
  }

  /// Выполняет GET запрос для получения списка чатов клубов.
  Future<List<ClubChatModel>> getClubChats() async {
    final response = await _apiClient.get('/api/messages/clubs');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((json) => ClubChatModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_club_chats_error');
  }

  /// Выполняет GET запрос для получения сообщений конкретного личного чата.
  ///
  /// NOTE: Personal chats backend API is not implemented in MVP.
  /// Returns an empty list to keep client code simple.
  Future<List<MessageModel>> getChatMessages(String chatId) async {
    return [];
  }

  /// Выполняет GET запрос для получения сообщений чата клуба.
  ///
  /// [clubId] - уникальный идентификатор клуба
  /// [limit]/[offset] - параметры пагинации
  Future<List<MessageModel>> getClubChatMessages(
    String clubId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _apiClient.get(
      '/api/messages/clubs/$clubId?limit=$limit&offset=$offset',
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as List<dynamic>;
      return jsonData
          .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }
    _throwApiException(response, 'get_club_messages_error');
  }

  /// Выполняет POST запрос для отправки сообщения в личный чат.
  ///
  /// NOTE: Personal chats backend API отсутствует, поэтому метод помечен
  /// как не реализованный, чтобы явно сигнализировать о невозможности операции.
  Future<MessageModel> sendChatMessage(String chatId, String text) async {
    throw UnimplementedError('Personal chats are not implemented in MVP');
  }

  /// Выполняет POST запрос для отправки сообщения в чат клуба.
  ///
  /// [clubId] - идентификатор клуба
  /// [text] - текст сообщения
  Future<MessageModel> sendClubMessage(String clubId, String text) async {
    final response = await _apiClient.post(
      '/api/messages/clubs/$clubId',
      body: {'text': text},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      return MessageModel.fromJson(jsonData);
    }
    _throwApiException(response, 'send_club_message_error');
  }

  Never _throwApiException(dynamic response, String fallbackCode) {
    String errorCode = fallbackCode;
    String errorMessage = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
      if (decoded != null) {
        errorCode = (decoded['code'] as String?) ?? errorCode;
        errorMessage = (decoded['message'] as String?) ?? errorMessage;
      }
    } on FormatException {
      // Non-JSON response
    }
    // Reuse ApiException from users_service.dart
    throw ApiException(errorCode, errorMessage);
  }
}
