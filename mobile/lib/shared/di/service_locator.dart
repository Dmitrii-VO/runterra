import '../api/activities_service.dart';
import '../api/api_client.dart';
import '../api/cities_service.dart';
import '../api/clubs_service.dart';
import '../api/events_service.dart';
import '../api/map_service.dart';
import '../api/messages_service.dart';
import '../api/run_service.dart';
import '../api/territories_service.dart';
import '../api/users_service.dart';
import '../auth/auth_service.dart';
import '../config/api_config.dart';
import '../location/location_service.dart';
import '../services/current_city_service.dart';
import '../services/current_club_service.dart';

/// Simple service locator: single ApiClient and shared services created once at app start.
///
/// PURPOSE: Avoid creating ApiClient/XxxService per screen (connection reuse, no resource leak).
/// Call [init] from main() before runApp. Screens use [activitiesService], [eventsService], etc.
/// 
/// AUTH: Call [updateAuthToken] after login/logout to update the token in ApiClient.
class ServiceLocator {
  ServiceLocator._();

  static bool _initialized = false;
  static late final ApiClient _apiClient;
  static late final LocationService _locationService;
  static late final ActivitiesService _activitiesService;
  static late final CitiesService _citiesService;
  static late final ClubsService _clubsService;
  static late final EventsService _eventsService;
  static late final MapService _mapService;
  static late final MessagesService _messagesService;
  static late final RunService _runService;
  static late final TerritoriesService _territoriesService;
  static late final UsersService _usersService;
  static late final CurrentCityService _currentCityService;
  static late final CurrentClubService _currentClubService;

  /// Initialize shared ApiClient and all services. Call once from main() before runApp.
  static void init() {
    if (_initialized) return;
    final baseUrl = ApiConfig.getBaseUrl();
    _apiClient = ApiClient.getInstance(baseUrl: baseUrl);
    _locationService = LocationService();
    _activitiesService = ActivitiesService(apiClient: _apiClient);
    _citiesService = CitiesService(apiClient: _apiClient);
    _clubsService = ClubsService(apiClient: _apiClient);
    _eventsService = EventsService(apiClient: _apiClient);
    _mapService = MapService(apiClient: _apiClient);
    _messagesService = MessagesService(apiClient: _apiClient);
    _territoriesService = TerritoriesService(apiClient: _apiClient);
    _usersService = UsersService(apiClient: _apiClient);
    _runService = RunService(
      apiClient: _apiClient,
      locationService: _locationService,
    );
    _currentCityService = CurrentCityService(
      usersService: _usersService,
      citiesService: _citiesService,
    );
    _currentClubService = CurrentClubService(usersService: _usersService);
    _initialized = true;
  }

  static ApiClient get apiClient => _apiClient;
  static LocationService get locationService => _locationService;
  static ActivitiesService get activitiesService => _activitiesService;
  static CitiesService get citiesService => _citiesService;
  static ClubsService get clubsService => _clubsService;
  static EventsService get eventsService => _eventsService;
  static MapService get mapService => _mapService;
  static MessagesService get messagesService => _messagesService;
  static RunService get runService => _runService;
  static TerritoriesService get territoriesService => _territoriesService;
  static UsersService get usersService => _usersService;
  static CurrentCityService get currentCityService => _currentCityService;
  static CurrentClubService get currentClubService => _currentClubService;

  /// Обновить токен авторизации в ApiClient
  /// Вызывать после логина (с токеном) или логаута (с null)
  static void updateAuthToken(String? token) {
    _apiClient.updateToken(token);
  }

  /// Обновить токен из текущего пользователя Firebase
  /// Удобный метод для вызова после логина
  static Future<void> refreshAuthToken() async {
    final token = await AuthService.instance.getIdToken();
    updateAuthToken(token);
  }
}
