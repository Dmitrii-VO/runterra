/// DTO-модель чата клуба
/// 
/// Используется для парсинга JSON ответов от API чатов клубов.
/// Содержит только структуру данных без бизнес-логики и валидации.
/// 
/// TODO: Добавить валидацию полей
/// TODO: Добавить поле для непрочитанных сообщений
/// TODO: Добавить поле для последнего сообщения (preview)
class ClubChatModel {
  /// Уникальный идентификатор чата клуба
  final String id;
  
  /// ID клуба
  final String clubId;
  
  /// Название клуба (для отображения)
  /// 
  /// TODO: Загружать из API или кэшировать отдельно
  final String? clubName;
  
  /// Описание клуба (для отображения)
  final String? clubDescription;
  
  /// Логотип клуба (URL или путь к изображению)
  /// 
  /// TODO: Реализовать загрузку и кэширование логотипов
  final String? clubLogo;
  
  /// Дата последнего сообщения в чате
  final DateTime? lastMessageAt;
  
  /// Текст последнего сообщения (preview)
  /// 
  /// TODO: Обрезать длинные сообщения для preview
  final String? lastMessageText;
  
  /// ID пользователя, отправившего последнее сообщение
  final String? lastMessageUserId;
  
  /// Дата создания чата
  final DateTime createdAt;
  
  /// Дата последнего обновления
  final DateTime updatedAt;

  ClubChatModel({
    required this.id,
    required this.clubId,
    this.clubName,
    this.clubDescription,
    this.clubLogo,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создает ClubChatModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory ClubChatModel.fromJson(Map<String, dynamic> json) {
    return ClubChatModel(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      clubName: json['clubName'] as String?,
      clubDescription: json['clubDescription'] as String?,
      clubLogo: json['clubLogo'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageUserId: json['lastMessageUserId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Преобразует ClubChatModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      if (clubName != null) 'clubName': clubName,
      if (clubDescription != null) 'clubDescription': clubDescription,
      if (clubLogo != null) 'clubLogo': clubLogo,
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt!.toIso8601String(),
      if (lastMessageText != null) 'lastMessageText': lastMessageText,
      if (lastMessageUserId != null) 'lastMessageUserId': lastMessageUserId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
