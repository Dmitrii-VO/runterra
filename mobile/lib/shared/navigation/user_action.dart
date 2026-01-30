/// Intent-based навигация: sealed class действий пользователя
/// 
/// Используется для декларации намерений пользователя без привязки к конкретной реализации навигации.
/// 
/// Поддерживает передачу параметров через sealed class pattern (union-like).
sealed class UserAction {
  const UserAction();
}

/// Пользователь выбрал город
class SelectCityAction extends UserAction {
  /// ID выбранного города
  final String cityId;

  const SelectCityAction({required this.cityId});
}

/// Пользователь выбрал клуб
class SelectClubAction extends UserAction {
  /// ID выбранного клуба
  final String clubId;

  const SelectClubAction({required this.clubId});
}

/// Пользователь выбрал территорию
class SelectTerritoryAction extends UserAction {
  /// ID выбранной территории
  final String territoryId;

  const SelectTerritoryAction({required this.territoryId});
}

/// Пользователь выбрал активность
class SelectActivityAction extends UserAction {
  /// ID выбранной активности
  final String activityId;

  const SelectActivityAction({required this.activityId});
}

/// Пользователь хочет открыть карту
class OpenMapAction extends UserAction {
  const OpenMapAction();
}

/// Пользователь хочет найти тренировку
class FindTrainingAction extends UserAction {
  const FindTrainingAction();
}

/// Пользователь хочет начать пробежку / Check-in
class StartRunAction extends UserAction {
  const StartRunAction();
}

/// Пользователь хочет найти клуб
class FindClubAction extends UserAction {
  const FindClubAction();
}

/// Пользователь хочет создать клуб
class CreateClubAction extends UserAction {
  const CreateClubAction();
}
