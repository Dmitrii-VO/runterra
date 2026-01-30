/// DTO-модель статистики пользователя
/// 
/// Используется для парсинга JSON ответов от API /api/users/me/profile.
/// Содержит только структуру данных без бизнес-логики и валидации.
/// 
/// ВАЖНО: На текущей стадии (skeleton) содержит только заглушки
/// без логики подсчёта статистики.
class UserStatsModel {
  /// Количество участий в тренировках
  final int trainingCount;
  
  /// Количество территорий, в захвате которых пользователь участвовал
  final int territoriesParticipated;
  
  /// Баллы личного вклада
  final int contributionPoints;

  UserStatsModel({
    required this.trainingCount,
    required this.territoriesParticipated,
    required this.contributionPoints,
  });

  /// Создает UserStatsModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      trainingCount: (json['trainingCount'] as num).toInt(),
      territoriesParticipated: (json['territoriesParticipated'] as num).toInt(),
      contributionPoints: (json['contributionPoints'] as num).toInt(),
    );
  }

  /// Преобразует UserStatsModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'trainingCount': trainingCount,
      'territoriesParticipated': territoriesParticipated,
      'contributionPoints': contributionPoints,
    };
  }
}
