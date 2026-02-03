import 'package:go_router/go_router.dart';
import 'user_action.dart';

/// Централизованный обработчик навигации через UserAction
/// 
/// Обеспечивает единую точку обработки действий пользователя
/// и маппинг их на маршруты GoRouter.
/// 
/// Все навигационные действия должны проходить через этот handler,
/// а не через прямые вызовы Navigator или GoRouter в UI-компонентах.
class NavigationHandler {
  final GoRouter router;

  NavigationHandler({required this.router});

  /// Обрабатывает действие пользователя и выполняет соответствующую навигацию
  /// 
  /// Маппинг действий:
  /// - SelectClubAction(clubId) → /club/:id
  /// - SelectCityAction(cityId) → /city/:id
  /// - SelectTerritoryAction(territoryId) → /territory/:id
  /// - SelectActivityAction(activityId) → /activity/:id
  /// - OpenMapAction → /map
  /// - FindTrainingAction → TODO: экран поиска тренировок
  /// - StartRunAction → TODO: экран начала пробежки
  /// - FindClubAction → TODO: экран поиска клубов
  /// - CreateClubAction → TODO: экран создания клуба
  void handle(UserAction action) {
    switch (action) {
      case SelectClubAction(clubId: final clubId):
        router.push('/club/$clubId');
        break;
      case SelectCityAction(cityId: final cityId):
        router.push('/city/$cityId');
        break;
      case SelectTerritoryAction(territoryId: final territoryId):
        router.push('/territory/$territoryId');
        break;
      case SelectActivityAction(activityId: final activityId):
        router.push('/activity/$activityId');
        break;
      case OpenMapAction():
        router.go('/map');
        break;
      case FindTrainingAction():
        router.go('/events');
        break;
      case StartRunAction():
        router.go('/run');
        break;
      case FindClubAction():
        router.go('/map');
        break;
      case CreateClubAction():
        // TODO: Реализовать навигацию к экрану создания клуба
        break;
    }
  }
}
