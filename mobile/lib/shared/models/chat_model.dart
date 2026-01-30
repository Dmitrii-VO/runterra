/// DTO-модель личного чата
/// 
/// Используется для парсинга JSON ответов от API личных переписок.
/// Содержит только структуру данных без бизнес-логики и валидации.
/// 
/// TODO: Добавить валидацию полей
/// TODO: Добавить поле для непрочитанных сообщений
/// TODO: Добавить поле для последнего сообщения (preview)
class ChatModel {
  /// Уникальный идентификатор чата
  final String id;
  
  /// ID собеседника (другого пользователя в переписке)
  final String otherUserId;
  
  /// Имя собеседника (для отображения)
  /// 
  /// TODO: Загружать из API или кэшировать отдельно
  final String? otherUserName;
  
  /// Аватар собеседника (URL или путь к изображению)
  /// 
  /// TODO: Реализовать загрузку и кэширование аватаров
  final String? otherUserAvatar;
  
  /// Дата последнего сообщения в чате
  final DateTime? lastMessageAt;
  
  /// Текст последнего сообщения (preview)
  /// 
  /// TODO: Обрезать длинные сообщения для preview
  final String? lastMessageText;
  
  /// Дата создания чата
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.otherUserId,
    this.otherUserName,
    this.otherUserAvatar,
    this.lastMessageAt,
    this.lastMessageText,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает ChatModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      otherUserId: json['otherUserId'] as String,
      otherUserName: json['otherUserName'] as String?,
      otherUserAvatar: json['otherUserAvatar'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      lastMessageText: json['lastMessageText'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует ChatModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'otherUserId': otherUserId,
      if (otherUserName != null) 'otherUserName': otherUserName,
      if (otherUserAvatar != null) 'otherUserAvatar': otherUserAvatar,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
      if (lastMessageText != null) 'lastMessageText': lastMessageText,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
