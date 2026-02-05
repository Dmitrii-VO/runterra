import 'profile_club_model.dart';
import 'profile_activity_model.dart';
import 'user_stats_model.dart';
import 'notification_model.dart';

/// DTO-модель личного кабинета пользователя
/// 
/// Агрегированная модель для отображения всех данных личного кабинета.
/// Используется для парсинга JSON ответов от API /api/users/me/profile.
/// Содержит только структуру данных без бизнес-логики и валидации.
class ProfileModel {
  /// Данные пользователя
  final ProfileUserData user;
  
  /// Информация о клубе (если пользователь состоит в клубе).
  /// Явный контракт: club == null — не в клубе. UI обрабатывает
  /// club == null + isMercenary (меркатель) и club == null + !isMercenary (без клуба).
  final ProfileClubModel? club;
  
  /// Мини-статистика пользователя
  final UserStatsModel stats;
  
  /// Ближайшая активность (тренировка)
  final ProfileActivityModel? nextActivity;
  
  /// Последняя активность
  final ProfileActivityModel? lastActivity;
  
  /// Список последних уведомлений
  final List<NotificationModel> notifications;

  ProfileModel({
    required this.user,
    this.club,
    required this.stats,
    this.nextActivity,
    this.lastActivity,
    required this.notifications,
  });

  /// Создает ProfileModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      user: ProfileUserData.fromJson(json['user'] as Map<String, dynamic>),
      club: json['club'] != null
          ? ProfileClubModel.fromJson(json['club'] as Map<String, dynamic>)
          : null,
      stats: UserStatsModel.fromJson(json['stats'] as Map<String, dynamic>),
      nextActivity: json['nextActivity'] != null
          ? ProfileActivityModel.fromJson(
              json['nextActivity'] as Map<String, dynamic>)
          : null,
      lastActivity: json['lastActivity'] != null
          ? ProfileActivityModel.fromJson(
              json['lastActivity'] as Map<String, dynamic>)
          : null,
      notifications: (json['notifications'] as List<dynamic>)
          .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Преобразует ProfileModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      if (club != null) 'club': club!.toJson(),
      'stats': stats.toJson(),
      if (nextActivity != null) 'nextActivity': nextActivity!.toJson(),
      if (lastActivity != null) 'lastActivity': lastActivity!.toJson(),
      'notifications': notifications.map((n) => n.toJson()).toList(),
    };
  }
}

/// Данные пользователя для личного кабинета
class ProfileUserData {
  /// Уникальный идентификатор пользователя
  final String id;
  
  /// Имя пользователя
  final String name;

  /// Имя (раздельно)
  final String? firstName;

  /// Фамилия (раздельно)
  final String? lastName;

  /// Дата рождения
  final DateTime? birthDate;

  /// Страна
  final String? country;

  /// Пол
  final String? gender;
  
  /// URL фото профиля (опционально)
  final String? avatarUrl;
  
  /// Идентификатор города пользователя (опционально)
  final String? cityId;
  
  /// Название города (опционально, для удобства)
  final String? cityName;
  
  /// Идентификатор основного клуба (для фильтра «Мой клуб»)
  final String? primaryClubId;

  /// Флаг меркателя (true - меркатель, false - участник клуба)
  final bool isMercenary;

  /// Статус пользователя
  ///
  /// Возможные значения: 'active', 'inactive', 'blocked'
  final String status;

  ProfileUserData({
    required this.id,
    required this.name,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.country,
    this.gender,
    this.avatarUrl,
    this.cityId,
    this.cityName,
    this.primaryClubId,
    required this.isMercenary,
    required this.status,
  });

  /// Создает ProfileUserData из JSON
  factory ProfileUserData.fromJson(Map<String, dynamic> json) {
    return ProfileUserData(
      id: json['id'] as String,
      name: json['name'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      country: json['country'] as String?,
      gender: json['gender'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      cityId: json['cityId'] as String?,
      cityName: json['cityName'] as String?,
      primaryClubId: json['primaryClubId'] as String?,
      isMercenary: json['isMercenary'] as bool? ?? false,
      status: json['status'] as String,
    );
  }

  /// Преобразует ProfileUserData в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
      if (country != null) 'country': country,
      if (gender != null) 'gender': gender,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (cityId != null) 'cityId': cityId,
      if (cityName != null) 'cityName': cityName,
      if (primaryClubId != null) 'primaryClubId': primaryClubId,
      'isMercenary': isMercenary,
      'status': status,
    };
  }
}
