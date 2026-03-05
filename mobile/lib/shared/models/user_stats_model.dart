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
  
  /// Суммарная дистанция пробежек в км
  final double totalDistanceKm;
  
  /// Баллы личного вклада
  final int contributionPoints;

  UserStatsModel({
    required this.trainingCount,
    required this.totalDistanceKm,
    required this.contributionPoints,
  });

  /// Создает UserStatsModel из JSON
  /// 
  /// Парсит JSON объект, полученный от backend API.
  /// Не выполняет валидацию данных.
  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      trainingCount: (json['trainingCount'] as num?)?.toInt() ?? 0,
      totalDistanceKm: (json['totalDistanceKm'] as num?)?.toDouble() ?? 0.0,
      contributionPoints: (json['contributionPoints'] as num?)?.toInt() ?? 0,
    );
  }

  /// Преобразует UserStatsModel в JSON
  /// 
  /// Используется для отправки данных на backend.
  Map<String, dynamic> toJson() {
    return {
      'trainingCount': trainingCount,
      'totalDistanceKm': totalDistanceKm,
      'contributionPoints': contributionPoints,
    };
  }
}
