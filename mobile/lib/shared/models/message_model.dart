/// DTO-модель сообщения
/// 
/// Используется для парсинга JSON ответов от API сообщений.
/// Содержит только структуру данных без бизнес-логики и валидации.
/// 
/// TODO: Добавить валидацию полей
/// TODO: Добавить обработку вложений (изображения, файлы)
class MessageModel {
  /// Уникальный идентификатор сообщения
  final String id;
  
  /// Текст сообщения
  final String text;
  
  /// ID пользователя, отправившего сообщение
  final String userId;
  
  /// Имя пользователя, отправившего сообщение (для отображения)
  /// 
  /// TODO: Загружать из API или кэшировать отдельно
  final String? userName;
  
  /// Дата и время создания сообщения
  final DateTime createdAt;
  
  /// Дата последнего обновления сообщения
  final DateTime updatedAt;

  MessageModel({
    required this.id,
    required this.text,
    required this.userId,
    this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает MessageModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует MessageModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'userId': userId,
      if (userName != null) 'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
