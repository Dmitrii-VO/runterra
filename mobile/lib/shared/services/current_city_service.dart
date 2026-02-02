import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/users_service.dart';
import '../api/cities_service.dart';
import '../models/profile_model.dart';
import '../models/city_model.dart';

/// Сервис для хранения и получения текущего города пользователя.
///
/// Источники правды:
/// - backend профиль (`ProfileUserData.cityId`);
/// - локальное хранилище (SharedPreferences) для быстрого старта.
class CurrentCityService extends ChangeNotifier {
  static const _storageKeyCurrentCityId = 'currentCityId';

  final UsersService _usersService;
  final CitiesService _citiesService;

  String? _currentCityId;
  bool _initialized = false;

  CurrentCityService({
    required UsersService usersService,
    required CitiesService citiesService,
  })  : _usersService = usersService,
        _citiesService = citiesService;

  bool get isInitialized => _initialized;

  String? get currentCityId => _currentCityId;

  /// Загружает текущий город:
  /// - сначала из локального хранилища;
  /// - затем из backend профиля (если доступен).
  Future<void> init() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _currentCityId = prefs.getString(_storageKeyCurrentCityId);

    try {
      final ProfileModel profile = await _usersService.getProfile();
      final String? profileCityId = profile.user.cityId;

      if (profileCityId != null && profileCityId.isNotEmpty) {
        _currentCityId = profileCityId;
        await prefs.setString(_storageKeyCurrentCityId, profileCityId);
      }
    } catch (_) {
      // Профиль может быть недоступен (offline / ошибка API) — используем только локальное значение.
    }

    _initialized = true;
    notifyListeners();
  }

  /// Устанавливает текущий город и сохраняет его локально.
  /// Синхронизация с backend выполняется вызывающим кодом (например ProfileScreen через UsersService.updateProfile).
  Future<void> setCurrentCityId(String cityId) async {
    _currentCityId = cityId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKeyCurrentCityId, cityId);
    notifyListeners();
  }

  /// Возвращает модель текущего города по currentCityId, если она известна.
  Future<CityModel?> getCurrentCity() async {
    if (_currentCityId == null || _currentCityId!.isEmpty) {
      return null;
    }

    try {
      return await _citiesService.getCityById(_currentCityId!);
    } catch (_) {
      // В случае ошибки (неизвестный город / сетевой сбой) возвращаем null.
      return null;
    }
  }
}

